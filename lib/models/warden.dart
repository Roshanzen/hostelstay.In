class WardenProfile {
  final String name;
  final String staffId;
  final String role;
  final String phone;
  final String email;
  final String authSession;
  final bool isSessionActive;
  final String eSewaMerchantId;
  final bool autoInvoiceCycle;
  final int graceWindowDays;
  final double lateSurchargePerDay;
  final bool appPushAlerts;
  final bool whatsAppReminders;
  final bool criticalOverdueEscalation;
  final bool messVoucherApprovalAlert;
  final double messVoucherCap;
  final String appearance; // 'Light', 'Dark', 'Auto'
  final String language;
  final bool twoFactorEnabled;
  final int passwordAgeDays;

  const WardenProfile({
    required this.name,
    required this.staffId,
    required this.role,
    required this.phone,
    required this.email,
    required this.authSession,
    this.isSessionActive = true,
    this.eSewaMerchantId = 'ES-84920',
    this.autoInvoiceCycle = true,
    this.graceWindowDays = 5,
    this.lateSurchargePerDay = 100.0,
    this.appPushAlerts = true,
    this.whatsAppReminders = true,
    this.criticalOverdueEscalation = true,
    this.messVoucherApprovalAlert = true,
    this.messVoucherCap = 10000.0,
    this.appearance = 'Light',
    this.language = 'English (Nepal)',
    this.twoFactorEnabled = true,
    this.passwordAgeDays = 42,
  });

  WardenProfile copyWith({
    String? name,
    String? staffId,
    String? role,
    String? phone,
    String? email,
    String? authSession,
    bool? isSessionActive,
    String? eSewaMerchantId,
    bool? autoInvoiceCycle,
    int? graceWindowDays,
    double? lateSurchargePerDay,
    bool? appPushAlerts,
    bool? whatsAppReminders,
    bool? criticalOverdueEscalation,
    bool? messVoucherApprovalAlert,
    double? messVoucherCap,
    String? appearance,
    String? language,
    bool? twoFactorEnabled,
    int? passwordAgeDays,
  }) {
    return WardenProfile(
      name: name ?? this.name,
      staffId: staffId ?? this.staffId,
      role: role ?? this.role,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      authSession: authSession ?? this.authSession,
      isSessionActive: isSessionActive ?? this.isSessionActive,
      eSewaMerchantId: eSewaMerchantId ?? this.eSewaMerchantId,
      autoInvoiceCycle: autoInvoiceCycle ?? this.autoInvoiceCycle,
      graceWindowDays: graceWindowDays ?? this.graceWindowDays,
      lateSurchargePerDay: lateSurchargePerDay ?? this.lateSurchargePerDay,
      appPushAlerts: appPushAlerts ?? this.appPushAlerts,
      whatsAppReminders: whatsAppReminders ?? this.whatsAppReminders,
      criticalOverdueEscalation: criticalOverdueEscalation ?? this.criticalOverdueEscalation,
      messVoucherApprovalAlert: messVoucherApprovalAlert ?? this.messVoucherApprovalAlert,
      messVoucherCap: messVoucherCap ?? this.messVoucherCap,
      appearance: appearance ?? this.appearance,
      language: language ?? this.language,
      twoFactorEnabled: twoFactorEnabled ?? this.twoFactorEnabled,
      passwordAgeDays: passwordAgeDays ?? this.passwordAgeDays,
    );
  }
}

