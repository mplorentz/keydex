import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/recovery_request.dart';
import 'logger.dart';

/// Service for managing recovery notifications
class RecoveryNotificationService {
  static const String _notificationsKey = 'recovery_notifications';
  static const String _viewedNotificationsKey = 'viewed_notification_ids';
  static List<RecoveryRequest>? _cachedNotifications;
  static Set<String>? _viewedNotificationIds;
  static bool _isInitialized = false;

  // Stream controllers for real-time updates
  static final StreamController<RecoveryRequest> _recoveryRequestController =
      StreamController<RecoveryRequest>.broadcast();
  static final StreamController<List<RecoveryRequest>> _notificationController =
      StreamController<List<RecoveryRequest>>.broadcast();

  /// Initialize the service
  static Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await _loadNotifications();
      await _loadViewedNotificationIds();
      _isInitialized = true;
      Log.info(
          'RecoveryNotificationService initialized with ${_cachedNotifications?.length ?? 0} notifications');
    } catch (e) {
      Log.error('Error initializing RecoveryNotificationService', e);
      _cachedNotifications = [];
      _viewedNotificationIds = {};
      _isInitialized = true;
    }
  }

  /// Load notifications from storage
  static Future<void> _loadNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonData = prefs.getString(_notificationsKey);

    if (jsonData == null || jsonData.isEmpty) {
      _cachedNotifications = [];
      return;
    }

    try {
      final List<dynamic> jsonList = json.decode(jsonData);
      _cachedNotifications =
          jsonList.map((json) => RecoveryRequest.fromJson(json as Map<String, dynamic>)).toList();
      Log.info('Loaded ${_cachedNotifications!.length} notifications from storage');
    } catch (e) {
      Log.error('Error loading notifications', e);
      _cachedNotifications = [];
    }
  }

  /// Save notifications to storage
  static Future<void> _saveNotifications() async {
    if (_cachedNotifications == null) return;

    try {
      final jsonList = _cachedNotifications!.map((request) => request.toJson()).toList();
      final jsonString = json.encode(jsonList);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_notificationsKey, jsonString);
      Log.info('Saved ${jsonList.length} notifications to storage');

      // Emit notification update
      _notificationController.add(List.from(_cachedNotifications!));
    } catch (e) {
      Log.error('Error saving notifications', e);
      throw Exception('Failed to save notifications: $e');
    }
  }

  /// Load viewed notification IDs from storage
  static Future<void> _loadViewedNotificationIds() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonData = prefs.getString(_viewedNotificationsKey);

    if (jsonData == null || jsonData.isEmpty) {
      _viewedNotificationIds = {};
      return;
    }

    try {
      final List<dynamic> jsonList = json.decode(jsonData);
      _viewedNotificationIds = jsonList.map((id) => id as String).toSet();
      Log.info('Loaded ${_viewedNotificationIds!.length} viewed notification IDs from storage');
    } catch (e) {
      Log.error('Error loading viewed notification IDs', e);
      _viewedNotificationIds = {};
    }
  }

  /// Save viewed notification IDs to storage
  static Future<void> _saveViewedNotificationIds() async {
    if (_viewedNotificationIds == null) return;

    try {
      final jsonString = json.encode(_viewedNotificationIds!.toList());

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_viewedNotificationsKey, jsonString);
      Log.info('Saved ${_viewedNotificationIds!.length} viewed notification IDs to storage');
    } catch (e) {
      Log.error('Error saving viewed notification IDs', e);
    }
  }

  /// Get pending recovery request notifications
  static Future<List<RecoveryRequest>> getPendingNotifications() async {
    await initialize();

    // Filter out viewed notifications and keep only active requests
    final pendingNotifications = _cachedNotifications!
        .where(
            (request) => !_viewedNotificationIds!.contains(request.id) && request.status.isActive)
        .toList();

    return pendingNotifications;
  }

  /// Get all notifications (including viewed)
  static Future<List<RecoveryRequest>> getAllNotifications() async {
    await initialize();
    return List.unmodifiable(_cachedNotifications ?? []);
  }

  /// Add a new notification
  static Future<void> addNotification(RecoveryRequest request) async {
    await initialize();

    // Check if notification already exists
    final existingIndex = _cachedNotifications!.indexWhere((r) => r.id == request.id);
    if (existingIndex != -1) {
      // Update existing notification
      _cachedNotifications![existingIndex] = request;
      Log.info('Updated existing notification: ${request.id}');
    } else {
      // Add new notification
      _cachedNotifications!.add(request);
      Log.info('Added new notification: ${request.id}');
    }

    await _saveNotifications();

    // Emit recovery request event
    _recoveryRequestController.add(request);
  }

  /// Mark a notification as viewed
  static Future<void> markNotificationAsViewed(String recoveryRequestId) async {
    await initialize();

    if (!_viewedNotificationIds!.contains(recoveryRequestId)) {
      _viewedNotificationIds!.add(recoveryRequestId);
      await _saveViewedNotificationIds();
      Log.info('Marked notification as viewed: $recoveryRequestId');

      // Emit updated notification list
      final pendingNotifications = await getPendingNotifications();
      _notificationController.add(pendingNotifications);
    }
  }

  /// Mark a notification as unviewed
  static Future<void> markNotificationAsUnviewed(String recoveryRequestId) async {
    await initialize();

    if (_viewedNotificationIds!.contains(recoveryRequestId)) {
      _viewedNotificationIds!.remove(recoveryRequestId);
      await _saveViewedNotificationIds();
      Log.info('Marked notification as unviewed: $recoveryRequestId');

      // Emit updated notification list
      final pendingNotifications = await getPendingNotifications();
      _notificationController.add(pendingNotifications);
    }
  }

  /// Get notification count
  static Future<int> getNotificationCount({bool unviewedOnly = true}) async {
    await initialize();

    if (unviewedOnly) {
      final pendingNotifications = await getPendingNotifications();
      return pendingNotifications.length;
    }

    return _cachedNotifications!.length;
  }

  /// Check if a notification has been viewed
  static Future<bool> isNotificationViewed(String recoveryRequestId) async {
    await initialize();
    return _viewedNotificationIds!.contains(recoveryRequestId);
  }

  /// Clear all notifications
  static Future<void> clearAllNotifications() async {
    await initialize();

    _cachedNotifications!.clear();
    await _saveNotifications();

    Log.info('Cleared all notifications');
  }

  /// Clear viewed notification IDs
  static Future<void> clearViewedNotifications() async {
    await initialize();

    _viewedNotificationIds!.clear();
    await _saveViewedNotificationIds();

    Log.info('Cleared all viewed notification IDs');

    // Emit updated notification list
    final pendingNotifications = await getPendingNotifications();
    _notificationController.add(pendingNotifications);
  }

  /// Remove a specific notification
  static Future<void> removeNotification(String recoveryRequestId) async {
    await initialize();

    final initialLength = _cachedNotifications!.length;
    _cachedNotifications!.removeWhere((r) => r.id == recoveryRequestId);

    if (_cachedNotifications!.length < initialLength) {
      await _saveNotifications();
      _viewedNotificationIds!.remove(recoveryRequestId);
      await _saveViewedNotificationIds();
      Log.info('Removed notification: $recoveryRequestId');
    }
  }

  /// Remove expired notifications
  static Future<void> removeExpiredNotifications() async {
    await initialize();

    final initialLength = _cachedNotifications!.length;
    _cachedNotifications!.removeWhere((r) => r.isExpired);

    if (_cachedNotifications!.length < initialLength) {
      await _saveNotifications();
      Log.info('Removed ${initialLength - _cachedNotifications!.length} expired notifications');
    }
  }

  /// Subscribe to recovery request updates
  static Stream<RecoveryRequest> get recoveryRequestStream {
    return _recoveryRequestController.stream;
  }

  /// Subscribe to notification list updates
  static Stream<List<RecoveryRequest>> get notificationStream {
    return _notificationController.stream;
  }

  /// Dispose of stream controllers
  static Future<void> dispose() async {
    await _recoveryRequestController.close();
    await _notificationController.close();
  }

  /// Clear all data (for testing)
  static Future<void> clearAll() async {
    _cachedNotifications = [];
    _viewedNotificationIds = {};

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_notificationsKey);
    await prefs.remove(_viewedNotificationsKey);
    _isInitialized = false;

    Log.info('Cleared all notifications and viewed IDs');
  }

  /// Refresh the cached data from storage
  static Future<void> refresh() async {
    _isInitialized = false;
    _cachedNotifications = null;
    _viewedNotificationIds = null;
    await initialize();
  }
}
