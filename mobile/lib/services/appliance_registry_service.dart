import 'package:flutter/foundation.dart';

/// Appliance communication and IoT technology type
enum ApplianceTechType {
  wifiMdns,
  bleIot,
  irBlaster,
  smartPlug,
  manual,
}

/// Operational state of an electrical appliance
enum ApplianceState {
  running,
  standby,
  off,
}

/// Model representing a smart household electrical device with inbuilt WiFi / BLE
class ApplianceDevice {
  final String id;
  final String name;
  final String category; // 'ac', 'fridge', 'tv', 'geyser'
  final bool isSmart;
  final ApplianceTechType techType;
  final double activePowerWatts;
  final double standbyPowerWatts;
  ApplianceState state;
  DateTime lastStateChange;

  ApplianceDevice({
    required this.id,
    required this.name,
    required this.category,
    required this.isSmart,
    required this.techType,
    required this.activePowerWatts,
    required this.standbyPowerWatts,
    required this.state,
    DateTime? lastStateChange,
  }) : lastStateChange = lastStateChange ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'category': category,
        'isSmart': isSmart,
        'techType': techType.name,
        'activePowerWatts': activePowerWatts,
        'standbyPowerWatts': standbyPowerWatts,
        'state': state.name,
        'lastStateChange': lastStateChange.toIso8601String(),
      };
}

/// Record of an appliance state change queued during offline mode
class OfflineApplianceEvent {
  final String deviceId;
  final ApplianceState oldState;
  final ApplianceState newState;
  final DateTime timestamp;

  OfflineApplianceEvent({
    required this.deviceId,
    required this.oldState,
    required this.newState,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        'deviceId': deviceId,
        'oldState': oldState.name,
        'newState': newState.name,
        'timestamp': timestamp.toIso8601String(),
      };
}

/// Service managing smart appliances with inbuilt WiFi / BLE
class ApplianceRegistryService extends ChangeNotifier {
  static final ApplianceRegistryService instance =
      ApplianceRegistryService._internal();

  ApplianceRegistryService._internal() {
    _initDefaultAppliances();
  }

  bool _isOnline = true;
  final List<ApplianceDevice> _devices = [];
  final List<OfflineApplianceEvent> _offlineEventQueue = [];

  bool get isOnline => _isOnline;
  List<ApplianceDevice> get devices => List.unmodifiable(_devices);
  List<OfflineApplianceEvent> get offlineEventQueue =>
      List.unmodifiable(_offlineEventQueue);

  double get totalActivePowerWatts => _devices
      .where((d) => d.state == ApplianceState.running)
      .fold(0.0, (sum, d) => sum + d.activePowerWatts);

  double get totalStandbyVampireWatts => _devices
      .where((d) => d.state == ApplianceState.standby)
      .fold(0.0, (sum, d) => sum + d.standbyPowerWatts);

  void _initDefaultAppliances() {
    _devices.addAll([
      ApplianceDevice(
        id: 'dev_ac_1',
        name: 'Master Bed Smart Inverter AC',
        category: 'ac',
        isSmart: true,
        techType: ApplianceTechType.wifiMdns,
        activePowerWatts: 1450.0,
        standbyPowerWatts: 18.0,
        state: ApplianceState.standby,
      ),
      ApplianceDevice(
        id: 'dev_fridge_1',
        name: 'Kitchen Smart Refrigerator',
        category: 'fridge',
        isSmart: true,
        techType: ApplianceTechType.bleIot,
        activePowerWatts: 185.0,
        standbyPowerWatts: 8.0,
        state: ApplianceState.running,
      ),
      ApplianceDevice(
        id: 'dev_tv_1',
        name: 'Living Room 55" Smart Connected TV',
        category: 'tv',
        isSmart: true,
        techType: ApplianceTechType.wifiMdns,
        activePowerWatts: 110.0,
        standbyPowerWatts: 14.0,
        state: ApplianceState.standby,
      ),
      ApplianceDevice(
        id: 'dev_geyser_1',
        name: 'Bathroom Smart Water Geyser',
        category: 'geyser',
        isSmart: true,
        techType: ApplianceTechType.bleIot,
        activePowerWatts: 2000.0,
        standbyPowerWatts: 5.0,
        state: ApplianceState.off,
      ),
    ]);
  }

  /// Changes the state of a device
  void setDeviceState(String deviceId, ApplianceState newState) {
    final idx = _devices.indexWhere((d) => d.id == deviceId);
    if (idx == -1) return;

    final oldState = _devices[idx].state;
    if (oldState == newState) return;

    _devices[idx].state = newState;
    _devices[idx].lastStateChange = DateTime.now();

    if (!_isOnline) {
      _offlineEventQueue.add(
        OfflineApplianceEvent(
          deviceId: deviceId,
          oldState: oldState,
          newState: newState,
          timestamp: DateTime.now(),
        ),
      );
    }

    notifyListeners();
  }

  void toggleOnline(bool online) {
    _isOnline = online;
    if (_isOnline && _offlineEventQueue.isNotEmpty) {
      _offlineEventQueue.clear();
    }
    notifyListeners();
  }
}
