import 'dart:async';
import 'package:flutter/services.dart';

/// Service for posting native Android notifications to the System Notification Shade,
/// listening for physical hardware charger unplug events, modern geofence departure reminders,
/// and interactive action buttons embedded directly in the notification shade.
class NotificationService {
  static const MethodChannel _channel =
      MethodChannel('com.geda.urjavatika.urja/notifications');

  static final NotificationService instance = NotificationService._internal();

  final _chargerDisconnectedController = StreamController<void>.broadcast();
  final _chargerConnectedController = StreamController<void>.broadcast();
  final _departureRewardClaimedController = StreamController<int>.broadcast();

  Stream<void> get onChargerDisconnected =>
      _chargerDisconnectedController.stream;
  Stream<void> get onChargerConnected => _chargerConnectedController.stream;
  Stream<int> get onDepartureRewardClaimed =>
      _departureRewardClaimedController.stream;

  NotificationService._internal() {
    _channel.setMethodCallHandler(_handleNativeCall);
  }

  Future<dynamic> _handleNativeCall(MethodCall call) async {
    switch (call.method) {
      case 'onChargerDisconnected':
        _chargerDisconnectedController.add(null);
        break;
      case 'onChargerConnected':
        _chargerConnectedController.add(null);
        break;
      case 'onDepartureRewardClaimed':
        final coins = (call.arguments as Map?)?['coins'] as int? ?? 10;
        _departureRewardClaimedController.add(coins);
        break;
    }
  }

  /// Requests POST_NOTIFICATIONS permission on Android 13+ (API 33+)
  Future<void> requestPermission() async {
    try {
      await _channel.invokeMethod('requestPermission');
    } catch (_) {}
  }

  /// Requests Location permissions for 300m departure geofencing
  Future<void> requestLocationPermission() async {
    try {
      await _channel.invokeMethod('requestLocationPermission');
    } catch (_) {}
  }

  /// Updates native charger nudge setting
  Future<void> setChargerNudgeEnabled(bool enabled) async {
    try {
      await _channel.invokeMethod('setChargerNudgeEnabled', {'enabled': enabled});
    } catch (_) {}
  }

  /// Posts a real Android system notification in the device's notification center
  Future<bool> showSystemNotification({
    required String title,
    required String message,
    int id = 1001,
    String? actionButton,
  }) async {
    try {
      final res = await _channel.invokeMethod<bool>('showNotification', {
        'title': title,
        'message': message,
        'id': id,
        if (actionButton != null) 'actionButton': actionButton,
      });
      return res ?? true;
    } catch (_) {
      return false;
    }
  }

  /// Triggers a modern 300m departure notification with embedded "Claim +10 🪙" action button
  Future<void> triggerDepartureNotification({double distance = 300.0}) async {
    try {
      await _channel.invokeMethod('triggerDepartureNotification', {
        'distance': distance,
      });
    } catch (_) {}
  }

  /// Triggers the physical charger unplug reminder directly
  Future<void> triggerChargerUnplugNudge() async {
    try {
      await _channel.invokeMethod('triggerChargerUnplugNudge');
    } catch (_) {}
  }

  /// Triggers creative learning notifications (phantom vampire load or solar generation window)
  /// Triggers 3 Mission LiFE push notifications directly to device shade
  Future<void> triggerThreeEcoTips() async {
    try {
      await _channel.invokeMethod('triggerThreeEcoTips');
    } catch (_) {}
  }

  /// Triggers short departure reminder (< 300m)
  Future<void> triggerShortDepartureReminder({double distance = 150.0}) async {
    try {
      await _channel.invokeMethod('triggerShortDepartureReminder', {'distance': distance});
    } catch (_) {}
  }

  /// Triggers long commute travel reminder (> 1.5 km)
  Future<void> triggerLongCommuteNotification({double distanceKm = 4.2}) async {
    try {
      await _channel.invokeMethod('triggerLongCommuteNotification', {'distanceKm': distanceKm});
    } catch (_) {}
  }

  Future<void> triggerLearningNotification(String type) async {
    try {
      await _channel.invokeMethod('triggerLearningNotification', {'type': type});
    } catch (_) {}
  }
}
