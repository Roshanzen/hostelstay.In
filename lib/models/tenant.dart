enum TenantPaymentStatus {
  paid,
  overdue,
  pending,
  exitNotice,
}

class Tenant {
  final String id;
  final String fullName;
  final String initials;
  final String phoneNumber;
  final String email;
  final String organizationOrCollege;
  final bool isKycVerified;
  final TenantPaymentStatus paymentStatus;
  final String statusLabel; // e.g. 'Paid', '8d Late', 'Due in 2d', 'Exit Notice'
  final String roomNumber;
  final String bedSlot;
  final String floor;
  final String roomType;
  final String joinedDate;
  final double monthlyRent;
  final double outstandingBalance;
  final double totalCycleAmount;
  final String? nextDueDate;
  final String? dueSince;
  final String? gracePeriodExp;
  final String? checkoutDate;
  final double securityDeposit;
  final String? exitStatus;
  
  // KYC & Guardian details
  final String? idType;
  final String? idNumber;
  final String? guardianName;
  final String? guardianRelation;
  final String? guardianPhone;
  final String? permanentAddress;

  const Tenant({
    required this.id,
    required this.fullName,
    required this.initials,
    required this.phoneNumber,
    required this.email,
    required this.organizationOrCollege,
    required this.isKycVerified,
    required this.paymentStatus,
    required this.statusLabel,
    required this.roomNumber,
    required this.bedSlot,
    required this.floor,
    required this.roomType,
    required this.joinedDate,
    required this.monthlyRent,
    this.outstandingBalance = 0,
    this.totalCycleAmount = 0,
    this.nextDueDate,
    this.dueSince,
    this.gracePeriodExp,
    this.checkoutDate,
    this.securityDeposit = 0,
    this.exitStatus,
    this.idType,
    this.idNumber,
    this.guardianName,
    this.guardianRelation,
    this.guardianPhone,
    this.permanentAddress,
  });

  Tenant copyWith({
    String? id,
    String? fullName,
    String? initials,
    String? phoneNumber,
    String? email,
    String? organizationOrCollege,
    bool? isKycVerified,
    TenantPaymentStatus? paymentStatus,
    String? statusLabel,
    String? roomNumber,
    String? bedSlot,
    String? floor,
    String? roomType,
    String? joinedDate,
    double? monthlyRent,
    double? outstandingBalance,
    double? totalCycleAmount,
    String? nextDueDate,
    String? dueSince,
    String? gracePeriodExp,
    String? checkoutDate,
    double? securityDeposit,
    String? exitStatus,
    String? idType,
    String? idNumber,
    String? guardianName,
    String? guardianRelation,
    String? guardianPhone,
    String? permanentAddress,
  }) {
    return Tenant(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      initials: initials ?? this.initials,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      email: email ?? this.email,
      organizationOrCollege: organizationOrCollege ?? this.organizationOrCollege,
      isKycVerified: isKycVerified ?? this.isKycVerified,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      statusLabel: statusLabel ?? this.statusLabel,
      roomNumber: roomNumber ?? this.roomNumber,
      bedSlot: bedSlot ?? this.bedSlot,
      floor: floor ?? this.floor,
      roomType: roomType ?? this.roomType,
      joinedDate: joinedDate ?? this.joinedDate,
      monthlyRent: monthlyRent ?? this.monthlyRent,
      outstandingBalance: outstandingBalance ?? this.outstandingBalance,
      totalCycleAmount: totalCycleAmount ?? this.totalCycleAmount,
      nextDueDate: nextDueDate ?? this.nextDueDate,
      dueSince: dueSince ?? this.dueSince,
      gracePeriodExp: gracePeriodExp ?? this.gracePeriodExp,
      checkoutDate: checkoutDate ?? this.checkoutDate,
      securityDeposit: securityDeposit ?? this.securityDeposit,
      exitStatus: exitStatus ?? this.exitStatus,
      idType: idType ?? this.idType,
      idNumber: idNumber ?? this.idNumber,
      guardianName: guardianName ?? this.guardianName,
      guardianRelation: guardianRelation ?? this.guardianRelation,
      guardianPhone: guardianPhone ?? this.guardianPhone,
      permanentAddress: permanentAddress ?? this.permanentAddress,
    );
  }
}

