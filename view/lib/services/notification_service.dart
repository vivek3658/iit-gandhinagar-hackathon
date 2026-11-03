import 'package:flutter/services.dart';

class NotificationService {
  NotificationService._();

  static final instance = NotificationService._();

  static const _channel = MethodChannel(
    'com.geda.urjavatika.urja/notifications',
  );

  Future<bool> getChargerNudgeEnabled() async =>
      await _channel.invokeMethod<bool>('getChargerNudgeEnabled') ?? false;

  Future<bool> requestPermission() async =>
      await _channel.invokeMethod<bool>('requestNotificationPermission') ??
      false;

  Future<void> setChargerNudgeEnabled(bool enabled) async {
    final saved = await _channel.invokeMethod<bool>('setChargerNudgeEnabled', {
      'enabled': enabled,
    });
    if (saved != true) {
      throw StateError('The charger reminder setting was not saved.');
    }
  }

  Future<bool> showChargerNudgeTest() async =>
      await _channel.invokeMethod<bool>('showChargerNudgeTest') ?? false;
}
