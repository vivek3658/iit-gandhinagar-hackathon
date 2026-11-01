import 'dart:convert';
import 'dart:io';
import '../constants/auth_config.dart';
import 'auth_service.dart';
import 'notification_service.dart';

class HighUsageAlertData {
  final bool triggered;
  final String alertTitle;
  final String alertMessage;
  final double excessHours;
  final int potentialSavingsRupeesMonthly;
  final int potentialCo2ReductionKgMonthly;
  final String recommendation;

  HighUsageAlertData({
    required this.triggered,
    required this.alertTitle,
    required this.alertMessage,
    required this.excessHours,
    required this.potentialSavingsRupeesMonthly,
    required this.potentialCo2ReductionKgMonthly,
    required this.recommendation,
  });

  factory HighUsageAlertData.fromJson(Map<String, dynamic> json) {
    return HighUsageAlertData(
      triggered: json['triggered'] as bool? ?? false,
      alertTitle: json['alertTitle'] as String? ?? '⚠️ High Usage Warning',
      alertMessage: json['alertMessage'] as String? ?? '',
      excessHours: (json['excessHours'] as num?)?.toDouble() ?? 0.0,
      potentialSavingsRupeesMonthly: json['potentialSavingsRupeesMonthly'] as int? ?? 0,
      potentialCo2ReductionKgMonthly: json['potentialCo2ReductionKgMonthly'] as int? ?? 0,
      recommendation: json['recommendation'] as String? ?? '',
    );
  }
}

class ApplianceLogEntry {
  final String id;
  final String deviceId;
  final String deviceName;
  final String icon;
  final double operatingHours;
  final double energyConsumedKwh;
  final double co2EmissionsKg;
  final int costRupees;
  final bool isOverLimit;
  final DateTime loggedAt;

  ApplianceLogEntry({
    required this.id,
    required this.deviceId,
    required this.deviceName,
    required this.icon,
    required this.operatingHours,
    required this.energyConsumedKwh,
    required this.co2EmissionsKg,
    required this.costRupees,
    required this.isOverLimit,
    required this.loggedAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'deviceId': deviceId,
    'deviceName': deviceName,
    'icon': icon,
    'operatingHours': operatingHours,
    'energyConsumedKwh': energyConsumedKwh,
    'co2EmissionsKg': co2EmissionsKg,
    'costRupees': costRupees,
    'isOverLimit': isOverLimit,
    'loggedAt': loggedAt.toIso8601String(),
  };

  factory ApplianceLogEntry.fromJson(Map<String, dynamic> json) {
    return ApplianceLogEntry(
      id: json['id'] as String? ?? '',
      deviceId: json['deviceId'] as String? ?? 'ac',
      deviceName: json['deviceName'] as String? ?? 'Appliance',
      icon: json['icon'] as String? ?? '📱',
      operatingHours: (json['operatingHours'] as num?)?.toDouble() ?? 0.0,
      energyConsumedKwh: (json['energyConsumedKwh'] as num?)?.toDouble() ?? 0.0,
      co2EmissionsKg: (json['co2EmissionsKg'] as num?)?.toDouble() ?? 0.0,
      costRupees: json['costRupees'] as int? ?? 0,
      isOverLimit: json['isOverLimit'] as bool? ?? false,
      loggedAt: json['loggedAt'] != null ? DateTime.parse(json['loggedAt'] as String) : DateTime.now(),
    );
  }
}

class LoggedDeviceResult {
  final String deviceId;
  final String deviceName;
  final String icon;
  final double operatingHours;
  final double ratedPowerKw;
  final double energyConsumedKwh;
  final double co2EmissionsKg;
  final HighUsageAlertData? highUsageAlert;

  LoggedDeviceResult({
    required this.deviceId,
    required this.deviceName,
    required this.icon,
    required this.operatingHours,
    required this.ratedPowerKw,
    required this.energyConsumedKwh,
    required this.co2EmissionsKg,
    this.highUsageAlert,
  });

