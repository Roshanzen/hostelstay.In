import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/responsive_layout.dart';
import '../../../models/tenant.dart';
import '../../../models/room.dart';
import '../../../backend/core/api_client.dart';

class AddTenantScreen extends StatefulWidget {
  final Function(Tenant newTenant, {String? roomId, String? bedId}) onTenantAdded;
  final List<Room>? rooms;
  final Room? initialRoom;
  final String? initialBedSlot;

  const AddTenantScreen({
    super.key,
    required this.onTenantAdded,
    this.rooms,
    this.initialRoom,
    this.initialBedSlot,
  });

  @override
  State<AddTenantScreen> createState() => _AddTenantScreenState();
}

class _AddTenantScreenState extends State<AddTenantScreen> {
  // Form controllers
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController(text: '+977 ');
  final _emailController = TextEditingController();
  final _collegeController = TextEditingController();
  final _idNumberController = TextEditingController();
  final _moveInDateController = TextEditingController(text: DateFormat('dd MMM yyyy').format(DateTime.now()));
  late final TextEditingController _rentController;
  late final TextEditingController _depositController;
  final _guardianNameController = TextEditingController();
  final _guardianPhoneController = TextEditingController(text: '+977 ');
  final _addressController = TextEditingController(
    text: 'Kathmandu, Bagmati Province, Ward No. 4',
  );

