import 'dart:convert';
import 'dart:io';
import '../constants/auth_config.dart';

class AnalyticsDashboardData {
  final Map<String, dynamic> realTimeMetrics;
  final List<Map<String, dynamic>> hourlyLoadCurve;
  final List<Map<String, dynamic>> applianceBreakdown;
  final List<Map<String, dynamic>> monthlyTrends;
  final List<Map<String, dynamic>> carbonLedger;
  final Map<String, dynamic> gridTariffInsights;

  AnalyticsDashboardData({
    required this.realTimeMetrics,
    required this.hourlyLoadCurve,
    required this.applianceBreakdown,
    required this.monthlyTrends,
    required this.carbonLedger,
    required this.gridTariffInsights,
  });

  factory AnalyticsDashboardData.fromJson(Map<String, dynamic> json) {
    return AnalyticsDashboardData(
      realTimeMetrics: json['realTimeMetrics'] as Map<String, dynamic>? ?? {},
      hourlyLoadCurve: (json['hourlyLoadCurve'] as List<dynamic>?)?.map((e) => e as Map<String, dynamic>).toList() ?? [],
      applianceBreakdown: (json['applianceBreakdown'] as List<dynamic>?)?.map((e) => e as Map<String, dynamic>).toList() ?? [],
      monthlyTrends: (json['monthlyTrends'] as List<dynamic>?)?.map((e) => e as Map<String, dynamic>).toList() ?? [],
      carbonLedger: (json['carbonLedger'] as List<dynamic>?)?.map((e) => e as Map<String, dynamic>).toList() ?? [],
      gridTariffInsights: json['gridTariffInsights'] as Map<String, dynamic>? ?? {},
    );
  }
}

class AnalyticsClientService {
  static final AnalyticsClientService instance = AnalyticsClientService._();
  AnalyticsClientService._();

  final HttpClient _http = HttpClient()..connectionTimeout = const Duration(seconds: 4);

  Future<AnalyticsDashboardData> getDashboard() async {
    try {
      final uri = Uri.parse('${AuthConfig.apiBaseUrl}/analytics/dashboard');
      final req = await _http.getUrl(uri);
      final res = await req.close();
      if (res.statusCode == 200) {
        final body = await res.transform(utf8.decoder).join();
        return AnalyticsDashboardData.fromJson(jsonDecode(body) as Map<String, dynamic>);
      }
    } catch (_) {}
    return _mockDashboard();
  }

  AnalyticsDashboardData _mockDashboard() {
    // 24 load points
    final loadPoints = <Map<String, dynamic>>[];
    for (int h = 0; h < 24; h++) {
      double load = 0.45;
      double solar = 0.0;
      if (h >= 6 && h <= 9) load = 1.35;
      if (h >= 10 && h <= 17) {
        load = 0.85;
        // Solar bell curve 09:00 to 16:00
        solar = 2.4 * (1.0 - ((h - 13).abs() / 4.5)).clamp(0.0, 1.0);
      }
      if (h >= 18 && h <= 22) load = 2.45; // Evening peak
      if (h >= 23 || h < 6) load = 0.65; // Night baseload

      loadPoints.add({
        'hour': h,
        'timeLabel': '${h.toString().padLeft(2, '0')}:00',
        'loadKw': double.parse(load.toStringAsFixed(2)),
        'solarGenKw': double.parse(solar.toStringAsFixed(2)),
        'gridNetKw': double.parse((load - solar).toStringAsFixed(2)),
        'isPeakHour': h >= 18 && h <= 22,
      });
    }

    return AnalyticsDashboardData(
      realTimeMetrics: {
        'activePowerKw': 1.15,
        'todayKwh': 8.6,
        'todaySolarKwh': 11.2,
        'todayCo2AvoidedKg': 9.18,
        'peakDemandKw': 2.65,
      },
      hourlyLoadCurve: loadPoints,
      applianceBreakdown: [
        {'applianceName': '1.5 Ton Inverter AC', 'category': 'Cooling', 'kwhPerMonth': 180.0, 'percentShare': 44.5, 'icon': '❄️', 'rating': 'HIGH'},
        {'applianceName': 'Frost-Free Refrigerator', 'category': 'Refrigeration', 'kwhPerMonth': 68.0, 'percentShare': 16.8, 'icon': '🧊', 'rating': 'OPTIMAL'},
        {'applianceName': 'Water Storage Geyser', 'category': 'Heating', 'kwhPerMonth': 54.0, 'percentShare': 13.3, 'icon': '🚿', 'rating': 'MODERATE'},
        {'applianceName': '1.0 HP Sump Pump', 'category': 'Water Supply', 'kwhPerMonth': 38.0, 'percentShare': 9.4, 'icon': '💧', 'rating': 'OPTIMAL'},
        {'applianceName': 'Smart Induction Cooktop', 'category': 'Cooking', 'kwhPerMonth': 35.0, 'percentShare': 8.6, 'icon': '🥘', 'rating': 'OPTIMAL'},
        {'applianceName': 'EV 2-Wheeler Home Charger', 'category': 'EV Mobility', 'kwhPerMonth': 30.0, 'percentShare': 7.4, 'icon': '🛵', 'rating': 'OPTIMAL'},
      ],
      monthlyTrends: [
        {'month': 'May', 'consumptionKwh': 380.0, 'billRupees': 2470.0, 'solarOffsetPercent': 68.0, 'co2eAvoidedKg': 311.6},
        {'month': 'Jun', 'consumptionKwh': 395.0, 'billRupees': 2567.0, 'solarOffsetPercent': 65.0, 'co2eAvoidedKg': 323.9},
        {'month': 'Jul', 'consumptionKwh': 340.0, 'billRupees': 2210.0, 'solarOffsetPercent': 55.0, 'co2eAvoidedKg': 278.8},
        {'month': 'Aug', 'consumptionKwh': 320.0, 'billRupees': 2080.0, 'solarOffsetPercent': 58.0, 'co2eAvoidedKg': 262.4},
        {'month': 'Sep', 'consumptionKwh': 310.0, 'billRupees': 2015.0, 'solarOffsetPercent': 72.0, 'co2eAvoidedKg': 254.2},
        {'month': 'Oct', 'consumptionKwh': 295.0, 'billRupees': 1917.0, 'solarOffsetPercent': 78.0, 'co2eAvoidedKg': 241.9},
      ],
      carbonLedger: [
        {'domain': 'Electricity Grid', 'kgCo2e': 185.0, 'percent': 58.0, 'icon': '⚡'},
        {'domain': 'LPG / Cooking Fuel', 'kgCo2e': 52.0, 'percent': 16.3, 'icon': '🔥'},
        {'domain': 'Commute & Travel', 'kgCo2e': 48.0, 'percent': 15.0, 'icon': '🛵'},
        {'domain': 'Water Pumping & Misc', 'kgCo2e': 34.0, 'percent': 10.7, 'icon': '💧'},
      ],
      gridTariffInsights: {
        'discomName': 'Torrent Power / UGVCL',
        'peakTariffRateRupees': 7.20,
        'offPeakTariffRateRupees': 4.85,
        'solarFeedInTariffRupees': 2.25,
        'recommendation': 'Shift washing machine and EV charging to 11:00 AM - 03:00 PM to maximize solar self-consumption and save ₹450/month.',
      },
    );
  }
}
