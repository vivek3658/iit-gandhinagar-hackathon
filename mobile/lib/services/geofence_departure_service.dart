import 'dart:async';
import 'dart:math';
import 'notification_service.dart';

class GeofenceDepartureService {
  static final GeofenceDepartureService instance = GeofenceDepartureService._();
  GeofenceDepartureService._();

  // Citizen registered home coordinates (Default: Navrangpura, Ahmedabad)
  double _homeLat = 23.0365;
  double _homeLng = 72.5611;
  String _homeAddress = 'Navrangpura, Ahmedabad, Gujarat';
  double _currentDistanceMeters = 45.0; // Currently inside home zone
  bool _isOutsideGeofence = false;
  bool _locationPermissionGranted = false;

  final double departureThresholdMeters = 300.0;

  double get homeLat => _homeLat;
  double get homeLng => _homeLng;
  String get homeAddress => _homeAddress;
  double get currentDistanceMeters => _currentDistanceMeters;
  bool get isOutsideGeofence => _isOutsideGeofence;
  bool get locationPermissionGranted => _locationPermissionGranted;

  Future<void> requestPermission() async {
    await NotificationService.instance.requestLocationPermission();
    _locationPermissionGranted = true;
  }

  void setHomeCoordinates(double lat, double lng, [String? address]) {
    _homeLat = lat;
    _homeLng = lng;
    if (address != null && address.isNotEmpty) {
      _homeAddress = address;
    }
  }

  /// Calculates geodesic distance using Haversine formula
  double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const r = 6371000.0; // Earth radius in meters
    final dLat = (lat2 - lat1) * (pi / 180.0);
    final dLon = (lon2 - lon1) * (pi / 180.0);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1 * (pi / 180.0)) *
            cos(lat2 * (pi / 180.0)) *
            sin(dLon / 2) *
            sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return r * c;
  }

  /// Updates user location and triggers notifications
  Future<void> updateLocation(double lat, double lng) async {
    _currentDistanceMeters = calculateDistance(_homeLat, _homeLng, lat, lng);
    if (_currentDistanceMeters >= 50 && _currentDistanceMeters <= departureThresholdMeters && !_isOutsideGeofence) {
      _isOutsideGeofence = true;
      await NotificationService.instance.triggerShortDepartureReminder(
        distance: _currentDistanceMeters,
      );
    } else if (_currentDistanceMeters > 1500) {
      await NotificationService.instance.triggerLongCommuteNotification(
        distanceKm: _currentDistanceMeters / 1000.0,
      );
    } else if (_currentDistanceMeters < 50) {
      _isOutsideGeofence = false;
    }
  }

  /// Simulates departing home (< 300m) to check appliances & switches
  Future<void> simulateShortDeparture([double distanceMeters = 180.0]) async {
    _currentDistanceMeters = distanceMeters;
    _isOutsideGeofence = true;
    await NotificationService.instance.triggerShortDepartureReminder(
      distance: distanceMeters,
    );
  }

  /// Simulates long commute travel (> 1.5 km) to log transit mode
  Future<void> simulateLongCommute([double distanceKm = 4.2]) async {
    _currentDistanceMeters = distanceKm * 1000.0;
    _isOutsideGeofence = true;
    await NotificationService.instance.triggerLongCommuteNotification(
      distanceKm: distanceKm,
    );
  }

  /// Simulates departing home (> 300m)
  Future<void> simulateDeparture([double distanceMeters = 350.0]) async {
    _currentDistanceMeters = distanceMeters;
    _isOutsideGeofence = true;
    await NotificationService.instance.triggerDepartureNotification(
      distance: distanceMeters,
    );
  }

  /// Simulates returning home (< 300m)
  void simulateReturn() {
    _currentDistanceMeters = 30.0;
    _isOutsideGeofence = false;
  }
}
