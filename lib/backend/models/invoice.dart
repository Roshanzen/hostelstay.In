enum InvoiceStatus { unpaid, pending, partial, overdue, paid, draft, cancelled, voided }
enum InvoiceType { rent, expense, meal, utility, fine, maintenance, deposit, other }

class InvoiceModel {
  InvoiceModel({
    this.id = '',
    required this.tenantId,
    this.roomId,
    this.bedId,
    required this.type,
    required this.amount,
    this.paidAmount = 0,
    this.discount = 0,
    this.lateFee = 0,
    this.gracePeriodDays = 0,
    required this.status,
    required this.dueDate,
    this.billingDate,
    this.paidDate,
    this.periodStart,
    this.periodEnd,
    this.invoiceNumber,
    this.note,
    this.isVoided = false,
    DateTime? createdAt,
    this.pgId = '',
  }) : createdAt = createdAt ?? DateTime.now();

  final String id;
  final String tenantId;
  final String? roomId;
  final String? bedId;
  final InvoiceType type;
  final double amount;
  final double paidAmount;
  final double discount;
  final double lateFee;
  final int gracePeriodDays;
  final InvoiceStatus status;
  final DateTime dueDate;
  final DateTime? billingDate;
  final DateTime? paidDate;
  final String? periodStart;
  final String? periodEnd;
  final String? invoiceNumber;
  final String? note;
  final bool isVoided;
  final DateTime createdAt;
  final String pgId;

  double get netAmount => (amount + lateFee - discount).clamp(0.0, double.infinity);
  double get remainingAmount => (netAmount - paidAmount).clamp(0.0, double.infinity);
  bool get isOverdue => status == InvoiceStatus.overdue;
  bool get isPaid => status == InvoiceStatus.paid;
  bool get isPending => status == InvoiceStatus.pending;
  bool get isPartial => status == InvoiceStatus.partial;

  String get displayPeriod {
    if (periodStart == null) return '';
    if (periodEnd == null) return periodStart!;
    return '$periodStart to $periodEnd';
  }

  factory InvoiceModel.fromJson(Map<String, dynamic> json) {
    final statusStr = (json['status'] ?? 'pending').toString().toLowerCase();
    final typeStr = (json['type'] ?? 'rent').toString().toLowerCase();

    InvoiceType parsedType = InvoiceType.rent;
    if (typeStr == 'utility') {
      parsedType = InvoiceType.utility;
    } else if (typeStr == 'meal') {
      parsedType = InvoiceType.meal;
    } else if (typeStr == 'expense') {
      parsedType = InvoiceType.expense;
    } else if (typeStr == 'deposit') {
      parsedType = InvoiceType.deposit;
    } else if (typeStr == 'maintenance') {
      parsedType = InvoiceType.maintenance;
    } else if (typeStr == 'fine') {
      parsedType = InvoiceType.fine;
    }

    InvoiceStatus parsedStatus = InvoiceStatus.pending;
    if (statusStr == 'paid') {
      parsedStatus = InvoiceStatus.paid;
    } else if (statusStr == 'partial') {
      parsedStatus = InvoiceStatus.partial;
    } else if (statusStr == 'overdue') {
      parsedStatus = InvoiceStatus.overdue;
    } else if (statusStr == 'cancelled') {
      parsedStatus = InvoiceStatus.cancelled;
    } else if (statusStr == 'void') {
      parsedStatus = InvoiceStatus.voided;
    } else if (statusStr == 'draft') {
      parsedStatus = InvoiceStatus.draft;
    } else if (statusStr == 'unpaid') {
      parsedStatus = InvoiceStatus.unpaid;
    }

    return InvoiceModel(
      id: json['id']?.toString() ?? '',
      tenantId: json['tenant']?.toString() ?? json['tenant_id']?.toString() ?? '',
      roomId: json['room']?.toString() ?? json['room_id']?.toString(),
      bedId: json['bed']?.toString() ?? json['bed_id']?.toString(),
      type: parsedType,
      amount: double.tryParse(json['amount']?.toString() ?? '0') ?? 0.0,
      paidAmount: double.tryParse(json['paid_amount']?.toString() ?? '0') ?? 0.0,
      discount: double.tryParse(json['discount']?.toString() ?? '0') ?? 0.0,
      lateFee: double.tryParse(json['late_fee']?.toString() ?? '0') ?? 0.0,
      gracePeriodDays: int.tryParse(json['grace_period_days']?.toString() ?? '0') ?? 0,
      status: parsedStatus,
      dueDate: DateTime.tryParse(json['due_date']?.toString() ?? '') ?? DateTime.now(),
      billingDate: json['billing_date'] != null ? DateTime.tryParse(json['billing_date'].toString()) : null,
      paidDate: json['paid_date'] != null ? DateTime.tryParse(json['paid_date'].toString()) : null,
      periodStart: json['period_start']?.toString(),
      periodEnd: json['period_end']?.toString(),
      invoiceNumber: json['invoice_number']?.toString(),
      note: json['notes']?.toString() ?? json['note']?.toString(),
      isVoided: json['is_voided'] == true,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) : null,
      pgId: json['pg']?.toString() ?? json['pg_id']?.toString() ?? '',
    );
  }

  InvoiceModel copyWith({
    String? id,
    String? tenantId,
    String? roomId,
    String? bedId,
    InvoiceType? type,
    double? amount,
    double? paidAmount,
    double? discount,
    double? lateFee,
    int? gracePeriodDays,
    InvoiceStatus? status,
    DateTime? dueDate,
    DateTime? billingDate,
    DateTime? paidDate,
    String? periodStart,
    String? periodEnd,
    String? invoiceNumber,
    String? note,
    bool? isVoided,
    DateTime? createdAt,
    String? pgId,
  }) {
    return InvoiceModel(
      id: id ?? this.id,
      tenantId: tenantId ?? this.tenantId,
      roomId: roomId ?? this.roomId,
      bedId: bedId ?? this.bedId,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      paidAmount: paidAmount ?? this.paidAmount,
      discount: discount ?? this.discount,
      lateFee: lateFee ?? this.lateFee,
      gracePeriodDays: gracePeriodDays ?? this.gracePeriodDays,
      status: status ?? this.status,
      dueDate: dueDate ?? this.dueDate,
      billingDate: billingDate ?? this.billingDate,
      paidDate: paidDate ?? this.paidDate,
      periodStart: periodStart ?? this.periodStart,
      periodEnd: periodEnd ?? this.periodEnd,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      note: note ?? this.note,
      isVoided: isVoided ?? this.isVoided,
      createdAt: createdAt ?? this.createdAt,
      pgId: pgId ?? this.pgId,
    );
  }
}
