class RentCycle {
  RentCycle({
    required this.id,
    required this.pgId,
    required this.billingMonth,
    required this.generatedAt,
    required this.totalTenantsBilled,
    required this.totalAmountBilled,
  });
  final String id;
  final String pgId;
  final String billingMonth;
  final DateTime generatedAt;
  final int totalTenantsBilled;
  final double totalAmountBilled;

  RentCycle copyWith({
    String? id,
    String? pgId,
    String? billingMonth,
    DateTime? generatedAt,
    int? totalTenantsBilled,
    double? totalAmountBilled,
  }) {
    return RentCycle(
      id: id ?? this.id,
      pgId: pgId ?? this.pgId,
      billingMonth: billingMonth ?? this.billingMonth,
      generatedAt: generatedAt ?? this.generatedAt,
      totalTenantsBilled: totalTenantsBilled ?? this.totalTenantsBilled,
      totalAmountBilled: totalAmountBilled ?? this.totalAmountBilled,
    );
  }
}
