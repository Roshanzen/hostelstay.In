import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../api_config.dart';
import 'storage/auth_storage.dart';

const _defaultTimeout = Duration(seconds: 30);

class ApiException implements Exception {
  ApiException(this.message, {this.statusCode, this.body, this.errors});
  final String message;
  final int? statusCode;
  final String? body;
  final Map<String, dynamic>? errors;

  @override
  String toString() => message;
}

class ApiClient {
  ApiClient({
    String? baseUrl,
    this.authStorage,
    http.Client? httpClient,
    Duration? timeout,
  })  : _baseUrl = (baseUrl ?? ApiConfig.baseUrl).replaceAll(RegExp(r'/+$'), ''),
        _httpClient = httpClient ?? http.Client(),
        _timeout = timeout ?? _defaultTimeout;

  final String _baseUrl;
  final AuthStorage? authStorage;
  final http.Client _httpClient;
  final Duration _timeout;

  String? get _token => authStorage?.accessToken;

  void setAuthToken(String token) {
    authStorage?.put('auth.accessToken', token);
  }

  void clearAuthToken() {
    authStorage?.clear();
  }

  Uri _buildUri(String path) {
    final normalized = path.startsWith('/') ? path.substring(1) : path;
    return Uri.parse('$_baseUrl/$normalized');
  }

  Map<String, String> _headers({bool contentType = false, String? token}) {
    final headers = <String, String>{'Accept': 'application/json'};
    if (contentType) headers['Content-Type'] = 'application/json';
    final activeToken = token ?? _token;
    if (activeToken != null && activeToken.isNotEmpty) {
      headers['Authorization'] = 'Bearer $activeToken';
    }
    return headers;
  }

