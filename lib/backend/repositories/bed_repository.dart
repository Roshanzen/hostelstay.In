import 'package:hive/hive.dart';
import '../../backend/models/bed.dart';
import '../core/api_client.dart';
import '../core/storage/auth_storage.dart';

class BedRepository {
  BedRepository(this._settings, this._authStorage);
  final Box<dynamic> _settings;
  final AuthStorage _authStorage;

  Future<List<BedModel>> fetchForPg(String pgId, {String? roomId}) async {
    try {
      final client = ApiClient(authStorage: _authStorage);
      final query = <String>['pg=$pgId'];
      if (roomId != null && roomId.isNotEmpty) query.add('room=$roomId');
      final data = await client.get('/api/beds/beds/?${query.join('&')}');
      final list = (data['results'] ?? data['value'] ?? <dynamic>[]) as List<dynamic>;
      final result = list.map((e) {
        final m = Map<String, dynamic>.from(e as Map);
        final statusStr = (m['status'] ?? 'available').toString().toLowerCase();
        return BedModel(
          id: m['id']?.toString() ?? '',
          roomId: m['room']?.toString() ?? m['room_number']?.toString() ?? roomId ?? '',
          label: m['label']?.toString() ?? '',
          rent: double.tryParse(m['rent']?.toString() ?? '0') ?? 0,
          status: statusStr == 'occupied' ? BedStatus.occupied : BedStatus.available,
          tenantId: m['tenant']?.toString(),
          pgId: m['pg']?.toString() ?? pgId,
        );
      }).toList();
      await _settings.put('cache.beds_$pgId', list);
      return result;
    } catch (_) {
      final cached = _settings.get('cache.beds_$pgId');
      if (cached is List) {
        return cached.map((e) {
          final m = Map<String, dynamic>.from(e as Map);
          final statusStr = (m['status'] ?? 'available').toString().toLowerCase();
          return BedModel(
            id: m['id']?.toString() ?? '',
            roomId: m['room']?.toString() ?? m['room_number']?.toString() ?? roomId ?? '',
            label: m['label']?.toString() ?? '',
            rent: double.tryParse(m['rent']?.toString() ?? '0') ?? 0,
            status: statusStr == 'occupied' ? BedStatus.occupied : BedStatus.available,
            tenantId: m['tenant']?.toString(),
            pgId: m['pg']?.toString() ?? pgId,
          );
        }).toList();
      }
      return [];
    }
  }

  Future<List<BedModel>> fetchBeds({required String pgId, String? roomId}) async {
    return fetchForPg(pgId, roomId: roomId);
  }

  Future<BedModel> createBed(BedModel bed) async {
    final client = ApiClient(authStorage: _authStorage);
    final body = {
      'pg': bed.pgId,
      'room': bed.roomId,
      'label': bed.label,
      'rent': bed.rent,
      'status': bed.status == BedStatus.occupied ? 'occupied' : 'available',
      if (bed.tenantId != null && bed.tenantId!.isNotEmpty) 'tenant': bed.tenantId,
    };
    final data = await client.post('/api/beds/beds/', body);
    final statusStr = (data['status'] ?? 'available').toString().toLowerCase();
    return BedModel(
      id: data['id']?.toString() ?? bed.id,
      roomId: data['room']?.toString() ?? data['room_number']?.toString() ?? bed.roomId,
      label: data['label']?.toString() ?? bed.label,
      rent: double.tryParse(data['rent']?.toString() ?? '${bed.rent}') ?? bed.rent,
      status: statusStr == 'occupied' ? BedStatus.occupied : BedStatus.available,
      tenantId: data['tenant']?.toString() ?? bed.tenantId,
      pgId: data['pg']?.toString() ?? bed.pgId,
    );
  }

  Future<void> updateBed(BedModel bed) async {
    final client = ApiClient(authStorage: _authStorage);
    final path = '/api/beds/beds/${bed.id}/';
    final body = {
      if (bed.roomId.isNotEmpty) 'room': bed.roomId,
      'label': bed.label,
      'rent': bed.rent,
      'status': bed.status == BedStatus.occupied ? 'occupied' : 'available',
      if (bed.tenantId != null && bed.tenantId!.isNotEmpty) 'tenant': bed.tenantId,
    };
    await client.patch(path, body);
  }
}

