enum InvoiceStatus {
  overdue,
  unpaid,
  grace,
  paid,
  securityDeposit,
}

class Invoice {
  final String id;
  final String tenantId;
  final String roomId;
  final String invoiceNumber;
  final String tenantName;
  final String tenantInitials;
  final String roomInfo;
  final InvoiceStatus status;
  final String statusBadgeText;
  final double totalAmount;
  final double paidAmount;
  final double outstandingAmount;
  final double discount;
  final double lateFee;
  final String? breakdownNote;
  final String? paymentDetail;
  final String? transactionRef;
  final String? dueDate;
  final String? graceDeadline;
  final String? periodStart;
  final String? periodEnd;
  final String billingCycle;

  const Invoice({
    required this.id,
    this.tenantId = '',
    this.roomId = '',
    required this.invoiceNumber,
    required this.tenantName,
    required this.tenantInitials,
    required this.roomInfo,
    required this.status,
    required this.statusBadgeText,
    required this.totalAmount,
    this.paidAmount = 0,
    required this.outstandingAmount,
    this.discount = 0,
    this.lateFee = 0,
    this.breakdownNote,
    this.paymentDetail,
    this.transactionRef,
    this.dueDate,
    this.graceDeadline,
    this.periodStart,
    this.periodEnd,
    this.billingCycle = 'Current Cycle',
  });

  bool get isFullyPaid => outstandingAmount <= 0;
  double get paidProgress => totalAmount > 0 ? (paidAmount / totalAmount).clamp(0.0, 1.0) : 0.0;

  Invoice copyWith({
    String? id,
    String? tenantId,
    String? roomId,
    String? invoiceNumber,
    String? tenantName,
    String? tenantInitials,
    String? roomInfo,
    InvoiceStatus? status,
    String? statusBadgeText,
    double? totalAmount,
    double? paidAmount,
    double? outstandingAmount,
    double? discount,
    double? lateFee,
    String? breakdownNote,
    String? paymentDetail,
    String? transactionRef,
    String? dueDate,
    String? graceDeadline,
    String? periodStart,
    String? periodEnd,
    String? billingCycle,
  }) {
    return Invoice(
      id: id ?? this.id,
      tenantId: tenantId ?? this.tenantId,
      roomId: roomId ?? this.roomId,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      tenantName: tenantName ?? this.tenantName,
      tenantInitials: tenantInitials ?? this.tenantInitials,
      roomInfo: roomInfo ?? this.roomInfo,
      status: status ?? this.status,
      statusBadgeText: statusBadgeText ?? this.statusBadgeText,
      totalAmount: totalAmount ?? this.totalAmount,
      paidAmount: paidAmount ?? this.paidAmount,
      outstandingAmount: outstandingAmount ?? this.outstandingAmount,
      discount: discount ?? this.discount,
      lateFee: lateFee ?? this.lateFee,
      breakdownNote: breakdownNote ?? this.breakdownNote,
      paymentDetail: paymentDetail ?? this.paymentDetail,
      transactionRef: transactionRef ?? this.transactionRef,
      dueDate: dueDate ?? this.dueDate,
      graceDeadline: graceDeadline ?? this.graceDeadline,
      periodStart: periodStart ?? this.periodStart,
      periodEnd: periodEnd ?? this.periodEnd,
      billingCycle: billingCycle ?? this.billingCycle,
    );
  }
}
