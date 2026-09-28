import 'package:hive/hive.dart';
import '../../backend/models/invoice.dart';
import '../core/api_client.dart';
import '../core/storage/auth_storage.dart';

class InvoiceRepository {
  InvoiceRepository(this._settings, this._authStorage);
  final Box<dynamic> _settings;
  final AuthStorage _authStorage;

  Future<List<InvoiceModel>> fetchForPg(String pgId) async {
    try {
      final client = ApiClient(authStorage: _authStorage);
      final data = await client.get('/api/invoices/invoices/?pg=$pgId');
      final list = (data['results'] ?? data['value'] ?? <dynamic>[]) as List<dynamic>;
      final result = list.map((e) {
        final m = Map<String, dynamic>.from(e as Map);
        return InvoiceModel.fromJson(m);
      }).toList();
      await _settings.put('cache.invoices_$pgId', list);
      return result;
    } catch (_) {
      final cached = _settings.get('cache.invoices_$pgId');
      if (cached is List) {
        return cached.map((e) {
          final m = Map<String, dynamic>.from(e as Map);
          return InvoiceModel.fromJson(m);
        }).toList();
      }
      return [];
    }
  }

  Future<InvoiceModel> createInvoice(InvoiceModel invoice) async {
    final client = ApiClient(authStorage: _authStorage);
    final body = {
      'tenant': invoice.tenantId,
      if (invoice.roomId != null && invoice.roomId!.isNotEmpty) 'room': invoice.roomId,
      if (invoice.bedId != null && invoice.bedId!.isNotEmpty) 'bed': invoice.bedId,
      'type': invoice.type.name,
      'amount': invoice.amount,
      'discount': invoice.discount,
      'late_fee': invoice.lateFee,
      'paid_amount': invoice.paidAmount,
      'status': invoice.status == InvoiceStatus.paid
          ? 'paid'
          : invoice.status == InvoiceStatus.partial
              ? 'partial'
              : 'pending',
      'due_date': invoice.dueDate.toIso8601String().split('T').first,
      if (invoice.billingDate != null)
        'billing_date': invoice.billingDate!.toIso8601String().split('T').first,
      if (invoice.periodStart != null) 'period_start': invoice.periodStart,
      if (invoice.periodEnd != null) 'period_end': invoice.periodEnd,
      if (invoice.note != null) 'notes': invoice.note,
      'pg': invoice.pgId,
    };
    final data = await client.post('/api/invoices/invoices/', body);
    return InvoiceModel.fromJson(Map<String, dynamic>.from(data as Map));
  }

  Future<InvoiceModel> updateInvoice(InvoiceModel invoice) async {
    final client = ApiClient(authStorage: _authStorage);
    final path = '/api/invoices/invoices/${invoice.id}/';
    final body = <String, dynamic>{
      if (invoice.tenantId.isNotEmpty) 'tenant': invoice.tenantId,
      if (invoice.roomId != null && invoice.roomId!.isNotEmpty) 'room': invoice.roomId,
      if (invoice.bedId != null && invoice.bedId!.isNotEmpty) 'bed': invoice.bedId,
      'amount': invoice.amount,
      'discount': invoice.discount,
      'late_fee': invoice.lateFee,
      'paid_amount': invoice.paidAmount,
      'status': invoice.status == InvoiceStatus.paid
          ? 'paid'
          : invoice.status == InvoiceStatus.partial
              ? 'partial'
              : 'pending',
      'due_date': invoice.dueDate.toIso8601String().split('T').first,
      if (invoice.note != null) 'notes': invoice.note,
    };
    final data = await client.patch(path, body);
    return InvoiceModel.fromJson(Map<String, dynamic>.from(data as Map));
  }
}
