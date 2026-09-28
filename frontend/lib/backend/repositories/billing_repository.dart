import 'package:hive/hive.dart';
import '../core/api_client.dart';
import '../core/storage/auth_storage.dart';
import '../models/billing_summary.dart';
import '../models/invoice.dart';
import '../models/tenant_billing_summary.dart';

class BillingRepository {
  BillingRepository(this._settings, this._authStorage);
  final Box<dynamic> _settings;
  final AuthStorage _authStorage;

  Future<BillingSummary> fetchSummary(String pgId) async {
    try {
      final client = ApiClient(authStorage: _authStorage);
      final data = await client.get('/api/billing/summary/?pg=$pgId');
      final summary = BillingSummary.fromJson(Map<String, dynamic>.from(data as Map));
      await _settings.put('cache.billing_summary_$pgId', data);
      return summary;
    } catch (_) {
      final cached = _settings.get('cache.billing_summary_$pgId');
      if (cached is Map) {
        return BillingSummary.fromJson(Map<String, dynamic>.from(cached));
      }
      return BillingSummary.empty;
    }
  }

  Future<TenantBillingSummary?> fetchTenantSummary(String tenantId) async {
    try {
      final client = ApiClient(authStorage: _authStorage);
      final data = await client.get('/api/billing/tenant-summary/$tenantId/');
      return TenantBillingSummary.fromJson(Map<String, dynamic>.from(data as Map));
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, dynamic>> recordPayment({
    required String tenantId,
    required String pgId,
    required double amount,
    required String paymentMethod,
    String? invoiceId,
    String? reference,
    String? notes,
    DateTime? paymentDate,
  }) async {
    final client = ApiClient(authStorage: _authStorage);
    final body = {
      'tenant': tenantId,
      'pg': pgId,
      'amount': amount,
      'payment_method': _normalizeMethod(paymentMethod),
      if (invoiceId != null && invoiceId.isNotEmpty) 'invoice': invoiceId,
      if (reference != null && reference.isNotEmpty) 'reference': reference,
      if (notes != null && notes.isNotEmpty) 'notes': notes,
      'payment_date': (paymentDate ?? DateTime.now()).toIso8601String().split('T').first,
    };
    final data = await client.post('/api/billing/record-payment/', body);
    return Map<String, dynamic>.from(data as Map);
  }

  Future<void> voidInvoice(String invoiceId, String reason) async {
    final client = ApiClient(authStorage: _authStorage);
    await client.post('/api/billing/void-invoice/$invoiceId/', {'reason': reason});
  }

  Future<List<InvoiceModel>> fetchOverdue(String pgId) async {
    try {
      final client = ApiClient(authStorage: _authStorage);
      final data = await client.get('/api/billing/overdue/?pg=$pgId');
      final list = (data['results'] ?? []) as List<dynamic>;
      return list.map((e) => InvoiceModel.fromJson(Map<String, dynamic>.from(e as Map))).toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<InvoiceModel>> fetchUpcoming(String pgId) async {
    try {
      final client = ApiClient(authStorage: _authStorage);
      final data = await client.get('/api/billing/upcoming/?pg=$pgId');
      final list = (data['results'] ?? []) as List<dynamic>;
      return list.map((e) => InvoiceModel.fromJson(Map<String, dynamic>.from(e as Map))).toList();
    } catch (_) {
      return [];
    }
  }

  Future<Map<String, dynamic>> generatePeriodInvoices({
    required String pgId,
    String? tenantId,
    int periodsAhead = 1,
  }) async {
    final client = ApiClient(authStorage: _authStorage);
    final body = {
      'pg': pgId,
      if (tenantId != null && tenantId.isNotEmpty) 'tenant': tenantId,
      'periods_ahead': periodsAhead,
    };
    final data = await client.post('/api/billing/generate-period-invoices/', body);
    return Map<String, dynamic>.from(data as Map);
  }

  Future<void> refreshStatuses(String pgId) async {
    try {
      final client = ApiClient(authStorage: _authStorage);
      await client.post('/api/billing/refresh-statuses/', {'pg': pgId});
    } catch (_) {}
  }

  String _normalizeMethod(String m) {
    final lower = m.toLowerCase();
    if (lower.contains('esewa')) return 'esewa';
    if (lower.contains('khalti')) return 'khalti';
    if (lower.contains('fonepay')) return 'fonepay';
    if (lower.contains('bank')) return 'bankTransfer';
    return 'cash';
  }
}
