import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive/hive.dart';

class AuthStorage {
  AuthStorage([FlutterSecureStorage? storage, Box<dynamic>? box])
      : _storage = storage ?? const FlutterSecureStorage(),
        _box = box ?? (Hive.isBoxOpen('app_settings') ? Hive.box<dynamic>('app_settings') : null) {
    _initFromCache();
  }

  final FlutterSecureStorage _storage;
  final Box<dynamic>? _box;
  void Function()? onSessionExpired;

  static const _accessKey = 'auth.accessToken';
  static const _refreshKey = 'auth.refreshToken';
  static const _profileKey = 'auth.profile';

  String? _accessToken;
  String? _refreshToken;
  Map<String, dynamic>? _cachedProfile;

  void _initFromCache() {
    final box = _box;
    if (box != null) {
      _accessToken = box.get(_accessKey)?.toString();
      _refreshToken = box.get(_refreshKey)?.toString();
      final raw = box.get(_profileKey);
      if (raw is Map) {
        _cachedProfile = Map<String, dynamic>.from(raw);
      } else if (raw is String) {
        try {
          _cachedProfile = Map<String, dynamic>.from(jsonDecode(raw) as Map);
        } catch (_) {}
      }
    }
  }

  String? get accessToken => _accessToken ?? _box?.get(_accessKey)?.toString();
  String? get refreshToken => _refreshToken ?? _box?.get(_refreshKey)?.toString();
  Map<String, dynamic>? get profileSync => _cachedProfile;

  Future<Map<String, dynamic>?> get profile async {
    if (_cachedProfile != null) return _cachedProfile;
    final box = _box;
    if (box != null) {
      final raw = box.get(_profileKey);
      if (raw is Map) {
        _cachedProfile = Map<String, dynamic>.from(raw);
        return _cachedProfile;
      } else if (raw is String) {
        try {
          _cachedProfile = Map<String, dynamic>.from(jsonDecode(raw) as Map);
          return _cachedProfile;
        } catch (_) {}
      }
    }
    try {
      final raw = await _storage.read(key: _profileKey);
      if (raw != null) {
        _cachedProfile = Map<String, dynamic>.from(jsonDecode(raw) as Map);
        return _cachedProfile;
      }
    } catch (_) {}
    return null;
  }

  Future<void> put(String key, dynamic value) async {
    if (key == _accessKey) {
      await putAccessToken(value?.toString() ?? '');
    } else if (key == _refreshKey) {
      await putRefreshToken(value?.toString() ?? '');
    } else if (key == _profileKey) {
      if (value is Map<String, dynamic>) {
        await putProfile(value);
      } else if (value is Map) {
        await putProfile(Map<String, dynamic>.from(value));
      }
    } else {
      await _box?.put(key, value);
      try {
        await _storage.write(key: key, value: value?.toString());
      } catch (_) {}
    }
  }

  Future<void> putAccessToken(String value) async {
    _accessToken = value;
    await _box?.put(_accessKey, value);
    try {
      await _storage.write(key: _accessKey, value: value);
    } catch (_) {}
  }

  Future<void> putRefreshToken(String value) async {
    _refreshToken = value;
    await _box?.put(_refreshKey, value);
    try {
      await _storage.write(key: _refreshKey, value: value);
    } catch (_) {}
  }

  Future<void> putProfile(Map<String, dynamic> value) async {
    _cachedProfile = Map<String, dynamic>.from(value);
    await _box?.put(_profileKey, value);
    try {
      await _storage.write(key: _profileKey, value: jsonEncode(value));
    } catch (_) {}
  }

  Future<void> clear() async {
    _accessToken = null;
    _refreshToken = null;
    _cachedProfile = null;
    await _box?.delete(_accessKey);
    await _box?.delete(_refreshKey);
    await _box?.delete(_profileKey);
    try {
      await _storage.delete(key: _accessKey);
      await _storage.delete(key: _refreshKey);
      await _storage.delete(key: _profileKey);
    } catch (_) {}
    onSessionExpired?.call();
  }
}
