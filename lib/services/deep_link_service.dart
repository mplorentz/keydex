import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/invitation_service.dart';

/// Provider for DeepLinkService
final deepLinkServiceProvider = Provider<DeepLinkService>((ref) {
  return DeepLinkService(
    ref.read(invitationServiceProvider),
  );
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

  DeepLinkService(this.invitationService);

  /// Initializes deep link handling when app starts
  ///
  /// Sets up app_links listeners.
  /// Handles initial link (app opened via link).
  /// Sets up stream listener for subsequent links.
  /// Supports both Universal Links and custom URL scheme.
  Future<void> initializeDeepLinking() async {
    // Stub: Non-functional for now
    throw UnimplementedError('initializeDeepLinking not yet implemented');
  }

  /// Handles link that opened the app (cold start)
  ///
  /// Retrieves initial link from app_links.
  /// Parses and validates link format.
  /// Routes to appropriate handler.
  Future<void> handleInitialLink() async {
    // Stub: Non-functional for now
    throw UnimplementedError('handleInitialLink not yet implemented');
  }

  /// Handles link received while app is running (warm start)
  ///
  /// Parses link URL.
  /// Validates link format.
  /// Routes to invitation acceptance flow.
  void handleIncomingLink(Uri uri) {
    // Stub: Non-functional for now
    throw UnimplementedError('handleIncomingLink not yet implemented');
  }

  /// Parses invitation link URL and extracts parameters
  ///
  /// Handles both Universal Links (`https://keydex.app/invite/{code}`)
  /// and custom URL scheme (`keydex://keydex.app/invite/{code}`) formats.
  /// Extracts invite code from path (same path structure for both).
  /// Extracts owner pubkey and relay URLs from query params.
  /// Returns parsed data or null if invalid.
  InvitationLinkData? parseInvitationLink(Uri uri) {
    // Stub: Non-functional for now
    throw UnimplementedError('parseInvitationLink not yet implemented');
  }
}
