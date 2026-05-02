import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:petscania/models/community_pet.dart';
import 'package:petscania/services/community_service.dart';
import 'package:petscania/theme/petscania_brand.dart';
import 'package:url_launcher/url_launcher.dart';

class PublishPetScreen extends StatefulWidget {
  final CommunityPostType initialType;

  const PublishPetScreen({super.key, required this.initialType});

  @override
  State<PublishPetScreen> createState() => _PublishPetScreenState();
}

class _PublishPetScreenState extends State<PublishPetScreen> {
  final _formKey = GlobalKey<FormState>();
  final CommunityService _communityService = CommunityService();

  late CommunityPostType _type;
  bool _emergencyMode = false;

  final _nameController = TextEditingController();
  final _speciesController = TextEditingController(text: 'Perro');
  final _breedController = TextEditingController();
  final _colorController = TextEditingController();
  final _ageController = TextEditingController();
  final _sizeController = TextEditingController(text: 'Mediano');
  final _cityController = TextEditingController(text: 'Lima');
  final _districtController = TextEditingController();
  final _locationController = TextEditingController();
  final _dateController = TextEditingController();
  final _healthController = TextEditingController();
  final _vaccinesController = TextEditingController();
  final _contactController = TextEditingController();
  final _rewardController = TextEditingController();
  final _descriptionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _type = widget.initialType;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _speciesController.dispose();
    _breedController.dispose();
    _colorController.dispose();
    _ageController.dispose();
    _sizeController.dispose();
    _cityController.dispose();
    _districtController.dispose();
    _locationController.dispose();
    _dateController.dispose();
    _healthController.dispose();
    _vaccinesController.dispose();
    _contactController.dispose();
    _rewardController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  String get _title {
    switch (_type) {
      case CommunityPostType.adoption:
        return 'Dar en adopcion';
      case CommunityPostType.lost:
        return 'Reportar perdida';
      case CommunityPostType.found:
        return 'Mascota encontrada';
    }
  }

  String get _primaryAction {
    switch (_type) {
      case CommunityPostType.adoption:
        return 'Publicar adopcion';
      case CommunityPostType.lost:
        return 'Activar alerta';
      case CommunityPostType.found:
        return 'Publicar encontrada';
    }
  }

