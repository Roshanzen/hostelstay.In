import 'package:hive/hive.dart';
import '../../backend/models/room.dart';
import '../core/api_client.dart';
import '../core/storage/auth_storage.dart';

class RoomRepository {
  RoomRepository(this._settings, this._authStorage);
  final Box<dynamic> _settings;
  final AuthStorage _authStorage;

  Future<List<Room>> fetchForPg(String pgId) async {
    try {
      final client = ApiClient(authStorage: _authStorage);
      final data = await client.get('/api/rooms/rooms/?pg=$pgId');
      final list = (data['results'] ?? data['value'] ?? <dynamic>[]) as List<dynamic>;
      final result = list.map((e) {
        final m = Map<String, dynamic>.from(e as Map);
        return Room(
          id: m['id']?.toString() ?? '',
          roomNumber: m['room_number']?.toString() ?? '',
          capacity: (m['capacity'] is int) ? m['capacity'] as int : int.tryParse(m['capacity']?.toString() ?? '1') ?? 1,
          rentAmount: double.tryParse(m['rent_amount']?.toString() ?? '0') ?? 0,
          pgId: m['pg']?.toString() ?? pgId,
        );
      }).toList();
      await _settings.put('cache.rooms_$pgId', list);
      return result;
    } catch (_) {
      final cached = _settings.get('cache.rooms_$pgId');
      if (cached is List) {
        return cached.map((e) {
          final m = Map<String, dynamic>.from(e as Map);
          return Room(
            id: m['id']?.toString() ?? '',
            roomNumber: m['room_number']?.toString() ?? '',
            capacity: (m['capacity'] is int) ? m['capacity'] as int : int.tryParse(m['capacity']?.toString() ?? '1') ?? 1,
            rentAmount: double.tryParse(m['rent_amount']?.toString() ?? '0') ?? 0,
            pgId: m['pg']?.toString() ?? pgId,
          );
        }).toList();
      }
      return [];
    }
  }

  Future<Room> createRoom(Room room) async {
    final client = ApiClient(authStorage: _authStorage);
    final body = {
      'room_number': room.roomNumber,
      'capacity': room.capacity,
      'rent_amount': room.rentAmount,
      'pg': room.pgId,
    };
    final data = await client.post('/api/rooms/rooms/', body);
    return Room(
      id: data['id']?.toString() ?? room.id,
      roomNumber: data['room_number']?.toString() ?? room.roomNumber,
      capacity: data['capacity'] is int ? data['capacity'] as int : int.tryParse(data['capacity']?.toString() ?? '${room.capacity}') ?? room.capacity,
      rentAmount: double.tryParse(data['rent_amount']?.toString() ?? '${room.rentAmount}') ?? room.rentAmount,
      pgId: data['pg']?.toString() ?? room.pgId,
    );
  }

  Future<Room> updateRoom(Room room) async {
    final client = ApiClient(authStorage: _authStorage);
    final body = {
      'room_number': room.roomNumber,
      'capacity': room.capacity,
      'rent_amount': room.rentAmount,
      'pg': room.pgId,
    };
    final data = await client.patch('/api/rooms/rooms/${room.id}/', body);
    return Room(
      id: data['id']?.toString() ?? room.id,
      roomNumber: data['room_number']?.toString() ?? room.roomNumber,
      capacity: data['capacity'] is int ? data['capacity'] as int : int.tryParse(data['capacity']?.toString() ?? '${room.capacity}') ?? room.capacity,
      rentAmount: double.tryParse(data['rent_amount']?.toString() ?? '${room.rentAmount}') ?? room.rentAmount,
      pgId: data['pg']?.toString() ?? room.pgId,
    );
  }

  Future<void> deleteRoom(String roomId) async {
    final client = ApiClient(authStorage: _authStorage);
    await client.delete('/api/rooms/rooms/$roomId/');
  }
}

