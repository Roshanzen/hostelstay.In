enum BedStatus { available, occupied, reserved }

class BedModel {
  BedModel({
    this.id = '',
    this.roomId = '',
    this.label = '',
    this.rent = 0,
    this.status = BedStatus.available,
    this.tenantId,
    this.pgId = '',
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();
  final String id;
  final String roomId;
  final String label;
  final double rent;
  final BedStatus status;
  final String? tenantId;
  final String pgId;
  final DateTime createdAt;

  BedModel copyWith({
    String? id,
    String? roomId,
    String? label,
    double? rent,
    BedStatus? status,
    String? tenantId,
    String? pgId,
    DateTime? createdAt,
  }) {
    return BedModel(
      id: id ?? this.id,
      roomId: roomId ?? this.roomId,
      label: label ?? this.label,
      rent: rent ?? this.rent,
      status: status ?? this.status,
      tenantId: tenantId ?? this.tenantId,
      pgId: pgId ?? this.pgId,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
