class TenantBillingSummary {
  final String tenantId;
  final String tenantName;
  final String billingFrequency;
  final double monthlyRent;
  final double discount;
  final int gracePeriodDays;
  final String? contractStart;
  final String? contractEnd;
  final double totalInvoiced;
  final double totalPaid;
  final double totalOutstanding;
  final double overdueAmount;
  final int overdueCount;
  final Map<String, dynamic>? nextInvoice;
  final List<Map<String, dynamic>> recentPayments;

  const TenantBillingSummary({
    required this.tenantId,
    required this.tenantName,
    this.billingFrequency = 'monthly',
    this.monthlyRent = 0.0,
    this.discount = 0.0,
    this.gracePeriodDays = 5,
    this.contractStart,
    this.contractEnd,
    this.totalInvoiced = 0.0,
    this.totalPaid = 0.0,
    this.totalOutstanding = 0.0,
    this.overdueAmount = 0.0,
    this.overdueCount = 0,
    this.nextInvoice,
    this.recentPayments = const [],
  });

  factory TenantBillingSummary.fromJson(Map<String, dynamic> json) {
    return TenantBillingSummary(
      tenantId: json['tenant_id']?.toString() ?? '',
      tenantName: json['tenant_name']?.toString() ?? '',
      billingFrequency: json['billing_frequency']?.toString() ?? 'monthly',
      monthlyRent: double.tryParse(json['monthly_rent']?.toString() ?? '0') ?? 0.0,
      discount: double.tryParse(json['discount']?.toString() ?? '0') ?? 0.0,
      gracePeriodDays: int.tryParse(json['grace_period_days']?.toString() ?? '5') ?? 5,
      contractStart: json['contract_start']?.toString(),
      contractEnd: json['contract_end']?.toString(),
      totalInvoiced: double.tryParse(json['total_invoiced']?.toString() ?? '0') ?? 0.0,
      totalPaid: double.tryParse(json['total_paid']?.toString() ?? '0') ?? 0.0,
      totalOutstanding: double.tryParse(json['total_outstanding']?.toString() ?? '0') ?? 0.0,
      overdueAmount: double.tryParse(json['overdue_amount']?.toString() ?? '0') ?? 0.0,
      overdueCount: int.tryParse(json['overdue_count']?.toString() ?? '0') ?? 0,
      nextInvoice: json['next_invoice'] != null ? Map<String, dynamic>.from(json['next_invoice'] as Map) : null,
      recentPayments: (json['recent_payments'] as List<dynamic>? ?? [])
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList(),
    );
  }
}
