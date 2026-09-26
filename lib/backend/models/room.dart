enum RoomStatus { available, occupied, full, maintenance }

class Room {
  Room({
    required this.id,
    required this.roomNumber,
    this.capacity = 1,
    this.rentAmount = 0,
    this.pgId = '',
    this.status = RoomStatus.available,
  });
  final String id;
  final String roomNumber;
  final int capacity;
  final double rentAmount;
  final String pgId;
  final RoomStatus status;

  Room copyWith({
    String? id,
    String? roomNumber,
    int? capacity,
    double? rentAmount,
    String? pgId,
    RoomStatus? status,
  }) {
    return Room(
      id: id ?? this.id,
      roomNumber: roomNumber ?? this.roomNumber,
      capacity: capacity ?? this.capacity,
      rentAmount: rentAmount ?? this.rentAmount,
      pgId: pgId ?? this.pgId,
      status: status ?? this.status,
    );
  }
}
