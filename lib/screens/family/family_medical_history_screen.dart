import 'package:flutter/material.dart';
import 'package:petscania/services/account_service.dart';
import 'package:petscania/theme/petscania_brand.dart';

class FamilyMedicalHistoryScreen extends StatefulWidget {
  const FamilyMedicalHistoryScreen({super.key});

  @override
  State<FamilyMedicalHistoryScreen> createState() =>
      _FamilyMedicalHistoryScreenState();
}

class _FamilyMedicalHistoryScreenState
    extends State<FamilyMedicalHistoryScreen> {
  final AccountService _accountService = AccountService();
  late Future<_MedicalPayload> _payloadFuture;
  bool _creatingCode = false;

  @override
  void initState() {
    super.initState();
    _payloadFuture = _load();
  }

  Future<_MedicalPayload> _load() async {
    final overview = await _accountService.getFamilyOverview();
    final records = await _accountService.getMedicalRecords();
    return _MedicalPayload(overview: overview, records: records);
  }

  Future<void> _reload() async {
    setState(() => _payloadFuture = _load());
    await _payloadFuture;
  }

  Future<void> _openAddRecord() async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _AddMedicalRecordSheet(),
    );

    if (saved == true) {
      await _reload();
    }
  }

  Future<void> _showVetAccessCode() async {
    setState(() => _creatingCode = true);
    final code = await _accountService.createVetAccessCode();
    if (!mounted) {
      return;
    }
    setState(() => _creatingCode = false);

    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text(
          'Codigo para veterinario',
          style: TextStyle(
            color: PetScaniaColors.ink,
            fontWeight: FontWeight.w900,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 24),
              decoration: BoxDecoration(
                color: PetScaniaColors.cloud,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                code,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: PetScaniaColors.royalBlue,
                  fontSize: 36,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 4,
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'El doctor puede usar este codigo durante 20 minutos para registrar una atencion autorizada.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: PetScaniaColors.ink.withValues(alpha: 0.68),
                height: 1.4,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'LISTO',
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PetScaniaColors.royalBlue,
      appBar: AppBar(
        title: const Text(
          'Historial medico familiar',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: PetScaniaBackground(
        showPaws: false,
        child: SafeArea(
          top: false,
          child: FutureBuilder<_MedicalPayload>(
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
                  _MedicalPayload(
                    overview: const FamilyOverview(
                      familyName: 'Mi familia',
                      userRole: 'owner',
                      memberCount: 1,
                      petCount: 0,
                      medicalRecordsCount: 0,
                      members: [],
                    ),
                    records: const [],
                  );

              return RefreshIndicator(
                onRefresh: _reload,
                color: PetScaniaColors.royalBlue,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 30),
                  children: [
                    _MedicalHero(
                      overview: payload.overview,
                      onAddRecord: _openAddRecord,
                      onAuthorizeVet: _creatingCode ? null : _showVetAccessCode,
                    ),
                    const SizedBox(height: 16),
                    _FamilyAccessCard(overview: payload.overview),
                    const SizedBox(height: 18),
                    const Text(
                      'Linea de tiempo',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (payload.records.isEmpty)
                      const _EmptyMedicalState()
                    else
                      ...payload.records.map(
                        (record) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _MedicalRecordCard(record: record),
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

class _MedicalPayload {
  final FamilyOverview overview;
  final List<MedicalRecordSummary> records;

  const _MedicalPayload({required this.overview, required this.records});
}

class _MedicalHero extends StatelessWidget {
  final FamilyOverview overview;
  final VoidCallback onAddRecord;
  final VoidCallback? onAuthorizeVet;

  const _MedicalHero({
    required this.overview,
    required this.onAddRecord,
    required this.onAuthorizeVet,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: const Icon(
                  Icons.health_and_safety_rounded,
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
                      '${overview.petCount} mascotas - ${overview.memberCount} miembros - ${overview.medicalRecordsCount} registros',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.78),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: onAddRecord,
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Agregar atencion'),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: PetScaniaColors.royalBlue,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    textStyle: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              IconButton(
                tooltip: 'Autorizar doctor',
                onPressed: onAuthorizeVet,
                icon: const Icon(Icons.qr_code_2_rounded),
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
        ],
      ),
    );
  }
}

class _FamilyAccessCard extends StatelessWidget {
  final FamilyOverview overview;

  const _FamilyAccessCard({required this.overview});

  @override
  Widget build(BuildContext context) {
    final visibleMembers = overview.members.take(3).toList();

    return PetScaniaSurfaceCard(
      padding: const EdgeInsets.all(16),
      borderRadius: BorderRadius.circular(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Quien puede ver este historial',
            style: TextStyle(
              color: PetScaniaColors.ink,
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          ...visibleMembers.map(
            (member) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: PetScaniaColors.cloud,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.person_rounded,
                      color: PetScaniaColors.royalBlue,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          member.name,
                          style: const TextStyle(
                            color: PetScaniaColors.ink,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          member.canEditPets
                              ? 'Puede editar mascotas e historial'
                              : 'Solo lectura del historial',
                          style: TextStyle(
                            color: PetScaniaColors.ink.withValues(alpha: 0.58),
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (member.canViewMedical)
                    const Icon(
                      Icons.visibility_rounded,
                      color: PetScaniaColors.leaf,
                      size: 20,
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MedicalRecordCard extends StatelessWidget {
  final MedicalRecordSummary record;

  const _MedicalRecordCard({required this.record});

  @override
  Widget build(BuildContext context) {
    final color = switch (record.recordType) {
      'vacuna' => PetScaniaColors.leaf,
      'desparasitacion' => PetScaniaColors.warmSun,
      'emergencia' => PetScaniaColors.alert,
      _ => PetScaniaColors.royalBlue,
    };

    return PetScaniaSurfaceCard(
      padding: const EdgeInsets.all(16),
      borderRadius: BorderRadius.circular(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(Icons.medical_services_rounded, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      record.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: PetScaniaColors.ink,
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${record.petName} - ${record.dateLabel}',
                      style: TextStyle(
                        color: PetScaniaColors.ink.withValues(alpha: 0.58),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              if (record.verifiedByVet)
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: PetScaniaColors.leaf.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.verified_rounded,
                    color: PetScaniaColors.leaf,
                    size: 18,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            record.notes,
            style: TextStyle(
              color: PetScaniaColors.ink.withValues(alpha: 0.70),
              height: 1.4,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Registrado por ${record.createdBy}',
            style: const TextStyle(
              color: PetScaniaColors.royalBlue,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyMedicalState extends StatelessWidget {
  const _EmptyMedicalState();

  @override
  Widget build(BuildContext context) {
    return PetScaniaSurfaceCard(
      padding: const EdgeInsets.all(24),
      borderRadius: BorderRadius.circular(24),
      child: const Column(
        children: [
          Icon(
            Icons.history_edu_rounded,
            color: PetScaniaColors.royalBlue,
            size: 44,
          ),
          SizedBox(height: 12),
          Text(
            'Aun no hay registros medicos',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: PetScaniaColors.ink,
              fontWeight: FontWeight.w900,
              fontSize: 18,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Agrega vacunas, consultas, desparasitaciones o autoriza a un doctor con codigo.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFF6B7F9F), height: 1.4),
          ),
        ],
      ),
    );
  }
}

class _AddMedicalRecordSheet extends StatefulWidget {
  const _AddMedicalRecordSheet();

  @override
  State<_AddMedicalRecordSheet> createState() => _AddMedicalRecordSheetState();
}

class _AddMedicalRecordSheetState extends State<_AddMedicalRecordSheet> {
  final AccountService _accountService = AccountService();
  final TextEditingController _petController = TextEditingController(
    text: 'Pupi',
  );
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  String _type = 'consulta';
  bool _saving = false;

  @override
  void dispose() {
    _petController.dispose();
    _titleController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_petController.text.trim().isEmpty ||
        _titleController.text.trim().isEmpty) {
      return;
    }

    setState(() => _saving = true);
    try {
      await _accountService.createMedicalRecord(
        petName: _petController.text.trim(),
        title: _titleController.text.trim(),
        recordType: _type,
        notes: _notesController.text.trim(),
      );
      if (mounted) {
        Navigator.pop(context, true);
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

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
            const Text(
              'Registrar atencion',
              style: TextStyle(
                color: PetScaniaColors.ink,
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 14),
            _SheetInput(
              controller: _petController,
              label: 'Mascota',
              icon: Icons.pets_rounded,
            ),
            const SizedBox(height: 10),
            _SheetInput(
              controller: _titleController,
              label: 'Titulo',
              icon: Icons.medical_information_rounded,
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: ['consulta', 'vacuna', 'desparasitacion', 'emergencia']
                  .map(
                    (type) => ChoiceChip(
                      label: Text(type),
                      selected: _type == type,
                      onSelected: (_) => setState(() => _type = type),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 10),
            _SheetInput(
              controller: _notesController,
              label: 'Notas',
              icon: Icons.notes_rounded,
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: FilledButton.icon(
                onPressed: _saving ? null : _save,
                icon: _saving
                    ? const SizedBox.shrink()
                    : const Icon(Icons.save_rounded),
                label: _saving
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Guardar registro'),
                style: FilledButton.styleFrom(
                  backgroundColor: PetScaniaColors.royalBlue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
              ),
            ),
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
  final int maxLines;

  const _SheetInput({
    required this.controller,
    required this.label,
    required this.icon,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
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
