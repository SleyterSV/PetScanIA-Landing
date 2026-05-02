import 'package:flutter/material.dart';
import 'package:petscania/services/account_service.dart';
import 'package:petscania/theme/petscania_brand.dart';

class FamilyRolesScreen extends StatefulWidget {
  const FamilyRolesScreen({super.key});

  @override
  State<FamilyRolesScreen> createState() => _FamilyRolesScreenState();
}

class _FamilyRolesScreenState extends State<FamilyRolesScreen> {
  final AccountService _accountService = AccountService();
  late Future<_FamilyRolesPayload> _payloadFuture;

  @override
  void initState() {
    super.initState();
    _payloadFuture = _load();
  }

  Future<_FamilyRolesPayload> _load() async {
    final overview = await _accountService.getFamilyOverview();
    final roles = await _accountService.getRoles();
    return _FamilyRolesPayload(overview: overview, roles: roles);
  }

  Future<void> _reload() async {
    setState(() => _payloadFuture = _load());
    await _payloadFuture;
  }

  Future<void> _inviteMember() async {
    final result = await showModalBottomSheet<_InvitePayload>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _InviteFamilySheet(),
    );

    if (result == null) {
      return;
    }

    await _accountService.inviteFamilyMember(
      phone: result.phone,
      role: result.role,
    );
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Invitacion familiar enviada.')),
    );
    await _reload();
  }

  Future<void> _activateRole(UserRoleSummary role) async {
    final result = await showModalBottomSheet<_RolePayload>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _RoleActivationSheet(role: role),
    );

    if (result == null) {
      return;
    }

    await _accountService.activateRole(
      role: role.role,
      licenseNumber: result.licenseNumber,
      organizationName: result.organizationName,
    );
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          role.role == 'vet'
              ? 'Perfil veterinario enviado a verificacion.'
              : 'Rol activado correctamente.',
        ),
      ),
    );
    await _reload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PetScaniaColors.royalBlue,
      appBar: AppBar(
        title: const Text(
          'Familia y roles',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: PetScaniaBackground(
        showPaws: false,
        child: SafeArea(
          top: false,
          child: FutureBuilder<_FamilyRolesPayload>(
            future: _payloadFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(
                    color: PetScaniaColors.skyBlue,
                  ),
                );
              }

              final payload =
                  snapshot.data ??
                  _FamilyRolesPayload(
                    overview: const FamilyOverview(
                      familyName: 'Mi familia',
                      userRole: 'owner',
                      memberCount: 1,
                      petCount: 0,
                      medicalRecordsCount: 0,
                      members: [],
                    ),
                    roles: const [],
                  );

              return RefreshIndicator(
                onRefresh: _reload,
                color: PetScaniaColors.royalBlue,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 30),
                  children: [
                    _FamilyHeader(
                      overview: payload.overview,
                      onInvite: _inviteMember,
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'Miembros',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 10),
                    ...payload.overview.members.map(
                      (member) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _MemberCard(member: member),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Roles de cuenta',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 10),
                    ...payload.roles.map(
                      (role) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _RoleCard(
                          role: role,
                          onActivate: () => _activateRole(role),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _FamilyRolesPayload {
  final FamilyOverview overview;
  final List<UserRoleSummary> roles;

  const _FamilyRolesPayload({required this.overview, required this.roles});
}

class _FamilyHeader extends StatelessWidget {
  final FamilyOverview overview;
  final VoidCallback onInvite;

  const _FamilyHeader({required this.overview, required this.onInvite});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
            ),
            child: const Icon(
              Icons.family_restroom_rounded,
              color: PetScaniaColors.royalBlue,
              size: 34,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  overview.familyName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${overview.memberCount} miembros comparten ${overview.petCount} mascotas',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.78),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Invitar familiar',
            onPressed: onInvite,
            icon: const Icon(Icons.group_add_rounded),
            color: Colors.white,
            style: IconButton.styleFrom(
              backgroundColor: Colors.white.withValues(alpha: 0.16),
              fixedSize: const Size(52, 52),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MemberCard extends StatelessWidget {
  final FamilyMemberSummary member;

  const _MemberCard({required this.member});

  @override
  Widget build(BuildContext context) {
    return PetScaniaSurfaceCard(
      padding: const EdgeInsets.all(14),
      borderRadius: BorderRadius.circular(22),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: PetScaniaColors.cloud,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.person_rounded,
              color: PetScaniaColors.royalBlue,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  member.name,
                  style: const TextStyle(
                    color: PetScaniaColors.ink,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  member.phone.isEmpty
                      ? member.role
                      : '${member.phone} - ${member.role}',
                  style: TextStyle(
                    color: PetScaniaColors.ink.withValues(alpha: 0.58),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          _SmallPermissionIcon(
            active: member.canEditPets,
            icon: Icons.edit_rounded,
          ),
          const SizedBox(width: 6),
          _SmallPermissionIcon(
            active: member.canViewMedical,
            icon: Icons.health_and_safety_rounded,
          ),
        ],
      ),
    );
  }
}

class _SmallPermissionIcon extends StatelessWidget {
  final bool active;
  final IconData icon;

  const _SmallPermissionIcon({required this.active, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(7),
      decoration: BoxDecoration(
        color: active
            ? PetScaniaColors.leaf.withValues(alpha: 0.12)
            : PetScaniaColors.line.withValues(alpha: 0.50),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        icon,
        size: 17,
        color: active ? PetScaniaColors.leaf : const Color(0xFF94A3B8),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final UserRoleSummary role;
  final VoidCallback onActivate;

  const _RoleCard({required this.role, required this.onActivate});

  @override
  Widget build(BuildContext context) {
    final active = role.status == 'active';
    final pending = role.status == 'pending_verification';
    final icon = switch (role.role) {
      'vet' => Icons.local_hospital_rounded,
      'rescuer' => Icons.volunteer_activism_rounded,
      _ => Icons.pets_rounded,
    };
    final color = switch (role.role) {
      'vet' => PetScaniaColors.royalBlue,
      'rescuer' => PetScaniaColors.rescueCoral,
      _ => PetScaniaColors.leaf,
    };

    return PetScaniaSurfaceCard(
      padding: const EdgeInsets.all(14),
      borderRadius: BorderRadius.circular(22),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  role.label,
                  style: const TextStyle(
                    color: PetScaniaColors.ink,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  pending
                      ? 'Pendiente de verificacion'
                      : active
                      ? 'Activo'
                      : 'Disponible para activar',
                  style: TextStyle(
                    color: pending
                        ? PetScaniaColors.warmSun
                        : active
                        ? PetScaniaColors.leaf
                        : PetScaniaColors.ink.withValues(alpha: 0.58),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: active || pending ? null : onActivate,
            child: Text(active ? 'ACTIVO' : 'ACTIVAR'),
          ),
        ],
      ),
    );
  }
}

class _InviteFamilySheet extends StatefulWidget {
  const _InviteFamilySheet();

  @override
  State<_InviteFamilySheet> createState() => _InviteFamilySheetState();
}

class _InviteFamilySheetState extends State<_InviteFamilySheet> {
  final TextEditingController _phoneController = TextEditingController();
  String _role = 'member';

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _BottomSheetShell(
      title: 'Invitar familiar',
      children: [
        _SheetInput(
          controller: _phoneController,
          label: 'Numero WhatsApp',
          icon: Icons.phone_iphone_rounded,
          keyboardType: TextInputType.phone,
        ),
        const SizedBox(height: 12),
        SegmentedButton<String>(
          segments: const [
            ButtonSegment(value: 'admin', label: Text('Admin')),
            ButtonSegment(value: 'member', label: Text('Miembro')),
            ButtonSegment(value: 'viewer', label: Text('Lectura')),
          ],
          selected: {_role},
          onSelectionChanged: (value) => setState(() => _role = value.first),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          height: 54,
          child: FilledButton.icon(
            onPressed: () {
              final phone = _phoneController.text.trim();
              if (phone.isEmpty) {
                return;
              }
              Navigator.pop(context, _InvitePayload(phone: phone, role: _role));
            },
            icon: const Icon(Icons.send_rounded),
            label: const Text('Enviar invitacion'),
          ),
        ),
      ],
    );
  }
}

class _RoleActivationSheet extends StatefulWidget {
  final UserRoleSummary role;

  const _RoleActivationSheet({required this.role});

  @override
  State<_RoleActivationSheet> createState() => _RoleActivationSheetState();
}

class _RoleActivationSheetState extends State<_RoleActivationSheet> {
  final TextEditingController _licenseController = TextEditingController();
  final TextEditingController _organizationController = TextEditingController();

  @override
  void dispose() {
    _licenseController.dispose();
    _organizationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isVet = widget.role.role == 'vet';

    return _BottomSheetShell(
      title: 'Activar ${widget.role.label}',
      children: [
        if (isVet) ...[
          _SheetInput(
            controller: _licenseController,
            label: 'Numero de colegiatura',
            icon: Icons.badge_rounded,
          ),
          const SizedBox(height: 10),
        ],
        _SheetInput(
          controller: _organizationController,
          label: isVet ? 'Clinica o consultorio' : 'Refugio o red',
          icon: Icons.apartment_rounded,
        ),
        const SizedBox(height: 14),
        Text(
          isVet
              ? 'El perfil veterinario queda pendiente hasta que PetScanIA valide los datos.'
              : 'Este rol permite publicar adopciones, campanas y reportes comunitarios.',
          style: TextStyle(
            color: PetScaniaColors.ink.withValues(alpha: 0.68),
            height: 1.35,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          height: 54,
          child: FilledButton.icon(
            onPressed: () => Navigator.pop(
              context,
              _RolePayload(
                licenseNumber: _licenseController.text.trim(),
                organizationName: _organizationController.text.trim(),
              ),
            ),
            icon: const Icon(Icons.verified_user_rounded),
            label: const Text('Solicitar activacion'),
          ),
        ),
      ],
    );
  }
}

class _BottomSheetShell extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _BottomSheetShell({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: PetScaniaColors.ink,
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _SheetInput extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final TextInputType keyboardType;

  const _SheetInput({
    required this.controller,
    required this.label,
    required this.icon,
    this.keyboardType = TextInputType.text,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        filled: true,
        fillColor: PetScaniaColors.mist,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

class _InvitePayload {
  final String phone;
  final String role;

  const _InvitePayload({required this.phone, required this.role});
}

class _RolePayload {
  final String licenseNumber;
  final String organizationName;

  const _RolePayload({
    required this.licenseNumber,
    required this.organizationName,
  });
}
