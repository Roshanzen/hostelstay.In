import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../backend/core/api_client.dart';
import '../backend/core/storage/auth_storage.dart';
import '../backend/models/tenant.dart' as db_tenant;
import '../backend/models/room.dart' as db_room;
import '../backend/models/bed.dart' as db_bed;
import '../backend/models/invoice.dart' as db_inv;
import '../backend/models/expense.dart' as db_exp;
import '../backend/models/property.dart' as db_prop;

import '../backend/repositories/auth_repository.dart';
import '../backend/repositories/property_repository.dart';
import '../backend/repositories/room_repository.dart';
import '../backend/repositories/bed_repository.dart';
import '../backend/repositories/tenant_repository.dart';
import '../backend/repositories/invoice_repository.dart';
import '../backend/repositories/expense_repository.dart';
import '../backend/repositories/payment_repository.dart';
import '../backend/repositories/ticket_repository.dart';
import '../backend/repositories/meal_repository.dart';
import '../backend/repositories/utility_repository.dart';
import '../backend/repositories/rent_repository.dart';
import '../backend/models/rent_cycle.dart' as db_rent;
import '../models/rent_cycle.dart';
import '../backend/models/ticket.dart' as db_ticket;
import '../backend/models/meal.dart' as db_meal;
import '../backend/models/utility.dart' as db_utility;
import '../models/property.dart';
import '../models/room.dart';
import '../models/tenant.dart';
import '../models/invoice.dart';
import '../models/expense.dart';
import '../models/warden.dart';
import '../core/utils/currency_formatter.dart';
import '../backend/repositories/billing_repository.dart';
import '../backend/models/billing_summary.dart';
import '../backend/models/tenant_billing_summary.dart';


class AppState extends ChangeNotifier {
  bool _isDisposed = false;
  bool get isDisposed => _isDisposed;

  @override
  void dispose() {
    _isDisposed = true;
    debugPrint('[APPSTATE] Disposed');
    super.dispose();
  }

  @override
  void notifyListeners() {
    if (_isDisposed) return;
    super.notifyListeners();
  }

  AppState([Box<dynamic>? settingsBox, AuthStorage? authStorage]) {
    debugPrint('[APPSTATE] Created');
    if (settingsBox != null) {
      _settings = settingsBox;
      _initSync(authStorage);
    } else if (Hive.isBoxOpen('app_settings')) {
      _settings = Hive.box('app_settings');
      _initSync(authStorage);
    } else {
      _initRepositories();
    }
  }

  late Box<dynamic> _settings;
  late AuthStorage _authStorage;
  late AuthRepository _authRepo;
  late PropertyRepository _propertyRepo;
  late RoomRepository _roomRepo;
  late BedRepository _bedRepo;
  late TenantRepository _tenantRepo;
  late InvoiceRepository _invoiceRepo;
  late ExpenseRepository _expenseRepo;
  late PaymentRepository _paymentRepo;
  late TicketRepository _ticketRepo;
  late MealRepository _mealRepo;
  late UtilityRepository _utilityRepo;
  late RentRepository _rentRepo;
  late BillingRepository _billingRepo;

  BillingSummary _billingSummary = BillingSummary.empty;
  BillingSummary get billingSummary => _billingSummary;

  List<db_inv.InvoiceModel> _overdueInvoices = [];
  List<db_inv.InvoiceModel> get overdueInvoices => _overdueInvoices;

  List<db_inv.InvoiceModel> _upcomingInvoices = [];
  List<db_inv.InvoiceModel> get upcomingInvoices => _upcomingInvoices;

  List<RentCycle> _rentCycles = [];
  List<RentCycle> get rentCycles => _rentCycles;


  List<db_ticket.TicketModel> _tickets = [];
  List<db_ticket.TicketModel> get tickets => _tickets;

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  static const String onboardingCompletedKey = 'onboarding.completed';

  bool _onboardingCompleted = false;
  bool get onboardingCompleted => _onboardingCompleted;

  Future<void> completeOnboarding() async {
    if (_isDisposed) return;
    _onboardingCompleted = true;
    if (_isInitialized) {
      await _settings.put(onboardingCompletedKey, true);
    }
    notifyListeners();
  }

  bool _isLoggedIn = false;
  bool get isLoggedIn => _isLoggedIn;

  // Active Property
  Property _currentProperty = const Property(
    id: '',
    name: 'Select Property',
    block: 'Main',
    address: 'Kathmandu, Nepal',
    totalBeds: 0,
    totalRooms: 0,
    totalFloors: 1,
    occupiedBeds: 0,
    clearanceLevel: 'Operational Warden Clearance',
    databaseSyncStatus: 'Synced with database',
  );
  Property get currentProperty => _currentProperty;

  List<Property> _availableProperties = [];
  List<Property> get availableProperties => _availableProperties;

  // Warden Profile
  WardenProfile _warden = const WardenProfile(
    name: 'Warden',
    staffId: '#W-001',
    role: 'Warden',
    phone: '+977 9800000000',
    email: 'warden@hostelghar.com',
    authSession: 'HostelGhar Live Auth Session',
  );
  WardenProfile get warden => _warden;

  // Business Data Collections (Empty by default — populated strictly from backend/database)
  List<Room> _rooms = [];
  List<Room> get rooms => _rooms;

  List<Tenant> _tenants = [];
  List<Tenant> get tenants => _tenants;

  List<Invoice> _invoices = [];
  List<Invoice> get invoices => _invoices;

  List<Expense> _expenses = [];
  List<Expense> get expenses => _expenses;

  int get totalBeds => _currentProperty.totalBeds > 0 ? _currentProperty.totalBeds : _rooms.fold(0, (sum, r) => sum + r.totalCapacity);
  int get occupiedBeds => _currentProperty.occupiedBeds > 0 ? _currentProperty.occupiedBeds : _rooms.fold(0, (sum, r) => sum + r.occupiedCount);
  double get occupancyRate => totalBeds > 0 ? (occupiedBeds / totalBeds) * 100 : 0.0;

  // Complaints / Tickets
  int get openComplaintsCount => _tickets.where((t) => t.status == db_ticket.TicketStatus.open || t.status == db_ticket.TicketStatus.inProgress).length;
  int get urgentComplaintsCount => _tickets.where((t) => t.priority == db_ticket.TicketPriority.high).length;

  // Tenant Daily Ops Metrics
  int get checkinsTodayCount {
    final now = DateTime.now();
    return _tenants.where((t) {
      try {
        final d = DateFormat('dd MMM yyyy').parse(t.joinedDate);
        return d.year == now.year && d.month == now.month && d.day == now.day;
      } catch (_) {
        return false;
      }
    }).length;
  }

  int get noticesPendingCount => _tenants.where((t) => t.paymentStatus == TenantPaymentStatus.exitNotice || t.exitStatus != null).length;

  // Financial Metrics
  double get totalInvoiced => _invoices.fold<double>(0, (s, i) => s + i.totalAmount);
  double get totalCollected => _invoices.fold<double>(0, (s, i) => s + i.paidAmount);
  double get totalOverdue => _invoices.where((i) => !i.isFullyPaid).fold<double>(0, (s, i) => s + i.outstandingAmount);
  double get totalExpenses => _expenses.fold<double>(0, (s, e) => s + e.amount);
  int get unpaidTenantsCount => _tenants.where((t) => t.paymentStatus == TenantPaymentStatus.overdue || t.paymentStatus == TenantPaymentStatus.pending || t.outstandingBalance > 0).length;
  List<Tenant> get overdueTenants => _tenants.where((t) => t.paymentStatus == TenantPaymentStatus.overdue || t.outstandingBalance > 0).toList();

