import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PhoneAccessResult {
  final bool hasBasicProfile;
  final bool hasAcceptedTerms;

  const PhoneAccessResult({
    required this.hasBasicProfile,
    required this.hasAcceptedTerms,
  });
}

class FamilyOverview {
  final String familyName;
  final String userRole;
  final int memberCount;
  final int petCount;
  final int medicalRecordsCount;
  final List<FamilyMemberSummary> members;

  const FamilyOverview({
    required this.familyName,
    required this.userRole,
    required this.memberCount,
    required this.petCount,
    required this.medicalRecordsCount,
    required this.members,
  });
}

class FamilyMemberSummary {
  final String name;
  final String phone;
  final String role;
  final bool canEditPets;
  final bool canViewMedical;

  const FamilyMemberSummary({
    required this.name,
    required this.phone,
    required this.role,
    required this.canEditPets,
    required this.canViewMedical,
  });
}

class UserRoleSummary {
  final String role;
  final String label;
  final String status;

  const UserRoleSummary({
    required this.role,
    required this.label,
    required this.status,
  });
}

class MedicalRecordSummary {
  final String id;
  final String petName;
  final String title;
  final String recordType;
  final String dateLabel;
  final String createdBy;
  final String notes;
  final bool verifiedByVet;

  const MedicalRecordSummary({
    required this.id,
    required this.petName,
    required this.title,
    required this.recordType,
    required this.dateLabel,
    required this.createdBy,
    required this.notes,
    required this.verifiedByVet,
  });
}

class AccountService {
  final SupabaseClient _supabase = Supabase.instance.client;

  String normalizePhone({required String countryCode, required String phone}) {
    final digits = phone.replaceAll(RegExp(r'[^0-9]'), '');
    final cleanCountry = countryCode.startsWith('+')
        ? countryCode
        : '+$countryCode';
    return '$cleanCountry$digits';
  }

  Future<void> requestWhatsAppOtp(String normalizedPhone) async {
    await _supabase.auth.signInWithOtp(
      phone: normalizedPhone,
      shouldCreateUser: true,
      channel: OtpChannel.whatsapp,
      data: {
        'phone': normalizedPhone,
        'login_channel': 'whatsapp',
        'default_role': 'pet_owner',
      },
    );
  }

  Future<PhoneAccessResult> verifyWhatsAppOtp({
    required String normalizedPhone,
    required String code,
  }) async {
    final response = await _supabase.auth.verifyOTP(
      phone: normalizedPhone,
      token: code,
      type: OtpType.sms,
    );

    final user = response.user ?? _supabase.auth.currentUser;
    if (user == null) {
      throw const AuthException('No se pudo crear la sesion.');
    }

    final profile = await _safeProfile(user.id);
    await _ensureBaseRole(user.id);

    return PhoneAccessResult(
      hasBasicProfile:
          profile != null &&
          (profile['full_name']?.toString().trim().isNotEmpty ?? false),
      hasAcceptedTerms: profile?['has_accepted_terms'] == true,
    );
  }

  Future<void> completePhoneProfile({
    required String fullName,
    required String city,
    required String normalizedPhone,
    required String familyName,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      throw const AuthException('No hay una sesion activa.');
    }

    await _upsertProfile(
      userId: user.id,
      fullName: fullName,
      city: city,
      normalizedPhone: normalizedPhone,
    );
    await _ensureBaseRole(user.id);
    await _ensureFamily(
      userId: user.id,
      familyName: familyName.trim().isEmpty ? 'Mi familia' : familyName.trim(),
    );
  }

