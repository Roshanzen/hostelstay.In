import 'package:flutter/foundation.dart';
import '../core/storage/auth_storage.dart';
import '../core/api_client.dart';

class AuthRepository {
  AuthRepository(this._authStorage);
  final AuthStorage _authStorage;

  Future<void> signIn({required String username, required String password}) async {
    final client = ApiClient(authStorage: _authStorage);
    final data = await client.post('/api/auth/login/', {
      'username': username,
      'password': password,
    });

    final access = data['access']?.toString();
    final refresh = data['refresh']?.toString();
    final user = data['user'] != null ? Map<String, dynamic>.from(data['user'] as Map) : null;

    if (access == null || refresh == null || user == null) {
      throw Exception('Invalid login response');
    }

    await _authStorage.putAccessToken(access);
    await _authStorage.putRefreshToken(refresh);
    await _authStorage.putProfile(user);
    debugPrint('[AUTH] Credential stored');
  }

  Future<void> signOut() async {
    final client = ApiClient(authStorage: _authStorage);
    final refresh = _authStorage.refreshToken;
    try {
      if (refresh != null && refresh.isNotEmpty) {
        await client.post('/api/auth/logout/', {'refresh': refresh});
      }
    } catch (_) {}
    await _authStorage.clear();
  }
}

