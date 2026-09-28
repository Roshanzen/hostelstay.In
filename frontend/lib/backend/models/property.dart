class Property {
  Property({
    required this.id,
    required this.name,
    this.address = '',
    this.phone = '',
    this.email = '',
    this.totalRooms = 0,
    this.totalBeds = 0,
    this.occupiedBeds = 0,
    this.vacantBeds = 0,
    this.occupancyRate = 0.0,
    this.status = 'active',
    this.leadWardenName = '',
  });

  final String id;
  final String name;
  final String address;
  final String phone;
  final String email;
  final int totalRooms;
  final int totalBeds;
  final int occupiedBeds;
  final int vacantBeds;
  final double occupancyRate;
  final String status;
  final String leadWardenName;

  factory Property.fromJson(Map<String, dynamic> json) {
    final warden = json['lead_warden'];
    String wName = '';
    if (warden is Map) {
      wName = warden['name']?.toString() ?? '';
    }
    return Property(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      address: json['address']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      totalRooms: (json['total_rooms'] is int)
          ? json['total_rooms'] as int
          : (json['rooms_count'] is int)
              ? json['rooms_count'] as int
              : int.tryParse(json['total_rooms']?.toString() ?? '0') ?? 0,
      totalBeds: (json['total_beds'] is int)
          ? json['total_beds'] as int
          : int.tryParse(json['total_beds']?.toString() ?? '0') ?? 0,
      occupiedBeds: (json['occupied_beds'] is int)
          ? json['occupied_beds'] as int
          : int.tryParse(json['occupied_beds']?.toString() ?? '0') ?? 0,
      vacantBeds: (json['vacant_beds'] is int)
          ? json['vacant_beds'] as int
          : int.tryParse(json['vacant_beds']?.toString() ?? '0') ?? 0,
      occupancyRate: (json['occupancy_rate'] is num)
          ? (json['occupancy_rate'] as num).toDouble()
          : double.tryParse(json['occupancy_rate']?.toString() ?? '0') ?? 0.0,
      status: json['status']?.toString() ?? 'active',
      leadWardenName: wName,
    );
  }
}