  void _generateWithAi() {
    final name = _nameController.text.trim().isEmpty
        ? (_type == CommunityPostType.found ? 'esta mascota' : 'tu mascota')
        : _nameController.text.trim();
    final city = _cityController.text.trim().isEmpty
        ? 'tu ciudad'
        : _cityController.text.trim();
    final location = _locationController.text.trim().isEmpty
        ? 'la zona indicada'
        : _locationController.text.trim();

    final generated = switch (_type) {
      CommunityPostType.adoption =>
        '$name busca una familia responsable en $city. Es una mascota especial, sociable y lista para recibir amor, rutinas tranquilas y cuidados constantes. #AdoptaNoCompres #PetScanIA #AdopcionResponsable',
      CommunityPostType.lost =>
        '$name se perdio cerca de $location. Si lo viste o tienes informacion, por favor comunicate de inmediato. Cada difusion puede ayudar a que vuelva a casa. #MascotaPerdida #PetScanIA #AyudaLocal',
      CommunityPostType.found =>
        'Encontramos a $name cerca de $location. Esta resguardada temporalmente y buscamos a su familia. Comparte esta alerta para llegar al barrio correcto. #MascotaEncontrada #PetScanIA #ComunidadPet',
    };

    setState(() => _descriptionController.text = generated);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('IA preparo texto y hashtags.')),
    );
  }

  Future<void> _publish() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final saved = await _communityService.createPost(
      type: _type,
      name: _nameController.text.trim(),
      species: _speciesController.text.trim(),
      breed: _breedController.text.trim(),
      color: _colorController.text.trim(),
      age: _ageController.text.trim(),
      size: _sizeController.text.trim(),
      city: _cityController.text.trim(),
      district: _districtController.text.trim(),
      location: _locationController.text.trim(),
      dateLabel: _dateController.text.trim(),
      healthStatus: _healthController.text.trim(),
      vaccines: _vaccinesController.text.trim(),
      contactPhone: _contactController.text.trim(),
      reward: _rewardController.text.trim(),
      description: _descriptionController.text.trim(),
    );

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          saved
              ? '$_primaryAction guardado en Supabase.'
              : '$_primaryAction listo. Falta crear las tablas de comunidad en Supabase.',
        ),
      ),
    );
    Navigator.pop(context, true);
  }

  Future<void> _openInstagramStory() async {
    final appUri = Uri.parse('instagram://story-camera');
    final webUri = Uri.parse('https://www.instagram.com/');

    try {
      if (kIsWeb) {
        await launchUrl(webUri, mode: LaunchMode.externalApplication);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'En web se abre Instagram. Para historias directas necesitamos la app movil.',
              ),
            ),
          );
        }
        return;
      }

      final opened = await launchUrl(
        appUri,
        mode: LaunchMode.externalApplication,
      );
      if (!opened) {
        await launchUrl(webUri, mode: LaunchMode.externalApplication);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Abri Instagram. La integracion nativa podra enviar el cartel directo a historia.',
            ),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No pude abrir Instagram.')),
        );
      }
    }
  }

  void _showPosterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Cartel listo',
                        style: TextStyle(
                          color: PetScaniaColors.ink,
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Cerrar',
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.62,
                  ),
                  child: _buildPosterPreview(),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _openInstagramStory();
                    },
                    icon: const Icon(Icons.camera_alt_rounded),
                    label: const Text('Abrir historia de Instagram'),
                    style: FilledButton.styleFrom(
                      backgroundColor: PetScaniaColors.rescueCoral,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLost = _type == CommunityPostType.lost;

    return Scaffold(
      backgroundColor: PetScaniaColors.royalBlue,
      appBar: AppBar(
        title: Text(
          _title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: PetScaniaBackground(
        showPaws: false,
        child: SafeArea(
          top: false,
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
              children: [
                _buildTypeSelector(),
                const SizedBox(height: 14),
                if (isLost) _buildEmergencyCard(),
                if (isLost) const SizedBox(height: 14),
                _buildPhotoPanel(),
                const SizedBox(height: 14),
                _buildMainFields(),
                const SizedBox(height: 14),
                _buildAiPanel(),
                const SizedBox(height: 14),
                _buildPosterPreview(),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _showPosterSheet,
                        icon: const Icon(Icons.image_rounded),
                        label: const Text('Ver cartel'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: BorderSide(
                            color: Colors.white.withValues(alpha: 0.46),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: _openInstagramStory,
                        icon: const Icon(Icons.camera_alt_rounded),
                        label: const Text('Instagram'),
                        style: FilledButton.styleFrom(
                          backgroundColor: PetScaniaColors.rescueCoral,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                FilledButton.icon(
                  onPressed: _publish,
                  icon: Icon(
                    isLost
                        ? Icons.notifications_active_rounded
                        : Icons.send_rounded,
                  ),
                  label: Text(_primaryAction),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: PetScaniaColors.royalBlue,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    textStyle: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 15,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTypeSelector() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: 0.20)),
      ),
      child: SegmentedButton<CommunityPostType>(
        segments: const [
          ButtonSegment(
            value: CommunityPostType.adoption,
            icon: Icon(Icons.favorite_rounded),
            label: Text('Adopta'),
          ),
          ButtonSegment(
            value: CommunityPostType.lost,
            icon: Icon(Icons.campaign_rounded),
            label: Text('Perdida'),
          ),
          ButtonSegment(
            value: CommunityPostType.found,
            icon: Icon(Icons.travel_explore_rounded),
            label: Text('Hallada'),
          ),
        ],
        selected: {_type},
        onSelectionChanged: (value) => setState(() => _type = value.first),
        style: SegmentedButton.styleFrom(
          backgroundColor: Colors.transparent,
          selectedBackgroundColor: Colors.white,
          selectedForegroundColor: PetScaniaColors.royalBlue,
          foregroundColor: Colors.white,
          side: BorderSide.none,
          textStyle: const TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
    );
  }

  Widget _buildEmergencyCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: PetScaniaColors.alert.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        children: [
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            value: _emergencyMode,
            activeThumbColor: Colors.white,
            activeTrackColor: Colors.white30,
            title: const Text(
              'Modo emergencia',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
              ),
            ),
            subtitle: const Text(
              'Prioriza foto, ubicacion, contacto y difusion inmediata.',
              style: TextStyle(color: Colors.white70, height: 1.35),
            ),
            onChanged: (value) => setState(() => _emergencyMode = value),
          ),
          if (_emergencyMode)
            const Row(
              children: [
                Icon(Icons.timer_rounded, color: Colors.white),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Al publicar se preparan cartel, WhatsApp y alerta cercana.',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildPhotoPanel() {
    return _SurfaceBlock(
      child: Row(
        children: [
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              color: PetScaniaColors.cloud,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.add_photo_alternate_rounded,
              color: PetScaniaColors.royalBlue,
              size: 38,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Foto principal',
                  style: TextStyle(
                    color: PetScaniaColors.ink,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'La IA revisara que parezca una mascota antes de difundir.',
                  style: TextStyle(
                    color: PetScaniaColors.ink.withValues(alpha: 0.62),
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Selector de imagen listo para conectar.'),
                    ),
                  ),
                  icon: const Icon(Icons.upload_rounded, size: 18),
                  label: const Text('Subir foto'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainFields() {
    final isAdoption = _type == CommunityPostType.adoption;
    final isLost = _type == CommunityPostType.lost;

    return _SurfaceBlock(
      child: Column(
        children: [
          _buildField(
            controller: _nameController,
            label: isAdoption ? 'Nombre de la mascota' : 'Nombre o referencia',
            icon: Icons.pets_rounded,
            requiredField: true,
          ),
          Row(
            children: [
              Expanded(
                child: _buildField(
                  controller: _speciesController,
                  label: 'Especie',
                  icon: Icons.category_rounded,
                  requiredField: true,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildField(
                  controller: _breedController,
                  label: 'Raza',
                  icon: Icons.badge_rounded,
                ),
              ),
            ],
          ),
          if (isLost)
            _buildField(
              controller: _colorController,
              label: 'Color o senas particulares',
              icon: Icons.palette_rounded,
              requiredField: true,
            ),
          Row(
            children: [
              Expanded(
                child: _buildField(
                  controller: _ageController,
                  label: 'Edad aproximada',
                  icon: Icons.cake_rounded,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildField(
                  controller: _sizeController,
                  label: 'Tamano',
                  icon: Icons.straighten_rounded,
                ),
              ),
            ],
          ),
          Row(
            children: [
              Expanded(
                child: _buildField(
                  controller: _cityController,
                  label: 'Ciudad',
                  icon: Icons.location_city_rounded,
                  requiredField: true,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildField(
                  controller: _districtController,
                  label: 'Distrito',
                  icon: Icons.map_rounded,
                  requiredField: true,
                ),
              ),
            ],
          ),
          _buildField(
            controller: _locationController,
            label: isLost
                ? 'Ultima ubicacion vista'
                : 'Ubicacion de referencia',
            icon: Icons.place_rounded,
            requiredField: true,
          ),
          if (isLost || _type == CommunityPostType.found)
            _buildField(
              controller: _dateController,
              label: isLost ? 'Fecha y hora de perdida' : 'Fecha de hallazgo',
              icon: Icons.event_rounded,
              requiredField: isLost,
            ),
          if (isAdoption) ...[
            _buildField(
              controller: _healthController,
              label: 'Estado de salud',
              icon: Icons.health_and_safety_rounded,
              requiredField: true,
            ),
            _buildField(
              controller: _vaccinesController,
              label: 'Vacunas',
              icon: Icons.vaccines_rounded,
            ),
          ],
          _buildField(
            controller: _contactController,
            label: 'WhatsApp de contacto',
            icon: Icons.chat_rounded,
            keyboardType: TextInputType.phone,
            requiredField: true,
          ),
          if (isLost)
            _buildField(
              controller: _rewardController,
              label: 'Recompensa opcional',
              icon: Icons.volunteer_activism_rounded,
            ),
          _buildField(
            controller: _descriptionController,
            label: 'Descripcion',
            icon: Icons.notes_rounded,
            maxLines: 4,
            requiredField: !_emergencyMode,
          ),
        ],
      ),
    );
  }

  Widget _buildAiPanel() {
    return _SurfaceBlock(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: PetScaniaColors.paleBlue,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              color: PetScaniaColors.royalBlue,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'IA como apoyo',
                  style: TextStyle(
                    color: PetScaniaColors.ink,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'Mejora el texto, sugiere hashtags y prepara el cartel de difusion.',
                  style: TextStyle(
                    color: PetScaniaColors.ink.withValues(alpha: 0.62),
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: _generateWithAi,
                  icon: const Icon(Icons.edit_note_rounded, size: 18),
                  label: const Text('Generar texto'),
                  style: FilledButton.styleFrom(
                    backgroundColor: PetScaniaColors.royalBlue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPosterPreview() {
    final name = _nameController.text.trim().isEmpty
        ? _title
        : _nameController.text.trim();
    final location = _locationController.text.trim().isEmpty
        ? 'Ubicacion por confirmar'
        : _locationController.text.trim();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _type == CommunityPostType.lost
            ? PetScaniaColors.alert
            : PetScaniaColors.royalBlue,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const PetScaniaBrandMark(size: 38),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _type == CommunityPostType.lost
                      ? 'ALERTA PETSCANIA'
                      : 'PETSCANIA COMUNIDAD',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0,
                  ),
                ),
              ),
              const Icon(Icons.ios_share_rounded, color: Colors.white),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            height: 128,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white24),
            ),
            child: const Icon(
              Icons.pets_rounded,
              color: Colors.white,
              size: 48,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            location,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            _descriptionController.text.trim().isEmpty
                ? 'El cartel se actualiza con foto, datos clave y contacto.'
                : _descriptionController.text.trim(),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.82),
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool requiredField = false,
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        validator: requiredField
            ? (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Completa este dato';
                }
                return null;
              }
            : null,
        onChanged: (_) => setState(() {}),
        style: const TextStyle(
          color: PetScaniaColors.ink,
          fontWeight: FontWeight.w700,
        ),
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: PetScaniaColors.royalBlue),
          filled: true,
          fillColor: PetScaniaColors.mist,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(color: PetScaniaColors.skyBlue),
          ),
        ),
      ),
    );
  }
}

class _SurfaceBlock extends StatelessWidget {
  final Widget child;

  const _SurfaceBlock({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: PetScaniaColors.line),
        boxShadow: PetScaniaDecor.softShadow,
      ),
      child: child,
    );
  }
}
