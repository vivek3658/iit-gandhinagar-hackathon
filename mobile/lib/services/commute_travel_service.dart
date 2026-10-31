import 'package:flutter/foundation.dart';
import 'package:urja/services/game_state_service.dart';

/// Vehicle engine and fuel category
enum VehicleType {
  bicycle,
  ev2w,
  petrol2w,
  ev4w,
  petrol4w,
  diesel4w,
}

/// Personal vehicle record in user's garage
class RegisteredVehicle {
  final String id;
  final String name;
  final VehicleType type;
  final String efficiencyText; // e.g. "45 km/L" or "4.2 km/kWh"
  bool isDefault;

  RegisteredVehicle({
    required this.id,
    required this.name,
    required this.type,
    required this.efficiencyText,
    this.isDefault = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'type': type.name,
        'efficiencyText': efficiencyText,
        'isDefault': isDefault,
      };
}

/// Commute transport modes for claiming Mission LiFE mobility rewards
enum CommuteMode {
  walk,
  bicycle,
  publicTransit, // Metro, GSRTC, AMTS, Local Train
  ev,
  petrolVehicle,
}

/// Commute trip record
class CommuteTripRecord {
  final String id;
  final double distanceKm;
  final CommuteMode mode;
  final String? vehicleName;
  final int coinsEarned;
  final double co2eSavedKg;
  final DateTime timestamp;

  CommuteTripRecord({
    required this.id,
    required this.distanceKm,
    required this.mode,
    this.vehicleName,
    required this.coinsEarned,
    required this.co2eSavedKg,
    required this.timestamp,
  });
}

/// Service managing home geofencing, trip displacement detection,
/// multi-vehicle garage, and travel commute rewards.
class CommuteTravelService extends ChangeNotifier {
  static final CommuteTravelService instance = CommuteTravelService._internal();

  CommuteTravelService._internal() {
    _initDefaultGarage();
  }

  // Home location in Gujarat
  double _homeLat = 23.0300;
  double _homeLng = 72.5800;
  String _homeAddress = 'Navrangpura, Ahmedabad, Gujarat';

  // Current simulated location
  final double _currentLat = 23.0540;
  final double _currentLng = 72.5920;

  final List<RegisteredVehicle> _vehicles = [];
  final List<CommuteTripRecord> _tripHistory = [];

  double get homeLat => _homeLat;
  double get homeLng => _homeLng;
  String get homeAddress => _homeAddress;
  double get currentLat => _currentLat;
  double get currentLng => _currentLng;
  List<RegisteredVehicle> get vehicles => List.unmodifiable(_vehicles);
  List<CommuteTripRecord> get tripHistory => List.unmodifiable(_tripHistory);

  void _initDefaultGarage() {
    _vehicles.addAll([
      RegisteredVehicle(
        id: 'veh_ev_scooter',
        name: 'Ather 450X Gen 3',
        type: VehicleType.ev2w,
        efficiencyText: '3.6 km/kWh (Zero Tailpipe)',
        isDefault: true,
      ),
      RegisteredVehicle(
        id: 'veh_petrol_scooter',
        name: 'Honda Activa 6G',
        type: VehicleType.petrol2w,
        efficiencyText: '48 km/L (BS6 Petrol)',
        isDefault: false,
      ),
      RegisteredVehicle(
        id: 'veh_bicycle',
        name: 'Firefox Target 21S',
        type: VehicleType.bicycle,
        efficiencyText: '100% Muscle Power',
        isDefault: false,
      ),
    ]);
  }

  /// Sets user's registered home location coordinates and address
  void setHomeLocation(double lat, double lng, String address) {
    _homeLat = lat;
    _homeLng = lng;
    _homeAddress = address;
    notifyListeners();
  }

  /// Adds a new vehicle to user's garage
  void addVehicle({
    required String name,
    required VehicleType type,
    required String efficiencyText,
    bool isDefault = false,
  }) {
    if (isDefault) {
      for (final v in _vehicles) {
        v.isDefault = false;
      }
    }
    _vehicles.add(
      RegisteredVehicle(
        id: 'veh_${DateTime.now().millisecondsSinceEpoch}',
        name: name,
        type: type,
        efficiencyText: efficiencyText,
        isDefault: isDefault || _vehicles.isEmpty,
      ),
    );
    notifyListeners();
  }

  /// Calculates straight-line distance displacement in km from home
  double get displacementFromHomeKm {
    final dLat = (_currentLat - _homeLat) * 111.0;
    final dLng = (_currentLng - _homeLng) * 102.0;
    return (dLat * dLat + dLng * dLng) > 0
        ? (dLat * dLat + dLng * dLng) / 10.0 + 1.8
        : 0.0;
  }

  /// Validates whether a trip distance is physically eligible for the chosen mode
  String? validateTripMode(CommuteMode mode, double distanceKm) {
    if (mode == CommuteMode.walk && distanceKm > 3.0) {
      return 'Walking limit is 3.0 km. Trips over 3 km should be logged via Bicycle, Public Transit, or Registered Vehicle!';
    }
    return null;
  }

  /// Logs a commute trip and calculates coins and avoided CO2e
  bool logCommuteTrip({
    required double distanceKm,
    required CommuteMode mode,
    String? vehicleName,
  }) {
    final validationErr = validateTripMode(mode, distanceKm);
    if (validationErr != null) return false;

    int coinsPerKm = 0;
    double co2eSavedKgPerKm = 0.0;

    switch (mode) {
      case CommuteMode.walk:
        coinsPerKm = 50; // Most reward for zero-emission active walking
        co2eSavedKgPerKm = 0.140; // 140g CO2e avoided vs petrol car
        break;
      case CommuteMode.bicycle:
        coinsPerKm = 40;
        co2eSavedKgPerKm = 0.140;
        break;
      case CommuteMode.publicTransit:
        coinsPerKm = 30; // High reward for bus / metro mass transit
        co2eSavedKgPerKm = 0.085;
        break;
      case CommuteMode.ev:
        coinsPerKm = 15; // Moderate reward for electric mobility
        co2eSavedKgPerKm = 0.060;
        break;
      case CommuteMode.petrolVehicle:
        coinsPerKm = 0; // 0 coins for petrol/diesel ICE
        co2eSavedKgPerKm = 0.0;
        break;
    }

    final totalCoins = (distanceKm * coinsPerKm).round();
    final totalCo2e = distanceKm * co2eSavedKgPerKm;

    final trip = CommuteTripRecord(
      id: 'trip_${DateTime.now().millisecondsSinceEpoch}',
      distanceKm: distanceKm,
      mode: mode,
      vehicleName: vehicleName,
      coinsEarned: totalCoins,
      co2eSavedKg: totalCo2e,
      timestamp: DateTime.now(),
    );

    _tripHistory.insert(0, trip);

    // Credit coins and avoided carbon to GameStateService
    if (totalCoins > 0) {
      GameStateService.instance.addCoins(totalCoins);
    }
    if (totalCo2e > 0) {
      GameStateService.instance.recordCo2eSaved(totalCo2e);
    }

    notifyListeners();
    return true;
  }
}
