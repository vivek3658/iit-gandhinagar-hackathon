/// Measured utility analytics returned by the backend.
class SeniorCarbonAnalytics {
  final Map<String, dynamic> dataAvailability;
  final Map<String, dynamic> realTimeMetrics;
  final List<Map<String, dynamic>> hourlyLoadCurve;
  final List<Map<String, dynamic>> applianceBreakdown;
  final List<Map<String, dynamic>> carbonLedger;
  final Map<String, dynamic> gridTariffInsights;
  final List<Map<String, dynamic>> utilityReadings;

  SeniorCarbonAnalytics({
    required this.dataAvailability,
    required this.realTimeMetrics,
    required this.hourlyLoadCurve,
    required this.applianceBreakdown,
    required this.carbonLedger,
    required this.gridTariffInsights,
    required this.utilityReadings,
  });

  factory SeniorCarbonAnalytics.fromJson(Map<String, dynamic> json) {
    return SeniorCarbonAnalytics(
      dataAvailability: _analyticsMap(json, 'dataAvailability'),
      realTimeMetrics: _analyticsMap(json, 'realTimeMetrics'),
      hourlyLoadCurve: _analyticsMapList(json, 'hourlyLoadCurve'),
      applianceBreakdown: _analyticsMapList(json, 'applianceBreakdown'),
      carbonLedger: _analyticsMapList(json, 'carbonLedger'),
      gridTariffInsights: _analyticsMap(json, 'gridTariffInsights'),
      utilityReadings: _analyticsMapList(json, 'utilityReadings'),
    );
  }
}

Map<String, dynamic> _analyticsMap(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value == null) return {};
  if (value is! Map) {
    throw FormatException('Carbon analytics field "$key" must be an object.');
  }
  return Map<String, dynamic>.from(value);
}

List<Map<String, dynamic>> _analyticsMapList(
  Map<String, dynamic> json,
  String key,
) {
  final value = json[key];
  if (value == null) return [];
  if (value is! List) {
    throw FormatException('Carbon analytics field "$key" must be a list.');
  }
  return value.map((item) {
    if (item is! Map) {
      throw FormatException(
        'Each item in carbon analytics field "$key" must be an object.',
      );
    }
    return Map<String, dynamic>.from(item);
  }).toList();
}
