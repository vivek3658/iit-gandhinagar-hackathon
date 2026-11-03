import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../constants/auth_config.dart';
import 'api_client.dart';

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
      householdMembers: json['householdMembers'] is num
          ? (json['householdMembers'] as num).toInt()
          : null,
      monthlyBillRupees: json['monthlyBillRupees'] is num
          ? (json['monthlyBillRupees'] as num).toDouble()
          : null,
      waterSupplyType: json['waterSupplyType'] as String?,
      waterStorageType: json['waterStorageType'] as String?,
      deviceCatalogIds:
          (json['deviceCatalogIds'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      vehicleCatalogIds:
          (json['vehicleCatalogIds'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
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
  AuthService._internal() {
    ApiClient.instance.configure(
      accessTokenProvider: () => _accessToken,
      sessionRefresher: refreshSession,
    );
    _loadProfileFromStorage();
  }

  File _getAuthStorageFile() {
    try {
      final dir = Directory('/data/user/0/com.geda.urjavatika.urja/files');
      if (!dir.existsSync()) dir.createSync(recursive: true);
      return File('${dir.path}/urja_citizen_profile.json');
    } catch (_) {}
    try {
      final dir2 = Directory('/data/data/com.geda.urjavatika.urja/files');
      if (!dir2.existsSync()) dir2.createSync(recursive: true);
      return File('${dir2.path}/urja_citizen_profile.json');
    } catch (_) {}
    return File('${Directory.systemTemp.path}/urja_citizen_profile.json');
  }

  void _loadProfileFromStorage() {
    try {
      final file = _getAuthStorageFile();
      if (!file.existsSync()) return;
      final raw = file.readAsStringSync();
      if (raw.isEmpty) return;
      final data = jsonDecode(raw) as Map<String, dynamic>;
      _currentUser = CitizenProfile.fromJson(data);
      if (data['accessToken'] is String) {
        _accessToken = data['accessToken'] as String;
      }
      if (data['refreshToken'] is String) {
        _refreshToken = data['refreshToken'] as String;
      }
    } catch (e) {
      debugPrint('[AuthService] Error reading cached citizen profile: $e');
    }
  }

  void _saveProfileToStorage() {
    try {
      if (_currentUser == null || _isGuestMode) return;
      final file = _getAuthStorageFile();
      final data = _currentUser!.toJson();
      if (_accessToken != null) {
        data['accessToken'] = _accessToken;
      }
      if (_refreshToken != null) {
        data['refreshToken'] = _refreshToken;
      }
      file.writeAsStringSync(jsonEncode(data), flush: true);
    } catch (e) {
      debugPrint('[AuthService] Error writing citizen profile to disk: $e');
    }
  }

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

  final HttpClient _httpClient = HttpClient()
    ..connectionTimeout = const Duration(seconds: 8);

  String? _lastSignInError;
  String? get lastSignInError => _lastSignInError;
  String? get lastAuthError => _lastSignInError;

  Future<CitizenProfile> refreshProfile() async {
    if (_isGuestMode) {
      final guest = _currentUser;
      if (guest == null) throw StateError('No signed-in citizen profile.');
      return guest;
    }

    final response = await ApiClient.instance.get('/auth/me');
    if (response.statusCode != HttpStatus.ok) {
      throw HttpException(
        'Could not refresh your profile (${response.statusCode}).',
      );
    }
    final user = response.decodeJson()['user'];
    if (user is! Map<String, dynamic>) {
      throw const FormatException('Profile response is missing user data.');
    }
    _currentUser = CitizenProfile.fromJson(user);
    _saveProfileToStorage();
    notifyListeners();
    return _currentUser!;
  }

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId: AuthConfig.googleAndroidClientId.isNotEmpty
        ? AuthConfig.googleAndroidClientId
        : null,
    serverClientId:
        AuthConfig.googleServerClientId.isNotEmpty &&
            AuthConfig.googleServerClientId.endsWith(
              '.apps.googleusercontent.com',
            ) &&
            !AuthConfig.googleServerClientId.startsWith('YOUR_')
        ? AuthConfig.googleServerClientId
        : null,
    scopes: ['email', 'profile'],
  );

  /// Authenticate with Google: triggers native Google account picker on Android
  Future<bool> signInWithGoogle([String? providedIdToken]) async {
    _lastSignInError = null;
    String? token = providedIdToken;

    try {
      if (token == null) {
        GoogleSignInAccount? account;
        try {
          account = await _googleSignIn.signIn();
        } catch (pickErr) {
          debugPrint('[AuthService] Google account picker error: $pickErr');
        }

        if (account == null) {
          _lastSignInError = null;
          return false;
        }

        try {
          final GoogleSignInAuthentication auth = await account.authentication;
          token = auth.idToken;
        } catch (authErr) {
          _lastSignInError =
              'Google could not finish sign-in. Please check the account and app configuration.';
          debugPrint('[AuthService] Google token retrieval failed: $authErr');
        }

        if (token == null || token.isEmpty) {
          _lastSignInError ??=
              'Google did not return an ID token. Check the Android SHA-1 and Web OAuth client ID configuration.';
          return false;
        }
      }

      if (token.isEmpty) {
        _lastSignInError = 'Google did not return a valid sign-in token.';
        return false;
      }

      final uri = Uri.parse('${AuthConfig.apiBaseUrl}/auth/google');
      final request = await _httpClient
          .postUrl(uri)
          .timeout(const Duration(seconds: 15));
      request.headers.contentType = ContentType.json;
      request.write(jsonEncode({'idToken': token}));

      final response = await request.close().timeout(
        const Duration(seconds: 15),
      );
      final responseBody = await response
          .transform(utf8.decoder)
          .join()
          .timeout(const Duration(seconds: 15));

      if (response.statusCode != HttpStatus.ok) {
        _lastSignInError = _messageFromResponse(
          responseBody,
          'Sign-in failed. Please try again.',
        );
        debugPrint(
          '[AuthService] Google auth endpoint returned ${response.statusCode}: $_lastSignInError',
        );
        return false;
      }

      final data = jsonDecode(responseBody) as Map<String, dynamic>;
      final accessToken = data['accessToken'];
      final refreshToken = data['refreshToken'];
      final user = data['user'];
      if (accessToken is! String ||
          refreshToken is! String ||
          user is! Map<String, dynamic>) {
        throw const FormatException(
          'Authentication response is missing user or token data.',
        );
      }

      _accessToken = accessToken;
      _refreshToken = refreshToken;
      _currentUser = CitizenProfile.fromJson(user);
      _isGuestMode = false;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('[AuthService] Google Authentication error: $e');
      _lastSignInError = e is SocketException || e is HttpException
          ? 'Could not reach URJA. Check your internet connection and try again.'
          : e is TimeoutException
          ? 'Sign-in timed out. Please check your connection and try again.'
          : 'Google sign-in could not be completed. Please try again.';
      return false;
    }
  }

  String _messageFromResponse(String body, String fallback) {
    if (body.isEmpty) return fallback;
    try {
      final json = jsonDecode(body) as Map<String, dynamic>;
      final message = json['message'];
      if (message is String && message.isNotEmpty) return message;
      final error = json['error'];
      if (error is String && error.isNotEmpty) return error;
    } on FormatException {
      if (body.length < 240) return body;
    }
    return fallback;
  }

  /// Guest / Dev Mode
  void signInAsGuest() {
    _accessToken = null;
    _refreshToken = null;
    try {
      final file = _getAuthStorageFile();
      if (file.existsSync()) file.deleteSync();
    } catch (error) {
      debugPrint(
        '[AuthService] Could not clear saved session for guest: $error',
      );
    }
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
    List<String>? deviceCatalogIds,
    List<String>? vehicleCatalogIds,
    String? mascotName,
    bool retryAfterRefresh = true,
  }) async {
    final payload = {
      'district': district,
      'ward': ward,
      if (dob != null) 'dob': dob,
      if (houseType != null) 'houseType': houseType,
      if (householdMembers != null) 'householdMembers': householdMembers,
      if (monthlyBillRupees != null) 'monthlyBillRupees': monthlyBillRupees,
      if (electricityProviderId != null)
        'electricityProviderId': electricityProviderId,
      if (gasProviderId != null) 'gasProviderId': gasProviderId,
      if (waterSupplyType != null) 'waterSupplyType': waterSupplyType,
      if (waterStorageType != null) 'waterStorageType': waterStorageType,
      if (deviceCatalogIds != null) 'deviceCatalogIds': deviceCatalogIds,
      if (vehicleCatalogIds != null) 'vehicleCatalogIds': vehicleCatalogIds,
      if (mascotName != null) 'mascotName': mascotName,
    };

    if (_accessToken == null || _accessToken!.isEmpty) {
      _lastSignInError = 'Sign in again before saving your profile.';
      return false;
    }

    if (_accessToken != null) {
      try {
        final uri = Uri.parse('${AuthConfig.apiBaseUrl}/auth/complete-profile');
        final request = await _httpClient
            .postUrl(uri)
            .timeout(const Duration(seconds: 15));
        request.headers.contentType = ContentType.json;
        request.headers.set('Authorization', 'Bearer $_accessToken');
        request.write(jsonEncode(payload));

        final response = await request.close().timeout(
          const Duration(seconds: 15),
        );
        final responseBody = await response
            .transform(utf8.decoder)
            .join()
            .timeout(const Duration(seconds: 15));

        if (response.statusCode == HttpStatus.unauthorized &&
            retryAfterRefresh &&
            await refreshSession()) {
          return completeProfile(
            district: district,
            ward: ward,
            dob: dob,
            houseType: houseType,
            householdMembers: householdMembers,
            monthlyBillRupees: monthlyBillRupees,
            electricityProviderId: electricityProviderId,
            gasProviderId: gasProviderId,
            waterSupplyType: waterSupplyType,
            waterStorageType: waterStorageType,
            deviceCatalogIds: deviceCatalogIds,
            vehicleCatalogIds: vehicleCatalogIds,
            mascotName: mascotName,
            retryAfterRefresh: false,
          );
        }
        if (response.statusCode != HttpStatus.ok) {
          _lastSignInError = _messageFromResponse(
            responseBody,
            'Could not save your profile. Please try again.',
          );
          return false;
        }

        if (response.statusCode == 200) {
          final data = jsonDecode(responseBody) as Map<String, dynamic>;
          _currentUser = CitizenProfile.fromJson(
            data['user'] as Map<String, dynamic>,
          );
          notifyListeners();
          return true;
        }
      } catch (e) {
        debugPrint('[AuthService] Profile update failed: $e');
        _lastSignInError = e is SocketException || e is HttpException
            ? 'Could not reach URJA. Your profile was not saved; check your connection and retry.'
            : e is TimeoutException
            ? 'Saving your profile timed out. Please try again.'
            : 'Could not save your profile. Please try again.';
      }
    }

    return false;
  }

  @override
  void notifyListeners() {
    _saveProfileToStorage();
    super.notifyListeners();
  }

  Future<bool> refreshSession() async {
    final token = _refreshToken;
    if (token == null || token.isEmpty) return false;

    try {
      final request = await _httpClient
          .postUrl(Uri.parse('${AuthConfig.apiBaseUrl}/auth/refresh'))
          .timeout(const Duration(seconds: 15));
      request.headers.contentType = ContentType.json;
      request.write(jsonEncode({'refreshToken': token}));
      final response = await request.close().timeout(
        const Duration(seconds: 15),
      );
      final body = await response
          .transform(utf8.decoder)
          .join()
          .timeout(const Duration(seconds: 15));
      if (response.statusCode != HttpStatus.ok) {
        _lastSignInError = _messageFromResponse(
          body,
          'Your session expired. Please sign in again.',
        );
        if (response.statusCode == HttpStatus.unauthorized) {
          _accessToken = null;
          _refreshToken = null;
          _currentUser = null;
          try {
            final file = _getAuthStorageFile();
            if (file.existsSync()) file.deleteSync();
          } catch (error) {
            debugPrint('[AuthService] Could not clear expired session: $error');
          }
          notifyListeners();
        }
        return false;
      }

      final data = jsonDecode(body) as Map<String, dynamic>;
      final accessToken = data['accessToken'];
      final refreshToken = data['refreshToken'];
      if (accessToken is! String || refreshToken is! String) {
        throw const FormatException(
          'Refresh response is missing authentication tokens.',
        );
      }
      _accessToken = accessToken;
      _refreshToken = refreshToken;
      _lastSignInError = null;
      notifyListeners();
      return true;
    } catch (error) {
      debugPrint('[AuthService] Session refresh failed: $error');
      _lastSignInError = error is SocketException || error is HttpException
          ? 'Could not reach URJA to refresh your session.'
          : error is TimeoutException
          ? 'Session refresh timed out. Please try again.'
          : 'Your session could not be refreshed. Please sign in again.';
      return false;
    }
  }

  Future<bool> restoreSession() async {
    if (_refreshToken == null || _refreshToken!.isEmpty) return false;
    for (var attempt = 0; attempt < 2; attempt++) {
      try {
        final request = await _httpClient
            .getUrl(Uri.parse('${AuthConfig.apiBaseUrl}/auth/me'))
            .timeout(const Duration(seconds: 15));
        final token = _accessToken;
        if (token != null && token.isNotEmpty) {
          request.headers.set('Authorization', 'Bearer $_accessToken');
        }
        final response = await request.close().timeout(
          const Duration(seconds: 15),
        );
        final body = await response
            .transform(utf8.decoder)
            .join()
            .timeout(const Duration(seconds: 15));

        if (response.statusCode == HttpStatus.unauthorized &&
            attempt == 0 &&
            await refreshSession()) {
          continue;
        }
        if (response.statusCode != HttpStatus.ok) {
          _lastSignInError = _messageFromResponse(
            body,
            'Your session has expired. Please sign in again.',
          );
          return false;
        }

        final data = jsonDecode(body) as Map<String, dynamic>;
        final user = data['user'];
        if (user is! Map<String, dynamic>) {
          throw const FormatException('Profile response is missing user data.');
        }
        _currentUser = CitizenProfile.fromJson(user);
        _isGuestMode = false;
        _lastSignInError = null;
        notifyListeners();
        return true;
      } catch (error) {
        debugPrint('[AuthService] Session restore failed: $error');
        _lastSignInError = error is SocketException || error is HttpException
            ? 'Could not reach URJA. Check your connection and retry.'
            : error is TimeoutException
            ? 'Session restore timed out. Please try again.'
            : 'Your session could not be restored. Please sign in again.';
        return false;
      }
    }
    return false;
  }

  Future<void> logout() async {
    final hasTokens = _accessToken != null && _refreshToken != null;
    if (hasTokens) {
      for (var attempt = 0; attempt < 2; attempt++) {
        try {
          final request = await _httpClient
              .postUrl(Uri.parse('${AuthConfig.apiBaseUrl}/auth/logout'))
              .timeout(const Duration(seconds: 10));
          request.headers.contentType = ContentType.json;
          request.headers.set('Authorization', 'Bearer $_accessToken');
          request.write(jsonEncode({'refreshToken': _refreshToken}));
          final response = await request.close().timeout(
            const Duration(seconds: 10),
          );
          await response.drain<void>();
          if (response.statusCode == HttpStatus.unauthorized &&
              attempt == 0 &&
              await refreshSession()) {
            continue;
          }
          if (response.statusCode < 200 || response.statusCode >= 300) {
            debugPrint(
              '[AuthService] Backend logout returned ${response.statusCode}; clearing local session.',
            );
          }
          break;
        } catch (error) {
          debugPrint(
            '[AuthService] Backend logout failed; clearing local session: $error',
          );
          break;
        }
      }
    }

    try {
      await _googleSignIn.signOut();
    } catch (error) {
      debugPrint('[AuthService] Google account sign-out failed: $error');
    }

    try {
      final file = _getAuthStorageFile();
      if (file.existsSync()) file.deleteSync();
    } catch (_) {}
    _accessToken = null;
    _refreshToken = null;
    _currentUser = null;
    _isGuestMode = false;
    _lastSignInError = null;
    notifyListeners();
  }
}
