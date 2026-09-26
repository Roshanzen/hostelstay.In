import 'payment_allocation.dart';

enum PaymentMethod { cash, esewa, khalti, fonepay, bankTransfer, other }

class Payment {
  Payment({
    this.id = '',
    required this.tenantId,
    required this.amount,
    required this.date,
    required this.method,
    this.reference,
    this.receiptNumber,
    this.notes,
    this.isVoided = false,
    this.monthCovered,
    this.invoiceId,
    this.pgId = '',
    this.allocations = const [],
  });

  final String id;
  final String tenantId;
  final double amount;
  final DateTime date;
  final PaymentMethod method;
  final String? reference;
  final String? receiptNumber;
  final String? notes;
  final bool isVoided;
  final String? monthCovered;
  final String? invoiceId;
  final String pgId;
  final List<PaymentAllocation> allocations;

  Payment copyWith({
    String? id,
    String? tenantId,
    double? amount,
    DateTime? date,
    PaymentMethod? method,
    String? reference,
    String? receiptNumber,
    String? notes,
    bool? isVoided,
    String? monthCovered,
    String? invoiceId,
    String? pgId,
    List<PaymentAllocation>? allocations,
  }) {
    return Payment(
      id: id ?? this.id,
      tenantId: tenantId ?? this.tenantId,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      method: method ?? this.method,
      reference: reference ?? this.reference,
      receiptNumber: receiptNumber ?? this.receiptNumber,
      notes: notes ?? this.notes,
      isVoided: isVoided ?? this.isVoided,
      monthCovered: monthCovered ?? this.monthCovered,
      invoiceId: invoiceId ?? this.invoiceId,
      pgId: pgId ?? this.pgId,
      allocations: allocations ?? this.allocations,
    );
  }
}
