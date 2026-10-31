import 'package:flutter/material.dart';
import 'notification_service.dart';

/// Central Game & Behavioral State for URJA ONE.
///
/// Follows BEHAVIORAL_NUDGES.md:
/// - Mascot Level starts at 1 and only increases with verified CO2e saved.
/// - Urja Mudra coins are only earned through verified conservation habits.
/// - Configurable settings for Charger Unplug and Sleep Time reminders.
/// - Garden Island starts with ONLY the centerpiece Eco Home; other 8 plots free.
/// - Garden blocks do NOT generate coins or fake CO2e.
/// - Monthly Electricity Meter Units tracker with reduction goals & plot graph.
/// - Idle sleep timer (2 min), night dimming, and interactive bird states.
class GameStateService extends ChangeNotifier {
  static final GameStateService instance = GameStateService._internal();

  GameStateService._internal() {
    NotificationService.instance.onChargerDisconnected.listen((_) {
      if (_enableChargerReminder) {
        addCoins(5);
        addNotification(
          title: '🔌 Charger Pin Removed!',
          message: 'Nice job disconnecting! Ensure wall switch is OFF to stop standby vampire drain.',
          type: 'charger_unplug',
        );
      }
    });

    NotificationService.instance.onDepartureRewardClaimed.listen((coins) {
      addCoins(coins);
      recordEcoAction(
        actionName: '300m Departure: All Wall Switches OFF',
        co2Saved: 1.20,
        coinsAwarded: coins,
      );
      addNotification(
        title: '⚡ 300m Departure Verified! (+$coins 🪙)',
        message: 'Wall switches confirmed off upon leaving home. Saved ~1.20 kg CO₂e from idle phantom load!',
        type: 'departure_verified',
      );
    });
  }

  // --- Mascot State ---
  int _mascotLevel = 1;
  double _co2eSavedKg = 0.0;
  int _coins = 250; // Initial welcome bonus for sanctuary adoption
  double _vitality = 0.85;
  String _activeWeatherFx = 'rain';
  bool _isSleeping = false;

  // --- Onboarding & Energy Infrastructure Setup ---
  String _electricityProvider = 'Torrent Power (Gujarat)';
  bool _hasSolar = true;
  double _solarCapacityKw = 3.2; // PM Surya Ghar Muft Bijli Yojana rooftop installation
  bool _hasBatteryStorage = false;

  // --- Behavioral Settings ---
  bool _enableChargerReminder = true;
  bool _enableSleepReminder = true;
  TimeOfDay _sleepTime = const TimeOfDay(hour: 22, minute: 30); // 10:30 PM default
  String _mascotBehaviorTone = 'Zen Guardian'; // 'Encouraging' | 'Coach' | 'Zen Guardian'
  bool _soundEnabled = true;
  bool _enableNightDimming = true;
  int _idleTimeoutSeconds = 120; // 2 minutes idle sleep

  // --- Wardrobe State ---
  final Set<String> _ownedItems = {'acorn', 'readers', 'plaid', 'leaves'};
  String? _equippedHead;
  String? _equippedFace;
  String? _equippedNeck;
  String? _equippedHeld;
  String? _equippedOutfit = 'natural';

  // --- Garden Island State (3x3 Grid, Center Home Locked, 8 Free Plots) ---
  final List<Map<String, dynamic>> _gardenGridSlots = [
    {'x': -1, 'z': -1, 'id': null, 'r': 0},
    {'x': 0, 'z': -1, 'id': null, 'r': 0},
    {'x': 1, 'z': -1, 'id': null, 'r': 0},
    {'x': -1, 'z': 0, 'id': null, 'r': 0},
    {'x': 0, 'z': 0, 'id': 'SPARROW_HOME', 'r': 0},
    {'x': 1, 'z': 0, 'id': null, 'r': 0},
    {'x': -1, 'z': 1, 'id': null, 'r': 0},
    {'x': 0, 'z': 1, 'id': null, 'r': 0},
    {'x': 1, 'z': 1, 'id': null, 'r': 0},
  ];

