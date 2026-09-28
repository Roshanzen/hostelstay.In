enum ExpenseCategory {
  mess,
  utilities,
  salaries,
  maintenance,
  supplies,
  other,
}

class Expense {
  final String id;
  final String title;
  final ExpenseCategory category;
  final String categoryLabel;
  final String vendorOrLocation;
  final double amount;
  final String paymentMode; // 'eSewa Paid', 'Cash Voucher', 'Bank NEFT', etc.
  final String voucherDoc;
  final String transactionRef;
  final String timestamp;
  final String dateGroup; // 'TODAY • 12 OCT 2024', 'YESTERDAY • 11 OCT 2024', etc.

  const Expense({
    required this.id,
    required this.title,
    required this.category,
    required this.categoryLabel,
    required this.vendorOrLocation,
    required this.amount,
    required this.paymentMode,
    required this.voucherDoc,
    required this.transactionRef,
    required this.timestamp,
    required this.dateGroup,
  });

  Expense copyWith({
    String? id,
    String? title,
    ExpenseCategory? category,
    String? categoryLabel,
    String? vendorOrLocation,
    double? amount,
    String? paymentMode,
    String? voucherDoc,
    String? transactionRef,
    String? timestamp,
    String? dateGroup,
  }) {
    return Expense(
      id: id ?? this.id,
      title: title ?? this.title,
      category: category ?? this.category,
      categoryLabel: categoryLabel ?? this.categoryLabel,
      vendorOrLocation: vendorOrLocation ?? this.vendorOrLocation,
      amount: amount ?? this.amount,
      paymentMode: paymentMode ?? this.paymentMode,
      voucherDoc: voucherDoc ?? this.voucherDoc,
      transactionRef: transactionRef ?? this.transactionRef,
      timestamp: timestamp ?? this.timestamp,
      dateGroup: dateGroup ?? this.dateGroup,
    );
  }
}

