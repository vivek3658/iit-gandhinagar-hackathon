import 'package:flutter_test/flutter_test.dart';
import 'package:urja/models/senior_carbon_analytics.dart';
import 'package:urja/services/quests_service.dart';

void main() {
  group('SeniorCarbonAnalytics', () {
    test('missing response fields stay empty instead of using sample data', () {
      final analytics = SeniorCarbonAnalytics.fromJson({});

      expect(analytics.realTimeMetrics, isEmpty);
      expect(analytics.hourlyLoadCurve, isEmpty);
      expect(analytics.applianceBreakdown, isEmpty);
      expect(analytics.carbonLedger, isEmpty);
      expect(analytics.gridTariffInsights, isEmpty);
      expect(analytics.dataAvailability, isEmpty);
      expect(analytics.utilityReadings, isEmpty);
    });

    test('parses analytics returned by the API', () {
      final analytics = SeniorCarbonAnalytics.fromJson({
        'dataAvailability': {'utilityReadings': true},
        'realTimeMetrics': {'todayKwh': 4.2},
        'hourlyLoadCurve': [
          {'hour': 8, 'loadKw': 1.1},
        ],
        'applianceBreakdown': [
          {'applianceName': 'Fan', 'kwhPerMonth': 12},
        ],
        'carbonLedger': [
          {'domain': 'Electricity', 'kgCo2e': 5},
        ],
        'gridTariffInsights': {'recommendation': 'Use power later'},
        'utilityReadings': [
          {
            'utility': 'ELECTRICITY',
            'value': 142,
            'unit': 'kWh',
            'periodEnd': '2026-10-31',
          },
        ],
      });

      expect(analytics.dataAvailability['utilityReadings'], isTrue);
      expect(analytics.realTimeMetrics['todayKwh'], 4.2);
      expect(analytics.hourlyLoadCurve.single['loadKw'], 1.1);
      expect(analytics.applianceBreakdown.single['applianceName'], 'Fan');
      expect(analytics.carbonLedger.single['kgCo2e'], 5);
      expect(analytics.gridTariffInsights['recommendation'], 'Use power later');
      expect(analytics.utilityReadings.single['value'], 142);
    });

    test('rejects malformed analytics records', () {
      expect(
        () => SeniorCarbonAnalytics.fromJson({
          'carbonLedger': [1],
        }),
        throwsFormatException,
      );
    });
  });

  group('DailyQuestsData', () {
    test('missing reward data defaults to zero', () {
      final quests = DailyQuestsData.fromJson({
        'quests': [
          {'id': 'walk', 'title': 'Walk to work'},
        ],
      });

      expect(quests.streakDays, 0);
      expect(quests.totalCoinsEarnableToday, 0);
      expect(quests.totalCo2AvoidableToday, 0);
      expect(quests.quests.single.coinReward, 0);
      expect(quests.quests.single.xpReward, 0);
      expect(quests.quests.single.co2SavedKg, 0);
    });

    test('parses daily quest rewards returned by the API', () {
      final quests = DailyQuestsData.fromJson({
        'streakDays': 3,
        'totalCoinsEarnableToday': 25,
        'totalCo2AvoidableToday': 1.5,
        'quests': [
          {
            'id': 'walk',
            'title': 'Walk to work',
            'co2SavedKg': 1.5,
            'coinReward': 25,
            'xpReward': 10,
          },
        ],
      });

      expect(quests.streakDays, 3);
      expect(quests.totalCoinsEarnableToday, 25);
      expect(quests.totalCo2AvoidableToday, 1.5);
      expect(quests.quests.single.coinReward, 25);
      expect(quests.quests.single.xpReward, 10);
      expect(quests.quests.single.co2SavedKg, 1.5);
    });

    test('rejects a task without its server-provided identity', () {
      expect(
        () => DailyQuestsData.fromJson({
          'quests': [
            {'title': 'Walk to work'},
          ],
        }),
        throwsFormatException,
      );
    });
  });
}
