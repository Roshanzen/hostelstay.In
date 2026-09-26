class PaymentAllocation {
  final String id;
  final String paymentId;
  final String invoiceId;
  final String? invoiceNumber;
  final String? invoiceStatus;
  final double allocatedAmount;
  final DateTime allocatedAt;

  const PaymentAllocation({
    this.id = '',
    required this.paymentId,
    required this.invoiceId,
    this.invoiceNumber,
    this.invoiceStatus,
    required this.allocatedAmount,
    required this.allocatedAt,
  });

  factory PaymentAllocation.fromJson(Map<String, dynamic> json) {
    return PaymentAllocation(
      id: json['id']?.toString() ?? '',
      paymentId: json['payment']?.toString() ?? '',
      invoiceId: json['invoice']?.toString() ?? '',
      invoiceNumber: json['invoice_number']?.toString(),
      invoiceStatus: json['invoice_status']?.toString(),
      allocatedAmount: double.tryParse(json['allocated_amount']?.toString() ?? '0') ?? 0.0,
      allocatedAt: DateTime.tryParse(json['allocated_at']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'payment': paymentId,
    'invoice': invoiceId,
    if (invoiceNumber != null) 'invoice_number': invoiceNumber,
    if (invoiceStatus != null) 'invoice_status': invoiceStatus,
    'allocated_amount': allocatedAmount,
    'allocated_at': allocatedAt.toIso8601String(),
  };
}
