import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import '../constants/auth_config.dart';
import 'auth_service.dart';
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
/// - Robust Local Persistence (Never loses purchases or garden on refresh) + Backend Sync.
class GameStateService extends ChangeNotifier {
  static final GameStateService instance = GameStateService._internal();

  GameStateService._internal() {
    _loadFromLocalStorage();

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

    // Asynchronously synchronize with remote Fastify backend if online
    syncWithBackend();
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

  // ==========================================
  // LOCAL PERSISTENCE SYSTEM (Never resets on refresh)
  // ==========================================
  File _getStorageFile() {
    try {
      final dir = Directory('/data/user/0/com.geda.urjavatika.urja/files');
      if (!dir.existsSync()) {
        dir.createSync(recursive: true);
      }
      return File('${dir.path}/urja_game_state.json');
    } catch (_) {}
    try {
      final dir2 = Directory('/data/data/com.geda.urjavatika.urja/files');
      if (!dir2.existsSync()) {
        dir2.createSync(recursive: true);
      }
      return File('${dir2.path}/urja_game_state.json');
    } catch (_) {}
    try {
      return File('${Directory.systemTemp.path}/urja_game_state.json');
    } catch (_) {
      return File('urja_game_state.json');
    }
  }

  void _loadFromLocalStorage() {
    try {
      final file = _getStorageFile();
      if (!file.existsSync()) return;
      final raw = file.readAsStringSync();
      if (raw.isEmpty) return;
      final json = jsonDecode(raw) as Map<String, dynamic>;

      if (json['coins'] is num) _coins = (json['coins'] as num).toInt();
      if (json['vitality'] is num) _vitality = (json['vitality'] as num).toDouble().clamp(0.0, 1.0);
      if (json['mascotLevel'] is num) _mascotLevel = (json['mascotLevel'] as num).toInt();
      if (json['co2eSavedKg'] is num) _co2eSavedKg = (json['co2eSavedKg'] as num).toDouble();
      if (json['ownedItems'] is List) {
        for (final item in json['ownedItems'] as List) {
          _ownedItems.add(item.toString());
        }
      }
      _equippedHead = json['equippedHead'] as String?;
      _equippedFace = json['equippedFace'] as String?;
      _equippedNeck = json['equippedNeck'] as String?;
      _equippedHeld = json['equippedHeld'] as String?;
      _equippedOutfit = json['equippedOutfit'] as String? ?? _equippedOutfit;

      if (json['gardenGridSlots'] is List) {
        final list = json['gardenGridSlots'] as List;
        for (final s in list) {
          if (s is Map) {
            final x = s['x'];
            final z = s['z'];
            final id = s['id'] as String?;
            final r = s['r'] as int? ?? 0;
            final idx = _gardenGridSlots.indexWhere((g) => g['x'] == x && g['z'] == z);
            if (idx != -1) {
              _gardenGridSlots[idx]['id'] = id;
              _gardenGridSlots[idx]['r'] = r;
            }
          }
        }
      }

      if (json['gardenInventory'] is List) {
        _gardenInventory.clear();
        for (final item in json['gardenInventory'] as List) {
          _gardenInventory.add(item.toString());
        }
      }

      if (json['monthlyUnitsLedger'] is Map) {
        final map = json['monthlyUnitsLedger'] as Map;
        map.forEach((k, v) {
          if (v is num) _monthlyUnitsLedger[k.toString()] = v.toDouble();
        });
      }

      if (json['electricityProvider'] is String) {
        _electricityProvider = json['electricityProvider'] as String;
      }
      if (json['hasSolar'] is bool) _hasSolar = json['hasSolar'] as bool;
      if (json['solarCapacityKw'] is num) {
        _solarCapacityKw = (json['solarCapacityKw'] as num).toDouble();
      }
      if (json['hasBatteryStorage'] is bool) {
        _hasBatteryStorage = json['hasBatteryStorage'] as bool;
      }
    } catch (e) {
      debugPrint('[GameStateService] Failed to load local state: $e');
    }
  }

  void _saveToLocalStorage() {
    try {
      final file = _getStorageFile();
      final json = {
        'coins': _coins,
        'vitality': _vitality,
        'mascotLevel': _mascotLevel,
        'co2eSavedKg': _co2eSavedKg,
        'ownedItems': _ownedItems.toList(),
        'equippedHead': _equippedHead,
        'equippedFace': _equippedFace,
        'equippedNeck': _equippedNeck,
        'equippedHeld': _equippedHeld,
        'equippedOutfit': _equippedOutfit,
        'gardenGridSlots': _gardenGridSlots,
        'gardenInventory': _gardenInventory,
        'monthlyUnitsLedger': _monthlyUnitsLedger,
        'electricityProvider': _electricityProvider,
        'hasSolar': _hasSolar,
        'solarCapacityKw': _solarCapacityKw,
        'hasBatteryStorage': _hasBatteryStorage,
      };
      file.writeAsStringSync(jsonEncode(json), flush: true);
    } catch (e) {
      debugPrint('[GameStateService] Failed to save local state: $e');
    }
  }

  @override
  void notifyListeners() {
    _saveToLocalStorage();
    super.notifyListeners();
  }

  // ==========================================
  // BACKEND SYNC SYSTEM
  // ==========================================
  Future<void> _sendBackendPost(String endpoint, Map<String, dynamic> data) async {
    final token = AuthService.instance.accessToken;
    if (token == null || token.isEmpty) return;
    try {
      final client = HttpClient()..connectionTimeout = const Duration(seconds: 6);
      final request = await client.postUrl(Uri.parse('${AuthConfig.apiBaseUrl}$endpoint'));
      request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $token');
      request.headers.contentType = ContentType.json;
      request.write(jsonEncode(data));
      final response = await request.close();
      client.close();
      debugPrint('[GameStateService] Backend POST $endpoint -> ${response.statusCode}');
    } catch (e) {
      debugPrint('[GameStateService] Backend POST $endpoint error: $e');
    }
  }

  Future<void> syncWithBackend() async {
    final token = AuthService.instance.accessToken;
    if (token == null || token.isEmpty) return;
    try {
      final client = HttpClient()..connectionTimeout = const Duration(seconds: 8);

      // 1. Fetch remote Mascot State
      final mascotReq = await client.getUrl(Uri.parse('${AuthConfig.apiBaseUrl}/mascot/state'));
      mascotReq.headers.set(HttpHeaders.authorizationHeader, 'Bearer $token');
      mascotReq.headers.set(HttpHeaders.acceptHeader, 'application/json');
      final mascotResp = await mascotReq.close();
      final mascotBody = await mascotResp.transform(utf8.decoder).join();
      if (mascotResp.statusCode == 200) {
        final decoded = jsonDecode(mascotBody) as Map<String, dynamic>;
        final data = decoded['data'] is Map<String, dynamic>
            ? decoded['data'] as Map<String, dynamic>
            : decoded;
        if (data['vitality'] is num) {
          final v = (data['vitality'] as num).toDouble();
          _vitality = (v > 1 ? v / 100 : v).clamp(0.0, 1.0);
        }
        if (data['level'] is num) _mascotLevel = (data['level'] as num).toInt();
        if (data['co2eSavedKg'] is num) _co2eSavedKg = (data['co2eSavedKg'] as num).toDouble();
      }

      // 2. Fetch remote Wardrobe
      final wardrobeReq = await client.getUrl(Uri.parse('${AuthConfig.apiBaseUrl}/mascot/wardrobe'));
      wardrobeReq.headers.set(HttpHeaders.authorizationHeader, 'Bearer $token');
      wardrobeReq.headers.set(HttpHeaders.acceptHeader, 'application/json');
      final wardrobeResp = await wardrobeReq.close();
      final wardrobeBody = await wardrobeResp.transform(utf8.decoder).join();
      if (wardrobeResp.statusCode == 200) {
        final decoded = jsonDecode(wardrobeBody) as Map<String, dynamic>;
        final owned = decoded['owned'] is List
            ? decoded['owned'] as List
            : (decoded['data']?['owned'] as List?);
        if (owned != null) {
          for (final item in owned) {
            if (item is String) _ownedItems.add(item);
            else if (item is Map && item['id'] is String) _ownedItems.add(item['id'] as String);
          }
        }
      }

      // 3. Fetch remote Garden Sanctuary
      final gardenReq = await client.getUrl(Uri.parse('${AuthConfig.apiBaseUrl}/garden'));
      gardenReq.headers.set(HttpHeaders.authorizationHeader, 'Bearer $token');
      gardenReq.headers.set(HttpHeaders.acceptHeader, 'application/json');
      final gardenResp = await gardenReq.close();
      final gardenBody = await gardenResp.transform(utf8.decoder).join();
      if (gardenResp.statusCode == 200) {
        final decoded = jsonDecode(gardenBody) as Map<String, dynamic>;
        final data = decoded['garden'] is Map<String, dynamic>
            ? decoded['garden'] as Map<String, dynamic>
            : decoded['data'];
        if (data is Map<String, dynamic>) {
          final slots = data['grid'] is List ? data['grid'] as List : data['slots'] as List?;
          if (slots != null) {
            for (final s in slots) {
              if (s is Map) {
                final x = s['x'];
                final z = s['z'] ?? s['y'];
                final id = s['tileCatalogId'] ?? s['id'];
                final r = s['rotation'] ?? s['r'] ?? 0;
                final idx = _gardenGridSlots.indexWhere((g) => g['x'] == x && g['z'] == z);
                if (idx != -1) {
                  _gardenGridSlots[idx]['id'] = id;
                  _gardenGridSlots[idx]['r'] = r;
                }
              }
            }
          }
        }
      }

      client.close();
      notifyListeners();
    } catch (e) {
      debugPrint('[GameStateService] Sync backend failed: $e');
    }
  }

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

  /// Purchase an accessory with Urja Mudra coins (Persists locally & syncs to Fastify API)
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
    _sendBackendPost('/mascot/wardrobe/buy', {'itemId': itemId});
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
    _sendBackendPost('/mascot/wardrobe/equip', {'slot': slot, 'itemId': itemId});
    notifyListeners();
  }

