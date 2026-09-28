enum ExpenseCategory { water, electricity, maintenance, other }

class Expense {
  Expense({
    this.id = '',
    required this.category,
    required this.amount,
    required this.date,
    this.note,
    this.pgId = '',
  });
  final String id;
  final ExpenseCategory category;
  final double amount;
  final DateTime date;
  final String? note;
  final String pgId;
}