  // --- Garden Stored Inventory (Items stored without selling) ---
  final List<String> _gardenInventory = [];
  bool _gardenScrollLocked = true; // Prevents accidental page scrolling when in garden

  // --- Monthly Electricity Consumption Ledger (Units / kWh) ---
  final Map<String, double> _monthlyUnitsLedger = {
    '2026-07': 315.0,
    '2026-08': 298.0,
    '2026-09': 282.0,
    '2026-10': 268.0,
  };
  double _targetReductionPercent = 15.0; // 15% reduction goal

  // --- Notification Center & Push History ---
  final List<Map<String, dynamic>> _notificationHistory = [
    {
      'id': 'notif_welcome',
      'title': '🕊️ Welcome to URJA ONE',
      'message': 'Your Level 1 Sparrow Sanctuary companion has hatched! Tap him to pet.',
      'type': 'system',
      'timestamp': DateTime.now().subtract(const Duration(hours: 2)),
      'read': true,
    },
    {
      'id': 'notif_charger',
      'title': '🔌 Charger Unplug Reminder Active',
      'message': 'Turn off the wall socket whenever your phone is disconnected.',
      'type': 'nudge',
      'timestamp': DateTime.now().subtract(const Duration(minutes: 45)),
      'read': false,
    },
  ];

  // Getters
  int get mascotLevel => _mascotLevel;
  double get co2eSavedKg => _co2eSavedKg;
  int get coins => _coins;
  double get vitality => _vitality;
  String get activeWeatherFx => _activeWeatherFx;
  bool get isSleeping => _isSleeping;

  String get electricityProvider => _electricityProvider;
  bool get hasSolar => _hasSolar;
  double get solarCapacityKw => _solarCapacityKw;
  bool get hasBatteryStorage => _hasBatteryStorage;

  bool get enableChargerReminder => _enableChargerReminder;
  bool get enableSleepReminder => _enableSleepReminder;
  TimeOfDay get sleepTime => _sleepTime;
  String get mascotBehaviorTone => _mascotBehaviorTone;
  bool get soundEnabled => _soundEnabled;
  bool get enableNightDimming => _enableNightDimming;
  int get idleTimeoutSeconds => _idleTimeoutSeconds;

  Set<String> get ownedItems => _ownedItems;
  String? get equippedHead => _equippedHead;
  String? get equippedFace => _equippedFace;
  String? get equippedNeck => _equippedNeck;
  String? get equippedHeld => _equippedHeld;
  String? get equippedOutfit => _equippedOutfit;

  List<Map<String, dynamic>> get gardenGridSlots =>
      List.unmodifiable(_gardenGridSlots);
  List<String> get gardenInventory => List.unmodifiable(_gardenInventory);
  bool get gardenScrollLocked => _gardenScrollLocked;
  Map<String, double> get monthlyUnitsLedger =>
      Map.unmodifiable(_monthlyUnitsLedger);
  double get targetReductionPercent => _targetReductionPercent;
  List<Map<String, dynamic>> get notificationHistory =>
      List.unmodifiable(_notificationHistory);

  /// Calculate the 15-minute advance reminder time for user's bedtime
  TimeOfDay get sleepReminderTime {
    int totalMins = _sleepTime.hour * 60 + _sleepTime.minute - 15;
    if (totalMins < 0) totalMins += 24 * 60;
    return TimeOfDay(hour: totalMins ~/ 60, minute: totalMins % 60);
  }

  /// Calculates next level CO2e requirement (Level 1: 10kg, Level 2: 25kg, etc.)
  double get nextLevelTargetKg {
    switch (_mascotLevel) {
      case 1:
        return 10.0;
      case 2:
        return 25.0;
      case 3:
        return 50.0;
      case 4:
        return 90.0;
      case 5:
        return 150.0;
      default:
        return (_mascotLevel * 35.0);
    }
  }

