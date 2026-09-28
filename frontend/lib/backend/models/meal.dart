enum MealType { breakfast, lunch, dinner }

class MealModel {
  MealModel({
    this.id = '',
    required this.tenantId,
    required this.date,
    required this.mealType,
    this.attended = false,
    this.isExtra = false,
    this.extraCharge,
    DateTime? createdAt,
    this.pgId = '',
  }) : createdAt = createdAt ?? DateTime.now();
  final String id;
  final String tenantId;
  final DateTime date;
  final MealType mealType;
  final bool attended;
  final bool isExtra;
  final double? extraCharge;
  final DateTime createdAt;
  final String pgId;
}
