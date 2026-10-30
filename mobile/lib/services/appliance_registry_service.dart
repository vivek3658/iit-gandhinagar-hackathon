import 'dart:async';
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

/// Model representing a smart or traditional ("dumb") household electrical device
class ApplianceDevice {
  final String id;
  final String name;
  final String category; // 'ac', 'fridge', 'tv', 'washing_machine', 'fan', 'geyser', 'microwave'
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

/// Service managing household electrical devices, IoT recognition (BLE, Wi-Fi, IR),
/// event-driven delta updates (only dispatched on state change), and offline sync queuing.
class ApplianceRegistryService extends ChangeNotifier {
  static final ApplianceRegistryService instance =
      ApplianceRegistryService._internal();

  ApplianceRegistryService._internal() {
    _initDefaultAppliances();
  }

  bool _isOnline = true;
  bool _isScanningIot = false;
  final List<ApplianceDevice> _devices = [];
  final List<OfflineApplianceEvent> _offlineEventQueue = [];

  bool get isOnline => _isOnline;
  bool get isScanningIot => _isScanningIot;
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
        name: 'Master Bed Dual Inverter AC',
        category: 'ac',
        isSmart: true,
        techType: ApplianceTechType.wifiMdns,
        activePowerWatts: 1450.0,
        standbyPowerWatts: 18.0,
        state: ApplianceState.standby,
      ),
      ApplianceDevice(
        id: 'dev_fridge_1',
        name: 'Kitchen Frost-Free Refrigerator',
        category: 'fridge',
        isSmart: true,
        techType: ApplianceTechType.bleIot,
        activePowerWatts: 185.0,
        standbyPowerWatts: 8.0,
        state: ApplianceState.running,
      ),
      ApplianceDevice(
        id: 'dev_tv_1',
        name: 'Living Room 55" 4K Smart TV',
        category: 'tv',
        isSmart: true,
        techType: ApplianceTechType.wifiMdns,
        activePowerWatts: 110.0,
        standbyPowerWatts: 14.0,
        state: ApplianceState.standby,
      ),
      ApplianceDevice(
        id: 'dev_wm_1',
        name: 'EcoInverter Washing Machine',
        category: 'washing_machine',
        isSmart: true,
        techType: ApplianceTechType.bleIot,
        activePowerWatts: 450.0,
        standbyPowerWatts: 5.0,
        state: ApplianceState.off,
      ),
      ApplianceDevice(
        id: 'dev_fan_1',
        name: 'BLDC Smart Ceiling Fan',
        category: 'fan',
        isSmart: true,
        techType: ApplianceTechType.bleIot,
        activePowerWatts: 28.0,
        standbyPowerWatts: 1.5,
        state: ApplianceState.running,
      ),
      ApplianceDevice(
        id: 'dev_fan_dumb',
        name: 'Balcony Traditional Regulator Fan',
        category: 'fan',
        isSmart: false,
        techType: ApplianceTechType.manual,
        activePowerWatts: 75.0,
        standbyPowerWatts: 0.0,
        state: ApplianceState.off,
      ),
      ApplianceDevice(
        id: 'dev_geyser_1',
        name: 'Bathroom Storage Geyser (Smart Plug)',
        category: 'geyser',
        isSmart: false,
        techType: ApplianceTechType.smartPlug,
        activePowerWatts: 2000.0,
        standbyPowerWatts: 2.0,
        state: ApplianceState.off,
      ),
      ApplianceDevice(
        id: 'dev_microwave_1',
        name: 'Kitchen Convection Microwave',
        category: 'microwave',
        isSmart: false,
        techType: ApplianceTechType.irBlaster,
        activePowerWatts: 1200.0,
        standbyPowerWatts: 6.0,
        state: ApplianceState.standby,
      ),
    ]);
  }

  /// Toggles simulated network connectivity (online <-> offline)
  void setOnlineStatus(bool online) {
    if (_isOnline == online) return;
    _isOnline = online;
    if (_isOnline && _offlineEventQueue.isNotEmpty) {
      syncOfflineQueue();
    }
    notifyListeners();
  }

  /// Updates an appliance's operational state with delta-only dispatching
  bool updateDeviceState(String deviceId, ApplianceState newState) {
    final idx = _devices.indexWhere((d) => d.id == deviceId);
    if (idx == -1) return false;

    final device = _devices[idx];
    if (device.state == newState) {
      // Delta rule: Only dispatch or log if state has ACTUALLY changed!
      return false;
    }

    final oldState = device.state;
    device.state = newState;
    device.lastStateChange = DateTime.now();

    if (!_isOnline) {
      // Buffer event in offline queue
      _offlineEventQueue.add(
        OfflineApplianceEvent(
          deviceId: deviceId,
          oldState: oldState,
          newState: newState,
          timestamp: DateTime.now(),
        ),
      );
    } else {
      // Immediately dispatch state delta to server
      _dispatchStateDelta(device, oldState, newState);
    }

    notifyListeners();
    return true;
  }

  /// Flushes all queued offline events in batch when internet connection returns
  int syncOfflineQueue() {
    if (_offlineEventQueue.isEmpty) return 0;
    final count = _offlineEventQueue.length;
    // In production, sends batch POST /api/v1/appliances/events/batch
    _offlineEventQueue.clear();
    notifyListeners();
    return count;
  }

  void _dispatchStateDelta(
    ApplianceDevice device,
    ApplianceState oldState,
    ApplianceState newState,
  ) {
    // Delta dispatched to backend API
  }

  /// Discovers nearby IoT appliances via Wi-Fi/mDNS and BLE scan
  Future<int> scanNearbyIotDevices() async {
    _isScanningIot = true;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 1400));
    _isScanningIot = false;
    notifyListeners();
    return _devices.where((d) => d.isSmart).length;
  }
}
