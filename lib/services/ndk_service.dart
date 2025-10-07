import 'dart:async';
import 'dart:convert';
import 'package:ndk/ndk.dart';
import 'package:ndk/domain_layer/entities/nip_01_event.dart';
import 'key_service.dart';
import 'recovery_notification_service.dart';
import 'lockbox_share_service.dart';
import 'logger.dart';
import '../models/shard_data.dart';
import '../models/recovery_request.dart';

/// Service for managing NDK (Nostr Development Kit) connections and subscriptions
/// Handles real-time listening for recovery requests and key share events
class NdkService {
  static Ndk? _ndk;
  static bool _isInitialized = false;
  static NdkResponse? _recoveryRequestSubscription;
  static NdkResponse? _keyShareSubscription;
  static final List<String> _activeRelays = [];
  static StreamSubscription<Nip01Event>? _recoveryStreamSub;
  static StreamSubscription<Nip01Event>? _keyShareStreamSub;

  /// Initialize NDK with current user's key and set up subscriptions
  static Future<void> initialize() async {
    if (_isInitialized) {
      Log.info('NDK already initialized');
      return;
    }

    try {
      // Get current user's key pair
      final keyPair = await KeyService.getStoredNostrKey();
      if (keyPair == null) {
        throw Exception('No key pair available. Cannot initialize NDK.');
      }

      // Initialize NDK with default config
      _ndk = Ndk.defaultConfig();

      // Login with user's private key
      _ndk!.accounts.loginPrivateKey(
        pubkey: keyPair.publicKey,
        privkey: keyPair.privateKey!,
      );

      _isInitialized = true;
      Log.info('NDK initialized successfully with pubkey: ${keyPair.publicKey}');

      // Start listening for events if we have relays
      if (_activeRelays.isNotEmpty) {
        await _setupSubscriptions();
      }
    } catch (e) {
      Log.error('Error initializing NDK', e);
      throw Exception('Failed to initialize NDK: $e');
    }
  }

  /// Add a relay and start listening to it immediately
  static Future<void> addRelay(String relayUrl) async {
    if (!_isInitialized) {
      await initialize();
    }

    if (_activeRelays.contains(relayUrl)) {
      Log.info('Relay already active: $relayUrl');
      return;
    }

    try {
      _activeRelays.add(relayUrl);
      Log.info('Added relay: $relayUrl (total active: ${_activeRelays.length})');

      // Restart subscriptions to include new relay
      await _setupSubscriptions();
    } catch (e) {
      Log.error('Error adding relay $relayUrl', e);
      _activeRelays.remove(relayUrl);
    }
  }

  /// Remove a relay from active listening
  static Future<void> removeRelay(String relayUrl) async {
    _activeRelays.remove(relayUrl);
    Log.info('Removed relay: $relayUrl (remaining active: ${_activeRelays.length})');

    // Restart subscriptions without this relay
    if (_activeRelays.isNotEmpty) {
      await _setupSubscriptions();
    } else {
      await stopListening();
    }
  }

  /// Set up subscriptions for recovery requests and key shares
  static Future<void> _setupSubscriptions() async {
    if (!_isInitialized || _ndk == null) {
      Log.warning('Cannot setup subscriptions: NDK not initialized');
      return;
    }

    // Get current user's pubkey
    final keyPair = await KeyService.getStoredNostrKey();
    if (keyPair == null) {
      Log.error('No key pair available for subscriptions');
      return;
    }

    final myPubkey = keyPair.publicKey;

    // Close existing subscriptions
    await _closeSubscriptions();

    Log.info('Setting up NDK subscriptions on ${_activeRelays.length} relays');

    // Subscribe to recovery request DMs (kind 4 encrypted direct messages)
    // These are recovery requests sent TO us (we are in the 'p' tag)
    _recoveryRequestSubscription = _ndk!.requests.subscription(
      filters: [
        Filter(
          kinds: [4], // Encrypted DMs
          pTags: [myPubkey], // Messages sent to us
          limit: 100, // Get recent messages
        ),
      ],
      explicitRelays: _activeRelays,
    );

    // Listen to recovery request stream
    _recoveryStreamSub = _recoveryRequestSubscription!.stream.listen(
      (event) => _handleRecoveryRequest(event),
      onError: (error) => Log.error('Error in recovery request stream', error),
    );

    // Subscribe to gift wrap key shares (kind 1059)
    // These are encrypted key shares sent TO us
    _keyShareSubscription = _ndk!.requests.subscription(
      filters: [
        Filter(
          kinds: [1059], // Gift wrap events
          pTags: [myPubkey], // Shares sent to us
          limit: 100, // Get recent shares
        ),
      ],
      explicitRelays: _activeRelays,
    );

    // Listen to key share stream
    _keyShareStreamSub = _keyShareSubscription!.stream.listen(
      (event) => _handleKeyShare(event),
      onError: (error) => Log.error('Error in key share stream', error),
    );

    Log.info('NDK subscriptions active for recovery requests (kind 4) and key shares (kind 1059)');
  }

