import 'dart:io';

import 'api_client.dart';

class CarbonEstimateResult {
  final double totalYearlyKgCO2e;
  final double totalMonthlyKgCO2e;
  final Map<String, double> breakdown;
  final Map<String, double> percentages;
  final double gujaratAverageKgCO2e;
  final double indiaAverageKgCO2e;
  final double percentileVsGujarat;
  final String rating;
  final List<Map<String, dynamic>> actionPlan;

  CarbonEstimateResult({
    required this.totalYearlyKgCO2e,
    required this.totalMonthlyKgCO2e,
    required this.breakdown,
    required this.percentages,
    required this.gujaratAverageKgCO2e,
    required this.indiaAverageKgCO2e,
    required this.percentileVsGujarat,
    required this.rating,
    required this.actionPlan,
  });

  factory CarbonEstimateResult.fromJson(Map<String, dynamic> json) {
    final breakdown = json['breakdown'] as Map<String, dynamic>? ?? {};
    final percentages = json['percentages'] as Map<String, dynamic>? ?? {};
    final benchmarks = json['benchmarks'] as Map<String, dynamic>? ?? {};
    final plan = (json['actionPlan'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .toList();

    return CarbonEstimateResult(
      totalYearlyKgCO2e: (json['totalYearlyKgCO2e'] as num?)?.toDouble() ?? 0,
      totalMonthlyKgCO2e: (json['totalMonthlyKgCO2e'] as num?)?.toDouble() ?? 0,
      breakdown: breakdown.map(
        (key, value) => MapEntry(key, (value as num).toDouble()),
      ),
      percentages: percentages.map(
        (key, value) => MapEntry(key, (value as num).toDouble()),
      ),
      gujaratAverageKgCO2e:
          (benchmarks['gujaratAverageKgCO2e'] as num?)?.toDouble() ?? 0,
      indiaAverageKgCO2e:
          (benchmarks['indiaAverageKgCO2e'] as num?)?.toDouble() ?? 0,
      percentileVsGujarat:
          (benchmarks['percentileVsGujarat'] as num?)?.toDouble() ?? 0,
      rating: benchmarks['rating'] as String? ?? '',
      actionPlan: plan,
    );
  }
}

class CalculatorClientService {
  static final CalculatorClientService instance = CalculatorClientService._();

  CalculatorClientService._();

  Future<CarbonEstimateResult> estimate({
    required double monthlyKwh,
    required String cookingFuelType,
    required double cookingQuantity,
    required double dailyCommuteKm,
    required String commuteMode,
    String dietType = 'VEGETARIAN',
  }) async {
    final response = await ApiClient.instance.post(
      '/calculator/estimate',
      authenticated: false,
      body: {
        'monthlyElectricityUnitsKwh': monthlyKwh,
        'cookingFuelType': cookingFuelType,
        'cookingMonthlyQuantity': cookingQuantity,
        'dailyCommuteKm': dailyCommuteKm,
        'commuteMode': commuteMode,
        'dietType': dietType,
      },
    );
    if (response.statusCode < HttpStatus.ok ||
        response.statusCode >= HttpStatus.multipleChoices) {
      throw HttpException(
        'Could not calculate your footprint (${response.statusCode}): ${response.body}',
      );
    }
    return CarbonEstimateResult.fromJson(response.decodeJson());
  }
}
