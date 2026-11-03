import 'package:flutter/services.dart';

class DeviceDiscovery {
  DeviceDiscovery._();

  static const _channel = MethodChannel('urja/device_discovery');
  static final instance = DeviceDiscovery._();

  Future<List<Map<String, dynamic>>> scan() async {
    final result = await _channel.invokeListMethod<Object?>(
      'discoverNearbyDevices',
    );
    if (result == null) return const [];
    return result.map((item) {
      if (item is! Map) {
        throw const FormatException('Device discovery returned invalid data.');
      }
      return Map<String, dynamic>.from(item);
    }).toList();
  }
}
