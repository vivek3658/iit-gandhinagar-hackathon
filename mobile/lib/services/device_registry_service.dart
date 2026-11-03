import 'dart:convert';
import 'dart:io';

import 'api_client.dart';

class RegisteredHouseholdDevice {
  const RegisteredHouseholdDevice({
    required this.id,
    required this.name,
    required this.category,
    required this.discoveryMethod,
    required this.ratedPowerW,
    required this.createdAt,
    required this.lastLoggedHours,
    required this.lastEnergyKwh,
    required this.lastLogDate,
  });

  final String id;
  final String name;
  final String category;
  final String discoveryMethod;
  final double? ratedPowerW;
  final String createdAt;
  final double? lastLoggedHours;
  final double? lastEnergyKwh;
  final String? lastLogDate;

  factory RegisteredHouseholdDevice.fromJson(Map<String, dynamic> json) =>
      RegisteredHouseholdDevice(
        id: json['id'] as String,
        name: json['name'] as String,
        category: json['category'] as String,
        discoveryMethod: json['discoveryMethod'] as String,
        ratedPowerW: (json['ratedPowerW'] as num?)?.toDouble(),
        createdAt: json['createdAt'] as String,
        lastLoggedHours: (json['lastLoggedHours'] as num?)?.toDouble(),
        lastEnergyKwh: (json['lastEnergyKwh'] as num?)?.toDouble(),
        lastLogDate: json['lastLogDate'] as String?,
      );
}

class RegisteredDeviceRuntime {
  const RegisteredDeviceRuntime({
    required this.operatingHours,
    required this.energyConsumedKwh,
    required this.energyEvidence,
    required this.date,
  });

  final double operatingHours;
  final double? energyConsumedKwh;
  final String energyEvidence;
  final String date;

  factory RegisteredDeviceRuntime.fromJson(Map<String, dynamic> json) =>
      RegisteredDeviceRuntime(
        operatingHours: (json['operatingHours'] as num).toDouble(),
        energyConsumedKwh: (json['energyConsumedKwh'] as num?)?.toDouble(),
        energyEvidence: json['energyEvidence'] as String,
        date: json['date'] as String,
      );
}

class DeviceRegistryService {
  DeviceRegistryService._();

  static final instance = DeviceRegistryService._();

  Future<List<RegisteredHouseholdDevice>> getDevices() async {
    final response = await ApiClient.instance.get('/devices/registry');
    _ensureSuccess(response, HttpStatus.ok);
    final rawDevices = response.decodeJson()['devices'];
    if (rawDevices is! List) {
      throw const FormatException('The device registry response is invalid.');
    }
    return rawDevices
        .map(
          (item) => RegisteredHouseholdDevice.fromJson(
            Map<String, dynamic>.from(item as Map),
          ),
        )
        .toList();
  }

  Future<void> registerDevice({
    required String name,
    required String category,
    double? ratedPowerW,
  }) async {
    final response = await ApiClient.instance.post(
      '/devices/registry',
      body: {
        'name': name.trim(),
        'category': category,
        'discoveryMethod': 'MANUAL',
        if (ratedPowerW != null) 'ratedPowerW': ratedPowerW,
      },
    );
    _ensureSuccess(response, HttpStatus.created);
  }

  Future<void> removeDevice(String deviceId) async {
    final response = await ApiClient.instance.delete(
      '/devices/registry/${Uri.encodeComponent(deviceId)}',
    );
    if (response.statusCode != HttpStatus.noContent) {
      _throwRequestError(response);
    }
  }

  Future<RegisteredDeviceRuntime> logRuntime({
    required String deviceId,
    required double operatingHours,
    required DateTime date,
  }) async {
    final response = await ApiClient.instance.post(
      '/devices/registry/${Uri.encodeComponent(deviceId)}/runtime',
      body: {'operatingHours': operatingHours, 'date': _dateOnly(date)},
    );
    _ensureSuccess(response, HttpStatus.ok);
    return RegisteredDeviceRuntime.fromJson(response.decodeJson());
  }

  static void _ensureSuccess(ApiResponse response, int expectedStatus) {
    if (response.statusCode != expectedStatus) _throwRequestError(response);
  }

  static Never _throwRequestError(ApiResponse response) {
    var message = response.body;
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map && decoded['message'] is String) {
        message = decoded['message'] as String;
      }
    } on FormatException {
      // Keep the response body when the server does not return JSON.
    }
    throw HttpException(
      'Device request failed (${response.statusCode}). $message',
    );
  }

  static String _dateOnly(DateTime value) =>
      '${value.year.toString().padLeft(4, '0')}-'
      '${value.month.toString().padLeft(2, '0')}-'
      '${value.day.toString().padLeft(2, '0')}';
}
