import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../constants/auth_config.dart';

typedef AccessTokenProvider = String? Function();
typedef SessionRefresher = Future<bool> Function();

class ApiResponse {
  const ApiResponse({required this.statusCode, required this.body});

  final int statusCode;
  final String body;

  Map<String, dynamic> decodeJson() => jsonDecode(body) as Map<String, dynamic>;
}

class ApiClient {
  ApiClient._();

  static final ApiClient instance = ApiClient._();

  final HttpClient _httpClient = HttpClient()
    ..connectionTimeout = const Duration(seconds: 8);

  AccessTokenProvider? _accessTokenProvider;
  SessionRefresher? _sessionRefresher;
  Future<bool>? _refreshInProgress;

  void configure({
    required AccessTokenProvider accessTokenProvider,
    required SessionRefresher sessionRefresher,
  }) {
    _accessTokenProvider = accessTokenProvider;
    _sessionRefresher = sessionRefresher;
  }

  Future<ApiResponse> get(String path, {bool authenticated = true}) =>
      request(path, authenticated: authenticated);

  Future<ApiResponse> post(
    String path, {
    Object? body,
    bool authenticated = true,
  }) => request(path, method: 'POST', body: body, authenticated: authenticated);

  Future<ApiResponse> put(
    String path, {
    Object? body,
    bool authenticated = true,
  }) => request(path, method: 'PUT', body: body, authenticated: authenticated);

  Future<ApiResponse> patch(
    String path, {
    Object? body,
    bool authenticated = true,
  }) =>
      request(path, method: 'PATCH', body: body, authenticated: authenticated);

  Future<ApiResponse> delete(
    String path, {
    Object? body,
    bool authenticated = true,
  }) =>
      request(path, method: 'DELETE', body: body, authenticated: authenticated);

  Future<ApiResponse> request(
    String path, {
    String method = 'GET',
    Object? body,
    bool authenticated = true,
  }) async {
    var token = authenticated ? _accessTokenProvider?.call() : null;
    if (authenticated && (token == null || token.isEmpty)) {
      if (!await _refreshSession()) {
        throw StateError('Sign in to use this feature.');
      }
      token = _accessTokenProvider?.call();
    }

    for (var attempt = 0; attempt < 2; attempt++) {
      final request = await _httpClient
          .openUrl(method, _buildUri(path))
          .timeout(const Duration(seconds: 15));
      request.headers.set(HttpHeaders.acceptHeader, 'application/json');
      if (authenticated) {
        if (token == null || token.isEmpty) {
          throw StateError('Your session expired. Sign in again.');
        }
        request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $token');
      }
      if (body != null) {
        request.headers.contentType = ContentType.json;
        request.write(jsonEncode(body));
      }

      final response = await request.close().timeout(
        const Duration(seconds: 15),
      );
      final responseBody = await response
          .transform(utf8.decoder)
          .join()
          .timeout(const Duration(seconds: 15));
      if (response.statusCode == HttpStatus.unauthorized &&
          authenticated &&
          attempt == 0 &&
          await _refreshSession()) {
        token = _accessTokenProvider?.call();
        continue;
      }
      return ApiResponse(statusCode: response.statusCode, body: responseBody);
    }

    throw StateError('The request could not be completed after refreshing.');
  }

  Future<bool> _refreshSession() async {
    final refresher = _sessionRefresher;
    if (refresher == null) return false;
    final currentRefresh = _refreshInProgress;
    if (currentRefresh != null) return currentRefresh;

    final refresh = refresher();
    _refreshInProgress = refresh;
    try {
      return await refresh;
    } finally {
      _refreshInProgress = null;
    }
  }

  Uri _buildUri(String path) {
    final base = AuthConfig.apiBaseUrl.endsWith('/')
        ? AuthConfig.apiBaseUrl
        : '${AuthConfig.apiBaseUrl}/';
    final relativePath = path.startsWith('/') ? path.substring(1) : path;
    return Uri.parse('$base$relativePath');
  }
}
