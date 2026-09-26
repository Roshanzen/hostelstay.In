import 'package:hive/hive.dart';
import '../../backend/models/utility.dart';
import '../core/api_client.dart';
import '../core/storage/auth_storage.dart';

class UtilityRepository {
  UtilityRepository(this._settings, this._authStorage);
  final Box<dynamic> _settings;
  final AuthStorage _authStorage;

  Future<List<UtilityModel>> fetchForPg(String pgId) async {
    try {
      final client = ApiClient(authStorage: _authStorage);
      final data = await client.get('/api/utilities/utilities/?pg=$pgId');
      final list = (data['results'] ?? data['value'] ?? <dynamic>[]) as List<dynamic>;
      await _settings.put('cache.utilities_$pgId', list);
      return list.map((e) {
          final m = Map<String, dynamic>.from(e as Map);
          final typeStr = (m['utility_type'] ?? 'other').toString().toLowerCase();
          return UtilityModel(
            id: m['id']?.toString() ?? '',
            type: typeStr.contains('electricity')
                ? UtilityType.electricity
                : typeStr.contains('water')
                    ? UtilityType.water
                    : typeStr.contains('internet')
                        ? UtilityType.internet
                        : UtilityType.other,
            totalAmount: double.tryParse(m['total_amount']?.toString() ?? '0') ?? 0,
            billMonth: DateTime.tryParse(m['billing_date']?.toString() ?? '') ?? DateTime.now(),
            dueDate: m['due_date'] != null ? DateTime.tryParse(m['due_date'].toString()) : null,
            note: m['note']?.toString(),
            isSplitEqually: m['is_split_equally'] == true || m['is_split_equally'] == 'true' || m['is_split_equally'] == '1',
            pgId: m['pg']?.toString() ?? pgId,
          );
        }).toList();
    } catch (_) {
      final cached = _settings.get('cache.utilities_$pgId');
      if (cached is List) {
        return cached.map((e) {
          final m = Map<String, dynamic>.from(e as Map);
          final typeStr = (m['utility_type'] ?? 'other').toString().toLowerCase();
          return UtilityModel(
            id: m['id']?.toString() ?? '',
            type: typeStr.contains('electricity')
                ? UtilityType.electricity
                : typeStr.contains('water')
                    ? UtilityType.water
                    : typeStr.contains('internet')
                        ? UtilityType.internet
                        : UtilityType.other,
            totalAmount: double.tryParse(m['total_amount']?.toString() ?? '0') ?? 0,
            billMonth: DateTime.tryParse(m['billing_date']?.toString() ?? '') ?? DateTime.now(),
            dueDate: m['due_date'] != null ? DateTime.tryParse(m['due_date'].toString()) : null,
            note: m['note']?.toString(),
            isSplitEqually: m['is_split_equally'] == true || m['is_split_equally'] == 'true' || m['is_split_equally'] == '1',
            pgId: m['pg']?.toString() ?? pgId,
          );
        }).toList();
      }
      return [];
    }
  }

  Future<UtilityModel> createUtility(UtilityModel utility) async {
    final client = ApiClient(authStorage: _authStorage);
    final typeStr = utility.type == UtilityType.electricity
        ? 'electricity'
        : utility.type == UtilityType.water
            ? 'water'
            : utility.type == UtilityType.internet
                ? 'internet'
                : 'other';
    final body = {
      'utility_type': typeStr,
      'total_amount': utility.totalAmount,
      'units': utility.totalAmount,
      'rate': 1.0,
      'billing_date': utility.billMonth.toIso8601String().split('T').first,
      if (utility.dueDate != null) 'due_date': utility.dueDate!.toIso8601String().split('T').first,
      if (utility.note != null) 'note': utility.note,
      'is_split_equally': utility.isSplitEqually,
      'pg': utility.pgId,
    };

    final data = await client.post('/api/utilities/utilities/', body);
    final typeStrResp = (data['utility_type'] ?? 'other').toString().toLowerCase();
    return UtilityModel(
      id: data['id']?.toString() ?? utility.id,
      type: typeStrResp.contains('electricity')
          ? UtilityType.electricity
          : typeStrResp.contains('water')
              ? UtilityType.water
              : typeStrResp.contains('internet')
                  ? UtilityType.internet
                  : UtilityType.other,
      totalAmount: double.tryParse(data['total_amount']?.toString() ?? '${utility.totalAmount}') ?? utility.totalAmount,
      billMonth: DateTime.tryParse(data['billing_date']?.toString() ?? '') ?? utility.billMonth,
      dueDate: data['due_date'] != null ? DateTime.tryParse(data['due_date'].toString()) : utility.dueDate,
      note: data['note']?.toString() ?? utility.note,
      isSplitEqually: data['is_split_equally'] == true || data['is_split_equally'] == 'true' || data['is_split_equally'] == '1',
      pgId: data['pg']?.toString() ?? utility.pgId,
    );
  }
}