  String _selectedIdType = 'Citizenship';
  Room? _selectedRoom;
  String _selectedBed = 'A';
  String _selectedDuration = '6 Mos';
  bool _wifiAddon = true;
  bool _depositReceived = true;
  final String _guardianRelation = 'Father';
  bool _rulesAgreed = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialRoom != null) {
      _selectedRoom = widget.initialRoom;
    } else if (widget.rooms != null && widget.rooms!.isNotEmpty) {
      _selectedRoom = widget.rooms!.first;
    }

    final initialRent = _selectedRoom?.rentAmount ?? 12000;
    _rentController = TextEditingController(text: initialRent.round().toString());
    _depositController = TextEditingController(text: initialRent.round().toString());

    if (widget.initialBedSlot != null && widget.initialBedSlot!.isNotEmpty) {
      _selectedBed = widget.initialBedSlot!;
    } else if (_selectedRoom != null) {
      final availableSlot = _selectedRoom!.slots.where((s) => !s.isOccupied).firstOrNull;
      if (availableSlot != null) {
        _selectedBed = availableSlot.slotId;
      }
    }

    _rentController.addListener(_onAmountChanged);
    _depositController.addListener(_onAmountChanged);
  }

  void _onAmountChanged() {
    setState(() {});
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _collegeController.dispose();
    _idNumberController.dispose();
    _moveInDateController.dispose();
    _rentController.dispose();
    _depositController.dispose();
    _guardianNameController.dispose();
    _guardianPhoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;

    if (!_rulesAgreed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please confirm agreement to HostelGhar House Rules')),
      );
      return;
    }

    final fullName = _nameController.text.trim();
    if (fullName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter full legal name')),
      );
      return;
    }

    if (_selectedRoom == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a room')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final cleanBed = _selectedBed.replaceAll('Bed ', '').trim();
    final bedDisplay = 'Bed $cleanBed';
    final roomDisplay = _selectedRoom?.roomNumber ?? 'Unassigned';

    final tenant = Tenant(
      id: 't-${DateTime.now().millisecondsSinceEpoch}',
      fullName: fullName,
      initials: fullName.split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join(),
      phoneNumber: _phoneController.text.trim(),
      email: _emailController.text.trim(),
      organizationOrCollege: _collegeController.text.trim(),
      isKycVerified: true,
      paymentStatus: TenantPaymentStatus.paid,
      statusLabel: 'Paid',
      roomNumber: roomDisplay,
      bedSlot: bedDisplay,
      floor: _selectedRoom?.floor ?? 'Floor 1',
      roomType: _selectedRoom?.sharingType ?? 'Standard',
      joinedDate: DateFormat('dd MMM yyyy').format(DateTime.now()),
      monthlyRent: double.tryParse(_rentController.text) ?? 12000,
      securityDeposit: double.tryParse(_depositController.text) ?? 12000,
      idType: _selectedIdType,
      idNumber: _idNumberController.text.trim(),
      guardianName: _guardianNameController.text.trim(),
      guardianRelation: _guardianRelation,
      guardianPhone: _guardianPhoneController.text.trim(),
      permanentAddress: _addressController.text.trim(),
    );

    try {
      await widget.onTenantAdded(tenant, roomId: _selectedRoom?.id, bedId: cleanBed);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Tenant ${tenant.fullName} admitted to $roomDisplay • $bedDisplay!'),
            backgroundColor: const Color(0xFF0D9488),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        String errorMsg;
        if (e is ApiException) {
          if (e.errors != null && e.errors!.containsKey('bed')) {
            final bedErr = e.errors!['bed'];
            errorMsg = bedErr is List ? bedErr.join(', ') : bedErr.toString();
          } else {
            errorMsg = e.message;
          }
        } else {
          errorMsg = e.toString().replaceAll('Exception: ', '');
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMsg),
            backgroundColor: const Color(0xFFDC2626),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      child: Scaffold(
        backgroundColor: context.backgroundColor,
        appBar: AppBar(
          backgroundColor: context.surfaceColor,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.close_rounded, color: context.textPrimaryColor),
            onPressed: () => Navigator.pop(context),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: context.primaryTintColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.home_work_rounded, color: AppColors.primaryAccent, size: 16),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Add New Tenant', style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: context.textPrimaryColor)),
                  Text('Hostel Resident Registration', style: TextStyle(fontSize: 10.5, color: context.textSecondaryColor)),
                ],
              ),
            ],
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(
                  color: Color(0xFF8D4004),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.person, color: Colors.white, size: 18),
              ),
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Step Progress Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Step 1 of 4', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: context.orangeFgColor)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: context.orangeTintColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text('25% Completed', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: context.orangeFgColor)),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: 0.25,
                  minHeight: 5,
                  backgroundColor: context.borderColor,
                  valueColor: AlwaysStoppedAnimation<Color>(context.orangeFgColor),
                ),
              ),
              const SizedBox(height: 12),

              // Step Icons row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStepIcon(Icons.person_rounded, 'Personal', true),
                  _buildStepIcon(Icons.bed_rounded, 'Room', false),
                  _buildStepIcon(Icons.payments_rounded, 'Rent', false),
                  _buildStepIcon(Icons.family_restroom_rounded, 'Guardian', false),
                ],
              ),
              const SizedBox(height: 16),

              // Property Banner
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: context.indigoTintColor,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: context.indigoFgColor.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: context.cardColor,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Icon(Icons.apartment_rounded, color: context.indigoFgColor, size: 16),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _selectedRoom != null
                                ? 'Selected: ${_selectedRoom!.roomNumber}'
                                : 'Resident Admission',
                            style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: context.textPrimaryColor),
                          ),
                          Text(
                            _selectedRoom != null
                                ? 'Admitting to ${_selectedRoom!.roomNumber} (${_selectedRoom!.sharingType}) • Bed $_selectedBed'
                                : 'Choose room and bed slot below',
                            style: TextStyle(fontSize: 10.5, color: context.textSecondaryColor),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // SECTION 1: Resident Profile & KYC
              _buildSectionCard(
                title: '1. Resident Profile & KYC',
                badgeText: 'Required',
                badgeBg: context.tealTintColor,
                badgeFg: context.tealFgColor,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Headshot row
                    Row(
                      children: [
                        Container(
                          width: 54,
                          height: 54,
                          decoration: BoxDecoration(
                            color: context.orangeTintColor,
                            shape: BoxShape.circle,
                            border: Border.all(color: context.orangeFgColor.withValues(alpha: 0.5), width: 2),
                          ),
                          child: Icon(Icons.person_outline_rounded, color: context.orangeFgColor, size: 32),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Resident Headshot', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: context.textPrimaryColor)),
                              Text('Clear front photo for PG register and digital smart door access...', style: TextStyle(fontSize: 10, color: context.textSecondaryColor)),
                              const SizedBox(height: 4),
                              InkWell(
                                onTap: () {
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Photo selected from camera/gallery.')));
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: context.surfaceSecondaryColor,
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(color: context.borderColor),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.camera_alt_outlined, size: 12, color: context.textPrimaryColor),
                                      const SizedBox(width: 4),
                                      Text('Choose Photo', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: context.textPrimaryColor)),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    _buildFieldLabel('Full Legal Name *'),
                    _buildInputField(_nameController, Icons.badge_outlined),
                    const SizedBox(height: 10),

                    _buildFieldLabel('Mobile Number *'),
                    _buildInputField(_phoneController, Icons.phone_outlined),
                    const SizedBox(height: 10),

                    _buildFieldLabel('Email Address'),
                    _buildInputField(_emailController, Icons.mail_outline_rounded),
                    const SizedBox(height: 10),

                    _buildFieldLabel('College / Workplace'),
                    _buildInputField(_collegeController, Icons.school_outlined),
                    const SizedBox(height: 14),

                    _buildFieldLabel('Government ID Verification *'),
                    Row(
                      children: ['Citizenship', 'National ID', 'Passport', 'License'].map((id) {
                        final isSel = _selectedIdType == id;
                        return Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _selectedIdType = id),
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 3),
                              padding: const EdgeInsets.symmetric(vertical: 7),
                              decoration: BoxDecoration(
                                color: isSel ? AppColors.primary : context.surfaceSecondaryColor,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: isSel ? AppColors.primary : context.borderColor),
                              ),
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 4),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      if (isSel) const Icon(Icons.check, size: 12, color: Colors.white),
                                      if (isSel) const SizedBox(width: 4),
                                      Text(
                                        id,
                                        style: TextStyle(
                                          fontSize: 10.5,
                                          fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
                                          color: isSel ? Colors.white : context.textSecondaryColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 10),
                    _buildInputField(_idNumberController, Icons.credit_card_outlined),
                    const SizedBox(height: 12),

                    // Document Upload Cards (Front & Back)
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: context.surfaceSecondaryColor,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: context.borderColor),
                            ),
                            child: Column(
                              children: [
                                Container(
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: context.elevatedSurfaceColor,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Center(
                                    child: Icon(Icons.contact_mail_outlined, color: context.textSecondaryColor, size: 24),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text('Front Side.pdf', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: context.textPrimaryColor)),
                                    const SizedBox(width: 4),
                                    Icon(Icons.check_circle_rounded, size: 12, color: context.tealFgColor),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: context.orangeTintColor,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: context.orangeFgColor.withValues(alpha: 0.4), style: BorderStyle.solid),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.cloud_upload_outlined, color: context.orangeFgColor, size: 22),
                                const SizedBox(height: 4),
                                Text('Upload Back', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: context.orangeFgColor)),
                                Text('Citizenship Backside', style: TextStyle(fontSize: 8.5, color: context.textSecondaryColor)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // SECTION 2: Room & Bed Allocation
              _buildSectionCard(
                title: '2. Room & Bed Allocation',
                badgeText: _selectedRoom != null ? '${_selectedRoom!.vacantCount} Bed${_selectedRoom!.vacantCount == 1 ? "" : "s"} Vacant' : 'Select Room',
                badgeBg: context.tealTintColor,
                badgeFg: context.tealFgColor,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFieldLabel('Select Room'),
                    DropdownButtonHideUnderline(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          color: context.surfaceSecondaryColor,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: context.borderColor),
                        ),
                        child: DropdownButton<Room>(
                          isExpanded: true,
                          value: _selectedRoom,
                          dropdownColor: context.cardColor,
                          hint: Text('Select room', style: TextStyle(fontSize: 11.5, color: context.textMutedColor)),
                          items: widget.rooms
                              ?.map((room) => DropdownMenuItem<Room>(
                                    value: room,
                                    child: Text(
                                      '${room.roomNumber} • ${room.sharingType}',
                                      style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: context.textPrimaryColor),
                                    ),
                                  ))
                              .toList(),
                          onChanged: (room) => setState(() {
                            _selectedRoom = room;
                            if (room != null) {
                              _rentController.text = room.rentAmount.round().toString();
                              _depositController.text = room.rentAmount.round().toString();
                              final availableSlot = room.slots.where((s) => !s.isOccupied).firstOrNull;
                              if (availableSlot != null) {
                                _selectedBed = availableSlot.slotId;
                              }
                            }
                          }),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Bed Slot Allocation *', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: context.textSecondaryColor)),
                        Text('Tap to select bed', style: TextStyle(fontSize: 10, color: context.textMutedColor)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (_selectedRoom == null || _selectedRoom!.slots.isEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: context.surfaceSecondaryColor,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: context.borderColor),
                        ),
                        child: Text('Select a room to view available beds.', style: TextStyle(fontSize: 11.5, color: context.textSecondaryColor)),
                      )
                    else
                      ..._selectedRoom!.slots.map((slot) {
                        final isSelected = _selectedBed == slot.slotId;
                        final isAvailable = !slot.isOccupied;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: GestureDetector(
                            onTap: isAvailable ? () => setState(() => _selectedBed = slot.slotId) : null,
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: isSelected ? context.orangeTintColor : context.surfaceSecondaryColor,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: isSelected ? context.orangeFgColor : context.borderColor,
                                  width: isSelected ? 1.5 : 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.bed_rounded, size: 16, color: isSelected ? context.orangeFgColor : context.textSecondaryColor),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Bed ${slot.slotId}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                                            color: isSelected ? context.orangeFgColor : context.textPrimaryColor,
                                          ),
                                        ),
                                        Text(
                                          isAvailable ? 'Ready for Move-in' : 'Occupied by ${slot.tenantName ?? "tenant"}',
                                          style: TextStyle(fontSize: 10, color: context.textSecondaryColor),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (isSelected) Icon(Icons.check_circle_rounded, size: 16, color: context.orangeFgColor),
                                ],
                              ),
                            ),
                          ),
                        );
                      }),
                    const SizedBox(height: 14),

                    _buildFieldLabel('Admission / Move-in Date'),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: context.surfaceSecondaryColor,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: context.borderColor),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.calendar_today_outlined, size: 15, color: context.textSecondaryColor),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _moveInDateController.text,
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: context.textPrimaryColor),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: context.elevatedSurfaceColor,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text('Today', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: context.textPrimaryColor)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    _buildFieldLabel('Agreement Duration'),
                    Row(
                      children: ['3 Mos', '6 Mos', '11 Mos'].map((d) {
                        final isSel = _selectedDuration == d;
                        return Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _selectedDuration = d),
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 3),
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                color: isSel ? const Color(0xFF9A3412) : context.surfaceSecondaryColor,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Center(
                                child: Text(
                                  d,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
                                    color: isSel ? Colors.white : context.textSecondaryColor,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // SECTION 3: Rent & Deposit Terms
              _buildSectionCard(
                title: '3. Rent & Deposit Terms',
                badgeText: 'Cycle: 1st / Mo',
                badgeBg: context.surfaceSecondaryColor,
                badgeFg: context.textSecondaryColor,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildFieldLabel('Monthly Base Rent'),
                              _buildInputField(_rentController, Icons.payments_outlined),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildFieldLabel('Security Deposit'),
                              _buildInputField(_depositController, Icons.account_balance_wallet_outlined),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Addon checkbox
                    InkWell(
                      onTap: () => setState(() => _wifiAddon = !_wifiAddon),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          color: _wifiAddon ? context.tealTintColor : context.surfaceSecondaryColor,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: _wifiAddon ? context.tealFgColor.withValues(alpha: 0.4) : context.borderColor),
                        ),
                        child: Row(
                          children: [
                            Checkbox(
                              value: _wifiAddon,
                              activeColor: const Color(0xFF0D9488),
                              onChanged: (v) => setState(() => _wifiAddon = v ?? false),
                            ),
                            Icon(Icons.wifi_rounded, size: 16, color: context.tealFgColor),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Maintenance & High-Speed WiFi', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: context.textPrimaryColor)),
                                  Text('Daily housekeeping, 300 Mbps fiber & laundry', style: TextStyle(fontSize: 9.5, color: context.textSecondaryColor)),
                                ],
                              ),
                            ),
                            Text('+${CurrencyFormatter.format(1000)}', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: context.tealFgColor)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    Row(
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: Checkbox(
                            value: _depositReceived,
                            activeColor: const Color(0xFFC2410C),
                            onChanged: (v) => setState(() => _depositReceived = v ?? false),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text('Security Deposit Received Upfront', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: context.textPrimaryColor)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // SECTION 4: Guardian & Emergency Info
              _buildSectionCard(
                title: '4. Guardian & Emergency Info',
                badgeText: 'Mandatory',
                badgeBg: context.tealTintColor,
                badgeFg: context.tealFgColor,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFieldLabel('Guardian / Parent Name *'),
                    _buildInputField(_guardianNameController, Icons.person_outline_rounded),
                    const SizedBox(height: 10),

                    _buildFieldLabel('Relationship'),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: context.surfaceSecondaryColor,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: context.borderColor),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(_guardianRelation, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: context.textPrimaryColor)),
                          Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: context.textSecondaryColor),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),

                    _buildFieldLabel('Emergency Contact Phone *'),
                    _buildInputField(_guardianPhoneController, Icons.phone_outlined),
                    const SizedBox(height: 10),

                    _buildFieldLabel('Permanent Home Address'),
                    _buildInputField(_addressController, Icons.home_outlined),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Initial Billing Snapshot
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: context.tealTintColor.withValues(alpha: context.isDarkMode ? 0.5 : 1.0),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: context.tealFgColor.withValues(alpha: 0.4)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Icon(Icons.receipt_long_rounded, size: 16, color: context.tealFgColor),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  'Initial Billing Snapshot',
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: context.textPrimaryColor),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: context.tealTintColor,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text('Invoice Ready', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700, color: context.tealFgColor)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Builder(
                      builder: (ctx) {
                        final rentVal = double.tryParse(_rentController.text.trim()) ?? (_selectedRoom?.rentAmount ?? 0.0);
                        final depVal = double.tryParse(_depositController.text.trim()) ?? rentVal;
                        final utilVal = _wifiAddon ? 1000.0 : 0.0;
                        final advVal = _depositReceived ? depVal : 0.0;
                        final netDue = (rentVal + depVal + utilVal) - advVal;
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSnapshotRow('First Month Rent (${_selectedRoom?.roomNumber ?? "Room"})', CurrencyFormatter.format(rentVal)),
                            _buildSnapshotRow('Security Deposit (Refundable)', CurrencyFormatter.format(depVal)),
                            _buildSnapshotRow('Maintenance & Utilities Charge', CurrencyFormatter.format(utilVal)),
                            if (_depositReceived)
                              _buildSnapshotRow(
                                'Deposit Advance Received',
                                '- ${CurrencyFormatter.format(advVal)}',
                                isRed: true,
                              ),
                            Divider(height: 16, color: context.dividerColor),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Net Balance Due on Move-In', style: TextStyle(fontSize: 10, color: context.textSecondaryColor)),
                                      Text(
                                        CurrencyFormatter.format(netDue),
                                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: context.textPrimaryColor),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                OutlinedButton.icon(
                                  onPressed: () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Generating printable admission invoice slip...')),
                                    );
                                  },
                                  icon: const Icon(Icons.print_outlined, size: 14),
                                  label: const Text('Print Slip', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: context.textPrimaryColor,
                                    side: BorderSide(color: context.borderColor),
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    minimumSize: const Size(0, 32),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Agreement confirmation
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: Checkbox(
                      value: _rulesAgreed,
                      activeColor: const Color(0xFF9A3412),
                      onChanged: (v) => setState(() => _rulesAgreed = v ?? false),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'I confirm that the physical document verification is authenticated and resident has agreed to the HostelGhar House Rules & curfew policies.',
                      style: TextStyle(fontSize: 10.5, color: context.textSecondaryColor, height: 1.3),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Bottom Actions: Cancel & Save
              Row(
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('Cancel', style: TextStyle(color: context.textSecondaryColor, fontWeight: FontWeight.w600)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: ElevatedButton.icon(
                        onPressed: _isSubmitting ? null : _submit,
                        icon: _isSubmitting
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.person_add_alt_1_rounded, size: 18, color: Colors.white),
                        label: Text(
                          _isSubmitting ? 'Admitting Tenant...' : '+ Save & Admit Tenant',
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF9A3412),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusFull)),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepIcon(IconData icon, String label, bool isActive) {
    return Column(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFFC2410C) : context.surfaceSecondaryColor,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 18, color: isActive ? Colors.white : context.textMutedColor),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
            color: isActive ? context.orangeFgColor : context.textMutedColor,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionCard({
    required String title,
    required String badgeText,
    required Color badgeBg,
    required Color badgeFg,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.borderColor),
        boxShadow: context.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: context.textPrimaryColor),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: badgeBg,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(badgeText, style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700, color: badgeFg)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: context.textSecondaryColor)),
    );
  }

  Widget _buildInputField(TextEditingController controller, IconData icon) {
    return Container(
      decoration: BoxDecoration(
        color: context.surfaceSecondaryColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: context.borderColor),
      ),
      child: TextField(
        controller: controller,
        style: TextStyle(fontSize: 12.5, color: context.textPrimaryColor),
        decoration: InputDecoration(
          filled: false,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          prefixIcon: Icon(icon, size: 16, color: context.textSecondaryColor),
        ),
      ),
    );
  }

  Widget _buildSnapshotRow(String label, String value, {bool isRed = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(fontSize: 11, color: context.textSecondaryColor),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: isRed ? context.redFgColor : context.textPrimaryColor,
            ),
          ),
        ],
      ),
    );
  }
}
