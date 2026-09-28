enum TicketStatus { open, inProgress, resolved, closed }
enum TicketPriority { low, medium, high, critical }
enum TicketCategory { plumbing, electrical, cleaning, other }

class TicketModel {
  TicketModel({
    this.id = '',
    required this.title,
    this.description,
    required this.category,
    this.roomId = '',
    required this.priority,
    this.status = TicketStatus.open,
    this.costIncurred,
    required this.createdAt,
    this.pgId = '',
  });
  final String id;
  final String title;
  final String? description;
  final TicketCategory category;
  final String roomId;
  final TicketPriority priority;
  final TicketStatus status;
  final double? costIncurred;
  final DateTime createdAt;
  final String pgId;

  TicketModel copyWith({
    String? id,
    String? title,
    String? description,
    TicketCategory? category,
    String? roomId,
    TicketPriority? priority,
    TicketStatus? status,
    double? costIncurred,
    DateTime? createdAt,
    String? pgId,
  }) {
    return TicketModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      roomId: roomId ?? this.roomId,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      costIncurred: costIncurred ?? this.costIncurred,
      createdAt: createdAt ?? this.createdAt,
      pgId: pgId ?? this.pgId,
    );
  }
}
