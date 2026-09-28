class BillingSummary {
  final String pgId;
  final double totalInvoiced;
  final double totalCollected;
  final double totalOutstanding;
  final double overdueAmount;
  final double pendingAmount;
  final int invoiceCount;
  final int overdueCount;
  final int pendingCount;
  final int paidCount;
  final int partialCount;

  const BillingSummary({
    this.pgId = '',
    this.totalInvoiced = 0.0,
    this.totalCollected = 0.0,
    this.totalOutstanding = 0.0,
    this.overdueAmount = 0.0,
    this.pendingAmount = 0.0,
    this.invoiceCount = 0,
    this.overdueCount = 0,
    this.pendingCount = 0,
    this.paidCount = 0,
    this.partialCount = 0,
  });

  static const empty = BillingSummary();

  factory BillingSummary.fromJson(Map<String, dynamic> json) {
    return BillingSummary(
      pgId: json['pg_id']?.toString() ?? '',
      totalInvoiced: double.tryParse(json['total_invoiced']?.toString() ?? '0') ?? 0.0,
      totalCollected: double.tryParse(json['total_collected']?.toString() ?? '0') ?? 0.0,
      totalOutstanding: double.tryParse(json['total_outstanding']?.toString() ?? '0') ?? 0.0,
      overdueAmount: double.tryParse(json['overdue_amount']?.toString() ?? '0') ?? 0.0,
      pendingAmount: double.tryParse(json['pending_amount']?.toString() ?? '0') ?? 0.0,
      invoiceCount: int.tryParse(json['invoice_count']?.toString() ?? '0') ?? 0,
      overdueCount: int.tryParse(json['overdue_count']?.toString() ?? '0') ?? 0,
      pendingCount: int.tryParse(json['pending_count']?.toString() ?? '0') ?? 0,
      paidCount: int.tryParse(json['paid_count']?.toString() ?? '0') ?? 0,
      partialCount: int.tryParse(json['partial_count']?.toString() ?? '0') ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'pg_id': pgId,
    'total_invoiced': totalInvoiced,
    'total_collected': totalCollected,
    'total_outstanding': totalOutstanding,
    'overdue_amount': overdueAmount,
    'pending_amount': pendingAmount,
    'invoice_count': invoiceCount,
    'overdue_count': overdueCount,
    'pending_count': pendingCount,
    'paid_count': paidCount,
    'partial_count': partialCount,
  };
}
