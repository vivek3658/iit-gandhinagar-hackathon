import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'api_client.dart';
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
    final auth = AuthService.instance;
    _storageUserKey = _identityKey(auth);
    _loadFromLocalStorage();
    auth.addListener(_onAuthChanged);

    NotificationService.instance.onChargerDisconnected.listen((_) {
      if (_enableChargerReminder) {
        addCoins(5);
        addNotification(
          title: '🔌 Charger Pin Removed!',
          message:
              'Nice job disconnecting! Ensure wall switch is OFF to stop standby vampire drain.',
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
        message:
            'Wall switches confirmed off upon leaving home. Saved ~1.20 kg CO₂e from idle phantom load!',
        type: 'departure_verified',
      );
    });

    // Asynchronously synchronize with remote Fastify backend if online
    if (auth.accessToken != null) unawaited(syncWithBackend());
  }

  String _storageUserKey = 'signed-out';

  String _identityKey(AuthService auth) {
    if (auth.isGuestMode) return 'guest';
    return auth.currentUser?.id ?? 'signed-out';
  }

  void _onAuthChanged() {
    final auth = AuthService.instance;
    final nextKey = _identityKey(auth);
    if (nextKey == _storageUserKey) return;

    _storageUserKey = nextKey;
    _resetAccountState();
    _loadFromLocalStorage();
    notifyListeners();
    if (auth.accessToken != null && !auth.isGuestMode) {
      unawaited(syncWithBackend());
    }
  }

  void _resetAccountState() {
    _mascotLevel = 1;
    _co2eSavedKg = 0;
    _coins = 250;
    _vitality = 0.85;
    _activeWeatherFx = 'rain';
    _isSleeping = false;
    _electricityProvider = 'Torrent Power (Gujarat)';
    _hasSolar = true;
    _solarCapacityKw = 3.2;
    _hasBatteryStorage = false;
    _enableChargerReminder = true;
    _enableSleepReminder = true;
    _sleepTime = const TimeOfDay(hour: 22, minute: 30);
    _mascotBehaviorTone = 'Zen Guardian';
    _soundEnabled = true;
    _enableNightDimming = true;
    _idleTimeoutSeconds = 120;
    _ownedItems
      ..clear()
      ..addAll({'acorn', 'readers', 'plaid', 'leaves'});
    _equippedHead = null;
    _equippedFace = null;
    _equippedNeck = null;
    _equippedHeld = null;
    _equippedFx = null;
    _equippedOutfit = 'natural';
    for (final slot in _gardenGridSlots) {
      slot['id'] = null;
      slot['r'] = 0;
    }
    _gardenGridSlots[4]['id'] = 'SPARROW_HOME';
    _gardenInventory.clear();
    _gardenScrollLocked = true;
    _targetReductionPercent = 15;
    _notificationHistory.clear();
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
  double _solarCapacityKw =
      3.2; // PM Surya Ghar Muft Bijli Yojana rooftop installation
  bool _hasBatteryStorage = false;

  // --- Behavioral Settings ---
  bool _enableChargerReminder = true;
  bool _enableSleepReminder = true;
  TimeOfDay _sleepTime = const TimeOfDay(
    hour: 22,
    minute: 30,
  ); // 10:30 PM default
  String _mascotBehaviorTone =
      'Zen Guardian'; // 'Encouraging' | 'Coach' | 'Zen Guardian'
  bool _soundEnabled = true;
  bool _enableNightDimming = true;
  int _idleTimeoutSeconds = 120; // 2 minutes idle sleep

  // --- Wardrobe State ---
  final Set<String> _ownedItems = {'acorn', 'readers', 'plaid', 'leaves'};
  String? _equippedHead;
  String? _equippedFace;
  String? _equippedNeck;
  String? _equippedHeld;
  String? _equippedFx;
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
  final Map<String, Map<String, dynamic>> _gardenCatalogById = {};

  // --- Garden Stored Inventory (Items stored without selling) ---
  final List<String> _gardenInventory = [];
  bool _gardenScrollLocked =
      true; // Prevents accidental page scrolling when in garden

  // --- Personal electricity reduction goal ---
  double _targetReductionPercent = 15.0; // 15% reduction goal

  // --- Notification Center & Push History ---
  final List<Map<String, dynamic>> _notificationHistory = [
    {
      'id': 'notif_welcome',
      'title': '🕊️ Welcome to URJA ONE',
      'message':
          'Your Level 1 Sparrow Sanctuary companion has hatched! Tap him to pet.',
      'type': 'system',
      'timestamp': DateTime.now().subtract(const Duration(hours: 2)),
      'read': true,
    },
    {
      'id': 'notif_charger',
      'title': '🔌 Charger Unplug Reminder Active',
      'message':
          'Turn off the wall socket whenever your phone is disconnected.',
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
  String? get equippedFx => _equippedFx;
  String? get equippedOutfit => _equippedOutfit;

  List<Map<String, dynamic>> get gardenGridSlots =>
      List.unmodifiable(_gardenGridSlots);
  List<String> get gardenInventory => List.unmodifiable(_gardenInventory);
  int gardenPrice(String tileId, int fallback) =>
      (_gardenCatalogById[tileId]?['cost'] as num?)?.toInt() ?? fallback;
  int gardenRequiredLevel(String tileId) =>
      (_gardenCatalogById[tileId]?['requiredLevel'] as num?)?.toInt() ?? 1;
  bool get hasRemoteGardenCatalog => _gardenCatalogById.isNotEmpty;
  bool get gardenScrollLocked => _gardenScrollLocked;
  double get targetReductionPercent => _targetReductionPercent;
  List<Map<String, dynamic>> get notificationHistory =>
      List.unmodifiable(_notificationHistory);

  // ==========================================
  // LOCAL PERSISTENCE SYSTEM (Never resets on refresh)
  // ==========================================
  File _getStorageFile() {
    final userKey = _storageUserKey.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
    try {
      final dir = Directory('/data/user/0/com.geda.urjavatika.urja/files');
      if (!dir.existsSync()) {
        dir.createSync(recursive: true);
      }
      return File('${dir.path}/urja_game_state_$userKey.json');
    } catch (_) {}
    try {
      final dir2 = Directory('/data/data/com.geda.urjavatika.urja/files');
      if (!dir2.existsSync()) {
        dir2.createSync(recursive: true);
      }
      return File('${dir2.path}/urja_game_state_$userKey.json');
    } catch (_) {}
    try {
      return File('${Directory.systemTemp.path}/urja_game_state_$userKey.json');
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

      if (json['coins'] is num) {
        _coins = (json['coins'] as num).toInt();
      }
      if (json['vitality'] is num) {
        _vitality = (json['vitality'] as num).toDouble().clamp(0.0, 1.0);
      }
      if (json['mascotLevel'] is num) {
        _mascotLevel = (json['mascotLevel'] as num).toInt();
      }
      if (json['co2eSavedKg'] is num) {
        _co2eSavedKg = (json['co2eSavedKg'] as num).toDouble();
      }
      if (json['ownedItems'] is List) {
        for (final item in json['ownedItems'] as List) {
          _ownedItems.add(item.toString());
        }
      }
      _equippedHead = json['equippedHead'] as String?;
      _equippedFace = json['equippedFace'] as String?;
      _equippedNeck = json['equippedNeck'] as String?;
      _equippedHeld = json['equippedHeld'] as String?;
      _equippedFx = json['equippedFx'] as String?;
      _equippedOutfit = json['equippedOutfit'] as String? ?? _equippedOutfit;

      if (json['gardenGridSlots'] is List) {
        final list = json['gardenGridSlots'] as List;
        for (final s in list) {
          if (s is Map) {
            final x = s['x'];
            final z = s['z'];
            final id = s['id'] as String?;
            final r = s['r'] as int? ?? 0;
            final idx = _gardenGridSlots.indexWhere(
              (g) => g['x'] == x && g['z'] == z,
            );
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
      if (AuthService.instance.currentUser == null) return;
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
        'equippedFx': _equippedFx,
        'equippedOutfit': _equippedOutfit,
        'gardenGridSlots': _gardenGridSlots,
        'gardenInventory': _gardenInventory,
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
  Future<void> _sendBackendPost(
    String endpoint,
    Map<String, dynamic> data,
  ) async {
    final token = AuthService.instance.accessToken;
    if (token == null || token.isEmpty) return;
    try {
      final response = await ApiClient.instance.post(endpoint, body: data);
      debugPrint(
        '[GameStateService] Backend POST $endpoint -> ${response.statusCode}',
      );
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw HttpException(
          'Backend POST $endpoint failed (${response.statusCode}): ${response.body}',
        );
      }
    } catch (e) {
      debugPrint('[GameStateService] Backend POST $endpoint error: $e');
    }
  }

  Future<void> syncWithBackend() async {
    final auth = AuthService.instance;
    final token = auth.accessToken;
    final accountKey = _storageUserKey;
    if (token == null || token.isEmpty) return;
    try {
      // 1. Fetch remote Mascot State
      final mascotResp = await ApiClient.instance.get('/mascot/state');
      if (_storageUserKey != accountKey) return;
      if (mascotResp.statusCode < 200 || mascotResp.statusCode >= 300) {
        throw HttpException(
          'Could not sync mascot state (${mascotResp.statusCode}): ${mascotResp.body}',
        );
      }
      if (mascotResp.statusCode == 200) {
        final decoded = mascotResp.decodeJson();
        final data = decoded['data'] is Map<String, dynamic>
            ? decoded['data'] as Map<String, dynamic>
            : decoded;
        if (data['vitality'] is num) {
          final v = (data['vitality'] as num).toDouble();
          _vitality = (v > 1 ? v / 100 : v).clamp(0.0, 1.0);
        }
        if (data['level'] is num) {
          _mascotLevel = (data['level'] as num).toInt();
        }
        if (data['co2eSavedKg'] is num) {
          _co2eSavedKg = (data['co2eSavedKg'] as num).toDouble();
        }
        if (data['ownedAccessories'] is List) {
          for (final item in data['ownedAccessories'] as List) {
            if (item is String) _ownedItems.add(item);
          }
        }
        final equipped = data['equipped'];
        if (equipped is Map) {
          _equippedHead = equipped['head'] as String?;
          _equippedFace = equipped['face'] as String?;
          _equippedNeck = equipped['neck'] as String?;
          _equippedHeld = equipped['held'] as String?;
          _equippedFx = equipped['fx'] as String?;
          _equippedOutfit = null;
        }
      }

      // 2. Fetch remote Wardrobe
      final wardrobeResp = await ApiClient.instance.get('/mascot/wardrobe');
      if (_storageUserKey != accountKey) return;
      if (wardrobeResp.statusCode < 200 || wardrobeResp.statusCode >= 300) {
        throw HttpException(
          'Could not sync wardrobe (${wardrobeResp.statusCode}): ${wardrobeResp.body}',
        );
      }
      if (wardrobeResp.statusCode == 200) {
        final decoded = wardrobeResp.decodeJson();
        final data = decoded['data'] is Map<String, dynamic>
            ? decoded['data'] as Map<String, dynamic>
            : decoded;
        final items = data['items'];
        if (items is List) {
          for (final item in items) {
            if (item is Map &&
                item['isOwned'] == true &&
                item['id'] is String) {
              _ownedItems.add(item['id'] as String);
            }
          }
        }
      }

      // 3. Fetch remote Garden Sanctuary
      final gardenResp = await ApiClient.instance.get('/garden');
      if (_storageUserKey != accountKey) return;
      if (gardenResp.statusCode < 200 || gardenResp.statusCode >= 300) {
        throw HttpException(
          'Could not sync garden (${gardenResp.statusCode}): ${gardenResp.body}',
        );
      }
      if (gardenResp.statusCode == 200) {
        final decoded = gardenResp.decodeJson();
        final data = decoded['data'] is Map<String, dynamic>
            ? decoded['data'] as Map<String, dynamic>
            : decoded;
        if (data['citizenCoins'] is num) {
          _coins = (data['citizenCoins'] as num).toInt();
        }
        _gardenCatalogById
          ..clear()
          ..addEntries(
            (data['catalog'] as List? ?? const [])
                .whereType<Map>()
                .where((item) => item['id'] is String)
                .map(
                  (item) => MapEntry(
                    item['id'] as String,
                    Map<String, dynamic>.from(item),
                  ),
                ),
          );
        for (final slot in _gardenGridSlots) {
          slot['id'] = slot['x'] == 0 && slot['z'] == 0 ? 'SPARROW_HOME' : null;
          slot['r'] = 0;
        }
        for (final tile in data['placedTiles'] as List? ?? const []) {
          if (tile is! Map) continue;
          final remoteX = (tile['x'] as num?)?.toInt();
          final remoteY = (tile['y'] as num?)?.toInt();
          if (remoteX == null || remoteY == null) continue;
          final idx = _gardenGridSlots.indexWhere(
            (slot) => slot['x'] == remoteX - 1 && slot['z'] == remoteY - 1,
          );
          if (idx == -1) continue;
          _gardenGridSlots[idx]['id'] = tile['tileId'] as String?;
          _gardenGridSlots[idx]['r'] =
              ((tile['rotation'] as num?)?.toInt() ?? 0) ~/ 90;
        }
      }

      if (_storageUserKey != accountKey) return;
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
      message:
          'Earned +$coinsAwarded 🪙 Urja Mudra and prevented +${co2Saved.toStringAsFixed(2)} kg CO2e.',
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
    _sendBackendPost('/mascot/wardrobe/buy', {'accessoryId': itemId});
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
      case 'fx':
        _equippedFx = itemId;
        break;
    }
    _equippedOutfit = null;
    _sendBackendPost('/mascot/wardrobe/equip', {
      'slot': slot.toUpperCase(),
      'accessoryId': itemId,
    });
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
  Future<bool> buyAndPlaceGardenTile({
    required int x,
    required int z,
    required String tileId,
    required int cost,
    int rotation = 0,
  }) async {
    final idx = _gardenGridSlots.indexWhere((s) => s['x'] == x && s['z'] == z);
    if (idx == -1) return false;
    if (_gardenGridSlots[idx]['id'] != null) return false; // Already occupied
    if (_coins < cost) return false;

    final token = AuthService.instance.accessToken;
    var remainingCoins = _coins - cost;
    if (token != null && token.isNotEmpty) {
      final response = await ApiClient.instance.post(
        '/garden/buy-and-place',
        body: {
          'tileId': tileId,
          'x': x + 1,
          'y': z + 1,
          'rotation': rotation * 90,
        },
      );
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw HttpException(
          'Garden purchase failed (${response.statusCode}): ${response.body}',
        );
      }
      final result = response.decodeJson();
      if (result['success'] != true || result['remainingCoins'] is! num) {
        throw const FormatException(
          'Garden purchase returned an invalid response.',
        );
      }
      remainingCoins = (result['remainingCoins'] as num).toInt();
    }

    _coins = remainingCoins;
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
    final fromIdx = _gardenGridSlots.indexWhere(
      (s) => s['x'] == fromX && s['z'] == fromZ,
    );
    final toIdx = _gardenGridSlots.indexWhere(
      (s) => s['x'] == toX && s['z'] == toZ,
    );
    if (fromIdx == -1 || toIdx == -1) return false;
    if (_gardenGridSlots[fromIdx]['id'] == null) return false;
    if (_gardenGridSlots[toIdx]['id'] != null) {
      return false; // Destination must be empty
    }

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
    if (idx == -1 || _gardenGridSlots[idx]['id'] != null) {
      return false; // Must be empty
    }

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
      message:
          'Recovered +$refund 🪙 Urja Mudra (80% resale value) for sustainable reuse!',
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
        final idx = _gardenGridSlots.indexWhere(
          (g) => g['x'] == x && g['z'] == z,
        );
        if (idx != -1) {
          _gardenGridSlots[idx]['id'] = id;
          _gardenGridSlots[idx]['r'] = r;
        }
      }
    }
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
