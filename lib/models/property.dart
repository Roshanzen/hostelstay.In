class Property {
  final String id;
  final String name;
  final String block;
  final String address;
  final int totalBeds;
  final int totalRooms;
  final int totalFloors;
  final int occupiedBeds;
  final String clearanceLevel;
  final String databaseSyncStatus;

  const Property({
    required this.id,
    required this.name,
    required this.block,
    required this.address,
    required this.totalBeds,
    required this.totalRooms,
    required this.totalFloors,
    required this.occupiedBeds,
    required this.clearanceLevel,
    required this.databaseSyncStatus,
  });

  double get occupancyRate => totalBeds > 0 ? (occupiedBeds / totalBeds) * 100 : 0.0;
}

