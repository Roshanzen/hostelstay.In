import 'package:hive/hive.dart';
import '../../backend/models/tenant.dart';
import '../core/api_client.dart';
import '../core/storage/auth_storage.dart';

class TenantRepository {
  TenantRepository(this._settings, this._authStorage);
  final Box<dynamic> _settings;
  final AuthStorage _authStorage;

  Future<List<Tenant>> fetchForPg(String pgId) async {
    try {
      final client = ApiClient(authStorage: _authStorage);
      final data = await client.get('/api/tenants/tenants/?pg=$pgId');
      final list = (data['results'] ?? data['value'] ?? <dynamic>[]) as List<dynamic>;
      final result = list.map((e) {
        final m = Map<String, dynamic>.from(e as Map);
        final idTypeStr = (m['id_type'] ?? 'other').toString().toLowerCase();
        return Tenant(
          id: m['id']?.toString() ?? '',
          name: m['name']?.toString() ?? '',
          phone: m['phone']?.toString() ?? '',
          email: m['email']?.toString(),
          emergencyContact: m['emergency_contact']?.toString() ?? '',
          idNumber: m['id_number']?.toString() ?? '',
          idType: idTypeStr.contains('passport')
              ? IdType.passport
              : idTypeStr.contains('license')
                  ? IdType.drivingLicense
                  : IdType.citizenship,
          roomId: m['room']?.toString() ?? m['room_number']?.toString() ?? '',
          bedId: m['bed']?.toString() ?? m['bed_label']?.toString(),
          moveInDate: DateTime.tryParse(m['move_in_date']?.toString() ?? '') ?? DateTime.now(),
          monthlyRent: double.tryParse(m['rent_amount']?.toString() ?? '0') ?? 0,
          securityDeposit: double.tryParse(m['security_deposit']?.toString() ?? '0') ?? 0,
          depositDeductions: double.tryParse(m['deposit_deductions']?.toString() ?? '0') ?? 0,
          isActive: (m['status'] ?? 'active').toString().toLowerCase() == 'active',
          guardianName: m['guardian_name']?.toString(),
          guardianPhone: m['guardian_phone']?.toString(),
          address: m['address']?.toString(),
          outstandingBalance: double.tryParse(m['outstanding_balance']?.toString() ?? '0') ?? 0,
        );
      }).toList();
      await _settings.put('cache.tenants_$pgId', list);
      return result;
    } catch (_) {
      final cached = _settings.get('cache.tenants_$pgId');
      if (cached is List) {
        return cached.map((e) {
          final m = Map<String, dynamic>.from(e as Map);
          final idTypeStr = (m['id_type'] ?? 'other').toString().toLowerCase();
          return Tenant(
            id: m['id']?.toString() ?? '',
            name: m['name']?.toString() ?? '',
            phone: m['phone']?.toString() ?? '',
            email: m['email']?.toString(),
            emergencyContact: m['emergency_contact']?.toString() ?? '',
            idNumber: m['id_number']?.toString() ?? '',
            idType: idTypeStr.contains('passport')
                ? IdType.passport
                : idTypeStr.contains('license')
                    ? IdType.drivingLicense
                    : IdType.citizenship,
            roomId: m['room']?.toString() ?? m['room_number']?.toString() ?? '',
            bedId: m['bed']?.toString() ?? m['bed_label']?.toString(),
            moveInDate: DateTime.tryParse(m['move_in_date']?.toString() ?? '') ?? DateTime.now(),
            monthlyRent: double.tryParse(m['rent_amount']?.toString() ?? '0') ?? 0,
            securityDeposit: double.tryParse(m['security_deposit']?.toString() ?? '0') ?? 0,
            depositDeductions: double.tryParse(m['deposit_deductions']?.toString() ?? '0') ?? 0,
            isActive: (m['status'] ?? 'active').toString().toLowerCase() == 'active',
            guardianName: m['guardian_name']?.toString(),
            guardianPhone: m['guardian_phone']?.toString(),
            address: m['address']?.toString(),
            outstandingBalance: double.tryParse(m['outstanding_balance']?.toString() ?? '0') ?? 0,
          );
        }).toList();
      }
      return [];
    }
  }