  // Search & Filter State
  String _roomSearchQuery = '';
  String _roomFilter = 'All Rooms';
  String get roomSearchQuery => _roomSearchQuery;
  String get roomFilter => _roomFilter;

  String _tenantSearchQuery = '';
  String _tenantFilter = 'All';
  String get tenantSearchQuery => _tenantSearchQuery;
  String get tenantFilter => _tenantFilter;

  String _invoiceSearchQuery = '';
  String _invoiceFilter = 'All';
  String get invoiceSearchQuery => _invoiceSearchQuery;
  String get invoiceFilter => _invoiceFilter;

  String _expenseSearchQuery = '';
  String _expenseFilter = 'All';
  String get expenseSearchQuery => _expenseSearchQuery;
  String get expenseFilter => _expenseFilter;

  ThemeMode _themeMode = ThemeMode.light;
  ThemeMode get themeMode => _themeMode;

  void setThemeMode(ThemeMode mode) {
    if (_themeMode == mode) return;
    _themeMode = mode;
    final modeStr = mode == ThemeMode.dark
        ? 'dark'
        : mode == ThemeMode.system
            ? 'system'
            : 'light';
    if (_isInitialized) {
      _settings.put('setting.themeMode', modeStr);
    }
    notifyListeners();
  }

  void _initSync(AuthStorage? customAuthStorage) {
    final secureStorage = const FlutterSecureStorage();
    _authStorage = customAuthStorage ?? AuthStorage(secureStorage, _settings);
    _authRepo = AuthRepository(_authStorage);
    _propertyRepo = PropertyRepository(_settings, _authStorage);
    _roomRepo = RoomRepository(_settings, _authStorage);
    _bedRepo = BedRepository(_settings, _authStorage);
    _tenantRepo = TenantRepository(_settings, _authStorage);
    _invoiceRepo = InvoiceRepository(_settings, _authStorage);
    _expenseRepo = ExpenseRepository(_settings, _authStorage);
    _paymentRepo = PaymentRepository(_settings, _authStorage);
    _ticketRepo = TicketRepository(_settings, _authStorage);
    _mealRepo = MealRepository(_settings, _authStorage);
    _utilityRepo = UtilityRepository(_settings, _authStorage);
    _rentRepo = RentRepository(_settings, _authStorage);
    _billingRepo = BillingRepository(_settings, _authStorage);


    final savedTheme = _settings.get('setting.themeMode');
    if (savedTheme == 'dark') {
      _themeMode = ThemeMode.dark;
    } else if (savedTheme == 'system') {
      _themeMode = ThemeMode.system;
    } else {
      _themeMode = ThemeMode.light;
    }

    final savedOnboarding = _settings.get(onboardingCompletedKey) ?? _settings.get('onboardingCompleted');
    _onboardingCompleted = savedOnboarding == true || savedOnboarding == 'true';

    final token = _authStorage.accessToken;
    _isLoggedIn = token != null && token.isNotEmpty;
    if (_isLoggedIn) {
      _onboardingCompleted = true;
      debugPrint('[AUTH] Credential restored');
    }

    _authStorage.onSessionExpired = () {
      if (_isDisposed) return;
      if (_isLoggedIn) {
        debugPrint('[AUTH] Logout triggered');
        debugPrint('[AUTH] Logout reason: Session expired');
        _isLoggedIn = false;
        notifyListeners();
      }
    };

    _updateWardenFromStorage();
    _isInitialized = true;
    if (_isLoggedIn) {
      loadAllData();
    } else {
      _loadCachedOnly();
    }
  }

  Future<void> _initRepositories() async {
    try {
      if (_isDisposed) return;
      if (Hive.isBoxOpen('app_settings')) {
        _settings = Hive.box('app_settings');
      } else {
        _settings = await Hive.openBox('app_settings');
      }
      if (_isDisposed) return;
      _initSync(null);
    } catch (e) {
      if (_isDisposed) return;
      debugPrint('[AppState] Init repository error: $e');
    }
  }

