import 'dart:async';
import 'dart:convert';
import 'dart:io';

class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

class ApiClient {
  ApiClient._();

  static final instance = ApiClient._();
  static const baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://urjaone.vercel.app/api/v1',
  );

  final HttpClient _client = HttpClient()
    ..connectionTimeout = const Duration(seconds: 8);
  String? _accessToken;
  Future<bool> Function()? _refreshSession;
  Future<bool>? _refreshInProgress;

  void configure({required Future<bool> Function() refreshSession}) {
    _refreshSession = refreshSession;
  }

  void setAccessToken(String? value) => _accessToken = value;

  Future<Map<String, dynamic>> get(String path, {bool authenticated = true}) =>
      request(path, authenticated: authenticated);

  Future<Map<String, dynamic>> post(
    String path, {
    Object? body,
    bool authenticated = true,
  }) => request(path, method: 'POST', body: body, authenticated: authenticated);

  Future<Map<String, dynamic>> put(
    String path, {
    Object? body,
    bool authenticated = true,
  }) => request(path, method: 'PUT', body: body, authenticated: authenticated);

  Future<Map<String, dynamic>> delete(
    String path, {
    bool authenticated = true,
  }) => request(path, method: 'DELETE', authenticated: authenticated);

  Future<Map<String, dynamic>> request(
    String path, {
    String method = 'GET',
    Object? body,
    bool authenticated = true,
    bool retryUnauthorized = true,
  }) async {
    final response = await _send(
      path,
      method: method,
      body: body,
      authenticated: authenticated,
    );
    if (response.statusCode == HttpStatus.unauthorized &&
        authenticated &&
        retryUnauthorized &&
        await _refresh()) {
      return request(
        path,
        method: method,
        body: body,
        authenticated: authenticated,
        retryUnauthorized: false,
      );
    }

    final decoded = _decode(response.body);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message = decoded['message'];
      throw ApiException(
        message is String
            ? message
            : 'Request failed (${response.statusCode}).',
        statusCode: response.statusCode,
      );
    }
    return decoded;
  }

  Future<_RawResponse> _send(
    String path, {
    required String method,
    Object? body,
    required bool authenticated,
  }) async {
    final normalizedBase = baseUrl.endsWith('/') ? baseUrl : '$baseUrl/';
    final relativePath = path.startsWith('/') ? path.substring(1) : path;
    final request = await _client
        .openUrl(method, Uri.parse('$normalizedBase$relativePath'))
        .timeout(const Duration(seconds: 15));
    request.headers.set(HttpHeaders.acceptHeader, 'application/json');
    final token = _accessToken;
    if (authenticated) {
      if (token == null || token.isEmpty) {
        throw const ApiException('Sign in to continue.');
      }
      request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $token');
    }
    if (body != null) {
      request.headers.contentType = ContentType.json;
      request.write(jsonEncode(body));
    }
    final response = await request.close().timeout(const Duration(seconds: 15));
    final responseBody = await response
        .transform(utf8.decoder)
        .join()
        .timeout(const Duration(seconds: 15));
    return _RawResponse(response.statusCode, responseBody);
  }

  Future<bool> _refresh() async {
    final current = _refreshInProgress;
    if (current != null) return current;
    final callback = _refreshSession;
    if (callback == null) return false;
    final task = callback();
    _refreshInProgress = task;
    try {
      return await task;
    } finally {
      _refreshInProgress = null;
    }
  }

  Map<String, dynamic> _decode(String body) {
    if (body.isEmpty) return <String, dynamic>{};
    final value = jsonDecode(body);
    if (value is! Map) {
      throw const FormatException('The server returned an invalid response.');
    }
    return Map<String, dynamic>.from(value);
  }
}

class _RawResponse {
  const _RawResponse(this.statusCode, this.body);

  final int statusCode;
  final String body;
}
