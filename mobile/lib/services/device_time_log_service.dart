import 'dart:convert';
import 'dart:io';
import '../constants/auth_config.dart';

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

  Future<LoggedDeviceResult> logHours({
    required String deviceCatalogId,
    required double operatingHours,
    double? thermostatTemp,
  }) async {
    try {
      final uri = Uri.parse('${AuthConfig.apiBaseUrl}/devices/log-hours');
      final req = await _http.postUrl(uri);
      req.headers.contentType = ContentType.json;
      req.write(jsonEncode({
        'deviceCatalogId': deviceCatalogId,
        'operatingHours': operatingHours,
        if (thermostatTemp != null) 'thermostatTemp': thermostatTemp,
      }));
      final res = await req.close();
      if (res.statusCode == 200) {
        final body = await res.transform(utf8.decoder).join();
        return LoggedDeviceResult.fromJson(jsonDecode(body) as Map<String, dynamic>);
      }
    } catch (_) {}

    // Offline threshold logic
    double kw = 1.45;
    double ecoLimit = 5.0;
    String name = 'Split AC (1.5 Ton)';
    String icon = '❄️';
    if (deviceCatalogId == 'geyser') {
      kw = 2.0;
      ecoLimit = 1.5;
      name = 'Storage Water Geyser';
      icon = '🚿';
    } else if (deviceCatalogId == 'pump') {
      kw = 1.1;
      ecoLimit = 1.0;
      name = 'Sump Water Pump';
      icon = '💧';
    }

    final kwh = double.parse((kw * operatingHours).toStringAsFixed(1));
    final co2 = double.parse((kwh * 0.82).toStringAsFixed(1));

    HighUsageAlertData? alert;
    if (operatingHours > ecoLimit) {
      final excess = double.parse((operatingHours - ecoLimit).toStringAsFixed(1));
      final monthlyExcess = excess * kw * 30;
      final monthlyInr = (monthlyExcess * 6.5).round();
      final monthlyCo2 = (monthlyExcess * 0.82).round();

      alert = HighUsageAlertData(
        triggered: true,
        alertTitle: '⚠️ High Hours Alert: $name',
        alertMessage: '$name ran for $operatingHours hrs today ($excess hrs above eco threshold of $ecoLimit hrs).',
        excessHours: excess,
        potentialSavingsRupeesMonthly: monthlyInr,
        potentialCo2ReductionKgMonthly: monthlyCo2,
        recommendation: deviceCatalogId == 'ac'
            ? 'Set AC sleep timer to 4 hours and thermostat to 24°C to save ₹$monthlyInr/month.'
            : 'Turn off after morning use to prevent standby reheat losses.',
      );
    }

    return LoggedDeviceResult(
      deviceId: deviceCatalogId,
      deviceName: name,
      icon: icon,
      operatingHours: operatingHours,
      ratedPowerKw: kw,
      energyConsumedKwh: kwh,
      co2EmissionsKg: co2,
      highUsageAlert: alert,
    );
  }

  Future<Map<String, dynamic>> getSummary() async {
    try {
      final uri = Uri.parse('${AuthConfig.apiBaseUrl}/devices/summary');
      final req = await _http.getUrl(uri);
      final res = await req.close();
      if (res.statusCode == 200) {
        final body = await res.transform(utf8.decoder).join();
        return jsonDecode(body) as Map<String, dynamic>;
      }
    } catch (_) {}

    return {
      'devices': [
        {'deviceId': 'ac', 'name': 'Inverter Split AC (1.5 Ton)', 'category': 'Cooling', 'icon': '❄️', 'ratedPowerKw': 1.45, 'totalWeeklyHours': 45.5, 'avgDailyHours': 6.5, 'status': 'HIGH_USAGE', 'recommendation': 'High daily usage! Consider scheduling off-peak.'},
        {'deviceId': 'refrigerator', 'name': 'Frost-Free Refrigerator', 'category': 'Refrigeration', 'icon': '🧊', 'ratedPowerKw': 0.16, 'totalWeeklyHours': 98.0, 'avgDailyHours': 14.0, 'status': 'OPTIMAL', 'recommendation': 'Operating within eco-optimal range.'},
        {'deviceId': 'geyser', 'name': 'Storage Water Geyser', 'category': 'Water Heating', 'icon': '🚿', 'ratedPowerKw': 2.0, 'totalWeeklyHours': 8.4, 'avgDailyHours': 1.2, 'status': 'OPTIMAL', 'recommendation': 'Operating within eco-optimal range.'},
      ],
      'highHourWarnings': [
        '⚠️ Inverter Split AC is running 6.5h/day. Eco threshold is 5.0h.',
      ],
      'monthlyProjectedBillRupees': 2140,
    };
  }
}
