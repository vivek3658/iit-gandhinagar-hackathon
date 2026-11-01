/// Senior Energy & Carbon Analytics Model for UrjaVatika
class SeniorCarbonAnalytics {
  final Map<String, dynamic> realTimeMetrics;
  final List<Map<String, dynamic>> hourlyLoadCurve;
  final List<Map<String, dynamic>> applianceBreakdown;
  final List<Map<String, dynamic>> carbonLedger;
  final Map<String, dynamic> gridTariffInsights;

  SeniorCarbonAnalytics({
    required this.realTimeMetrics,
    required this.hourlyLoadCurve,
    required this.applianceBreakdown,
    required this.carbonLedger,
    required this.gridTariffInsights,
  });

  factory SeniorCarbonAnalytics.fromJson(Map<String, dynamic> json) {
    final fallback = SeniorCarbonAnalytics.mockData();
    return SeniorCarbonAnalytics(
      realTimeMetrics: json['realTimeMetrics'] is Map
          ? Map<String, dynamic>.from(json['realTimeMetrics'] as Map)
          : fallback.realTimeMetrics,
      hourlyLoadCurve: json['hourlyLoadCurve'] is List
          ? (json['hourlyLoadCurve'] as List)
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList()
          : fallback.hourlyLoadCurve,
      applianceBreakdown: json['applianceBreakdown'] is List
          ? (json['applianceBreakdown'] as List)
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList()
          : fallback.applianceBreakdown,
      carbonLedger: json['carbonLedger'] is List
          ? (json['carbonLedger'] as List)
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList()
          : fallback.carbonLedger,
      gridTariffInsights: json['gridTariffInsights'] is Map
          ? Map<String, dynamic>.from(json['gridTariffInsights'] as Map)
          : fallback.gridTariffInsights,
    );
  }

  factory SeniorCarbonAnalytics.mockData() {
    return SeniorCarbonAnalytics(
      realTimeMetrics: {
        'activePowerKw': 1.15,
        'todayKwh': 8.6,
        'todaySolarKwh': 11.2,
        'todayCo2AvoidedKg': 9.2,
      },
      hourlyLoadCurve: [
        {'hour': 0, 'loadKw': 0.45, 'solarKw': 0.0},
        {'hour': 2, 'loadKw': 0.38, 'solarKw': 0.0},
        {'hour': 4, 'loadKw': 0.40, 'solarKw': 0.0},
        {'hour': 6, 'loadKw': 0.85, 'solarKw': 0.2},
        {'hour': 8, 'loadKw': 1.60, 'solarKw': 1.1},
        {'hour': 10, 'loadKw': 1.95, 'solarKw': 2.8},
        {'hour': 12, 'loadKw': 1.70, 'solarKw': 3.2},
        {'hour': 14, 'loadKw': 1.50, 'solarKw': 2.9},
        {'hour': 16, 'loadKw': 1.80, 'solarKw': 1.4},
        {'hour': 18, 'loadKw': 2.45, 'solarKw': 0.2},
        {'hour': 20, 'loadKw': 2.80, 'solarKw': 0.0},
        {'hour': 22, 'loadKw': 1.20, 'solarKw': 0.0},
      ],
      applianceBreakdown: [
        {
          'icon': '❄️',
          'applianceName': 'Inverter AC (1.5 Ton)',
          'percentShare': 42,
          'kwhPerMonth': 118,
          'rating': 'HIGH',
        },
        {
          'icon': '🚿',
          'applianceName': 'Storage Water Geyser (25L)',
          'percentShare': 24,
          'kwhPerMonth': 68,
          'rating': 'MODERATE',
        },
        {
          'icon': '🧊',
          'applianceName': '5-Star Refrigerator',
          'percentShare': 16,
          'kwhPerMonth': 45,
          'rating': 'LOW',
        },
        {
          'icon': '💧',
          'applianceName': '1.0 HP Overhead Water Pump',
          'percentShare': 12,
          'kwhPerMonth': 34,
          'rating': 'MODERATE',
        },
        {
          'icon': '💡',
          'applianceName': 'LED Lighting & Fans',
          'percentShare': 6,
          'kwhPerMonth': 17,
          'rating': 'LOW',
        },
      ],
      carbonLedger: [
        {'domain': 'Electricity Grid', 'kgCo2e': 142.0, 'percent': 58.0, 'icon': '⚡'},
        {'domain': 'Cooking LPG', 'kgCo2e': 42.0, 'percent': 17.0, 'icon': '🔥'},
        {'domain': 'Commute & Travel', 'kgCo2e': 38.0, 'percent': 15.0, 'icon': '🚴'},
        {'domain': 'Water Pumping', 'kgCo2e': 24.0, 'percent': 10.0, 'icon': '💧'},
      ],
      gridTariffInsights: {
        'recommendation': 'Shift heavy water pumping & washing cycles to 11:00-15:00 to consume free rooftop solar power and shave evening peak demand (18:00-22:00).',
        'monthlySavingsEstimateRupees': 420,
      },
    );
  }
}