  Future<Tenant> createTenant(Tenant tenant) async {
    final client = ApiClient(authStorage: _authStorage);
    final idTypeStr = tenant.idType == IdType.citizenship
        ? 'citizenship'
        : tenant.idType == IdType.passport
            ? 'passport'
            : tenant.idType == IdType.drivingLicense
                ? 'drivingLicense'
                : 'other';


    final effectivePg = tenant.pgId.isNotEmpty
        ? (int.tryParse(tenant.pgId) ?? tenant.pgId)
        : (_settings.get('active_pg_id') ?? '');

    final body = <String, dynamic>{
      'name': tenant.name,
      'phone': tenant.phone,
      if (tenant.email != null && tenant.email!.isNotEmpty) 'email': tenant.email,
      'emergency_contact': tenant.emergencyContact,
      'id_number': tenant.idNumber,
      'id_type': idTypeStr,
      'room': int.tryParse(tenant.roomId) ?? tenant.roomId,
      if (tenant.bedId != null && tenant.bedId!.isNotEmpty)
        'bed': int.tryParse(tenant.bedId!) ?? tenant.bedId,
      'move_in_date': tenant.moveInDate.toIso8601String().split('T').first,
      'rent_amount': tenant.monthlyRent,
      'security_deposit': tenant.securityDeposit,
      'deposit_deductions': tenant.depositDeductions,
      'status': tenant.isActive ? 'active' : 'inactive',
      if (tenant.guardianName != null && tenant.guardianName!.isNotEmpty)
        'guardian_name': tenant.guardianName,
      if (tenant.guardianPhone != null && tenant.guardianPhone!.isNotEmpty)
        'guardian_phone': tenant.guardianPhone,
      if (tenant.address != null && tenant.address!.isNotEmpty)
        'address': tenant.address,
      'pg': effectivePg,
    };

    final data = await client.post('/api/tenants/tenants/', body);
    final respObj = data['tenant'] is Map ? Map<String, dynamic>.from(data['tenant'] as Map) : data;
    final idTypeStrResp = (respObj['id_type'] ?? 'other').toString().toLowerCase();

    return Tenant(
      id: respObj['id']?.toString() ?? tenant.id,
      name: respObj['name']?.toString() ?? tenant.name,
      phone: respObj['phone']?.toString() ?? tenant.phone,
      email: respObj['email']?.toString(),
      emergencyContact: respObj['emergency_contact']?.toString() ?? tenant.emergencyContact,
      idNumber: respObj['id_number']?.toString() ?? tenant.idNumber,
      idType: idTypeStrResp.contains('passport')
          ? IdType.passport
          : idTypeStrResp.contains('license')
              ? IdType.drivingLicense
              : IdType.citizenship,
      roomId: respObj['room']?.toString() ?? respObj['room_number']?.toString() ?? tenant.roomId,
      bedId: respObj['bed']?.toString() ?? respObj['bed_label']?.toString() ?? tenant.bedId,
      moveInDate: DateTime.tryParse(respObj['move_in_date']?.toString() ?? '') ?? tenant.moveInDate,
      monthlyRent: double.tryParse(respObj['rent_amount']?.toString() ?? '${tenant.monthlyRent}') ?? tenant.monthlyRent,
      securityDeposit: double.tryParse(respObj['security_deposit']?.toString() ?? '${tenant.securityDeposit}') ?? tenant.securityDeposit,
      depositDeductions: double.tryParse(respObj['deposit_deductions']?.toString() ?? '${tenant.depositDeductions}') ?? tenant.depositDeductions,
      isActive: (respObj['status'] ?? 'active').toString().toLowerCase() == 'active',
      guardianName: respObj['guardian_name']?.toString() ?? tenant.guardianName,
      guardianPhone: respObj['guardian_phone']?.toString() ?? tenant.guardianPhone,
      address: respObj['address']?.toString() ?? tenant.address,
      outstandingBalance: double.tryParse(respObj['outstanding_balance']?.toString() ?? '0') ?? 0,
      pgId: respObj['pg']?.toString() ?? tenant.pgId,
    );
  }

  Future<void> updateTenant(Tenant tenant) async {
    final client = ApiClient(authStorage: _authStorage);
    final path = '/api/tenants/tenants/${tenant.id}/';
    final body = <String, dynamic>{
      if (tenant.name.isNotEmpty) 'name': tenant.name,
      if (tenant.phone.isNotEmpty) 'phone': tenant.phone,
      if (tenant.email != null) 'email': tenant.email,
      'status': tenant.isActive ? 'active' : 'inactive',
    };
    await client.patch(path, body);
  }
}

