class RentCycle {
  const RentCycle({
    required this.id,
    required this.billingMonth,
    required this.generatedAt,
    required this.totalTenantsBilled,
    required this.totalAmountBilled,
  });
  final String id;
  final String billingMonth;
  final DateTime generatedAt;
  final int totalTenantsBilled;
  final double totalAmountBilled;

  RentCycle copyWith({
    String? id,
    String? billingMonth,
    DateTime? generatedAt,
    int? totalTenantsBilled,
    double? totalAmountBilled,
  }) {
    return RentCycle(
      id: id ?? this.id,
      billingMonth: billingMonth ?? this.billingMonth,
      generatedAt: generatedAt ?? this.generatedAt,
      totalTenantsBilled: totalTenantsBilled ?? this.totalTenantsBilled,
      totalAmountBilled: totalAmountBilled ?? this.totalAmountBilled,
    );
  }
}
