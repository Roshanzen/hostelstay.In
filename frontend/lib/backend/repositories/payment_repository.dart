import 'package:hive/hive.dart';
import '../../backend/models/payment.dart';
import '../../backend/models/payment_allocation.dart';
import '../core/api_client.dart';
import '../core/storage/auth_storage.dart';

class PaymentRepository {
  PaymentRepository(this._settings, this._authStorage);
  final Box<dynamic> _settings;
  final AuthStorage _authStorage;

  Payment _mapPayment(Map<String, dynamic> m, String pgId) {
    final methodStr = (m['payment_method'] ?? 'cash').toString().toLowerCase();
    final rawAllocs = (m['allocations'] as List<dynamic>? ?? []);
    final allocs = rawAllocs
        .map((a) => PaymentAllocation.fromJson(Map<String, dynamic>.from(a as Map)))
        .toList();

    return Payment(
      id: m['id']?.toString() ?? '',
      tenantId: m['tenant']?.toString() ?? '',
      amount: double.tryParse(m['amount']?.toString() ?? '0') ?? 0,
      date: DateTime.tryParse(m['payment_date']?.toString() ?? '') ?? DateTime.now(),
      method: methodStr.contains('esewa')
          ? PaymentMethod.esewa
          : methodStr.contains('khalti')
              ? PaymentMethod.khalti
              : methodStr.contains('fonepay')
                  ? PaymentMethod.fonepay
                  : methodStr.contains('bank')
                      ? PaymentMethod.bankTransfer
                      : PaymentMethod.cash,
      reference: m['reference']?.toString(),
      receiptNumber: m['receipt_number']?.toString(),
      notes: m['notes']?.toString(),
      isVoided: m['is_voided'] == true,
      monthCovered: m['month_covered']?.toString(),
      invoiceId: m['invoice']?.toString(),
      pgId: m['pg']?.toString() ?? pgId,
      allocations: allocs,
    );
  }

  Future<List<Payment>> fetchForPg(String pgId) async {
    try {
      final client = ApiClient(authStorage: _authStorage);
      final data = await client.get('/api/payments/payments/?pg=$pgId');
      final list = (data['results'] ?? data['value'] ?? <dynamic>[]) as List<dynamic>;
      final result = list.map((e) {
        final m = Map<String, dynamic>.from(e as Map);
        return _mapPayment(m, pgId);
      }).toList();
      await _settings.put('cache.payments_$pgId', list);
      return result;
    } catch (_) {
      final cached = _settings.get('cache.payments_$pgId');
      if (cached is List) {
        return cached.map((e) {
          final m = Map<String, dynamic>.from(e as Map);
          return _mapPayment(m, pgId);
        }).toList();
      }
      return [];
    }
  }

  Future<Payment> createPayment(Payment payment) async {
    final client = ApiClient(authStorage: _authStorage);
    final methodStr = payment.method == PaymentMethod.esewa
        ? 'esewa'
        : payment.method == PaymentMethod.khalti
            ? 'khalti'
            : payment.method == PaymentMethod.fonepay
                ? 'fonepay'
                : payment.method == PaymentMethod.bankTransfer
                    ? 'bankTransfer'
                    : 'cash';
    final body = {
      'tenant': payment.tenantId,
      'amount': payment.amount,
      'payment_date': payment.date.toIso8601String().split('T').first,
      'payment_method': methodStr,
      if (payment.reference != null && payment.reference!.isNotEmpty) 'reference': payment.reference,
      if (payment.notes != null && payment.notes!.isNotEmpty) 'notes': payment.notes,
      if (payment.monthCovered != null) 'month_covered': payment.monthCovered,
      if (payment.invoiceId != null && payment.invoiceId!.isNotEmpty) 'invoice': payment.invoiceId,
      'pg': payment.pgId,
    };
    final data = await client.post('/api/payments/payments/', body);
    return _mapPayment(Map<String, dynamic>.from(data as Map), payment.pgId);
  }
}
