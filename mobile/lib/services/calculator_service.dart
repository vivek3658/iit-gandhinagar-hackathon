import 'dart:convert';
import 'dart:io';
import '../constants/auth_config.dart';

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
    final bd = json['breakdown'] as Map<String, dynamic>? ?? {};
    final pct = json['percentages'] as Map<String, dynamic>? ?? {};
    final bm = json['benchmarks'] as Map<String, dynamic>? ?? {};
    final plan = (json['actionPlan'] as List<dynamic>?)?.map((e) => e as Map<String, dynamic>).toList() ?? [];

    return CarbonEstimateResult(
      totalYearlyKgCO2e: (json['totalYearlyKgCO2e'] as num?)?.toDouble() ?? 1420.0,
      totalMonthlyKgCO2e: (json['totalMonthlyKgCO2e'] as num?)?.toDouble() ?? 118.0,
      breakdown: bd.map((k, v) => MapEntry(k, (v as num).toDouble())),
      percentages: pct.map((k, v) => MapEntry(k, (v as num).toDouble())),
      gujaratAverageKgCO2e: (bm['gujaratAverageKgCO2e'] as num?)?.toDouble() ?? 1850.0,
      indiaAverageKgCO2e: (bm['indiaAverageKgCO2e'] as num?)?.toDouble() ?? 1910.0,
      percentileVsGujarat: (bm['percentileVsGujarat'] as num?)?.toDouble() ?? 78.0,
      rating: bm['rating'] as String? ?? 'Conscious Citizen',
      actionPlan: plan,
    );
  }
}

class CalculatorClientService {
  static final CalculatorClientService instance = CalculatorClientService._();
  CalculatorClientService._();

  final HttpClient _http = HttpClient()..connectionTimeout = const Duration(seconds: 4);

  Future<CarbonEstimateResult> estimate({
    required double monthlyKwh,
    required String cookingFuelType,
    required double cookingQuantity,
    required double dailyCommuteKm,
    required String commuteMode,
    String dietType = 'VEGETARIAN',
  }) async {
    try {
      final uri = Uri.parse('${AuthConfig.apiBaseUrl}/calculator/estimate');
      final req = await _http.postUrl(uri);
      req.headers.contentType = ContentType.json;
      req.write(jsonEncode({
        'monthlyElectricityUnitsKwh': monthlyKwh,
        'cookingFuelType': cookingFuelType,
        'cookingMonthlyQuantity': cookingQuantity,
        'dailyCommuteKm': dailyCommuteKm,
        'commuteMode': commuteMode,
        'dietType': dietType,
      }));
      final res = await req.close();
      if (res.statusCode == 200) {
        final body = await res.transform(utf8.decoder).join();
        return CarbonEstimateResult.fromJson(jsonDecode(body) as Map<String, dynamic>);
      }
    } catch (_) {}

    // Offline CEA calculation fallback
    final elecKgYear = monthlyKwh * 0.82 * 12;
    double cookingKgYear = 0;
    if (cookingFuelType == 'LPG_CYLINDER') {
      cookingKgYear = cookingQuantity * 14.2 * 2.98 * 12;
    } else if (cookingFuelType == 'PNG_PIPED') {
      cookingKgYear = cookingQuantity * 1.95 * 12;
    } else {
      cookingKgYear = cookingQuantity * 30 * 0.82 * 12;
    }

    double commuteEmissionFactor = 0.035; // EV 2-wheeler
    if (commuteMode == 'PETROL_2WHEELER') commuteEmissionFactor = 0.052;
    if (commuteMode == 'PETROL_CAR') commuteEmissionFactor = 0.145;
    if (commuteMode == 'PUBLIC_BUS_METRO') commuteEmissionFactor = 0.022;
    if (commuteMode == 'BICYCLE_WALK') commuteEmissionFactor = 0.0;

    final commuteKgYear = dailyCommuteKm * 300 * commuteEmissionFactor;
    double dietKgYear = dietType == 'VEGAN' ? 400.0 : (dietType == 'NON_VEGETARIAN' ? 950.0 : 620.0);

    final totalYear = elecKgYear + cookingKgYear + commuteKgYear + dietKgYear;

    return CarbonEstimateResult(
      totalYearlyKgCO2e: double.parse(totalYear.toStringAsFixed(1)),
      totalMonthlyKgCO2e: double.parse((totalYear / 12).toStringAsFixed(1)),
      breakdown: {
        'electricityKgCO2e': double.parse(elecKgYear.toStringAsFixed(1)),
        'cookingKgCO2e': double.parse(cookingKgYear.toStringAsFixed(1)),
        'commuteKgCO2e': double.parse(commuteKgYear.toStringAsFixed(1)),
        'dietWasteKgCO2e': double.parse(dietKgYear.toStringAsFixed(1)),
      },
      percentages: {
        'electricity': double.parse((elecKgYear / totalYear * 100).toStringAsFixed(1)),
        'cooking': double.parse((cookingKgYear / totalYear * 100).toStringAsFixed(1)),
        'commute': double.parse((commuteKgYear / totalYear * 100).toStringAsFixed(1)),
        'dietWaste': double.parse((dietKgYear / totalYear * 100).toStringAsFixed(1)),
      },
      gujaratAverageKgCO2e: 1850.0,
      indiaAverageKgCO2e: 1910.0,
      percentileVsGujarat: 76.0,
      rating: totalYear < 1500 ? '🌱 Eco Guardian' : '💡 Conscious Citizen',
      actionPlan: [
        {
          'title': 'AC Set at 24°C Comfort',
          'description': 'Maintains ideal cooling while cutting compressor power by 24%',
          'annualSavingsRupees': 3800,
          'annualCo2ReductionKg': 340,
          'difficulty': 'EASY',
          'icon': '❄️',
        },
        {
          'title': 'Rooftop Solar Net-Metering',
          'description': '3 kW solar system generates ~360 units/month, eliminating ₹2,400 bill',
          'annualSavingsRupees': 28800,
          'annualCo2ReductionKg': 3540,
          'difficulty': 'HIGH_IMPACT',
          'icon': '☀️',
        },
        {
          'title': 'Vampire Standby Sweep at 9 PM',
          'description': 'Turn off TV consoles, microwave clocks, and idle chargers',
          'annualSavingsRupees': 1200,
          'annualCo2ReductionKg': 150,
          'difficulty': 'EASY',
          'icon': '🌙',
        },
      ],
    );
  }
}
