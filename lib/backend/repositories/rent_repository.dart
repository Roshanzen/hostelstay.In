import 'package:hive/hive.dart';
import '../../backend/models/rent_cycle.dart';
import '../core/api_client.dart';
import '../core/storage/auth_storage.dart';

class RentRepository {
  RentRepository(this._settings, this._authStorage);
  final Box<dynamic> _settings;
  final AuthStorage _authStorage;

  Future<List<RentCycle>> fetchForPg(String pgId) async {
    try {
      final client = ApiClient(authStorage: _authStorage);
      final data = await client.get('/api/rent/cycles/?pg=$pgId');
      final list = (data['results'] ?? data['value'] ?? <dynamic>[]) as List<dynamic>;
      final result = list.map((e) {
        final m = Map<String, dynamic>.from(e as Map);
        return RentCycle(
          id: m['id']?.toString() ?? '',
          pgId: m['pg']?.toString() ?? pgId,
          billingMonth: m['billing_month']?.toString() ?? '',
          generatedAt: DateTime.tryParse(m['generated_at']?.toString() ?? '') ?? DateTime.now(),
          totalTenantsBilled: m['total_tenants_billed'] is int
              ? m['total_tenants_billed'] as int
              : int.tryParse(m['total_tenants_billed']?.toString() ?? '0') ?? 0,
          totalAmountBilled: double.tryParse(m['total_amount_billed']?.toString() ?? '0') ?? 0,
        );
      }).toList();
      await _settings.put('cache.rent_cycles_$pgId', list);
      return result;
    } catch (_) {
      final cached = _settings.get('cache.rent_cycles_$pgId');
      if (cached is List) {
        return cached.map((e) {
          final m = Map<String, dynamic>.from(e as Map);
          return RentCycle(
            id: m['id']?.toString() ?? '',
            pgId: m['pg']?.toString() ?? pgId,
            billingMonth: m['billing_month']?.toString() ?? '',
            generatedAt: DateTime.tryParse(m['generated_at']?.toString() ?? '') ?? DateTime.now(),
            totalTenantsBilled: m['total_tenants_billed'] is int
                ? m['total_tenants_billed'] as int
                : int.tryParse(m['total_tenants_billed']?.toString() ?? '0') ?? 0,
            totalAmountBilled: double.tryParse(m['total_amount_billed']?.toString() ?? '0') ?? 0,
          );
        }).toList();
      }
      return [];
    }
  }

  Future<Map<String, dynamic>> generateInvoices({
    required String pgId,
    required String billingMonth,
    int dueDays = 10,
  }) async {
    final client = ApiClient(authStorage: _authStorage);
    final body = {
      'pg': int.tryParse(pgId) ?? pgId,
      'billing_month': billingMonth,
      'due_days': dueDays,
    };
    return await client.post('/api/rent/generate-invoices/', body);
  }
}
