enum UtilityType { electricity, water, internet, other }

class UtilityModel {
  UtilityModel({
    this.id = '',
    required this.type,
    required this.totalAmount,
    required this.billMonth,
    this.dueDate,
    this.note,
    this.isSplitEqually = false,
    DateTime? createdAt,
    this.pgId = '',
  }) : createdAt = createdAt ?? DateTime.now();
  final String id;
  final UtilityType type;
  final double totalAmount;
  final DateTime billMonth;
  final DateTime? dueDate;
  final String? note;
  final bool isSplitEqually;
  final DateTime createdAt;
  final String pgId;
}