  /// Calculates previous level baseline CO2e
  double get currentLevelBaselineKg {
    switch (_mascotLevel) {
      case 1:
        return 0.0;
      case 2:
        return 10.0;
      case 3:
        return 25.0;
      case 4:
        return 50.0;
      case 5:
        return 90.0;
      default:
        return ((_mascotLevel - 1) * 35.0);
    }
  }

  /// Current level progress fraction from 0.0 to 1.0
  double get levelProgress {
    final range = nextLevelTargetKg - currentLevelBaselineKg;
    if (range <= 0) return 1.0;
    final progress = (_co2eSavedKg - currentLevelBaselineKg) / range;
    return progress.clamp(0.0, 1.0);
  }

  /// Latest recorded monthly electricity consumption (kWh)
  double get latestMonthlyUnits {
    if (_monthlyUnitsLedger.isEmpty) return 250.0;
    final sortedKeys = _monthlyUnitsLedger.keys.toList()..sort();
    return _monthlyUnitsLedger[sortedKeys.last]!;
  }

  /// Target electricity units after applying reduction goal
  double get targetMonthlyUnits {
    return latestMonthlyUnits * (1.0 - (_targetReductionPercent / 100.0));
  }

  /// Potential monthly electricity bill savings (₹) at average Gujarat residential tariff ₹7.5/kWh
  double get projectedMonthlyRupeesSaved {
    final diff = latestMonthlyUnits - targetMonthlyUnits;
    return (diff * 7.5).clamp(0.0, 99999.0);
  }

  /// Potential monthly CO2e prevented (kg) at Western Grid emission factor 0.82 kg/kWh
  double get projectedMonthlyCo2SavedKg {
    final diff = latestMonthlyUnits - targetMonthlyUnits;
    return (diff * 0.82).clamp(0.0, 9999.0);
  }

  void setWeatherFx(String? fx) {
    _activeWeatherFx = fx ?? 'rain';
    notifyListeners();
  }

  void setVitality(double v) {
    _vitality = v.clamp(0.0, 1.0);
    notifyListeners();
  }

  void setSleeping(bool val) {
    if (_isSleeping != val) {
      _isSleeping = val;
      notifyListeners();
    }
  }

  // --- Behavioral Settings Updates ---
  void setEnableChargerReminder(bool val) {
    _enableChargerReminder = val;
    notifyListeners();
  }

  void setEnableSleepReminder(bool val) {
    _enableSleepReminder = val;
    notifyListeners();
  }

  void setSleepTime(TimeOfDay time) {
    _sleepTime = time;
    notifyListeners();
  }

  void setMascotBehaviorTone(String tone) {
    _mascotBehaviorTone = tone;
    notifyListeners();
  }

  void setSoundEnabled(bool val) {
    _soundEnabled = val;
    notifyListeners();
  }

  void setEnableNightDimming(bool val) {
    _enableNightDimming = val;
    notifyListeners();
  }

  void setIdleTimeoutSeconds(int secs) {
    _idleTimeoutSeconds = secs;
    notifyListeners();
  }

  /// Records a verified behavioral carbon saving action.
  /// Mascot levels up ONLY when cumulative CO2e saved passes threshold!
  bool recordEcoAction({
    required String actionName,
    required double co2Saved,
    required int coinsAwarded,
  }) {
    _co2eSavedKg += co2Saved;
    _coins += coinsAwarded;
    _vitality = (_vitality + 0.1).clamp(0.0, 1.0);

    bool didLevelUp = false;
    while (_co2eSavedKg >= nextLevelTargetKg) {
      _mascotLevel += 1;
      didLevelUp = true;
    }

    addNotification(
      title: '🍃 $actionName Completed!',
      message: 'Earned +$coinsAwarded 🪙 Urja Mudra and prevented +${co2Saved.toStringAsFixed(2)} kg CO2e.',
      type: 'eco_action',
    );

    notifyListeners();
    return didLevelUp;
  }

