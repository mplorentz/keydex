import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/invitation_service.dart';
import '../services/logger.dart';
import '../utils/validators.dart';

/// Provider for DeepLinkService
final deepLinkServiceProvider = Provider<DeepLinkService>((ref) {
  final service = DeepLinkService(
    ref.read(invitationServiceProvider),
  );
  ref.onDispose(() => service.dispose());
  return service;
});

/// Data structure for parsed invitation link information
typedef InvitationLinkData = ({
  String inviteCode,
  String ownerPubkey, // Hex format
  List<String> relayUrls,
});

/// Service for handling deep links, Universal Links, and custom URL schemes
class DeepLinkService {
  final InvitationService invitationService;
  final AppLinks _appLinks = AppLinks();
  StreamSubscription<Uri>? _linkSubscription;

  DeepLinkService(this.invitationService);

  /// Disposes resources
  void dispose() {
    _linkSubscription?.cancel();
    _linkSubscription = null;
  }

  /// Initializes deep link handling when app starts
  ///
  /// Sets up app_links listeners.
  /// Handles initial link (app opened via link).
  /// Sets up stream listener for subsequent links.
  /// Supports both Universal Links and custom URL scheme.
  Future<void> initializeDeepLinking() async {
    Log.info('Initializing deep link handling');

    // Handle initial link (app opened via link on cold start)
    try {
      final initialLink = await _appLinks.getInitialAppLink();
      if (initialLink != null) {
        Log.info('App opened via deep link: $initialLink');
        await _processLink(initialLink);
      }
    } catch (e) {
      Log.error('Error handling initial link', e);
    }

    // Set up listener for incoming links (app already running)
    _linkSubscription = _appLinks.uriLinkStream.listen(
      (Uri uri) {
        Log.info('Received deep link while app running: $uri');
        _processLink(uri);
      },
      onError: (error) {
        Log.error('Error in deep link stream', error);
      },
    );

    Log.info('Deep link handling initialized');
  }

  /// Handles link that opened the app (cold start)
  ///
  /// Retrieves initial link from app_links.
  /// Parses and validates link format.
  /// Routes to appropriate handler.
  Future<void> handleInitialLink() async {
    try {
      final initialLink = await _appLinks.getInitialAppLink();
      if (initialLink != null) {
        Log.info('Handling initial link: $initialLink');
        await _processLink(initialLink);
      }
    } catch (e) {
      Log.error('Error handling initial link', e);
      rethrow;
    }
  }

  /// Handles link received while app is running (warm start)
  ///
  /// Parses link URL.
  /// Validates link format.
  /// Routes to invitation acceptance flow.
  void handleIncomingLink(Uri uri) {
    Log.info('Handling incoming link: $uri');
    _processLink(uri);
  }

  /// Processes a deep link URI
  ///
  /// Parses the link and routes to appropriate handler.
  /// Currently only handles invitation links.
  Future<void> _processLink(Uri uri) async {
    try {
      final linkData = parseInvitationLink(uri);
      if (linkData == null) {
        Log.warning('Invalid invitation link format: $uri');
        return;
      }

      Log.info('Parsed invitation link: inviteCode=${linkData.inviteCode}');

      // TODO: Route to invitation acceptance screen
      // This will be implemented in Phase 3.9 (UI Implementation)
      // For now, we just parse and validate the link
      Log.info('Invitation link processed successfully');
    } catch (e) {
      Log.error('Error processing deep link', e);
    }
  }

  /// Parses invitation link URL and extracts parameters
  ///
  /// Handles both Universal Links (`https://keydex.app/invite/{code}`)
  /// and custom URL scheme (`keydex://keydex.app/invite/{code}`) formats.
  /// Extracts invite code from path (same path structure for both).
  /// Extracts owner pubkey and relay URLs from query params.
  /// Returns parsed data or null if invalid.
  InvitationLinkData? parseInvitationLink(Uri uri) {
    try {
      // Validate scheme: https or keydex
      if (uri.scheme != 'https' && uri.scheme != 'keydex') {
        Log.warning('Unsupported scheme: ${uri.scheme}');
        return null;
      }

      // Validate host: keydex.app (for Universal Links) or keydex.app (for custom scheme)
      if (uri.host != 'keydex.app') {
        Log.warning('Invalid host: ${uri.host}');
        return null;
      }

      // Extract invite code from path: /invite/{code}
      final pathSegments = uri.pathSegments;
      if (pathSegments.length != 2 || pathSegments[0] != 'invite') {
        Log.warning('Invalid path format: ${uri.path}');
        return null;
      }

      final inviteCode = pathSegments[1];
      if (!isValidInviteCode(inviteCode)) {
        Log.warning('Invalid invite code format: $inviteCode');
        return null;
      }

      // Extract owner pubkey from query params
      final ownerPubkey = uri.queryParameters['owner'];
      if (ownerPubkey == null || ownerPubkey.isEmpty) {
        Log.warning('Missing owner pubkey in query params');
        return null;
      }

      if (!isValidHexPubkey(ownerPubkey)) {
        Log.warning('Invalid owner pubkey format: $ownerPubkey');
        return null;
      }

      // Extract relay URLs from query params (comma-separated)
      final relayUrlsParam = uri.queryParameters['relays'];
      final relayUrls = <String>[];

      if (relayUrlsParam != null && relayUrlsParam.isNotEmpty) {
        // Split by comma and decode each URL
        final relayUrlStrings = relayUrlsParam.split(',');
        for (final relayUrlStr in relayUrlStrings) {
          final decodedUrl = Uri.decodeComponent(relayUrlStr.trim());
          if (isValidRelayUrl(decodedUrl)) {
            relayUrls.add(decodedUrl);
          } else {
            Log.warning('Invalid relay URL: $decodedUrl');
            // Continue processing other URLs, but log the invalid one
          }
        }
      }

      // Validate we have at least one relay URL
      if (relayUrls.isEmpty) {
        Log.warning('No valid relay URLs found');
        return null;
      }

      // Validate we don't have too many relay URLs (max 3)
      if (relayUrls.length > 3) {
        Log.warning('Too many relay URLs: ${relayUrls.length} (max 3)');
        return null;
      }

      Log.info(
          'Successfully parsed invitation link: inviteCode=$inviteCode, owner=$ownerPubkey, relays=${relayUrls.length}');

      return (
        inviteCode: inviteCode,
        ownerPubkey: ownerPubkey,
        relayUrls: relayUrls,
      );
    } catch (e) {
      Log.error('Error parsing invitation link: $uri', e);
      return null;
    }
  }
}