  void _loadCachedOnly() {
    if (_isDisposed) return;
    final rawProps = _propertyRepo.readCache();
    if (rawProps.isNotEmpty) {
      _availableProperties = rawProps.map((p) => Property(
        id: p.id,
        name: p.name,
        block: 'Main Block',
        address: p.address.isNotEmpty ? p.address : 'Kathmandu, Nepal',
        totalBeds: p.totalBeds > 0 ? p.totalBeds : (p.totalRooms * 2),
        totalRooms: p.totalRooms,
        totalFloors: 3,
        occupiedBeds: p.occupiedBeds,
        clearanceLevel: 'Operational Warden Clearance',
        databaseSyncStatus: 'Cached offline data',
      )).toList();
      final activePg = _propertyRepo.getActivePgId() ?? '';
      if (activePg.isNotEmpty) {
        final match = _availableProperties.where((p) => p.id == activePg).firstOrNull;
        if (match != null) {
          _currentProperty = match;
        }
      } else if (_availableProperties.isNotEmpty) {
        _currentProperty = _availableProperties.first;
      }
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> _updateWardenFromStorage() async {
    try {
      if (_isDisposed) return;
      final profile = await _authStorage.profile;
      if (_isDisposed) return;
      if (profile != null) {
        debugPrint('[AUTH] Current user restored');
        final rawId = profile['id']?.toString() ?? '1';
        final staffId = rawId.length >= 6
            ? '#W-${rawId.substring(0, 6)}'
            : '#W-${rawId.padLeft(3, '0')}';
        final savedAuto = _settings.get('setting.autoInvoiceCycle');
        final savedWa = _settings.get('setting.whatsAppReminders');
        final savedPush = _settings.get('setting.appPushAlerts');
        final savedEsc = _settings.get('setting.criticalOverdueEscalation');
        _warden = WardenProfile(
          name: profile['name']?.toString() ?? profile['username']?.toString() ?? 'Warden',
          staffId: staffId,
          role: profile['role']?.toString().toUpperCase() ?? 'WARDEN',
          phone: (profile['phone'] != null && profile['phone'].toString().isNotEmpty)
              ? profile['phone'].toString()
              : '+977 9800000000',
          email: profile['email']?.toString() ?? 'warden@hostelghar.com',
          authSession: 'HostelGhar Live Auth Session',
          autoInvoiceCycle: savedAuto is bool ? savedAuto : true,
          whatsAppReminders: savedWa is bool ? savedWa : true,
          appPushAlerts: savedPush is bool ? savedPush : true,
          criticalOverdueEscalation: savedEsc is bool ? savedEsc : true,
        );
        notifyListeners();
      }
    } catch (e) {
      if (_isDisposed) return;
      debugPrint('[AppState] updateWardenFromStorage error: $e');
    }
  }

  bool _isLoadingAllData = false;

  void _mapRoomsAndProperty(
    List<db_room.Room> rawRooms,
    List<db_bed.BedModel> rawBeds,
    List<db_tenant.Tenant> rawTenants,
  ) {
    int totalOccupiedBeds = 0;
    _rooms = rawRooms.map((r) {
      final roomBeds = rawBeds.where((b) => b.roomId == r.id).toList();
      final List<RoomSlot> slots = [];

      if (roomBeds.isNotEmpty) {
        for (final b in roomBeds) {
          final isOcc = b.status == db_bed.BedStatus.occupied;
          if (isOcc) totalOccupiedBeds++;
          final occTenant = rawTenants.where((t) => t.id == b.tenantId || t.bedId == b.id).firstOrNull;

          slots.add(RoomSlot(
            slotId: b.label.isNotEmpty ? b.label : 'A',
            isOccupied: isOcc,
            tenantName: isOcc ? (occTenant?.name ?? 'Occupied') : 'Bed Available',
            tenantSubtitle: isOcc ? '${occTenant?.phone ?? ''} • Rent: ${CurrencyFormatter.format(b.rent > 0 ? b.rent : r.rentAmount)}' : 'Available for booking',
            paymentStatus: isOcc ? 'Active' : null,
            isVerified: occTenant?.idNumber.isNotEmpty == true,
            tenantPhone: occTenant?.phone,
          ));
        }
      } else {
        // Generate capacity placeholders if beds haven't been individually created
        for (int i = 0; i < r.capacity; i++) {
          final slotLetter = String.fromCharCode(65 + i);
          slots.add(RoomSlot(
            slotId: slotLetter,
            isOccupied: false,
            tenantName: 'Bed Available',
            tenantSubtitle: 'Ready for move-in',
          ));
        }
      }

      return Room(
        id: r.id,
        roomNumber: 'Room ${r.roomNumber}',
        floor: 'Floor 1',
        sharingType: '${r.capacity}-Sharing',
        rentAmount: r.rentAmount,
        totalCapacity: r.capacity,
        slots: slots,
        amenities: const ['Attached Bath', 'Wi-Fi', 'Power Backup'],
        isMaintenance: r.status == db_room.RoomStatus.full && slots.isEmpty,
      );
    }).toList();

    // Update current property occupied bed count
    _currentProperty = Property(
      id: _currentProperty.id,
      name: _currentProperty.name,
      block: _currentProperty.block,
      address: _currentProperty.address,
      totalBeds: rawBeds.isNotEmpty ? rawBeds.length : _rooms.fold(0, (sum, r) => sum + r.totalCapacity),
      totalRooms: _rooms.length,
      totalFloors: _currentProperty.totalFloors,
      occupiedBeds: totalOccupiedBeds,
      clearanceLevel: _currentProperty.clearanceLevel,
      databaseSyncStatus: 'Synced with database',
    );
  }

  Future<void> loadAllData() async {
    if (_isDisposed) return;
    final token = _authStorage.accessToken;
    if (token == null || token.isEmpty) {
      _loadCachedOnly();
      return;
    }

    if (_isLoadingAllData) return;
    _isLoadingAllData = true;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      List<db_prop.Property> rawProps = [];
      final profile = await _authStorage.profile;
      if (_isDisposed) return;
      final role = profile?['role']?.toString();
      if (role == 'owner') {
        rawProps = await _propertyRepo.fetchProperties(profile?['id']?.toString() ?? 'local');
      } else {
        rawProps = await _propertyRepo.fetchAssignedProperties();
      }
      if (_isDisposed) return;

      if (rawProps.isEmpty) {
        rawProps = _propertyRepo.readCache();
      }

      _availableProperties = rawProps.map((p) => Property(
        id: p.id,
        name: p.name,
        block: 'Main Block',
        address: p.address.isNotEmpty ? p.address : 'Kathmandu, Nepal',
        totalBeds: p.totalBeds > 0 ? p.totalBeds : (p.totalRooms * 2),
        totalRooms: p.totalRooms,
        totalFloors: 3,
        occupiedBeds: p.occupiedBeds,
        clearanceLevel: 'Operational Warden Clearance',
        databaseSyncStatus: 'Synced with database',
      )).toList();

      String activePg = _propertyRepo.getActivePgId() ?? '';
      if ((activePg.isEmpty || !_availableProperties.any((p) => p.id == activePg)) && _availableProperties.isNotEmpty) {
        activePg = _availableProperties.first.id;
        await _propertyRepo.setActivePgId(activePg);
      }
      if (_isDisposed) return;

      if (activePg.isNotEmpty) {
        final match = _availableProperties.where((p) => p.id == activePg).firstOrNull;
        if (match != null) {
          _currentProperty = match;
        }
      }

      final pgId = _currentProperty.id;
      if (pgId.isEmpty) {
        _isLoading = false;
        notifyListeners();
        return;
      }

      // 2. Fetch all domain entities concurrently
      final results = await Future.wait([
        _roomRepo.fetchForPg(pgId),
        _bedRepo.fetchForPg(pgId),
        _tenantRepo.fetchForPg(pgId),
        _invoiceRepo.fetchForPg(pgId),
        _paymentRepo.fetchForPg(pgId),
        _expenseRepo.fetchForPg(pgId),
        _ticketRepo.fetchForPg(pgId).catchError((_) => <db_ticket.TicketModel>[]),
        _rentRepo.fetchForPg(pgId).catchError((_) => <db_rent.RentCycle>[]),
        _billingRepo.fetchSummary(pgId).catchError((_) => BillingSummary.empty),
        _billingRepo.fetchOverdue(pgId).catchError((_) => <db_inv.InvoiceModel>[]),
        _billingRepo.fetchUpcoming(pgId).catchError((_) => <db_inv.InvoiceModel>[]),
      ]);
      if (_isDisposed) return;
      final rawRooms = results[0] as List<db_room.Room>;
      final rawBeds = results[1] as List<db_bed.BedModel>;
      final rawTenants = results[2] as List<db_tenant.Tenant>;
      final rawInvoices = results[3] as List<db_inv.InvoiceModel>;
      // results[4] is payments
      final rawExpenses = results[5] as List<db_exp.Expense>;
      _tickets = results[6] as List<db_ticket.TicketModel>;
      final rawCycles = results[7] as List<db_rent.RentCycle>;
      _billingSummary = results[8] as BillingSummary;
      _overdueInvoices = results[9] as List<db_inv.InvoiceModel>;
      _upcomingInvoices = results[10] as List<db_inv.InvoiceModel>;
      _rentCycles = rawCycles.map((c) => RentCycle(
        id: c.id,
        billingMonth: c.billingMonth,
        generatedAt: c.generatedAt,
        totalTenantsBilled: c.totalTenantsBilled,
        totalAmountBilled: c.totalAmountBilled,
      )).toList();


      // Map dynamic rooms & slots using helper
      _mapRoomsAndProperty(rawRooms, rawBeds, rawTenants);

      // Map dynamic tenants
      _tenants = rawTenants.map((t) {
        final room = _rooms.where((r) => r.id == t.roomId || r.roomNumber.contains(t.roomId)).firstOrNull;
        final roomNumber = room?.roomNumber ?? (t.roomId.isNotEmpty ? 'Room ${t.roomId}' : 'Unassigned');
        final bedSlot = t.bedId != null && t.bedId!.isNotEmpty ? 'Bed ${t.bedId}' : 'Slot A';

        // Calculate payment status from invoices
        final tenantInvoices = rawInvoices.where((inv) => inv.tenantId == t.id).toList();
        final hasOverdue = tenantInvoices.any((inv) => inv.status == db_inv.InvoiceStatus.overdue);
        final hasPending = tenantInvoices.any((inv) => inv.status == db_inv.InvoiceStatus.pending || inv.status == db_inv.InvoiceStatus.partial);
        final double outstanding = tenantInvoices.fold(0.0, (sum, inv) => sum + (inv.amount - inv.paidAmount));

        TenantPaymentStatus payStatus = TenantPaymentStatus.paid;
        String statusLabel = 'Paid';
        if (!t.isActive) {
          payStatus = TenantPaymentStatus.exitNotice;
          statusLabel = 'Checked Out';
        } else if (hasOverdue) {
          payStatus = TenantPaymentStatus.overdue;
          statusLabel = 'Overdue';
        } else if (hasPending || outstanding > 0) {
          payStatus = TenantPaymentStatus.pending;
          statusLabel = 'Due';
        }

        final initials = t.name.trim().split(' ').map((e) => e.isNotEmpty ? e[0].toUpperCase() : '').take(2).join();

        return Tenant(
          id: t.id,
          fullName: t.name,
          initials: initials.isNotEmpty ? initials : 'TN',
          phoneNumber: t.phone.startsWith('+977') ? t.phone : (t.phone.startsWith('+') ? t.phone : '+977 ${t.phone}'),
          email: t.email ?? '',
          organizationOrCollege: t.emergencyContact.isNotEmpty ? 'Emergency: ${t.emergencyContact}' : 'Resident',
          isKycVerified: t.idNumber.isNotEmpty,
          paymentStatus: payStatus,
          statusLabel: statusLabel,
          roomNumber: roomNumber,
          bedSlot: bedSlot,
          floor: 'Floor 1',
          roomType: room?.sharingType ?? 'Standard',
          joinedDate: DateFormat('MMM yyyy').format(t.moveInDate),
          monthlyRent: t.monthlyRent,
          outstandingBalance: outstanding,
          totalCycleAmount: t.monthlyRent,
          securityDeposit: t.securityDeposit,
          idType: t.idType.name.toUpperCase(),
          idNumber: t.idNumber,
          guardianName: t.guardianName,
          guardianRelation: 'Guardian',
          guardianPhone: t.guardianPhone,
          permanentAddress: t.address ?? 'Nepal',
        );
      }).toList();

      // Map dynamic invoices
      _invoices = rawInvoices.map((inv) {
        final tenant = _tenants.where((t) => t.id == inv.tenantId).firstOrNull;
        final rawTenant = rawTenants.where((t) => t.id == inv.tenantId).firstOrNull;
        final now = DateTime.now();
        final isPastDue = inv.dueDate.isBefore(DateTime(now.year, now.month, now.day));

        InvoiceStatus status;
        String badge;
        switch (inv.status) {
          case db_inv.InvoiceStatus.paid:
            status = InvoiceStatus.paid;
            badge = 'Paid';
            break;
          case db_inv.InvoiceStatus.partial:
            status = isPastDue ? InvoiceStatus.overdue : InvoiceStatus.grace;
            badge = isPastDue ? 'Overdue (Part.)' : 'Partial';
            break;
          case db_inv.InvoiceStatus.overdue:
            status = InvoiceStatus.overdue;
            badge = 'Overdue';
            break;
          default:
            if (isPastDue && (inv.amount - inv.paidAmount) > 0.01) {
              status = InvoiceStatus.overdue;
              badge = 'Overdue';
            } else {
              status = InvoiceStatus.unpaid;
              badge = 'Due';
            }
        }

        final invNum = (inv.invoiceNumber != null && inv.invoiceNumber!.isNotEmpty)
            ? inv.invoiceNumber!
            : '#INV-${inv.id.length >= 6 ? inv.id.substring(0, 6).toUpperCase() : inv.id}';

        String cycleStr = 'Current Cycle';
        if (inv.periodStart != null && inv.periodEnd != null) {
          cycleStr = '${inv.periodStart} to ${inv.periodEnd}';
        } else if (inv.billingDate != null) {
          cycleStr = DateFormat('MMMM yyyy').format(inv.billingDate!);
        }

        return Invoice(
          id: inv.id,
          tenantId: inv.tenantId,
          roomId: inv.roomId ?? rawTenant?.roomId ?? '',
          invoiceNumber: invNum,
          tenantName: tenant?.fullName ?? 'Tenant #${inv.tenantId}',
          tenantInitials: tenant?.initials ?? 'TN',
          roomInfo: tenant?.roomNumber ?? 'Room N/A',
          status: status,
          statusBadgeText: badge,
          totalAmount: inv.amount,
          paidAmount: inv.paidAmount,
          outstandingAmount: inv.remainingAmount,
          discount: inv.discount,
          lateFee: inv.lateFee,
          dueDate: DateFormat('dd MMM yyyy').format(inv.dueDate),
          periodStart: inv.periodStart,
          periodEnd: inv.periodEnd,
          billingCycle: cycleStr,
        );
      }).toList();


      // Map dynamic expenses
      _expenses = rawExpenses.map((exp) {
        ExpenseCategory cat = ExpenseCategory.other;
        switch (exp.category) {
          case db_exp.ExpenseCategory.water:
            cat = ExpenseCategory.utilities;
            break;
          case db_exp.ExpenseCategory.electricity:
            cat = ExpenseCategory.utilities;
            break;
          case db_exp.ExpenseCategory.maintenance:
            cat = ExpenseCategory.maintenance;
            break;
          default:
            cat = ExpenseCategory.mess;
        }

        return Expense(
          id: exp.id,
          title: exp.note?.isNotEmpty == true ? exp.note! : '${exp.category.name.toUpperCase()} Expense',
          category: cat,
          categoryLabel: exp.category.name.toUpperCase(),
          vendorOrLocation: 'Operational Expense',
          amount: exp.amount,
          paymentMode: 'Cash / eSewa',
          voucherDoc: 'Logged',
          transactionRef: 'EXP-${exp.id.length >= 6 ? exp.id.substring(0, 6) : exp.id}',
          timestamp: DateFormat('hh:mm a').format(exp.date),
          dateGroup: DateFormat('dd MMM yyyy').format(exp.date),
        );
      }).toList();
    } catch (e) {
      if (_isDisposed) return;
      debugPrint('[AppState] Load all data error: $e');
      if (e is ApiException && e.statusCode == 401 && _authStorage.accessToken == null) {
        debugPrint('[AUTH] Logout triggered');
        debugPrint('[AUTH] Logout reason: Session expired and token refresh failed');
        _isLoggedIn = false;
      }
      _errorMessage = 'Could not sync latest data: $e';
    } finally {
      _isLoadingAllData = false;
      _isLoading = false;
      if (!_isDisposed) {
        notifyListeners();
      }
    }
  }

  // Multi-Property Switching
  Future<void> switchProperty(Property property) async {
    if (_isDisposed) return;
    _currentProperty = property;
    await _propertyRepo.setActivePgId(property.id);
    if (_isDisposed) return;
    await loadAllData();
  }

  Future<bool> createProperty({
    required String name,
    required String address,
    String phone = '',
    String email = '',
    int totalRooms = 10,
    String description = '',
  }) async {
    if (_isDisposed) return false;
    _isLoading = true;
    notifyListeners();
    try {
      final res = await _propertyRepo.createProperty({
        'name': name,
        'address': address,
        'phone': phone,
        'email': email,
        'total_rooms': totalRooms,
        'description': description,
      });
      if (res != null) {
        await loadAllData();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('[AppState] createProperty error: $e');
      _errorMessage = 'Failed to create property: $e';
      return false;
    } finally {
      _isLoading = false;
      if (!_isDisposed) notifyListeners();
    }
  }

  Future<bool> updateProperty({
    required String id,
    required String name,
    required String address,
    String phone = '',
    String email = '',
    int? totalRooms,
    String description = '',
    String status = 'active',
  }) async {
    if (_isDisposed) return false;
    _isLoading = true;
    notifyListeners();
    try {
      final payload = <String, dynamic>{
        'name': name,
        'address': address,
        'phone': phone,
        'email': email,
        'total_rooms': totalRooms ?? 10,
        if (description.isNotEmpty) 'description': description,
      };
      final res = await _propertyRepo.updateProperty(id, payload);
      if (res != null) {
        await loadAllData();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('[AppState] updateProperty error: $e');
      _errorMessage = 'Failed to update property: $e';
      return false;
    } finally {
      _isLoading = false;
      if (!_isDisposed) notifyListeners();
    }
  }

  Future<bool> deleteProperty(String id) async {
    if (_isDisposed) return false;
    _isLoading = true;
    notifyListeners();
    try {
      final success = await _propertyRepo.deleteProperty(id);
      if (success) {
        await loadAllData();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('[AppState] deleteProperty error: $e');
      _errorMessage = 'Failed to delete property: $e';
      return false;
    } finally {
      _isLoading = false;
      if (!_isDisposed) notifyListeners();
    }
  }

  // Dedicated Room Refresh (No overhead from unrelated domain endpoints)
  Future<void> refreshRooms({String? pgId}) async {
    if (_isDisposed) return;
    debugPrint('[APPSTATE] refreshRooms started');
    final targetPg = pgId ?? (_currentProperty.id.isNotEmpty ? _currentProperty.id : (_propertyRepo.getActivePgId() ?? ''));
    if (targetPg.isEmpty) return;
    try {
      final results = await Future.wait([
        _roomRepo.fetchForPg(targetPg),
        _bedRepo.fetchForPg(targetPg),
        _tenantRepo.fetchForPg(targetPg),
      ]);
      if (_isDisposed) return;
      final rawRooms = results[0] as List<db_room.Room>;
      final rawBeds = results[1] as List<db_bed.BedModel>;
      final rawTenants = results[2] as List<db_tenant.Tenant>;

      _mapRoomsAndProperty(rawRooms, rawBeds, rawTenants);
      debugPrint('[APPSTATE] refreshRooms completed');
      notifyListeners();
    } catch (e) {
      if (_isDisposed) return;
      debugPrint('[AppState] refreshRooms error: $e');
    }
  }

  // Room Actions
  Future<void> addRoom(Room room) async {
    if (_isDisposed) return;
    final pgId = _currentProperty.id.isNotEmpty ? _currentProperty.id : (_propertyRepo.getActivePgId() ?? '');
    if (pgId.isEmpty) {
      throw ApiException('Please select a property first.');
    }

    final cleanNum = room.roomNumber.replaceAll('Room ', '').trim();
    if (cleanNum.isEmpty) {
      throw ApiException('Please enter a room number.');
    }

    try {
      final dbRoom = db_room.Room(
        id: '',
        roomNumber: cleanNum,
        capacity: room.totalCapacity,
        rentAmount: room.rentAmount,
        pgId: pgId,
      );

      // Exactly ONE POST request sent to Django
      await _roomRepo.createRoom(dbRoom);
      if (_isDisposed) return;

      // Refresh the current property's rooms
      await refreshRooms(pgId: pgId);
    } catch (e) {
      if (_isDisposed) return;
      debugPrint('[AppState] addRoom error: $e');
      rethrow;
    }
  }

  Future<void> updateRoom(Room room) async {
    if (_isDisposed) return;
    final pgId = _currentProperty.id.isNotEmpty ? _currentProperty.id : (_propertyRepo.getActivePgId() ?? '');
    try {
      final dbRoom = db_room.Room(
        id: room.id,
        roomNumber: room.roomNumber.replaceAll('Room ', '').trim(),
        capacity: room.totalCapacity,
        rentAmount: room.rentAmount,
        pgId: pgId,
      );
      await _roomRepo.updateRoom(dbRoom);
      if (_isDisposed) return;
      await refreshRooms(pgId: pgId);
    } catch (e) {
      if (_isDisposed) return;
      debugPrint('[AppState] updateRoom error: $e');
      rethrow;
    }
  }

  Future<void> deleteRoom(String roomId) async {
    if (_isDisposed) return;
    final pgId = _currentProperty.id.isNotEmpty ? _currentProperty.id : (_propertyRepo.getActivePgId() ?? '');
    try {
      await _roomRepo.deleteRoom(roomId);
      if (_isDisposed) return;
      await refreshRooms(pgId: pgId);
      if (_isDisposed) return;
      await loadAllData();
    } catch (e) {
      if (_isDisposed) return;
      debugPrint('[AppState] deleteRoom error: $e');
      rethrow;
    }
  }

  Future<void> allocateBed(String roomId, String slotId, String tenantName, String phone) async {
    if (_isDisposed) return;
    try {
      final beds = await _bedRepo.fetchBeds(pgId: _currentProperty.id, roomId: roomId);
      if (_isDisposed) return;
      final bed = beds.where((b) => b.label == slotId).firstOrNull;
      if (bed != null) {
        await _bedRepo.updateBed(bed.copyWith(
          status: db_bed.BedStatus.occupied,
        ));
        if (_isDisposed) return;
        await loadAllData();
      }
    } catch (e) {
      if (_isDisposed) return;
      debugPrint('[AppState] allocateBed error: $e');
    }
  }

  // Tenant Actions
  Future<void> addTenant(Tenant tenant, {String? targetRoomId, String? targetBedId}) async {
    if (_isDisposed) return;
    debugPrint('[APPSTATE] addTenant started');
    try {
      final pgId = _currentProperty.id.isNotEmpty
          ? _currentProperty.id
          : (_propertyRepo.getActivePgId() ?? '');
      if (pgId.isEmpty) {
        throw ApiException('No property selected. Please select a property first.');
      }

      // 1. Resolve room ID
      String resolvedRoomId = targetRoomId ?? '';
      if (resolvedRoomId.isEmpty) {
        final cleanRoomNum = tenant.roomNumber.replaceAll('Room ', '').trim();
        final matchedRoom = _rooms.where((r) => r.roomNumber.contains(cleanRoomNum) || r.id == cleanRoomNum).firstOrNull;
        resolvedRoomId = matchedRoom?.id ?? cleanRoomNum;
      }

      // 2. Resolve bed ID
      String? resolvedBedId = targetBedId;
      if (resolvedBedId != null && resolvedBedId.isNotEmpty) {
        final cleanBed = resolvedBedId.replaceAll('Bed ', '').trim();
        final beds = await _bedRepo.fetchForPg(pgId);
        if (_isDisposed) return;
        final bed = beds.where((b) =>
            (resolvedRoomId.isEmpty || b.roomId == resolvedRoomId) &&
            (b.id == resolvedBedId ||
             b.label == resolvedBedId ||
             b.label.toUpperCase() == cleanBed.toUpperCase() ||
             b.id == cleanBed)).firstOrNull;
        if (bed != null) {
          resolvedBedId = bed.id;
          if (bed.status == db_bed.BedStatus.occupied) {
            throw ApiException('Bed ${bed.label} is already occupied. Please select an available bed.');
          }
        }
      }

      final dbTenant = db_tenant.Tenant(
        id: '',
        name: tenant.fullName,
        phone: tenant.phoneNumber,
        emergencyContact: tenant.organizationOrCollege,
        idNumber: tenant.idNumber ?? '',
        roomId: resolvedRoomId,
        bedId: resolvedBedId,
        moveInDate: DateTime.now(),
        monthlyRent: tenant.monthlyRent,
        securityDeposit: tenant.securityDeposit,
        isActive: true,
        idType: (tenant.idType?.toLowerCase().contains('citizen') ?? false)
            ? db_tenant.IdType.citizenship
            : (tenant.idType?.toLowerCase().contains('passport') ?? false)
                ? db_tenant.IdType.passport
                : (tenant.idType?.toLowerCase().contains('license') ?? false)
                    ? db_tenant.IdType.drivingLicense
                    : db_tenant.IdType.other,

        pgId: pgId,
        email: tenant.email,
        address: tenant.permanentAddress,
        guardianName: tenant.guardianName,
        guardianPhone: tenant.guardianPhone,
      );
      final savedTenant = await _tenantRepo.createTenant(dbTenant);
      if (_isDisposed) return;

      if (resolvedBedId != null && resolvedBedId.isNotEmpty) {
        final beds = await _bedRepo.fetchForPg(pgId);
        if (_isDisposed) return;
        final bed = beds.where((b) => b.id == resolvedBedId || b.label == resolvedBedId).firstOrNull;
        if (bed != null) {
          await _bedRepo.updateBed(bed.copyWith(
            status: db_bed.BedStatus.occupied,
            tenantId: savedTenant.id,
          ));
          if (_isDisposed) return;
        }
      }

      // Refresh both room/bed occupancy and all domain state immediately
      await refreshRooms(pgId: pgId);
      if (_isDisposed) return;
      await loadAllData();
      debugPrint('[APPSTATE] addTenant completed');
    } catch (e) {
      if (_isDisposed) return;
      debugPrint('[AppState] addTenant error: $e');
      rethrow;
    }
  }

  Future<void> checkoutTenant(String tenantId) async {
    if (_isDisposed) return;
    try {
      final client = ApiClient(authStorage: _authStorage);
      await client.post('/api/tenants/tenants/$tenantId/checkout/', {});
    } catch (e) {
      if (_isDisposed) return;
      debugPrint('[AppState] checkoutTenant backend call error: $e');
      final tenants = await _tenantRepo.fetchForPg(_currentProperty.id);
      if (_isDisposed) return;
      final match = tenants.where((t) => t.id == tenantId).firstOrNull;
      if (match != null) {
        await _tenantRepo.updateTenant(match.copyWith(
          isActive: false,
          actualVacateDate: DateTime.now(),
        ));
        if (_isDisposed) return;

        // Free the associated bed
        if (match.bedId != null && match.bedId!.isNotEmpty) {
          final beds = await _bedRepo.fetchForPg(_currentProperty.id);
          if (_isDisposed) return;
          final bed = beds.where((b) => b.id == match.bedId || b.label == match.bedId).firstOrNull;
          if (bed != null) {
            await _bedRepo.updateBed(bed.copyWith(
              status: db_bed.BedStatus.available,
              tenantId: '',
            ));
            if (_isDisposed) return;
          }
        }

        await loadAllData();
      }
    } finally {
      if (!_isDisposed) {
        await refreshRooms();
        if (!_isDisposed) {
          await loadAllData();
        }
      }
    }
  }

  // Payment & Billing Actions
  Future<Map<String, dynamic>> recordPaymentWithAllocation({
    required String tenantId,
    required double amount,
    required String paymentMethod,
    String? invoiceId,
    String? txRef,
    String? notes,
  }) async {
    if (_isDisposed) return {};
    final pgId = _currentProperty.id.isNotEmpty ? _currentProperty.id : (_propertyRepo.getActivePgId() ?? '');
    if (pgId.isEmpty) throw ApiException('Please select a property first.');

    final result = await _billingRepo.recordPayment(
      tenantId: tenantId,
      pgId: pgId,
      amount: amount,
      paymentMethod: paymentMethod,
      invoiceId: invoiceId,
      reference: txRef,
      notes: notes,
    );
    if (!_isDisposed) {
      await loadAllData();
    }
    return result;
  }

  Future<void> recordPayment(
    String tenantId,
    double amount, [
    String? methodOrNote,
    String? invoiceId,
    String? reference,
  ]) async {
    if (_isDisposed) return;
    try {
      String resolvedTenantId = tenantId;
      String? resolvedInvoiceId = invoiceId;
      final matchedInvByFirstArg = _invoices.where((i) => i.id == tenantId).firstOrNull;
      if (matchedInvByFirstArg != null && matchedInvByFirstArg.tenantId.isNotEmpty) {
        resolvedTenantId = matchedInvByFirstArg.tenantId;
        resolvedInvoiceId ??= matchedInvByFirstArg.id;
      }

      final pgId = _currentProperty.id.isNotEmpty ? _currentProperty.id : (_propertyRepo.getActivePgId() ?? '');
      await _billingRepo.recordPayment(
        tenantId: resolvedTenantId,
        pgId: pgId,
        amount: amount,
        paymentMethod: methodOrNote ?? 'Cash',
        invoiceId: (resolvedInvoiceId != null && resolvedInvoiceId.isNotEmpty && !resolvedInvoiceId.startsWith('INV-'))
            ? resolvedInvoiceId
            : null,
        reference: reference,
      );
      if (_isDisposed) return;

      await loadAllData();
    } catch (e) {
      if (_isDisposed) return;
      debugPrint('[AppState] recordPayment error: $e');
      rethrow;
    }
  }

  Future<TenantBillingSummary?> fetchTenantBillingSummary(String tenantId) async {
    return await _billingRepo.fetchTenantSummary(tenantId);
  }

  Future<void> voidInvoice(String invoiceId, String reason) async {
    if (_isDisposed) return;
    await _billingRepo.voidInvoice(invoiceId, reason);
    if (!_isDisposed) {
      await loadAllData();
    }
  }

  Future<Map<String, dynamic>> generatePeriodInvoices({String? tenantId, int periodsAhead = 1}) async {
    if (_isDisposed) return {};
    final pgId = _currentProperty.id.isNotEmpty ? _currentProperty.id : (_propertyRepo.getActivePgId() ?? '');
    if (pgId.isEmpty) throw ApiException('Please select a property first.');
    final result = await _billingRepo.generatePeriodInvoices(
      pgId: pgId,
      tenantId: tenantId,
      periodsAhead: periodsAhead,
    );
    if (!_isDisposed) {
      await loadAllData();
    }
    return result;
  }

  Future<void> refreshInvoiceStatuses() async {
    if (_isDisposed) return;
    final pgId = _currentProperty.id.isNotEmpty ? _currentProperty.id : (_propertyRepo.getActivePgId() ?? '');
    if (pgId.isNotEmpty) {
      await _billingRepo.refreshStatuses(pgId);
      if (!_isDisposed) {
        await loadAllData();
      }
    }
  }


  Future<void> createAdHocInvoice({
    required String tenantId,
    required String type,
    required double amount,
    required DateTime dueDate,
    String? note,
  }) async {
    if (_isDisposed) return;
    final pgId = _currentProperty.id.isNotEmpty ? _currentProperty.id : (_propertyRepo.getActivePgId() ?? '');
    if (pgId.isEmpty) {
      throw ApiException('Please select a property first.');
    }
    try {
      db_inv.InvoiceType invType = db_inv.InvoiceType.rent;
      if (type.toLowerCase().contains('util')) {
        invType = db_inv.InvoiceType.utility;
      } else if (type.toLowerCase().contains('meal')) {
        invType = db_inv.InvoiceType.meal;
      } else if (type.toLowerCase().contains('exp') || type.toLowerCase().contains('maint')) {
        invType = db_inv.InvoiceType.expense;
      }
      final inv = db_inv.InvoiceModel(
        id: '',
        tenantId: tenantId,
        type: invType,
        amount: amount,
        paidAmount: 0,
        status: db_inv.InvoiceStatus.unpaid,
        dueDate: dueDate,
        billingDate: DateTime.now(),
        note: note,
        pgId: pgId,
      );
      await _invoiceRepo.createInvoice(inv);
      if (_isDisposed) return;
      await loadAllData();
    } catch (e) {
      if (_isDisposed) return;
      debugPrint('[AppState] createAdHocInvoice error: $e');
      rethrow;
    }
  }

  // Expense Actions
  Future<void> addExpense(Expense exp) async {
    if (_isDisposed) return;
    try {
      db_exp.ExpenseCategory cat = db_exp.ExpenseCategory.other;
      switch (exp.category) {
        case ExpenseCategory.utilities:
          cat = db_exp.ExpenseCategory.electricity;
          break;
        case ExpenseCategory.maintenance:
          cat = db_exp.ExpenseCategory.maintenance;
          break;
        case ExpenseCategory.mess:
          cat = db_exp.ExpenseCategory.other;
          break;
        default:
          cat = db_exp.ExpenseCategory.other;
      }

      final expense = db_exp.Expense(
        id: '',
        category: cat,
        amount: exp.amount,
        date: DateTime.now(),
        note: exp.title,
        pgId: _currentProperty.id,
      );
      await _expenseRepo.createExpense(expense);
      if (_isDisposed) return;
      await loadAllData();
    } catch (e) {
      if (_isDisposed) return;
      debugPrint('[AppState] addExpense error: $e');
      rethrow;
    }
  }

  // Maintenance Actions
  Future<void> addMaintenanceTicket({
    required String title,
    String? description,
    String category = 'other',
    String? roomId,
    required String priority,
    double? cost,
  }) async {
    if (_isDisposed) return;
    try {
      final cat = db_ticket.TicketCategory.values.firstWhere(
        (e) => e.name.toLowerCase() == category.toLowerCase(),
        orElse: () => db_ticket.TicketCategory.other,
      );
      final ticket = db_ticket.TicketModel(
        id: '',
        title: title,
        description: description,
        category: cat,
        roomId: roomId ?? '',
        priority: db_ticket.TicketPriority.values.firstWhere(
          (e) => e.name.toLowerCase() == priority.toLowerCase(),
          orElse: () => db_ticket.TicketPriority.medium,
        ),
        costIncurred: cost,
        createdAt: DateTime.now(),
        pgId: _currentProperty.id,
      );
      await _ticketRepo.createTicket(ticket);
      if (_isDisposed) return;
      await loadAllData();
    } catch (e) {
      if (_isDisposed) return;
      debugPrint('[AppState] addMaintenanceTicket error: $e');
      rethrow;
    }
  }

  Future<void> updateMaintenanceTicketStatus(
    String ticketId,
    String status, {
    double? costIncurred,
    String? description,
  }) async {
    if (_isDisposed) return;
    try {
      db_ticket.TicketModel? ticket;
      for (final t in _tickets) {
        if (t.id == ticketId) {
          ticket = t;
          break;
        }
      }
      if (ticket == null) return;
      final st = status.toLowerCase();
      db_ticket.TicketStatus newStatus = db_ticket.TicketStatus.open;
      if (st == 'resolved') {
        newStatus = db_ticket.TicketStatus.resolved;
      } else if (st == 'inprogress' || st == 'in_progress') {
        newStatus = db_ticket.TicketStatus.inProgress;
      } else if (st == 'cancelled' || st == 'closed') {
        newStatus = db_ticket.TicketStatus.closed;
      }
      final updated = ticket.copyWith(
        status: newStatus,
        costIncurred: costIncurred ?? ticket.costIncurred,
        description: description ?? ticket.description,
      );
      await _ticketRepo.updateTicket(updated);
      if (_isDisposed) return;
      await loadAllData();
    } catch (e) {
      if (_isDisposed) return;
      debugPrint('[AppState] updateMaintenanceTicketStatus error: $e');
      rethrow;
    }
  }

  // Meal Actions
  Future<void> addMeal({
    required String tenantId,
    required String date,
    required String mealType,
    bool attended = false,
    bool isExtra = false,
    double? extraCharge,
  }) async {
    if (_isDisposed) return;
    try {
      final meal = db_meal.MealModel(
        id: '',
        tenantId: tenantId,
        date: DateTime.tryParse(date) ?? DateTime.now(),
        mealType: db_meal.MealType.values.firstWhere(
          (e) => e.name.toLowerCase() == mealType.toLowerCase(),
          orElse: () => db_meal.MealType.breakfast,
        ),
        attended: attended,
        isExtra: isExtra,
        extraCharge: extraCharge,
        createdAt: DateTime.now(),
        pgId: _currentProperty.id,
      );
      await _mealRepo.createMeal(meal);
      if (_isDisposed) return;
      await loadAllData();
    } catch (e) {
      if (_isDisposed) return;
      debugPrint('[AppState] addMeal error: $e');
      rethrow;
    }
  }

  // Rent Cycle Actions
  Future<void> generateRentInvoices({required String billingMonth, int dueDays = 10}) async {
    if (_isDisposed) return;
    final pgId = _currentProperty.id.isNotEmpty ? _currentProperty.id : (_propertyRepo.getActivePgId() ?? '');
    if (pgId.isEmpty) {
      throw ApiException('Please select a property first.');
    }
    try {
      await _rentRepo.generateInvoices(
        pgId: pgId,
        billingMonth: billingMonth,
        dueDays: dueDays,
      );
      if (_isDisposed) return;
      await loadAllData();
    } catch (e) {
      if (_isDisposed) return;
      debugPrint('[AppState] generateRentInvoices error: $e');
      rethrow;
    }
  }

  // Utility Actions
  Future<void> addUtility({
    required String type,
    required double totalAmount,
    required DateTime billMonth,
    DateTime? dueDate,
    String? note,
  }) async {
    if (_isDisposed) return;
    try {
      final utility = db_utility.UtilityModel(
        id: '',
        type: db_utility.UtilityType.values.firstWhere(
          (e) => e.name.toLowerCase() == type.toLowerCase(),
          orElse: () => db_utility.UtilityType.other,
        ),
        totalAmount: totalAmount,
        billMonth: billMonth,
        dueDate: dueDate ?? DateTime.now().add(const Duration(days: 30)),
        note: note,
        isSplitEqually: true,
        createdAt: DateTime.now(),
        pgId: _currentProperty.id,
      );
      await _utilityRepo.createUtility(utility);
      if (_isDisposed) return;
      await loadAllData();
    } catch (e) {
      if (_isDisposed) return;
      debugPrint('[AppState] addUtility error: $e');
      rethrow;
    }
  }

  // Auth Actions
  Future<bool> login(String username, String password) async {
    if (_isDisposed) return false;
    try {
      debugPrint('[AUTH] Login started');
      _isLoading = true;
      notifyListeners();
      await _authRepo.signIn(
        username: username,
        password: password,
      );
      if (_isDisposed) return false;
      _isLoggedIn = true;
      debugPrint('[AUTH] Login successful');
      await _updateWardenFromStorage();
      if (_isDisposed) return false;
      await loadAllData();
      if (_isDisposed) return false;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      if (_isDisposed) return false;
      _isLoading = false;
      debugPrint('[AppState] login error: $e');
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    if (_isDisposed) return;
    debugPrint('[AUTH] Logout triggered');
    debugPrint('[AUTH] Logout reason: User initiated logout from Settings');
    await _authRepo.signOut();
    if (_isDisposed) return;
    _isLoggedIn = false;
    _rooms = [];
    _tenants = [];
    _invoices = [];
    _expenses = [];
    _tickets = [];
    _availableProperties = [];
    _currentProperty = const Property(
      id: '',
      name: 'Select Property',
      block: 'Main',
      address: 'Kathmandu, Nepal',
      totalBeds: 0,
      totalRooms: 0,
      totalFloors: 1,
      occupiedBeds: 0,
      clearanceLevel: 'Operational Warden Clearance',
      databaseSyncStatus: 'Offline',
    );
    notifyListeners();
  }

  void updateWarden(WardenProfile updated) {
    _warden = updated;
    notifyListeners();
  }

  Future<void> updateWardenSettings({
    bool? autoInvoiceCycle,
    bool? whatsAppReminders,
    bool? appPushAlerts,
    bool? criticalOverdueEscalation,
  }) async {
    _warden = _warden.copyWith(
      autoInvoiceCycle: autoInvoiceCycle,
      whatsAppReminders: whatsAppReminders,
      appPushAlerts: appPushAlerts,
      criticalOverdueEscalation: criticalOverdueEscalation,
    );
    if (autoInvoiceCycle != null) await _settings.put('setting.autoInvoiceCycle', autoInvoiceCycle);
    if (whatsAppReminders != null) await _settings.put('setting.whatsAppReminders', whatsAppReminders);
    if (appPushAlerts != null) await _settings.put('setting.appPushAlerts', appPushAlerts);
    if (criticalOverdueEscalation != null) await _settings.put('setting.criticalOverdueEscalation', criticalOverdueEscalation);
    notifyListeners();
  }

  void sendWhatsAppNotice(String message) {
    debugPrint('[AppState] WhatsApp notice: $message');
    notifyListeners();
  }

  // Filter and Search methods
  void setRoomSearch(String q) {
    _roomSearchQuery = q;
    notifyListeners();
  }
  void setRoomSearchQuery(String q) => setRoomSearch(q);
  void setTenantSearchQuery(String q) => setTenantSearch(q);
  void setInvoiceSearchQuery(String q) => setInvoiceSearch(q);
  void setExpenseSearchQuery(String q) => setExpenseSearch(q);

  void setRoomFilter(String filter) {
    _roomFilter = filter;
    notifyListeners();
  }

  List<Room> get filteredRooms {
    return _rooms.where((r) {
      final matchesSearch = r.roomNumber.toLowerCase().contains(_roomSearchQuery.toLowerCase()) ||
          r.floor.toLowerCase().contains(_roomSearchQuery.toLowerCase()) ||
          r.sharingType.toLowerCase().contains(_roomSearchQuery.toLowerCase()) ||
          r.slots.any((s) => (s.tenantName ?? '').toLowerCase().contains(_roomSearchQuery.toLowerCase()));

      if (!matchesSearch) return false;

      if (_roomFilter.contains('Vacant')) {
        return r.vacantCount > 0 && !r.isMaintenance;
      } else if (_roomFilter.contains('Partial')) {
        return r.isPartial;
      } else if (_roomFilter.contains('Occupied')) {
        return r.isFull;
      }
      return true;
    }).toList();
  }

  void setTenantSearch(String q) {
    _tenantSearchQuery = q;
    notifyListeners();
  }

  void setTenantFilter(String filter) {
    _tenantFilter = filter;
    notifyListeners();
  }

  List<Tenant> get filteredTenants {
    return _tenants.where((t) {
      final matchesSearch = t.fullName.toLowerCase().contains(_tenantSearchQuery.toLowerCase()) ||
          t.phoneNumber.contains(_tenantSearchQuery) ||
          t.roomNumber.toLowerCase().contains(_tenantSearchQuery.toLowerCase()) ||
          t.bedSlot.toLowerCase().contains(_tenantSearchQuery.toLowerCase());

      if (!matchesSearch) return false;

      if (_tenantFilter == 'Overdue') {
        return t.paymentStatus == TenantPaymentStatus.overdue;
      } else if (_tenantFilter == 'Pending') {
        return t.paymentStatus == TenantPaymentStatus.pending;
      } else if (_tenantFilter == 'Paid') {
        return t.paymentStatus == TenantPaymentStatus.paid;
      }
      return true;
    }).toList();
  }

  void setInvoiceSearch(String q) {
    _invoiceSearchQuery = q;
    notifyListeners();
  }

  void setInvoiceFilter(String filter) {
    _invoiceFilter = filter;
    notifyListeners();
  }

  List<Invoice> get filteredInvoices {
    return _invoices.where((inv) {
      final matchesSearch = inv.tenantName.toLowerCase().contains(_invoiceSearchQuery.toLowerCase()) ||
          inv.invoiceNumber.toLowerCase().contains(_invoiceSearchQuery.toLowerCase()) ||
          inv.roomInfo.toLowerCase().contains(_invoiceSearchQuery.toLowerCase());

      if (!matchesSearch) return false;

      if (_invoiceFilter.contains('Overdue')) {
        return inv.status == InvoiceStatus.overdue;
      } else if (_invoiceFilter.contains('Pending')) {
        return inv.status == InvoiceStatus.grace || inv.status == InvoiceStatus.unpaid;
      } else if (_invoiceFilter.contains('Paid')) {
        return inv.status == InvoiceStatus.paid;
      }
      return true;
    }).toList();
  }

  void setExpenseSearch(String q) {
    _expenseSearchQuery = q;
    notifyListeners();
  }

  void setExpenseFilter(String filter) {
    _expenseFilter = filter;
    notifyListeners();
  }

  List<Expense> get filteredExpenses {
    return _expenses.where((e) {
      final matchesSearch = e.title.toLowerCase().contains(_expenseSearchQuery.toLowerCase()) ||
          e.categoryLabel.toLowerCase().contains(_expenseSearchQuery.toLowerCase()) ||
          e.transactionRef.toLowerCase().contains(_expenseSearchQuery.toLowerCase());

      if (!matchesSearch) return false;

      if (_expenseFilter.contains('Mess')) {
        return e.category == ExpenseCategory.mess;
      } else if (_expenseFilter.contains('Utilities')) {
        return e.category == ExpenseCategory.utilities;
      } else if (_expenseFilter.contains('Salaries')) {
        return e.category == ExpenseCategory.salaries;
      }
      return true;
    }).toList();
  }
}