  void addCoins(int amount) {
    _coins += amount;
    notifyListeners();
  }

  bool recordCo2eSaved(double kg) {
    _co2eSavedKg += kg;
    _vitality = (_vitality + 0.05).clamp(0.0, 1.0);
    bool didLevelUp = false;
    while (_co2eSavedKg >= nextLevelTargetKg) {
      _mascotLevel += 1;
      didLevelUp = true;
    }
    notifyListeners();
    return didLevelUp;
  }

  void setElectricityProvider(String provider) {
    _electricityProvider = provider;
    notifyListeners();
  }

  void setSolarDetails({
    required bool hasSolar,
    required double capacityKw,
    required bool hasBattery,
  }) {
    _hasSolar = hasSolar;
    _solarCapacityKw = capacityKw;
    _hasBatteryStorage = hasBattery;
    notifyListeners();
  }

  /// Purchase an accessory with Urja Mudra coins
  bool buyAccessory({
    required String itemId,
    required int price,
    required int requiredLevel,
  }) {
    if (_mascotLevel < requiredLevel) return false;
    if (_coins < price) return false;
    if (_ownedItems.contains(itemId)) return true;

    _coins -= price;
    _ownedItems.add(itemId);
    notifyListeners();
    return true;
  }

  /// Equips an item to a slot
  void equipItem(String slot, String? itemId) {
    switch (slot) {
      case 'head':
        _equippedHead = itemId;
        break;
      case 'face':
        _equippedFace = itemId;
        break;
      case 'neck':
        _equippedNeck = itemId;
        break;
      case 'held':
        _equippedHeld = itemId;
        break;
    }
    _equippedOutfit = null;
    notifyListeners();
  }

  /// Equips a full outfit
  void equipOutfit(String outfitKey, Map<String, String?> slots) {
    _equippedOutfit = outfitKey;
    _equippedHead = slots['head'];
    _equippedFace = slots['face'];
    _equippedNeck = slots['neck'];
    _equippedHeld = slots['held'];
    notifyListeners();
  }

  // --- Garden Island Building & Placement Operations ---
  bool buyAndPlaceGardenTile({
    required int x,
    required int z,
    required String tileId,
    required int cost,
    int rotation = 0,
  }) {
    final idx = _gardenGridSlots.indexWhere((s) => s['x'] == x && s['z'] == z);
    if (idx == -1) return false;
    if (_gardenGridSlots[idx]['id'] != null) return false; // Already occupied
    if (_coins < cost) return false;

    _coins -= cost;
    _gardenGridSlots[idx]['id'] = tileId;
    _gardenGridSlots[idx]['r'] = rotation;
    notifyListeners();
    return true;
  }

  bool rotateGardenTile(int x, int z) {
    final idx = _gardenGridSlots.indexWhere((s) => s['x'] == x && s['z'] == z);
    if (idx == -1 || _gardenGridSlots[idx]['id'] == null) return false;
    _gardenGridSlots[idx]['r'] = ((_gardenGridSlots[idx]['r'] as int) + 1) % 4;
    notifyListeners();
    return true;
  }

  bool moveGardenTile({
    required int fromX,
    required int fromZ,
    required int toX,
    required int toZ,
  }) {
    final fromIdx =
        _gardenGridSlots.indexWhere((s) => s['x'] == fromX && s['z'] == fromZ);
    final toIdx =
        _gardenGridSlots.indexWhere((s) => s['x'] == toX && s['z'] == toZ);
    if (fromIdx == -1 || toIdx == -1) return false;
    if (_gardenGridSlots[fromIdx]['id'] == null) return false;
    if (_gardenGridSlots[toIdx]['id'] != null) return false; // Destination must be empty

    _gardenGridSlots[toIdx]['id'] = _gardenGridSlots[fromIdx]['id'];
    _gardenGridSlots[toIdx]['r'] = _gardenGridSlots[fromIdx]['r'];
    _gardenGridSlots[fromIdx]['id'] = null;
    _gardenGridSlots[fromIdx]['r'] = 0;
    notifyListeners();
    return true;
  }