  /// Handle incoming recovery request event (kind 4 DM)
  static Future<void> _handleRecoveryRequest(Nip01Event event) async {
    try {
      Log.info('Received recovery request event: ${event.id}');

      // Get sender pubkey from tags
      final pTags = event.tags.where((tag) => tag.isNotEmpty && tag[0] == 'p').toList();
      if (pTags.isEmpty) {
        Log.warning('No sender pubkey in recovery request event');
        return;
      }

      // In DMs, we need to determine if we're the sender or recipient
      // The 'p' tag contains the other party
      final senderPubkey = pTags.first[1];

      // Decrypt the DM content
      final keyPair = await KeyService.getStoredNostrKey();
      if (keyPair == null) {
        Log.error('Cannot decrypt recovery request: no key pair');
        return;
      }

      final decryptedContent = await KeyService.decryptFromSender(
        encryptedText: event.content,
        senderPubkey: senderPubkey,
      );

      Log.info('Decrypted recovery request from $senderPubkey');

      // Parse the recovery request JSON
      final requestData = json.decode(decryptedContent) as Map<String, dynamic>;

      // Create RecoveryRequest object
      final recoveryRequest = RecoveryRequest(
        id: event.id,
        lockboxId: requestData['lockboxId'] as String,
        initiatorPubkey: senderPubkey,
        requestedAt: DateTime.fromMillisecondsSinceEpoch(event.createdAt * 1000),
        status: RecoveryRequestStatus.sent,
        nostrEventId: event.id,
        expiresAt: requestData['expiresAt'] != null
            ? DateTime.parse(requestData['expiresAt'] as String)
            : null,
        keyHolderResponses: {}, // Will be populated later
      );

      // Add to notification service
      await RecoveryNotificationService.addNotification(recoveryRequest);

      Log.info('Added recovery request notification: ${event.id}');
    } catch (e) {
      Log.error('Error handling recovery request event ${event.id}', e);
    }
  }

  /// Handle incoming key share event (kind 1059 gift wrap)
  static Future<void> _handleKeyShare(Nip01Event event) async {
    try {
      Log.info('Received key share gift wrap event: ${event.id}');

      // Unwrap the gift wrap event using NDK
      final unwrappedEvent = await _ndk!.giftWrap.fromGiftWrap(giftWrap: event);

      Log.info('Unwrapped gift wrap event: ${unwrappedEvent.id}');

      // Parse the shard data from the unwrapped content
      final shardJson = json.decode(unwrappedEvent.content) as Map<String, dynamic>;
      Log.debug(shardJson.toString());

      // Create ShardData from the unwrapped content
      final shardData = shardDataFromJson(shardJson);
      Log.info('Parsed shard data from gift wrap');

      // Store the shard data
      final lockboxId = shardData.lockboxId ?? 'unknown';
      await LockboxShareService.addLockboxShare(lockboxId, shardData);

      Log.info('Stored key share for lockbox: $lockboxId');
    } catch (e) {
      Log.error('Error handling key share event ${event.id}', e);
    }
  }

