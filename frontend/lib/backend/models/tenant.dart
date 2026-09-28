enum TenantStatus { active, inactive, pending }

enum IdType { citizenship, passport, drivingLicense, other }

class Tenant {
  Tenant({
    this.id = '',
    required this.name,
    this.phone = '',
    this.email,
    this.emergencyContact = '',
    this.idNumber = '',
    required this.idType,
    this.roomId = '',
    this.bedId,
    required this.moveInDate,
    this.monthlyRent = 0,
    this.securityDeposit = 0,
    this.depositDeductions = 0,
    required this.isActive,
    this.guardianName,
    this.guardianPhone,
    this.address,
    this.outstandingBalance = 0,
    this.actualVacateDate,
    DateTime? createdAt,
    this.pgId = '',
  }) : createdAt = createdAt ?? DateTime.now();
  final String id;
  final String name;
  final String phone;
  final String? email;
  final String emergencyContact;
  final String idNumber;
  final IdType idType;
  final String roomId;
  final String? bedId;
  final DateTime moveInDate;
  final double monthlyRent;
  final double securityDeposit;
  final double depositDeductions;
  final bool isActive;
  final String? guardianName;
  final String? guardianPhone;
  final String? address;
  final double outstandingBalance;
  final DateTime? actualVacateDate;
  final DateTime createdAt;
  final String pgId;

  Tenant copyWith({
    String? id,
    String? name,
    String? phone,
    String? email,
    String? emergencyContact,
    String? idNumber,
    IdType? idType,
    String? roomId,
    String? bedId,
    DateTime? moveInDate,
    double? monthlyRent,
    double? securityDeposit,
    double? depositDeductions,
    bool? isActive,
    String? guardianName,
    String? guardianPhone,
    String? address,
    double? outstandingBalance,
    DateTime? actualVacateDate,
    DateTime? createdAt,
    String? pgId,
  }) {
    return Tenant(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      emergencyContact: emergencyContact ?? this.emergencyContact,
      idNumber: idNumber ?? this.idNumber,
      idType: idType ?? this.idType,
      roomId: roomId ?? this.roomId,
      bedId: bedId ?? this.bedId,
      moveInDate: moveInDate ?? this.moveInDate,
      monthlyRent: monthlyRent ?? this.monthlyRent,
      securityDeposit: securityDeposit ?? this.securityDeposit,
      depositDeductions: depositDeductions ?? this.depositDeductions,
      isActive: isActive ?? this.isActive,
      guardianName: guardianName ?? this.guardianName,
      guardianPhone: guardianPhone ?? this.guardianPhone,
      address: address ?? this.address,
      outstandingBalance: outstandingBalance ?? this.outstandingBalance,
      actualVacateDate: actualVacateDate ?? this.actualVacateDate,
      createdAt: createdAt ?? this.createdAt,
      pgId: pgId ?? this.pgId,
    );
  }
}
