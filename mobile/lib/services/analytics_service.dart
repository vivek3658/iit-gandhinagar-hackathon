import 'dart:io';

import 'api_client.dart';

class AnalyticsDashboardData {
  final Map<String, dynamic> dataAvailability;
  final Map<String, dynamic> realTimeMetrics;
  final List<Map<String, dynamic>> hourlyLoadCurve;
  final List<Map<String, dynamic>> applianceBreakdown;
  final List<Map<String, dynamic>> monthlyTrends;
  final List<Map<String, dynamic>> carbonLedger;
  final Map<String, dynamic> gridTariffInsights;
  final List<Map<String, dynamic>> utilityReadings;

  AnalyticsDashboardData({
    required this.dataAvailability,
    required this.realTimeMetrics,
    required this.hourlyLoadCurve,
    required this.applianceBreakdown,
    required this.monthlyTrends,
    required this.carbonLedger,
    required this.gridTariffInsights,
    required this.utilityReadings,
  });

  factory AnalyticsDashboardData.fromJson(Map<String, dynamic> json) =>
      AnalyticsDashboardData(
        dataAvailability:
            json['dataAvailability'] as Map<String, dynamic>? ?? const {},
        realTimeMetrics:
            json['realTimeMetrics'] as Map<String, dynamic>? ?? const {},
        hourlyLoadCurve: _mapList(json['hourlyLoadCurve']),
        applianceBreakdown: _mapList(json['applianceBreakdown']),
        monthlyTrends: _mapList(json['monthlyTrends']),
        carbonLedger: _mapList(json['carbonLedger']),
        gridTariffInsights:
            json['gridTariffInsights'] as Map<String, dynamic>? ?? const {},
        utilityReadings: _mapList(json['utilityReadings']),
      );

  static List<Map<String, dynamic>> _mapList(Object? value) =>
      (value as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .toList();
}

class AnalyticsClientService {
  static final AnalyticsClientService instance = AnalyticsClientService._();

  AnalyticsClientService._();

  Future<AnalyticsDashboardData> getDashboard() async {
    final response = await ApiClient.instance.get('/analytics/dashboard');
    if (response.statusCode < HttpStatus.ok ||
        response.statusCode >= HttpStatus.multipleChoices) {
      throw HttpException(
        'Could not load analytics (${response.statusCode}): ${response.body}',
      );
    }
    return AnalyticsDashboardData.fromJson(response.decodeJson());
  }
}