  /// Publish a recovery request to key holders
  static Future<String?> publishRecoveryRequest({
    required String lockboxId,
    required List<String> keyHolderPubkeys,
    DateTime? expiresAt,
  }) async {
    if (!_isInitialized || _ndk == null) {
      throw Exception('NDK not initialized');
    }

    try {
      final keyPair = await KeyService.getStoredNostrKey();
      if (keyPair == null) {
        throw Exception('No key pair available');
      }

      // Create recovery request payload
      final requestPayload = {
        'lockboxId': lockboxId,
        'requestType': 'recovery',
        'expiresAt': expiresAt?.toIso8601String(),
        'timestamp': DateTime.now().toIso8601String(),
      };

      final requestJson = json.encode(requestPayload);

      // Send encrypted DM to each key holder
      final publishedEventIds = <String>[];

      for (final keyHolderPubkey in keyHolderPubkeys) {
        // Encrypt the request for this key holder
        final encryptedContent = await KeyService.encryptForRecipient(
          plaintext: requestJson,
          recipientPubkey: keyHolderPubkey,
        );

        // Create kind 4 DM event
        final dmEvent = Nip01Event(
          kind: 4,
          pubKey: keyPair.publicKey,
          content: encryptedContent,
          tags: [
            ['p', keyHolderPubkey], // Recipient
          ],
          createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        );

        // Sign and broadcast the event
        await _ndk!.accounts.sign(dmEvent);
        _ndk!.broadcast.broadcast(
          nostrEvent: dmEvent,
          specificRelays: _activeRelays.isNotEmpty ? _activeRelays : null,
        );

        publishedEventIds.add(dmEvent.id);
        Log.info('Published recovery request to $keyHolderPubkey: ${dmEvent.id}');
      }

      return publishedEventIds.isNotEmpty ? publishedEventIds.first : null;
    } catch (e) {
      Log.error('Error publishing recovery request', e);
      return null;
    }
  }

  /// Publish a recovery response
  static Future<String?> publishRecoveryResponse({
    required String initiatorPubkey,
    required String recoveryRequestId,
    required bool approved,
    String? shardDataJson,
  }) async {
    if (!_isInitialized || _ndk == null) {
      throw Exception('NDK not initialized');
    }

    try {
      final keyPair = await KeyService.getStoredNostrKey();
      if (keyPair == null) {
        throw Exception('No key pair available');
      }

      // Create response payload
      final responsePayload = {
        'recoveryRequestId': recoveryRequestId,
        'approved': approved,
        'shardData': shardDataJson,
        'respondedAt': DateTime.now().toIso8601String(),
      };

      final responseJson = json.encode(responsePayload);

      // Encrypt for initiator
      final encryptedContent = await KeyService.encryptForRecipient(
        plaintext: responseJson,
        recipientPubkey: initiatorPubkey,
      );

      // Create kind 4 DM event
      final dmEvent = Nip01Event(
        kind: 4,
        pubKey: keyPair.publicKey,
        content: encryptedContent,
        tags: [
          ['p', initiatorPubkey], // Send to initiator
          ['e', recoveryRequestId], // Reference to original request
        ],
        createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      );

      // Sign and broadcast the event
      await _ndk!.accounts.sign(dmEvent);
      _ndk!.broadcast.broadcast(
        nostrEvent: dmEvent,
        specificRelays: _activeRelays.isNotEmpty ? _activeRelays : null,
      );

      Log.info('Published recovery response: ${dmEvent.id}');
      return dmEvent.id;
    } catch (e) {
      Log.error('Error publishing recovery response', e);
      return null;
    }
  }

  /// Stop listening to all subscriptions
  static Future<void> stopListening() async {
    await _closeSubscriptions();
    Log.info('Stopped all NDK subscriptions');
  }

  /// Close all active subscriptions
  static Future<void> _closeSubscriptions() async {
    await _recoveryStreamSub?.cancel();
    _recoveryStreamSub = null;
    _recoveryRequestSubscription = null;

    await _keyShareStreamSub?.cancel();
    _keyShareStreamSub = null;
    _keyShareSubscription = null;
  }

  /// Get the list of active relays
  static List<String> getActiveRelays() {
    return List.unmodifiable(_activeRelays);
  }

  /// Check if NDK is initialized
  static bool get isInitialized => _isInitialized;

  /// Dispose of NDK resources
  static Future<void> dispose() async {
    await _closeSubscriptions();
    _activeRelays.clear();
    _ndk = null;
    _isInitialized = false;
    Log.info('NDK service disposed');
  }
}
