import 'package:hive/hive.dart';
import '../../backend/models/property.dart';
import '../core/api_client.dart';
import '../core/storage/auth_storage.dart';

class PropertyRepository {
  PropertyRepository(this._settings, this._authStorage);
  final Box<dynamic> _settings;
  final AuthStorage _authStorage;

  Future<List<Property>> fetchProperties(String ownerId) async {
    try {
      final client = ApiClient(authStorage: _authStorage);
      final data = await client.get('/api/properties/properties/');
      final list = (data['results'] ?? data['value'] ?? <dynamic>[]) as List<dynamic>;
      final result = list.map((e) {
        final m = Map<String, dynamic>.from(e as Map);
        return Property.fromJson(m);
      }).toList();
      if (result.isNotEmpty) {
        await _settings.put('cache.properties', list);
      }
      return result;
    } catch (e) {
      return readCache();
    }
  }

  Future<List<Property>> fetchAssignedProperties() async {
    try {
      final client = ApiClient(authStorage: _authStorage);
      final data = await client.get('/api/wardens/wardens/assigned/');
      var list = (data['results'] ?? data['value'] ?? <dynamic>[]) as List<dynamic>;
      if (list.isEmpty) {
        final propData = await client.get('/api/properties/properties/');
        list = (propData['results'] ?? propData['value'] ?? <dynamic>[]) as List<dynamic>;
      }
      final result = list.map((e) {
        final m = Map<String, dynamic>.from(e as Map);
        return Property.fromJson(m);
      }).toList();
      if (result.isNotEmpty) {
        await _settings.put('cache.properties', list);
      }
      return result;
    } catch (e) {
      return readCache();
    }
  }

  Future<Property?> createProperty(Map<String, dynamic> payload) async {
    final client = ApiClient(authStorage: _authStorage);
    final data = await client.post('/api/properties/properties/', payload);
    return Property.fromJson(data);
  }

  Future<Property?> updateProperty(String id, Map<String, dynamic> payload) async {
    final client = ApiClient(authStorage: _authStorage);
    final data = await client.patch('/api/properties/properties/$id/', payload);
    return Property.fromJson(data);
  }

  Future<bool> deleteProperty(String id) async {
    final client = ApiClient(authStorage: _authStorage);
    await client.delete('/api/properties/properties/$id/');
    return true;
  }

  List<Property> readCache() {
    final raw = _settings.get('cache.properties');
    if (raw is List) {
      return raw.map((e) {
        final m = Map<String, dynamic>.from(e as Map);
        return Property.fromJson(m);
      }).toList();
    }
    return [];
  }

  Future<void> setActivePgId(String id) async {
    await _settings.put('active_pg_id', id);
  }

  String? getActivePgId() => _settings.get('active_pg_id')?.toString();
}