  Future<FamilyOverview> getFamilyOverview() async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      return _fallbackFamilyOverview();
    }

    try {
      final membership = await _supabase
          .from('family_members')
          .select('family_id, role')
          .eq('user_id', user.id)
          .eq('status', 'active')
          .limit(1)
          .maybeSingle();

      if (membership == null) {
        return _fallbackFamilyOverview();
      }

      final familyId = membership['family_id'].toString();
      final family = await _supabase
          .from('family_groups')
          .select('name')
          .eq('id', familyId)
          .maybeSingle();

      final membersData = await _supabase
          .from('family_members')
          .select(
            'role, can_edit_pets, can_view_medical, profiles(full_name, phone)',
          )
          .eq('family_id', familyId)
          .eq('status', 'active');

      final petsData = await _supabase
          .from('pets')
          .select('id')
          .eq('family_id', familyId);

      final recordsData = await _supabase
          .from('medical_records')
          .select('id')
          .eq('family_id', familyId);

      final members = List<Map<String, dynamic>>.from(
        membersData,
      ).map(_memberFromMap).toList();

      return FamilyOverview(
        familyName: family?['name']?.toString() ?? 'Mi familia',
        userRole: membership['role']?.toString() ?? 'admin',
        memberCount: members.length,
        petCount: List<dynamic>.from(petsData).length,
        medicalRecordsCount: List<dynamic>.from(recordsData).length,
        members: members,
      );
    } catch (e) {
      debugPrint('AccountService.getFamilyOverview fallback: $e');
      return _fallbackFamilyOverview();
    }
  }

  Future<List<UserRoleSummary>> getRoles() async {
    final user = _supabase.auth.currentUser;
    const defaults = [
      UserRoleSummary(
        role: 'pet_owner',
        label: 'Cliente / familia',
        status: 'active',
      ),
      UserRoleSummary(role: 'vet', label: 'Veterinario', status: 'inactive'),
      UserRoleSummary(
        role: 'rescuer',
        label: 'Rescatista / refugio',
        status: 'inactive',
      ),
    ];

    if (user == null) {
      return defaults;
    }

    try {
      final response = await _supabase
          .from('user_roles')
          .select('role, status')
          .eq('user_id', user.id);
      final active = {
        for (final row in List<Map<String, dynamic>>.from(response))
          row['role'].toString(): row['status'].toString(),
      };

      return defaults
          .map(
            (role) => UserRoleSummary(
              role: role.role,
              label: role.label,
              status: active[role.role] ?? role.status,
            ),
          )
          .toList();
    } catch (e) {
      debugPrint('AccountService.getRoles fallback: $e');
      return defaults;
    }
  }

  Future<void> activateRole({
    required String role,
    String? licenseNumber,
    String? organizationName,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      return;
    }

    try {
      await _supabase.from('user_roles').upsert({
        'user_id': user.id,
        'role': role,
        'status': role == 'vet' ? 'pending_verification' : 'active',
        'metadata': {
          if (licenseNumber != null && licenseNumber.trim().isNotEmpty)
            'license_number': licenseNumber.trim(),
          if (organizationName != null && organizationName.trim().isNotEmpty)
            'organization_name': organizationName.trim(),
        },
      });

      if (role == 'vet') {
        await _supabase.from('vet_profiles').upsert({
          'user_id': user.id,
          'license_number': licenseNumber,
          'clinic_name': organizationName,
          'verification_status': 'pending',
        });
      }
    } catch (e) {
      debugPrint('AccountService.activateRole ignored: $e');
    }
  }

  Future<void> inviteFamilyMember({
    required String phone,
    required String role,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      return;
    }

    try {
      final membership = await _supabase
          .from('family_members')
          .select('family_id')
          .eq('user_id', user.id)
          .eq('status', 'active')
          .limit(1)
          .maybeSingle();

      if (membership == null) {
        return;
      }

      await _supabase.from('family_invites').insert({
        'family_id': membership['family_id'],
        'invited_by': user.id,
        'phone': phone,
        'role': role,
        'status': 'pending',
      });
    } catch (e) {
      debugPrint('AccountService.inviteFamilyMember ignored: $e');
    }
  }

  Future<List<MedicalRecordSummary>> getMedicalRecords() async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      return _fallbackMedicalRecords();
    }

    try {
      final membership = await _supabase
          .from('family_members')
          .select('family_id')
          .eq('user_id', user.id)
          .eq('status', 'active')
          .limit(1)
          .maybeSingle();
      final familyId = membership?['family_id']?.toString();

      if (familyId == null) {
        return _fallbackMedicalRecords();
      }

      final response = await _supabase
          .from('medical_records')
          .select(
            'id, pet_name, title, record_type, visit_date, created_by_name, notes, verified_by_vet',
          )
          .eq('family_id', familyId)
          .order('visit_date', ascending: false);

      final records = List<Map<String, dynamic>>.from(
        response,
      ).map(_medicalRecordFromMap).toList();

      if (records.isNotEmpty) {
        return records;
      }
    } catch (e) {
      debugPrint('AccountService.getMedicalRecords fallback: $e');
    }

    return _fallbackMedicalRecords();
  }

  Future<void> createMedicalRecord({
    required String petName,
    required String title,
    required String recordType,
    required String notes,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      return;
    }

    try {
      final membership = await _supabase
          .from('family_members')
          .select('family_id')
          .eq('user_id', user.id)
          .eq('status', 'active')
          .limit(1)
          .maybeSingle();

      await _supabase.from('medical_records').insert({
        'family_id': membership?['family_id'],
        'created_by': user.id,
        'created_by_name':
            user.userMetadata?['full_name']?.toString() ?? 'PetScanIA',
        'pet_name': petName,
        'title': title,
        'record_type': recordType,
        'notes': notes,
        'visit_date': DateTime.now().toUtc().toIso8601String(),
        'verified_by_vet': false,
      });
    } catch (e) {
      debugPrint('AccountService.createMedicalRecord ignored: $e');
    }
  }

  Future<String> createVetAccessCode() async {
    final user = _supabase.auth.currentUser;
    final code = DateTime.now().millisecondsSinceEpoch.toString().substring(
      7,
      13,
    );

    if (user == null) {
      return code;
    }

    try {
      final membership = await _supabase
          .from('family_members')
          .select('family_id')
          .eq('user_id', user.id)
          .eq('status', 'active')
          .limit(1)
          .maybeSingle();

      await _supabase.from('vet_access_codes').insert({
        'family_id': membership?['family_id'],
        'created_by': user.id,
        'code': code,
        'status': 'active',
        'expires_at': DateTime.now()
            .add(const Duration(minutes: 20))
            .toUtc()
            .toIso8601String(),
      });
    } catch (e) {
      debugPrint('AccountService.createVetAccessCode fallback: $e');
    }

    return code;
  }

  Future<Map<String, dynamic>?> _safeProfile(String userId) async {
    try {
      return await _supabase
          .from('profiles')
          .select('id, full_name, has_accepted_terms, phone')
          .eq('id', userId)
          .maybeSingle();
    } catch (e) {
      debugPrint('AccountService._safeProfile ignored: $e');
      return null;
    }
  }

  Future<void> _upsertProfile({
    required String userId,
    required String fullName,
    required String city,
    required String normalizedPhone,
  }) async {
    try {
      await _supabase.from('profiles').upsert({
        'id': userId,
        'full_name': fullName,
        'phone': normalizedPhone,
        'city': city,
        'country_code': normalizedPhone.startsWith('+51') ? 'PE' : null,
        'phone_verified_at': DateTime.now().toUtc().toIso8601String(),
        'has_accepted_terms': false,
      });
    } catch (e) {
      debugPrint('AccountService._upsertProfile minimal fallback: $e');
      await _supabase.from('profiles').upsert({
        'id': userId,
        'full_name': fullName,
        'has_accepted_terms': false,
      });
    }
  }

  Future<void> _ensureBaseRole(String userId) async {
    try {
      await _supabase.from('user_roles').upsert({
        'user_id': userId,
        'role': 'pet_owner',
        'status': 'active',
      });
    } catch (e) {
      debugPrint('AccountService._ensureBaseRole ignored: $e');
    }
  }

  Future<void> _ensureFamily({
    required String userId,
    required String familyName,
  }) async {
    try {
      final membership = await _supabase
          .from('family_members')
          .select('family_id')
          .eq('user_id', userId)
          .eq('status', 'active')
          .limit(1)
          .maybeSingle();

      if (membership != null) {
        return;
      }

      final family = await _supabase
          .from('family_groups')
          .insert({'name': familyName, 'created_by': userId})
          .select('id')
          .single();

      await _supabase.from('family_members').insert({
        'family_id': family['id'],
        'user_id': userId,
        'role': 'owner',
        'status': 'active',
        'can_edit_pets': true,
        'can_view_medical': true,
      });
    } catch (e) {
      debugPrint('AccountService._ensureFamily ignored: $e');
    }
  }

  FamilyMemberSummary _memberFromMap(Map<String, dynamic> map) {
    final profile = map['profiles'] is Map<String, dynamic>
        ? map['profiles'] as Map<String, dynamic>
        : <String, dynamic>{};
    return FamilyMemberSummary(
      name: profile['full_name']?.toString() ?? 'Familiar',
      phone: profile['phone']?.toString() ?? '',
      role: map['role']?.toString() ?? 'member',
      canEditPets: map['can_edit_pets'] == true,
      canViewMedical: map['can_view_medical'] == true,
    );
  }

  MedicalRecordSummary _medicalRecordFromMap(Map<String, dynamic> map) {
    return MedicalRecordSummary(
      id: map['id']?.toString() ?? '',
      petName: map['pet_name']?.toString() ?? 'Mascota',
      title: map['title']?.toString() ?? 'Atencion medica',
      recordType: map['record_type']?.toString() ?? 'consulta',
      dateLabel: _formatDate(map['visit_date']?.toString()),
      createdBy: map['created_by_name']?.toString() ?? 'PetScanIA',
      notes: map['notes']?.toString() ?? '',
      verifiedByVet: map['verified_by_vet'] == true,
    );
  }

  String _formatDate(String? value) {
    if (value == null || value.isEmpty) {
      return 'Fecha reciente';
    }
    try {
      final date = DateTime.parse(value).toLocal();
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    } catch (_) {
      return value;
    }
  }

  FamilyOverview _fallbackFamilyOverview() {
    return const FamilyOverview(
      familyName: 'Casa de Pupi',
      userRole: 'owner',
      memberCount: 3,
      petCount: 1,
      medicalRecordsCount: 4,
      members: [
        FamilyMemberSummary(
          name: 'Tu cuenta',
          phone: '+51 999 000 111',
          role: 'owner',
          canEditPets: true,
          canViewMedical: true,
        ),
        FamilyMemberSummary(
          name: 'Familiar invitado',
          phone: '+51 999 000 222',
          role: 'admin',
          canEditPets: true,
          canViewMedical: true,
        ),
        FamilyMemberSummary(
          name: 'Cuidador',
          phone: '+51 999 000 333',
          role: 'viewer',
          canEditPets: false,
          canViewMedical: true,
        ),
      ],
    );
  }

  List<MedicalRecordSummary> _fallbackMedicalRecords() {
    return const [
      MedicalRecordSummary(
        id: 'demo-001',
        petName: 'Pupi',
        title: 'Vacuna multiple aplicada',
        recordType: 'vacuna',
        dateLabel: '22/04/2026',
        createdBy: 'Dra. Valeria Ruiz',
        notes: 'Sin reacciones adversas. Proximo refuerzo en 12 meses.',
        verifiedByVet: true,
      ),
      MedicalRecordSummary(
        id: 'demo-002',
        petName: 'Pupi',
        title: 'Desparasitacion interna',
        recordType: 'desparasitacion',
        dateLabel: '15/04/2026',
        createdBy: 'Familia',
        notes:
            'Dosis registrada por peso aproximado. Repetir segun indicacion.',
        verifiedByVet: false,
      ),
      MedicalRecordSummary(
        id: 'demo-003',
        petName: 'Pupi',
        title: 'Chequeo general',
        recordType: 'consulta',
        dateLabel: '02/04/2026',
        createdBy: 'Clinica Patitas',
        notes: 'Peso estable, buena hidratacion y controles al dia.',
        verifiedByVet: true,
      ),
    ];
  }
}