  factory LoggedDeviceResult.fromJson(Map<String, dynamic> json) {
    final dev = json['loggedDevice'] as Map<String, dynamic>? ?? {};
    final alertMap = json['highUsageAlert'] as Map<String, dynamic>?;

    return LoggedDeviceResult(
      deviceId: dev['deviceId'] as String? ?? 'ac',
      deviceName: dev['deviceName'] as String? ?? 'Appliance',
      icon: dev['icon'] as String? ?? '📱',
      operatingHours: (dev['operatingHours'] as num?)?.toDouble() ?? 0.0,
      ratedPowerKw: (dev['ratedPowerKw'] as num?)?.toDouble() ?? 1.0,
      energyConsumedKwh: (dev['energyConsumedKwh'] as num?)?.toDouble() ?? 0.0,
      co2EmissionsKg: (dev['co2EmissionsKg'] as num?)?.toDouble() ?? 0.0,
      highUsageAlert: alertMap != null ? HighUsageAlertData.fromJson(alertMap) : null,
    );
  }
}

class DeviceTimeLogService {
  static final DeviceTimeLogService instance = DeviceTimeLogService._();
  DeviceTimeLogService._();

  final HttpClient _http = HttpClient()..connectionTimeout = const Duration(seconds: 4);
  final List<ApplianceLogEntry> _history = [];

  List<ApplianceLogEntry> get history => List.unmodifiable(_history);

  Future<LoggedDeviceResult> logHours({
    required String deviceCatalogId,
    required double operatingHours,
    double? thermostatTemp,
  }) async {
    final token = AuthService.instance.accessToken;
    if (token == null || token.isEmpty) throw Exception('Sign in to save appliance logs.');
    final uri = Uri.parse('${AuthConfig.apiBaseUrl}/devices/log-hours');
    final req = await _http.postUrl(uri);
    req.headers.contentType = ContentType.json;
    req.headers.set(HttpHeaders.authorizationHeader, 'Bearer $token');
    req.write(jsonEncode({
      'deviceCatalogId': deviceCatalogId,
      'operatingHours': operatingHours,
      if (thermostatTemp != null) 'thermostatTemp': thermostatTemp,
    }));
    final res = await req.close();
    final body = await res.transform(utf8.decoder).join();
    if (res.statusCode != 200) throw HttpException('Could not save log (${res.statusCode}): $body');
    final result = LoggedDeviceResult.fromJson(jsonDecode(body) as Map<String, dynamic>);

    // 1. Add to persistent history log
    final newEntry = ApplianceLogEntry(
      id: 'log_${DateTime.now().millisecondsSinceEpoch}',
      deviceId: result.deviceId,
      deviceName: result.deviceName,
      icon: result.icon,
      operatingHours: result.operatingHours,
      energyConsumedKwh: result.energyConsumedKwh,
      co2EmissionsKg: result.co2EmissionsKg,
      costRupees: (result.energyConsumedKwh * 6.5).round(),
      isOverLimit: result.highUsageAlert?.triggered ?? false,
      loggedAt: DateTime.now(),
    );
    _history.removeWhere((entry) => entry.deviceId == newEntry.deviceId &&
        entry.loggedAt.year == newEntry.loggedAt.year &&
        entry.loggedAt.month == newEntry.loggedAt.month &&
        entry.loggedAt.day == newEntry.loggedAt.day);
    _history.insert(0, newEntry);

    // 2. Trigger REAL Android System Notification if high usage alert is active!
    if (result.highUsageAlert?.triggered == true) {
      final alert = result.highUsageAlert!;
      NotificationService.instance.showSystemNotification(
        title: alert.alertTitle,
        message: alert.alertMessage,
        id: 4001,
      );
    }

    return result;
  }

  Future<Map<String, dynamic>> getSummary() async {
    final token = AuthService.instance.accessToken;
    if (token == null || token.isEmpty) throw Exception('Sign in to view appliance summary.');
    final uri = Uri.parse('${AuthConfig.apiBaseUrl}/devices/summary');
    final req = await _http.getUrl(uri);
    req.headers.set(HttpHeaders.authorizationHeader, 'Bearer $token');
    final res = await req.close();
    final body = await res.transform(utf8.decoder).join();
    if (res.statusCode != 200) throw HttpException('Could not load appliance summary (${res.statusCode}).');
    return jsonDecode(body) as Map<String, dynamic>;
  }
}
