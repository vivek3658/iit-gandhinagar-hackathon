import 'package:flutter/foundation.dart';
import 'package:urja/services/game_state_service.dart';

/// Type of water supply infrastructure
enum WaterSupplyType {
  timedMunicipalMorning, // 6 AM - 8 AM timed municipal batch supply (common in Gujarat)
  continuous24x7Paid, // 24x7 metered pressurized pipeline
}

/// A daily water conservation quest
class WaterQuest {
  final String id;
  final String title;
  final String description;
  final String howItWorks;
  final int litersSaved;
  final int coinsReward;
  final double co2eSavedKg;
  bool isCompleted;

  WaterQuest({
    required this.id,
    required this.title,
    required this.description,
    required this.howItWorks,
    required this.litersSaved,
    required this.coinsReward,
    required this.co2eSavedKg,
    this.isCompleted = false,
  });
}

/// Service providing insights into Timed Municipal vs 24/7 Paid water networks,
/// tracking daily water quests, and linking saved water to avoided pumping CO2e.
class WaterConservationService extends ChangeNotifier {
  static final WaterConservationService instance =
      WaterConservationService._internal();

  WaterConservationService._internal() {
    _initQuests();
  }

  WaterSupplyType _supplyType = WaterSupplyType.timedMunicipalMorning;
  final List<WaterQuest> _quests = [];

  WaterSupplyType get supplyType => _supplyType;
  List<WaterQuest> get quests => List.unmodifiable(_quests);

  int get totalLitersSaved => _quests
      .where((q) => q.isCompleted)
      .fold(0, (sum, q) => sum + q.litersSaved);

  double get totalCo2eSavedKg => _quests
      .where((q) => q.isCompleted)
      .fold(0.0, (sum, q) => sum + q.co2eSavedKg);

  void setSupplyType(WaterSupplyType type) {
    if (_supplyType == type) return;
    _supplyType = type;
    notifyListeners();
  }

  void _initQuests() {
    _quests.addAll([
      WaterQuest(
        id: 'wq_overflow',
        title: 'Overhead Tank Overflow Check',
        description: 'Verify mechanical float valve or switch off pump immediately.',
        howItWorks:
            'In timed morning supply (6-8 AM), overflowing tanks waste 200-400L in minutes. A float valve stops 100% of overflow!',
        litersSaved: 250,
        coinsReward: 20,
        co2eSavedKg: 0.12,
      ),
      WaterQuest(
        id: 'wq_ro_reject',
        title: 'RO Reject Water Bucket Catch',
        description: 'Collect RO reject water pipe into a bucket for floor mopping or gardening.',
        howItWorks:
            'Domestic RO purifiers discard ~70% of intake water. Catching it recovers 40-60 Liters of non-potable cleaning water daily.',
        litersSaved: 50,
        coinsReward: 25,
        co2eSavedKg: 0.08,
      ),
      WaterQuest(
        id: 'wq_bucket_bath',
        title: 'Bucket Bath Challenge',
        description: 'Bathe using a 15-liter bucket instead of a 10-minute running shower.',
        howItWorks:
            'Standard showers flow at 10-14 L/min (100-140 Liters total). A bucket bath caps consumption strictly at 15 Liters, saving 85L!',
        litersSaved: 85,
        coinsReward: 20,
        co2eSavedKg: 0.15,
      ),
      WaterQuest(
        id: 'wq_tap_brush',
        title: 'Turn Off Tap While Brushing',
        description: 'Keep the faucet turned off while brushing teeth or shaving.',
        howItWorks:
            'A running tap discharges 6-8 L/min. Turning it off between rinses saves ~10 Liters per session.',
        litersSaved: 10,
        coinsReward: 10,
        co2eSavedKg: 0.04,
      ),
      WaterQuest(
        id: 'wq_aerator',
        title: 'Low-Flow Tap Aerator Inspection',
        description: 'Ensure aerator nozzles with 50% air-infusion are installed on kitchen/basin taps.',
        howItWorks:
            'Aerators reduce flow rate from 12 L/min down to 3.5 L/min with identical pressure feel, saving thousands of liters per year.',
        litersSaved: 60,
        coinsReward: 15,
        co2eSavedKg: 0.10,
      ),
    ]);
  }

  /// Completes a water quest, awarding coins and recording avoided carbon emissions
  bool completeQuest(String questId) {
    final idx = _quests.indexWhere((q) => q.id == questId);
    if (idx == -1) return false;

    final quest = _quests[idx];
    if (quest.isCompleted) return false;

    quest.isCompleted = true;

    // Credit coins and record carbon avoided
    GameStateService.instance.addCoins(quest.coinsReward);
    GameStateService.instance.recordCo2eSaved(quest.co2eSavedKg);

    notifyListeners();
    return true;
  }
}
