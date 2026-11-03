import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'api_client.dart';

class AuthSession extends ChangeNotifier {
  AuthSession._() {
    ApiClient.instance.configure(refreshSession: refreshSession);
  }

  static final instance = AuthSession._();
  static const _vault = MethodChannel('urja/secure_store');
  static const _serverClientId = String.fromEnvironment(
    'GOOGLE_SERVER_CLIENT_ID',
    defaultValue:
        '382767216032-3744ggt0eifce7jcq0v4ff34fub5ml7s.apps.googleusercontent.com',
  );

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    serverClientId: _serverClientId.isEmpty ? null : _serverClientId,
    scopes: const ['email', 'profile'],
  );

  Map<String, dynamic>? _user;
  String? _refreshToken;
  bool _isReady = false;
  bool _isBusy = false;
  String? _startupError;

  Map<String, dynamic>? get user => _user;
  bool get isReady => _isReady;
  bool get isBusy => _isBusy;
  bool get isSignedIn => _user != null;
  bool get profileComplete => _user?['isProfileComplete'] == true;
  String? get startupError => _startupError;

  Future<void> initialize() async {
    if (_isReady) return;
    _startupError = null;
    try {
      _refreshToken = await _vault.invokeMethod<String>('getRefreshToken');
      if (_refreshToken != null && _refreshToken!.isNotEmpty) {
        if (await refreshSession()) {
          await _loadProfile();
        }
      }
    } on PlatformException {
      _refreshToken = null;
    } on ApiException catch (error) {
      if (error.statusCode == 401) await _clearSession();
      _startupError = error.toString();
    } catch (error) {
      _startupError = error.toString();
    } finally {
      _isReady = true;
      notifyListeners();
    }
  }

  Future<void> retryInitialization() async {
    _isReady = false;
    _startupError = null;
    notifyListeners();
    await initialize();
  }

  Future<void> signInWithGoogle() async {
    if (_isBusy) return;
    _isBusy = true;
    notifyListeners();
    try {
      final account = await _googleSignIn.signIn();
      if (account == null) return;
      final idToken = (await account.authentication).idToken;
      if (idToken == null || idToken.isEmpty) {
        throw const ApiException(
          'Google did not return an ID token. Check the Android OAuth client configuration.',
        );
      }
      final data = await ApiClient.instance.post(
        '/auth/google',
        body: {'idToken': idToken},
        authenticated: false,
      );
      await _acceptTokens(data);
      final user = data['user'];
      if (user is! Map) {
        throw const FormatException(
          'Sign-in response is missing citizen data.',
        );
      }
      _user = Map<String, dynamic>.from(user);
    } finally {
      _isBusy = false;
      notifyListeners();
    }
  }

  Future<void> completeProfile({required String district, String? ward}) async {
    final payload = <String, dynamic>{'district': district};
    if (ward != null && ward.trim().isNotEmpty) payload['ward'] = ward.trim();
    final response = await ApiClient.instance.post(
      '/auth/complete-profile',
      body: payload,
    );
    final user = response['user'];
    if (user is! Map) {
      throw const FormatException('The server did not return your profile.');
    }
    _user = Map<String, dynamic>.from(user);
    notifyListeners();
  }

  Future<bool> refreshSession() async {
    final current = _refreshToken;
    if (current == null || current.isEmpty) return false;
    try {
      final data = await ApiClient.instance.post(
        '/auth/refresh',
        body: {'refreshToken': current},
        authenticated: false,
      );
      await _acceptTokens(data);
      return true;
    } on ApiException catch (error) {
      if (error.statusCode == 401) await _clearSession();
      return false;
    }
  }

  Future<void> _acceptTokens(Map<String, dynamic> data) async {
    final access = data['accessToken'];
    final refresh = data['refreshToken'];
    if (access is! String || refresh is! String) {
      throw const FormatException('Authentication response is missing tokens.');
    }
    ApiClient.instance.setAccessToken(access);
    _refreshToken = refresh;
    await _vault.invokeMethod<void>('saveRefreshToken', refresh);
  }

  Future<void> _loadProfile() async {
    final response = await ApiClient.instance.get('/auth/me');
    final user = response['user'];
    if (user is! Map) {
      throw const FormatException('The server did not return your profile.');
    }
    _user = Map<String, dynamic>.from(user);
  }

  Future<void> signOut() async {
    try {
      if (_refreshToken != null) {
        await ApiClient.instance.post(
          '/auth/logout',
          body: {'refreshToken': _refreshToken},
        );
      }
    } finally {
      await _clearSession();
      await _googleSignIn.signOut();
      notifyListeners();
    }
  }

  Future<void> _clearSession() async {
    _refreshToken = null;
    _user = null;
    ApiClient.instance.setAccessToken(null);
    await _vault.invokeMethod<void>('clearRefreshToken');
  }
}
