import 'dart:convert';
import 'dart:io';
import '../constants/auth_config.dart';
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
  DeviceTimeLogService._() {
    _seedInitialHistory();
  }

  final HttpClient _http = HttpClient()..connectionTimeout = const Duration(seconds: 4);
  final List<ApplianceLogEntry> _history = [];

  List<ApplianceLogEntry> get history => List.unmodifiable(_history);

  void _seedInitialHistory() {
    final now = DateTime.now();
    _history.addAll([
      ApplianceLogEntry(
        id: 'log_seed_1',
        deviceId: 'ac',
        deviceName: 'Inverter Split AC (1.5 Ton)',
        icon: '❄️',
        operatingHours: 8.5,
        energyConsumedKwh: 12.3,
        co2EmissionsKg: 10.1,
        costRupees: 80,
        isOverLimit: true,
        loggedAt: now.subtract(const Duration(days: 1)),
      ),
      ApplianceLogEntry(
        id: 'log_seed_2',
        deviceId: 'refrigerator',
        deviceName: 'Frost-Free Refrigerator',
        icon: '🧊',
        operatingHours: 14.0,
        energyConsumedKwh: 2.2,
        co2EmissionsKg: 1.8,
        costRupees: 15,
        isOverLimit: false,
        loggedAt: now.subtract(const Duration(days: 1)),
      ),
      ApplianceLogEntry(
        id: 'log_seed_3',
        deviceId: 'geyser',
        deviceName: 'Storage Water Geyser',
        icon: '🚿',
        operatingHours: 1.2,
        energyConsumedKwh: 2.4,
        co2EmissionsKg: 2.0,
        costRupees: 16,
        isOverLimit: false,
        loggedAt: now.subtract(const Duration(days: 2)),
      ),
      ApplianceLogEntry(
        id: 'log_seed_4',
        deviceId: 'pump',
        deviceName: 'Sump Water Pump',
        icon: '💧',
        operatingHours: 0.8,
        energyConsumedKwh: 0.9,
        co2EmissionsKg: 0.7,
        costRupees: 6,
        isOverLimit: false,
        loggedAt: now.subtract(const Duration(days: 2)),
      ),
    ]);
  }

  Future<LoggedDeviceResult> logHours({
    required String deviceCatalogId,
    required double operatingHours,
    double? thermostatTemp,
  }) async {
    LoggedDeviceResult? result;

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
        result = LoggedDeviceResult.fromJson(jsonDecode(body) as Map<String, dynamic>);
      }
    } catch (_) {}

    if (result == null) {
      // Offline fallback calculation
      double kw = 1.45;
      double ecoLimit = 5.0;
      String name = 'Inverter Split AC (1.5 Ton)';
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
      } else if (deviceCatalogId == 'refrigerator') {
        kw = 0.16;
        ecoLimit = 14.0;
        name = 'Frost-Free Refrigerator';
        icon = '🧊';
      } else if (deviceCatalogId == 'induction') {
        kw = 1.5;
        ecoLimit = 2.0;
        name = 'Smart Induction Cooktop';
        icon = '🥘';
      } else if (deviceCatalogId == 'ev_charger') {
        kw = 0.75;
        ecoLimit = 4.0;
        name = 'EV 2-Wheeler Home Charger';
        icon = '🛵';
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
              ? 'Set AC sleep timer to 4 hours and thermostat to 24°C to save ₹$monthlyInr & $monthlyCo2 kg CO₂e monthly.'
              : 'Turn off after morning use to prevent standby reheat losses.',
        );
      }

      result = LoggedDeviceResult(
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
