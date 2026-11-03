import 'dart:convert';
import 'dart:io';

import 'api_client.dart';

class UtilityReading {
  const UtilityReading({
    required this.id,
    required this.utility,
    required this.value,
    required this.unit,
    required this.periodStart,
    required this.periodEnd,
    required this.createdAt,
  });

  final String id;
  final String utility;
  final double value;
  final String unit;
  final String periodStart;
  final String periodEnd;
  final String createdAt;

  factory UtilityReading.fromJson(Map<String, dynamic> json) => UtilityReading(
    id: json['id'] as String,
    utility: json['utility'] as String,
    value: (json['value'] as num).toDouble(),
    unit: json['unit'] as String,
    periodStart: json['periodStart'] as String,
    periodEnd: json['periodEnd'] as String,
    createdAt: json['createdAt'] as String,
  );
}

class CitizenVehicle {
  const CitizenVehicle({
    required this.id,
    required this.label,
    required this.vehicleType,
    required this.fuelType,
    this.make,
    this.model,
    this.modelYear,
    this.efficiency,
    this.efficiencyUnit,
    this.registrationLabel,
  });

  final String id;
  final String label;
  final String vehicleType;
  final String fuelType;
  final String? make;
  final String? model;
  final int? modelYear;
  final double? efficiency;
  final String? efficiencyUnit;
  final String? registrationLabel;

  factory CitizenVehicle.fromJson(Map<String, dynamic> json) => CitizenVehicle(
    id: json['id'] as String,
    label: json['label'] as String,
    vehicleType: json['vehicleType'] as String,
    fuelType: json['fuelType'] as String,
    make: json['make'] as String?,
    model: json['model'] as String?,
    modelYear: (json['modelYear'] as num?)?.toInt(),
    efficiency: (json['efficiency'] as num?)?.toDouble(),
    efficiencyUnit: json['efficiencyUnit'] as String?,
    registrationLabel: json['registrationLabel'] as String?,
  );
}

class CitizenTrip {
  const CitizenTrip({
    required this.id,
    required this.mode,
    required this.distanceKm,
    required this.startedAt,
    required this.endedAt,
    required this.evidenceTier,
  });

  final String id;
  final String mode;
  final double distanceKm;
  final String startedAt;
  final String endedAt;
  final String evidenceTier;

  factory CitizenTrip.fromJson(Map<String, dynamic> json) => CitizenTrip(
    id: json['id'] as String,
    mode: json['mode'] as String,
    distanceKm: (json['distanceKm'] as num).toDouble(),
    startedAt: json['startedAt'] as String,
    endedAt: json['endedAt'] as String,
    evidenceTier: json['evidenceTier'] as String,
  );
}

class CitizenDataService {
  CitizenDataService._();

  static final instance = CitizenDataService._();

  Future<Map<String, dynamic>> _request(
    String path, {
    String method = 'GET',
    Object? body,
  }) async {
    final response = await ApiClient.instance.request(
      path,
      method: method,
      body: body,
    );
    if (response.statusCode < HttpStatus.ok ||
        response.statusCode >= HttpStatus.multipleChoices) {
      throw HttpException(
        'Could not save your data (${response.statusCode}). ${_errorDetail(response.body)}',
      );
    }
    return response.body.isEmpty ? const {} : response.decodeJson();
  }

  Future<List<UtilityReading>> getReadings() async {
    final data = await _request('/readings');
    return _parseList(data['readings'], UtilityReading.fromJson);
  }

  Future<void> addReading({
    required String utility,
    required double value,
    required String unit,
    required DateTime periodStart,
    required DateTime periodEnd,
  }) async {
    await _request(
      '/readings',
      method: 'POST',
      body: {
        'utility': utility,
        'value': value,
        'unit': unit,
        'periodStart': _dateOnly(periodStart),
        'periodEnd': _dateOnly(periodEnd),
      },
    );
  }

  Future<List<CitizenVehicle>> getVehicles() async {
    final data = await _request('/vehicles');
    return _parseList(data['vehicles'], CitizenVehicle.fromJson);
  }

  Future<void> addVehicle(Map<String, dynamic> details) async {
    await _request('/vehicles', method: 'POST', body: details);
  }

  Future<void> removeVehicle(String vehicleId) async {
    await _request(
      '/vehicles/${Uri.encodeComponent(vehicleId)}',
      method: 'DELETE',
    );
  }

  Future<List<CitizenTrip>> getTrips() async {
    final data = await _request('/trips');
    return _parseList(data['trips'], CitizenTrip.fromJson);
  }

  Future<void> addTrip({
    required String mode,
    required double distanceKm,
    required DateTime startedAt,
    required DateTime endedAt,
    required bool userConfirmed,
    String? vehicleId,
    String? notes,
  }) async {
    await _request(
      '/trips',
      method: 'POST',
      body: {
        'idempotencyKey': DateTime.now().microsecondsSinceEpoch.toString(),
        'mode': mode,
        'distanceKm': distanceKm,
        'startedAt': startedAt.toUtc().toIso8601String(),
        'endedAt': endedAt.toUtc().toIso8601String(),
        'userConfirmed': userConfirmed,
        if (vehicleId != null) 'vehicleId': vehicleId,
        if (notes != null && notes.trim().isNotEmpty) 'notes': notes.trim(),
      },
    );
  }

  static List<T> _parseList<T>(
    Object? value,
    T Function(Map<String, dynamic>) parse,
  ) {
    if (value is! List) {
      throw const FormatException('The server returned an invalid list.');
    }
    return value.map((item) {
      if (item is! Map) {
        throw const FormatException('The server returned an invalid record.');
      }
      return parse(Map<String, dynamic>.from(item));
    }).toList();
  }

  static String _dateOnly(DateTime value) =>
      '${value.year.toString().padLeft(4, '0')}-'
      '${value.month.toString().padLeft(2, '0')}-'
      '${value.day.toString().padLeft(2, '0')}';

  static String _errorDetail(String body) {
    try {
      final json = jsonDecode(body);
      if (json is Map && json['message'] is String) {
        return json['message'] as String;
      }
    } on FormatException {
      // The server may return a non-JSON error body.
    }
    return 'Please try again.';
  }
}
