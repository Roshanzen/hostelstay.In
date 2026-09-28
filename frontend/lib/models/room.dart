class RoomSlot {
  final String slotId; // 'A', 'B', 'C'
  final bool isOccupied;
  final String? tenantName;
  final String? tenantSubtitle;
  final String? paymentStatus; // 'Paid MTD', 'Due रु 2,500'
  final bool isVerified;
  final String? tenantPhone;

  const RoomSlot({
    required this.slotId,
    required this.isOccupied,
    this.tenantName,
    this.tenantSubtitle,
    this.paymentStatus,
    this.isVerified = false,
    this.tenantPhone,
  });

  RoomSlot copyWith({
    String? slotId,
    bool? isOccupied,
    String? tenantName,
    String? tenantSubtitle,
    String? paymentStatus,
    bool? isVerified,
    String? tenantPhone,
  }) {
    return RoomSlot(
      slotId: slotId ?? this.slotId,
      isOccupied: isOccupied ?? this.isOccupied,
      tenantName: tenantName ?? this.tenantName,
      tenantSubtitle: tenantSubtitle ?? this.tenantSubtitle,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      isVerified: isVerified ?? this.isVerified,
      tenantPhone: tenantPhone ?? this.tenantPhone,
    );
  }
}

class Room {
  final String id;
  final String roomNumber;
  final String floor;
  final String sharingType; // e.g. '2-Sharing AC'
  final double rentAmount;
  final int totalCapacity;
  final List<RoomSlot> slots;
  final List<String> amenities;
  final String? meterNumber;
  final bool isMaintenance;
  final String? maintenanceNote;

  const Room({
    required this.id,
    required this.roomNumber,
    required this.floor,
    required this.sharingType,
    required this.rentAmount,
    required this.totalCapacity,
    required this.slots,
    required this.amenities,
    this.meterNumber,
    this.isMaintenance = false,
    this.maintenanceNote,
  });

  int get occupiedCount => slots.where((s) => s.isOccupied).length;
  int get vacantCount => totalCapacity - occupiedCount;
  bool get isFull => occupiedCount >= totalCapacity;
  bool get isVacant => occupiedCount == 0;
  bool get isPartial => occupiedCount > 0 && occupiedCount < totalCapacity;

  String get statusBadgeText {
    if (isMaintenance) return 'Maintenance';
    if (isFull) return '$totalCapacity/$totalCapacity Full';
    if (isVacant) return 'Vacant (1/$totalCapacity)';
    return '$vacantCount/$totalCapacity Vacant';
  }

  Room copyWith({
    String? id,
    String? roomNumber,
    String? floor,
    String? sharingType,
    double rentAmount = 0,
    int? totalCapacity,
    List<RoomSlot>? slots,
    List<String>? amenities,
    String? meterNumber,
    bool? isMaintenance,
    String? maintenanceNote,
  }) {
    return Room(
      id: id ?? this.id,
      roomNumber: roomNumber ?? this.roomNumber,
      floor: floor ?? this.floor,
      sharingType: sharingType ?? this.sharingType,
      rentAmount: rentAmount != 0 ? rentAmount : this.rentAmount,
      totalCapacity: totalCapacity ?? this.totalCapacity,
      slots: slots ?? this.slots,
      amenities: amenities ?? this.amenities,
      meterNumber: meterNumber ?? this.meterNumber,
      isMaintenance: isMaintenance ?? this.isMaintenance,
      maintenanceNote: maintenanceNote ?? this.maintenanceNote,
    );
  }
}

