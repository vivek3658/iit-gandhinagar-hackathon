import 'dart:async';
import 'package:flutter/services.dart';

/// Service for posting native Android notifications to the System Notification Shade,
/// listening for physical hardware charger unplug events, and providing creative learning notifications.
class NotificationService {
  static const MethodChannel _channel =
      MethodChannel('com.geda.urjavatika.urja/notifications');

  static final NotificationService instance = NotificationService._internal();

  final _chargerDisconnectedController = StreamController<void>.broadcast();
  final _chargerConnectedController = StreamController<void>.broadcast();

  Stream<void> get onChargerDisconnected =>
      _chargerDisconnectedController.stream;
  Stream<void> get onChargerConnected => _chargerConnectedController.stream;

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
    }
  }

  /// Requests POST_NOTIFICATIONS permission on Android 13+ (API 33+)
  Future<void> requestPermission() async {
    try {
      await _channel.invokeMethod('requestPermission');
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
  }) async {
    try {
      final res = await _channel.invokeMethod<bool>('showNotification', {
        'title': title,
        'message': message,
        'id': id,
      });
      return res ?? true;
    } catch (_) {
      return false;
    }
  }

  /// Triggers the physical charger unplug reminder directly
  Future<void> triggerChargerUnplugNudge() async {
    try {
      await _channel.invokeMethod('triggerChargerUnplugNudge');
    } catch (_) {}
  }

  /// Triggers creative learning notifications (phantom vampire load or solar generation window)
  Future<void> triggerLearningNotification(String type) async {
    try {
      await _channel.invokeMethod('triggerLearningNotification', {'type': type});
    } catch (_) {}
  }
}