  /// Equips a full outfit
  void equipOutfit(String outfitKey, Map<String, String?> slots) {
    _equippedOutfit = outfitKey;
    _equippedHead = slots['head'];
    _equippedFace = slots['face'];
    _equippedNeck = slots['neck'];
    _equippedHeld = slots['held'];
    _sendBackendPost('/mascot/outfits/equip', {'outfitId': outfitKey});
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

    _sendBackendPost('/garden/buy-and-place', {
      'tileCatalogId': tileId,
      'x': x,
      'y': z,
      'rotation': rotation,
    });

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

    _sendBackendPost('/garden/remove-to-inventory', {'x': x, 'y': z});
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

    _sendBackendPost('/garden/place-from-inventory', {
      'tileCatalogId': tileId,
      'x': x,
      'y': z,
      'rotation': rotation,
    });

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

  /// Sell tile from inventory or grid with 80% coin recovery
  bool sellGardenTile(String tileCatalogId) {
    final costs = <String, int>{
      'NEEM_TREE': 40,
      'TULSI_SHRINE': 30,
      'SOLAR_PUMP': 60,
      'DRIP_FEEDER': 25,
      'RAIN_CISTERN': 45,
      'COMPOST_TUMBLER': 35,
      'BEE_HOTEL': 30,
      'HERB_SPIRAL': 20,
      'TERRACOTTA_BENCH': 25,
      'STONE_PATH': 10,
    };
    final origCost = costs[tileCatalogId] ?? 30;
    final refund = (origCost * 0.8).round();

    if (_gardenInventory.contains(tileCatalogId)) {
      _gardenInventory.remove(tileCatalogId);
    } else {
      final idx = _gardenGridSlots.indexWhere((s) => s['id'] == tileCatalogId);
      if (idx != -1) {
        _gardenGridSlots[idx]['id'] = null;
        _gardenGridSlots[idx]['r'] = 0;
      } else {
        return false;
      }
    }

    addCoins(refund);
    addNotification(
      title: '💰 Garden Eco-Resale Completed',
      message: 'Recovered +$refund 🪙 Urja Mudra (80% resale value) for sustainable reuse!',
      type: 'garden_sale',
    );

    _sendBackendPost('/garden/sell', {'tileCatalogId': tileCatalogId});
    notifyListeners();
    return true;
  }

  void syncGardenGrid(List<dynamic> remoteSlots) {
    for (final s in remoteSlots) {
      if (s is Map) {
        final x = s['x'] as int?;
        final z = (s['z'] ?? s['y']) as int?;
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