  void setGardenScrollLocked(bool locked) {
    _gardenScrollLocked = locked;
    notifyListeners();
  }

  void toggleGardenScrollLock() {
    _gardenScrollLocked = !_gardenScrollLocked;
    notifyListeners();
  }

  bool storeGardenTileInInventory(int x, int z) {
    final idx = _gardenGridSlots.indexWhere((s) => s['x'] == x && s['z'] == z);
    if (idx == -1 || _gardenGridSlots[idx]['id'] == null) return false;
    // SPARROW_HOME cannot be removed or stored
    if (_gardenGridSlots[idx]['id'] == 'SPARROW_HOME') return false;

    final tileId = _gardenGridSlots[idx]['id'] as String;
    _gardenInventory.add(tileId);
    _gardenGridSlots[idx]['id'] = null;
    _gardenGridSlots[idx]['r'] = 0;
    notifyListeners();
    return true;
  }

  bool deployInventoryGardenTile({
    required int x,
    required int z,
    required String tileId,
    int rotation = 0,
  }) {
    if (!_gardenInventory.contains(tileId)) return false;
    final idx = _gardenGridSlots.indexWhere((s) => s['x'] == x && s['z'] == z);
    if (idx == -1 || _gardenGridSlots[idx]['id'] != null) return false; // Must be empty

    _gardenInventory.remove(tileId);
    _gardenGridSlots[idx]['id'] = tileId;
    _gardenGridSlots[idx]['r'] = rotation;
    notifyListeners();
    return true;
  }

  bool demolishGardenTile(int x, int z) {
    final idx = _gardenGridSlots.indexWhere((s) => s['x'] == x && s['z'] == z);
    if (idx == -1 || _gardenGridSlots[idx]['id'] == null) return false;
    // SPARROW_HOME cannot be deleted
    if (_gardenGridSlots[idx]['id'] == 'SPARROW_HOME') return false;

    _gardenGridSlots[idx]['id'] = null;
    _gardenGridSlots[idx]['r'] = 0;
    notifyListeners();
    return true;
  }

  void syncGardenGrid(List<dynamic> remoteSlots) {
    for (final s in remoteSlots) {
      if (s is Map) {
        final x = s['x'] as int?;
        final z = s['z'] as int?;
        final id = s['id'] as String?;
        final r = s['r'] as int? ?? 0;
        final idx =
            _gardenGridSlots.indexWhere((g) => g['x'] == x && g['z'] == z);
        if (idx != -1) {
          _gardenGridSlots[idx]['id'] = id;
          _gardenGridSlots[idx]['r'] = r;
        }
      }
    }
    notifyListeners();
  }

  // --- Monthly Electricity Meter Units Ledger ---
  void recordMonthlyUnits(String monthKey, double units) {
    _monthlyUnitsLedger[monthKey] = units;
    notifyListeners();
  }

  void setTargetReductionPercent(double percent) {
    _targetReductionPercent = percent.clamp(5.0, 50.0);
    notifyListeners();
  }

  // --- In-App Notifications History ---
  void addNotification({
    required String title,
    required String message,
    required String type,
  }) {
    _notificationHistory.insert(0, {
      'id': 'notif_${DateTime.now().millisecondsSinceEpoch}',
      'title': title,
      'message': message,
      'type': type,
      'timestamp': DateTime.now(),
      'read': false,
    });
    if (_notificationHistory.length > 30) {
      _notificationHistory.removeLast();
    }
    notifyListeners();
  }

  void markAllNotificationsRead() {
    for (final n in _notificationHistory) {
      n['read'] = true;
    }
    notifyListeners();
  }
}