  Future<bool> _tryRefreshToken() async {
    final refreshToken = authStorage?.refreshToken;
    if (refreshToken == null || refreshToken.isEmpty) return false;
    try {
      final uri = Uri.parse('$_baseUrl/api/auth/token/refresh/');
      final res = await _httpClient.post(
        uri,
        headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
        body: jsonEncode({'refresh': refreshToken}),
      ).timeout(const Duration(seconds: 5));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final newAccess = data['access'] as String?;
        final newRefresh = data['refresh'] as String?;
        if (newAccess != null && newAccess.isNotEmpty) {
          await authStorage?.putAccessToken(newAccess);
          if (newRefresh != null && newRefresh.isNotEmpty) {
            await authStorage?.putRefreshToken(newRefresh);
          }
          return true;
        }
      } else if (res.statusCode == 401) {
        debugPrint('[AUTH] Logout triggered');
        debugPrint('[AUTH] Logout reason: Refresh token expired or rejected by Django (401)');
        await authStorage?.clear();
      }
    } catch (e) {
      debugPrint('[ApiClient] Token refresh failed: $e');
    }
    return false;
  }

  void _ensureSuccess(http.Response response) {
    final code = response.statusCode;
    if (code >= 200 && code < 300) return;
    String message;
    Map<String, dynamic>? parsedErrors;
    try {
      final data = jsonDecode(response.body);
      if (data is Map<String, dynamic>) {
        if (data['errors'] is Map) {
          parsedErrors = Map<String, dynamic>.from(data['errors'] as Map);
        }
        if (data.containsKey('detail')) {
          message = data['detail'].toString();
        } else if (data.containsKey('error')) {
          message = data['error'].toString();
        } else if (data.containsKey('errors')) {
          final errs = data['errors'];
          if (errs is Map) {
            message = errs.values.map((e) => e.toString()).join(', ');
          } else {
            message = errs.toString();
          }
        } else {
          message = data.entries
              .map((e) => '${e.key}: ${e.value is List ? (e.value as List).join(', ') : e.value}')
              .join('; ');
        }
      } else {
        message = 'Request failed with status $code';
      }
    } on FormatException catch (_) {
      message = 'Request failed with status $code';
    }
    throw ApiException(message, statusCode: code, body: response.body, errors: parsedErrors);
  }

  final Map<String, Future<Map<String, dynamic>>> _inFlightRequests = {};

  Future<Map<String, dynamic>> get(String path) async {
    final pending = _inFlightRequests[path];
    if (pending != null) {
      return pending;
    }
    final future = _executeGet(path);
    _inFlightRequests[path] = future;
    return future.whenComplete(() {
      _inFlightRequests.remove(path);
    });
  }

  Future<Map<String, dynamic>> _executeGet(String path) async {
    final uri = _buildUri(path);
    var response = await _httpClient.get(uri, headers: _headers()).timeout(_timeout);
    if (response.statusCode == 401) {
      final refreshed = await _tryRefreshToken();
      if (refreshed) {
        response = await _httpClient.get(uri, headers: _headers()).timeout(_timeout);
      }
    }
    _ensureSuccess(response);
    final decoded = jsonDecode(response.body);
    if (decoded is List) {
      return {'results': decoded};
    }
    if (decoded is Map<String, dynamic>) {
      return decoded;
    }
    return <String, dynamic>{'results': <dynamic>[]};
  }

  Future<List<dynamic>> getList(String path) async {
    final map = await get(path);
    return (map['results'] ?? map['data'] ?? <dynamic>[]) as List<dynamic>;
  }

  Future<Map<String, dynamic>> post(String path, dynamic body) async {
    final uri = _buildUri(path);
    var response = await _httpClient.post(
      uri,
      headers: _headers(contentType: true),
      body: jsonEncode(body),
    ).timeout(_timeout);
    if (response.statusCode == 401) {
      final refreshed = await _tryRefreshToken();
      if (refreshed) {
        response = await _httpClient.post(
          uri,
          headers: _headers(contentType: true),
          body: jsonEncode(body),
        ).timeout(_timeout);
      }
    }
    _ensureSuccess(response);
    if (response.body.isEmpty) return <String, dynamic>{};
    final decoded = jsonDecode(response.body);
    if (decoded is Map<String, dynamic>) return decoded;
    if (decoded is List) return {'results': decoded};
    return <String, dynamic>{};
  }

  Future<Map<String, dynamic>> patch(String path, dynamic body) async {
    final uri = _buildUri(path);
    var response = await _httpClient.patch(
      uri,
      headers: _headers(contentType: true),
      body: jsonEncode(body),
    ).timeout(_timeout);
    if (response.statusCode == 401) {
      final refreshed = await _tryRefreshToken();
      if (refreshed) {
        response = await _httpClient.patch(
          uri,
          headers: _headers(contentType: true),
          body: jsonEncode(body),
        ).timeout(_timeout);
      }
    }
    _ensureSuccess(response);
    if (response.body.isEmpty) return <String, dynamic>{};
    final decoded = jsonDecode(response.body);
    if (decoded is Map<String, dynamic>) return decoded;
    if (decoded is List) return {'results': decoded};
    return <String, dynamic>{};
  }

  Future<Map<String, dynamic>> put(String path, dynamic body) async {
    final uri = _buildUri(path);
    var response = await _httpClient.put(
      uri,
      headers: _headers(contentType: true),
      body: jsonEncode(body),
    ).timeout(_timeout);
    if (response.statusCode == 401) {
      final refreshed = await _tryRefreshToken();
      if (refreshed) {
        response = await _httpClient.put(
          uri,
          headers: _headers(contentType: true),
          body: jsonEncode(body),
        ).timeout(_timeout);
      }
    }
    _ensureSuccess(response);
    if (response.body.isEmpty) return <String, dynamic>{};
    final decoded = jsonDecode(response.body);
    if (decoded is Map<String, dynamic>) return decoded;
    if (decoded is List) return {'results': decoded};
    return <String, dynamic>{};
  }

  Future<void> delete(String path) async {
    final uri = _buildUri(path);
    var response = await _httpClient.delete(uri, headers: _headers()).timeout(_timeout);
    if (response.statusCode == 401) {
      final refreshed = await _tryRefreshToken();
      if (refreshed) {
        response = await _httpClient.delete(uri, headers: _headers()).timeout(_timeout);
      }
    }
    _ensureSuccess(response);
  }
}
