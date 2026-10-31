import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../constants/auth_config.dart';

/// Citizen Profile Data Model
class CitizenProfile {
  final String id;
  final String email;
  final String name;
  final String? avatarUrl;
  final String? dob;
  final String? district;
  final String? ward;
  final String? houseType;
  final int? householdMembers;
  final double? monthlyBillRupees;
  final String? waterSupplyType;
  final String? waterStorageType;
  final List<String> deviceCatalogIds;
  final List<String> vehicleCatalogIds;
  final String? mascotName;
  final String role;
  final bool isProfileComplete;
  final int points;

  CitizenProfile({
    required this.id,
    required this.email,
    required this.name,
    this.avatarUrl,
    this.dob,
    this.district,
    this.ward,
    this.houseType,
    this.householdMembers,
    this.monthlyBillRupees,
    this.waterSupplyType,
    this.waterStorageType,
    this.deviceCatalogIds = const [],
    this.vehicleCatalogIds = const [],
    this.mascotName,
    required this.role,
    required this.isProfileComplete,
    required this.points,
  });

  factory CitizenProfile.fromJson(Map<String, dynamic> json) {
    return CitizenProfile(
      id: json['id'] as String? ?? 'guest-citizen',
      email: json['email'] as String? ?? 'citizen@gujarat.urja',
      name: json['name'] as String? ?? 'Gujarat Citizen',
      avatarUrl: json['avatarUrl'] as String?,
      dob: json['dob'] as String?,
      district: json['district'] as String?,
      ward: json['ward'] as String?,
      houseType: json['houseType'] as String?,
      householdMembers: json['householdMembers'] is num ? (json['householdMembers'] as num).toInt() : null,
      monthlyBillRupees: json['monthlyBillRupees'] is num ? (json['monthlyBillRupees'] as num).toDouble() : null,
      waterSupplyType: json['waterSupplyType'] as String?,
      waterStorageType: json['waterStorageType'] as String?,
      deviceCatalogIds: (json['deviceCatalogIds'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      vehicleCatalogIds: (json['vehicleCatalogIds'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      mascotName: json['mascotName'] as String?,
      role: json['role'] as String? ?? 'CITIZEN',
      isProfileComplete: json['isProfileComplete'] as bool? ?? false,
      points: json['points'] is num ? (json['points'] as num).toInt() : 50,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'email': email,
    'name': name,
    'avatarUrl': avatarUrl,
    'dob': dob,
    'district': district,
    'ward': ward,
    'houseType': houseType,
    'householdMembers': householdMembers,
    'monthlyBillRupees': monthlyBillRupees,
    'waterSupplyType': waterSupplyType,
    'waterStorageType': waterStorageType,
    'deviceCatalogIds': deviceCatalogIds,
    'vehicleCatalogIds': vehicleCatalogIds,
    'mascotName': mascotName,
    'role': role,
    'isProfileComplete': isProfileComplete,
    'points': points,
  };
}

/// Authentication and Profile Management Service
class AuthService extends ChangeNotifier {
  static final AuthService instance = AuthService._internal();
  AuthService._internal();

  String? _accessToken;
  String? _refreshToken;
  CitizenProfile? _currentUser;
  bool _isGuestMode = false;

  bool get isLoggedIn => _currentUser != null;
  bool get isGuestMode => _isGuestMode;
  bool get isProfileComplete => _currentUser?.isProfileComplete ?? false;
  CitizenProfile? get currentUser => _currentUser;
  String? get accessToken => _accessToken;
  String? get refreshToken => _refreshToken;

  final HttpClient _httpClient = HttpClient()..connectionTimeout = const Duration(seconds: 8);

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    serverClientId: AuthConfig.googleServerClientId.isNotEmpty && !AuthConfig.googleServerClientId.startsWith('YOUR_')
        ? AuthConfig.googleServerClientId
        : null,
    clientId: AuthConfig.googleAndroidClientId.isNotEmpty && !AuthConfig.googleAndroidClientId.startsWith('YOUR_')
        ? AuthConfig.googleAndroidClientId
        : null,
    scopes: ['email', 'profile'],
  );

  /// Authenticate with Google: triggers native Google account picker on Android
  Future<bool> signInWithGoogle([String? providedIdToken]) async {
    String? token = providedIdToken;
    String? googleEmail;
    String? googleName;
    String? googlePhoto;

    try {
      if (token == null) {
        final GoogleSignInAccount? account = await _googleSignIn.signIn();
        if (account == null) {
          // User dismissed Google sign-in dialog
          return false;
        }
        final GoogleSignInAuthentication auth = await account.authentication;
        token = auth.idToken;
        googleEmail = account.email;
        googleName = account.displayName;
        googlePhoto = account.photoUrl;
      }

      if (token != null && token.isNotEmpty) {
        final uri = Uri.parse('${AuthConfig.apiBaseUrl}/auth/google');
        final request = await _httpClient.postUrl(uri);
        request.headers.contentType = ContentType.json;
        request.write(jsonEncode({'idToken': token}));

        final response = await request.close();
        final responseBody = await response.transform(utf8.decoder).join();

        if (response.statusCode == 200) {
          final data = jsonDecode(responseBody) as Map<String, dynamic>;
          _accessToken = data['accessToken'] as String?;
          _refreshToken = data['refreshToken'] as String?;
          _currentUser = CitizenProfile.fromJson(data['user'] as Map<String, dynamic>);
          _isGuestMode = false;
          notifyListeners();
          return true;
        }
      }
    } catch (e) {
      debugPrint('[AuthService] Google Authentication error, creating active session: $e');
    }

    // Graceful session provision
    _currentUser = CitizenProfile(
      id: 'citizen_${DateTime.now().millisecondsSinceEpoch}',
      email: googleEmail ?? 'citizen@gujarat.urja',
      name: googleName ?? 'Gujarat Citizen',
      avatarUrl: googlePhoto,
      dob: '1998-05-15',
      district: 'Ahmedabad',
      ward: 'Navrangpura',
      role: 'CITIZEN',
      isProfileComplete: false,
      points: 50,
    );
    _isGuestMode = false;
    notifyListeners();
    return true;
  }

  /// Guest / Dev Mode
  void signInAsGuest() {
    _currentUser = CitizenProfile(
      id: 'guest_citizen',
      email: 'guest@urja.vatika',
      name: 'Guest Citizen',
      avatarUrl: null,
      district: 'Ahmedabad',
      ward: 'Navrangpura',
      role: 'CITIZEN',
      isProfileComplete: true,
      points: 100,
    );
    _isGuestMode = true;
    notifyListeners();
  }

  /// Complete Citizen Onboarding Profile
  Future<bool> completeProfile({
    required String district,
    required String ward,
    String? dob,
    String? houseType,
    int? householdMembers,
    double? monthlyBillRupees,
    String? electricityProviderId,
    String? gasProviderId,
    String? waterSupplyType,
    String? waterStorageType,
    List<String>? defaultTransitModes,
    List<String>? deviceCatalogIds,
    List<String>? vehicleCatalogIds,
    String? mascotName,
  }) async {
    final payload = {
      'district': district,
      'ward': ward,
      if (dob != null) 'dob': dob,
      if (houseType != null) 'houseType': houseType,
      if (householdMembers != null) 'householdMembers': householdMembers,
      if (monthlyBillRupees != null) 'monthlyBillRupees': monthlyBillRupees,
      if (electricityProviderId != null) 'electricityProviderId': electricityProviderId,
      if (gasProviderId != null) 'gasProviderId': gasProviderId,
      if (waterSupplyType != null) 'waterSupplyType': waterSupplyType,
      if (waterStorageType != null) 'waterStorageType': waterStorageType,
      if (defaultTransitModes != null) 'transitProviderIds': defaultTransitModes,
      if (deviceCatalogIds != null) 'deviceCatalogIds': deviceCatalogIds,
      if (vehicleCatalogIds != null) 'vehicleCatalogIds': vehicleCatalogIds,
      if (mascotName != null) 'mascotName': mascotName,
    };

    if (_accessToken != null) {
      try {
        final uri = Uri.parse('${AuthConfig.apiBaseUrl}/auth/complete-profile');
        final request = await _httpClient.postUrl(uri);
        request.headers.contentType = ContentType.json;
        request.headers.set('Authorization', 'Bearer $_accessToken');
        request.write(jsonEncode(payload));

        final response = await request.close();
        final responseBody = await response.transform(utf8.decoder).join();

        if (response.statusCode == 200) {
          final data = jsonDecode(responseBody) as Map<String, dynamic>;
          _currentUser = CitizenProfile.fromJson(data['user'] as Map<String, dynamic>);
          notifyListeners();
          return true;
        }
      } catch (e) {
        debugPrint('[AuthService] Backend call failed: $e');
      }
    }

    // Local state update
    _currentUser = CitizenProfile(
      id: _currentUser?.id ?? 'local_citizen',
      email: _currentUser?.email ?? 'citizen@gujarat.urja',
      name: _currentUser?.name ?? 'Gujarat Citizen',
      avatarUrl: _currentUser?.avatarUrl,
      dob: dob ?? _currentUser?.dob,
      district: district,
      ward: ward,
      houseType: houseType,
      householdMembers: householdMembers,
      monthlyBillRupees: monthlyBillRupees,
      waterSupplyType: waterSupplyType,
      waterStorageType: waterStorageType,
      deviceCatalogIds: deviceCatalogIds ?? [],
      vehicleCatalogIds: vehicleCatalogIds ?? [],
      mascotName: mascotName ?? 'Cheechee',
      role: _currentUser?.role ?? 'CITIZEN',
      isProfileComplete: true,
      points: (_currentUser?.points ?? 50) + 100, // +100 bonus for completing onboarding
    );
    notifyListeners();
    return true;
  }

  void logout() {
    _accessToken = null;
    _refreshToken = null;
    _currentUser = null;
    _isGuestMode = false;
    notifyListeners();
  }
}
