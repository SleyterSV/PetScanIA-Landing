import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:petscania/services/custom_ai_service.dart';
import 'package:petscania/theme/petscania_brand.dart';
import 'package:petscania/utils/disease_dictionary.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class VetIAScreen extends StatefulWidget {
  const VetIAScreen({super.key});

  @override
  State<VetIAScreen> createState() => _VetIAScreenState();
}

class _VetIAScreenState extends State<VetIAScreen> {
  final CustomAIService _aiService = CustomAIService();
  final SupabaseClient _supabase = Supabase.instance.client;
  final ImagePicker _picker = ImagePicker();

  final TextEditingController _symptomsController = TextEditingController();

  File? _selectedImage;
  Uint8List? _imageBytes;
  bool _isAnalyzing = false;
  List<Map<String, dynamic>> _history = [];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  @override
  void dispose() {
    _symptomsController.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    try {
      final userId = _supabase.auth.currentUser!.id;

      final petData = await _supabase
          .from('pets')
          .select('id, name')
          .eq('owner_id', userId)
          .limit(1)
          .maybeSingle();

      if (petData == null) return;

      final data = await _supabase
          .from('medical_scans')
          .select()
          .eq('pet_id', petData['id'])
          .order('created_at', ascending: false);

      if (mounted) {
        setState(() {
          _history = List<Map<String, dynamic>>.from(data);
        });
      }
    } catch (e) {
      debugPrint("Error historial: $e");
    }
  }

  Future<void> _deleteScan(String id, int index) async {
    try {
      await _supabase.from('medical_scans').delete().eq('id', id);

      if (mounted) {
        setState(() => _history.removeAt(index));

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Análisis eliminado"),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Error al eliminar"),
          ),
        );
      }
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    final XFile? image = await _picker.pickImage(source: source);

    if (image != null) {
      final bytes = await image.readAsBytes();

      setState(() {
        _selectedImage = File(image.path);
        _imageBytes = bytes;
      });
    }
  }

  Future<void> _analyze() async {
    if (_imageBytes == null) return;

    setState(() => _isAnalyzing = true);

    try {
      final result = await _aiService.analyzeImage(
        _imageBytes!,
        _symptomsController.text,
      );

      if (result['success'] == true) {
        final String rawDiagnosis = result['diagnosis'].toString();
        final double confidence = (result['confidence'] as num).toDouble();

        final diseaseInfo = DiseaseDictionary.getInfo(rawDiagnosis);

        final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
        final path = 'medical-scans/$fileName';

        await _supabase.storage
            .from('medical-scans')
            .uploadBinary(path, _imageBytes!);

        final imageUrl = _supabase.storage
            .from('medical-scans')
            .getPublicUrl(path);

        final userId = _supabase.auth.currentUser!.id;

        final petData = await _supabase
            .from('pets')
            .select('id, name')
            .eq('owner_id', userId)
            .limit(1)
            .single();

        await _supabase.from('medical_scans').insert({
          'pet_id': petData['id'],
          'image_url': imageUrl,
          'ai_diagnosis': diseaseInfo['nombre'],
          'confidence_score': confidence * 100,
          'mascota_nombre': petData['name'],
          'descripcion': diseaseInfo['descripcion'],
          'recomendaciones': diseaseInfo['recomendaciones'],
          'sintomas': _symptomsController.text,
          'origen': 'mixto',
        });

        await _loadHistory();

        _showDiagnosisResult(
          diseaseInfo['nombre'],
          confidence,
          diseaseInfo,
        );

        setState(() {
          _selectedImage = null;
          _imageBytes = null;
          _symptomsController.clear();
        });
      } else {
        _showErrorDialog(result['error'].toString());
      }
    } catch (e) {
      _showErrorDialog("Error inesperado: $e");
    } finally {
      if (mounted) {
        setState(() => _isAnalyzing = false);
      }
    }
  }

  void _showDiagnosisResult(
    String diseaseName,
    double confidence,
    Map<String, dynamic> info,
  ) {
    String urgencia = info['urgencia'] ?? "MEDIA";

    Color urgencyColor;

    if (urgencia == "ALTA") {
      urgencyColor = const Color(0xFFD84A4A);
    } else if (urgencia == "MEDIA") {
      urgencyColor = const Color(0xFFF59E0B);
    } else if (urgencia == "BAJA") {
      urgencyColor = const Color(0xFFEAB308);
    } else {
      urgencyColor = const Color(0xFF16A34A);
    }

    Color confidenceColor;
    String confidenceMsg;

    if (confidence >= 0.90) {
      confidenceColor = const Color(0xFF16A34A);
      confidenceMsg = "Alta certeza en el diagnóstico visual.";
    } else if (confidence >= 0.50) {
      confidenceColor = const Color(0xFFF59E0B);
      confidenceMsg = "Certeza media. Sugerimos observar los síntomas.";
    } else {
      confidenceColor = const Color(0xFFD84A4A);
      confidenceMsg = "Baja certeza. Recomendamos tomar una foto más clara.";
    }

    List<String> recs = List<String>.from(info['recomendaciones'] ?? []);

    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Container(
          decoration: BoxDecoration(
            color: PetScaniaColors.mist,
            borderRadius: BorderRadius.circular(30),
          ),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: urgencyColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Icon(
                          urgencia == "NULA"
                              ? Icons.check_circle_rounded
                              : Icons.analytics_rounded,
                          color: urgencyColor,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Text(
                          "Reporte IA",
                          style: TextStyle(
                            color: PetScaniaColors.ink,
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(
                          Icons.close_rounded,
                          color: PetScaniaColors.ink,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 18),

                  Text(
                    diseaseName,
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      color: urgencyColor,
                      height: 1.05,
                    ),
                  ),

                  const SizedBox(height: 18),

                  PetScaniaSurfaceCard(
                    padding: const EdgeInsets.all(16),
                    borderRadius: BorderRadius.circular(22),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Expanded(
                              child: Text(
                                "Confiabilidad IA",
                                style: TextStyle(
                                  color: PetScaniaColors.ink,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                            Text(
                              "${(confidence * 100).toStringAsFixed(1)}%",
                              style: TextStyle(
                                color: confidenceColor,
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 10),

                        ClipRRect(
                          borderRadius: BorderRadius.circular(999),
                          child: LinearProgressIndicator(
                            value: confidence,
                            minHeight: 9,
                            color: confidenceColor,
                            backgroundColor: PetScaniaColors.line,
                          ),
                        ),

                        const SizedBox(height: 8),

                        Text(
                          confidenceMsg,
                          style: TextStyle(
                            color: confidenceColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: urgencyColor.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.warning_amber_rounded,
                          color: urgencyColor,
                          size: 22,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          "Urgencia: $urgencia",
                          style: TextStyle(
                            color: urgencyColor,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 22),

                  const Text(
                    "Descripción",
                    style: TextStyle(
                      color: PetScaniaColors.ink,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    info['descripcion'] ?? "Sin descripción",
                    style: TextStyle(
                      color: PetScaniaColors.ink.withValues(alpha: 0.72),
                      fontSize: 14,
                      height: 1.45,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  const SizedBox(height: 22),

                  const Text(
                    "Recomendaciones rápidas",
                    style: TextStyle(
                      color: PetScaniaColors.ink,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),

                  const SizedBox(height: 10),

                  if (recs.isEmpty)
                    Text(
                      "No hay recomendaciones registradas.",
                      style: TextStyle(
                        color: PetScaniaColors.ink.withValues(alpha: 0.65),
                        fontWeight: FontWeight.w600,
                      ),
                    )
                  else
                    ...recs.map(
                      (r) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.check_circle_rounded,
                              color: PetScaniaColors.royalBlue,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                r,
                                style: TextStyle(
                                  color: PetScaniaColors.ink
                                      .withValues(alpha: 0.72),
                                  fontSize: 13,
                                  height: 1.35,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  const SizedBox(height: 18),

                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: PetScaniaDecor.primaryGradient,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        child: const Text(
                          "GUARDAR Y CERRAR",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showErrorDialog(String msg) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: PetScaniaColors.mist,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        title: const Text(
          "Aviso",
          style: TextStyle(
            color: PetScaniaColors.ink,
            fontWeight: FontWeight.w900,
          ),
        ),
        content: Text(
          msg,
          style: TextStyle(
            color: PetScaniaColors.ink.withValues(alpha: 0.72),
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              "OK",
              style: TextStyle(
                color: PetScaniaColors.royalBlue,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PetScaniaColors.mist,
      body: Stack(
        children: [
          Container(
            height: 330,
            decoration: const BoxDecoration(
              gradient: PetScaniaDecor.primaryGradient,
            ),
          ),

          Positioned(
            top: -40,
            left: -35,
            child: Container(
              width: 170,
              height: 170,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
            ),
          ),

          Positioned(
            top: 70,
            right: -35,
            child: Container(
              width: 185,
              height: 185,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 14, 18, 12),
                  child: Row(
                    children: [
                      _buildBackButton(),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Escáner Médico IA',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 23,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Sube una imagen y recibe orientación rápida con VetIA.',
                              style: TextStyle(
                                color: Color(0xD8FFFFFF),
                                height: 1.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                      PetScaniaBrandMark(size: 48),
                    ],
                  ),
                ),

                Expanded(
                  child: Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      color: PetScaniaColors.mist,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(34),
                      ),
                    ),
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(18, 20, 18, 34),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildScannerCard(),

                          const SizedBox(height: 24),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                "Historial Clínico",
                                style: TextStyle(
                                  color: PetScaniaColors.ink,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 7,
                                ),
                                decoration: BoxDecoration(
                                  color: PetScaniaColors.cloud,
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  "${_history.length} análisis",
                                  style: const TextStyle(
                                    color: PetScaniaColors.royalBlue,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 14),

                          if (_history.isEmpty)
                            _buildEmptyHistory()
                          else
                            ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _history.length,
                              itemBuilder: (context, index) {
                                final scan = _history[index];
                                return _buildHistoryCard(scan, index);
                              },
                            ),
                        ],
                      ),
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

  Widget _buildBackButton() {
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.16),
        ),
      ),
      child: IconButton(
        onPressed: () => Navigator.of(context).pop(),
        icon: const Icon(
          Icons.arrow_back_ios_new_rounded,
          color: Colors.white,
          size: 18,
        ),
      ),
    );
  }

  Widget _buildScannerCard() {
    return PetScaniaSurfaceCard(
      padding: const EdgeInsets.all(18),
      borderRadius: BorderRadius.circular(30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GestureDetector(
            onTap: () => _pickImage(ImageSource.gallery),
            child: Container(
              height: 225,
              decoration: BoxDecoration(
                color: PetScaniaColors.cloud,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: PetScaniaColors.line,
                  width: 1.4,
                ),
                image: _imageBytes != null
                    ? DecorationImage(
                        image: MemoryImage(_imageBytes!),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: _imageBytes == null
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            gradient: PetScaniaDecor.surfaceGradient,
                            shape: BoxShape.circle,
                            boxShadow: PetScaniaDecor.softShadow,
                          ),
                          child: const Icon(
                            Icons.add_a_photo_rounded,
                            size: 34,
                            color: PetScaniaColors.royalBlue,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          "Sube la foto de la zona afectada",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: PetScaniaColors.ink,
                            fontWeight: FontWeight.w900,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          "Formatos: JPG, PNG",
                          style: TextStyle(
                            color: PetScaniaColors.ink.withValues(alpha: 0.50),
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    )
                  : Align(
                      alignment: Alignment.topRight,
                      child: Container(
                        margin: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.92),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: IconButton(
                          onPressed: () {
                            setState(() {
                              _selectedImage = null;
                              _imageBytes = null;
                            });
                          },
                          icon: const Icon(
                            Icons.close_rounded,
                            color: PetScaniaColors.royalBlue,
                          ),
                        ),
                      ),
                    ),
            ),
          ),

          const SizedBox(height: 18),

          Row(
            children: [
              Expanded(
                child: _buildImageButton(
                  icon: Icons.camera_alt_rounded,
                  label: "Cámara",
                  onTap: () => _pickImage(ImageSource.camera),
                  filled: false,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildImageButton(
                  icon: Icons.photo_library_rounded,
                  label: "Galería",
                  onTap: () => _pickImage(ImageSource.gallery),
                  filled: false,
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          TextField(
            controller: _symptomsController,
            maxLines: 2,
            style: const TextStyle(
              color: PetScaniaColors.ink,
              fontWeight: FontWeight.w700,
            ),
            decoration: InputDecoration(
              hintText: "Ej. Se rasca mucho y tiene la piel roja...",
              hintStyle: const TextStyle(
                color: Color(0xFF7D96BF),
                fontSize: 14,
              ),
              filled: true,
              fillColor: PetScaniaColors.mist,
              prefixIcon: const Padding(
                padding: EdgeInsets.only(bottom: 20),
                child: Icon(
                  Icons.edit_note_rounded,
                  color: PetScaniaColors.royalBlue,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: const BorderSide(color: PetScaniaColors.line),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: const BorderSide(
                  color: PetScaniaColors.royalBlue,
                  width: 1.4,
                ),
              ),
            ),
          ),

          const SizedBox(height: 22),

          SizedBox(
            height: 56,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: (_isAnalyzing || _imageBytes == null)
                    ? null
                    : PetScaniaDecor.primaryGradient,
                color: (_isAnalyzing || _imageBytes == null)
                    ? PetScaniaColors.line
                    : null,
                borderRadius: BorderRadius.circular(18),
                boxShadow: (_isAnalyzing || _imageBytes == null)
                    ? []
                    : [
                        BoxShadow(
                          color:
                              PetScaniaColors.royalBlue.withValues(alpha: 0.22),
                          blurRadius: 14,
                          offset: const Offset(0, 8),
                        ),
                      ],
              ),
              child: ElevatedButton.icon(
                onPressed:
                    (_isAnalyzing || _imageBytes == null) ? null : _analyze,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  disabledBackgroundColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                icon: _isAnalyzing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Icon(
                        Icons.auto_awesome_rounded,
                        color: (_imageBytes == null)
                            ? PetScaniaColors.royalBlue.withValues(alpha: 0.45)
                            : Colors.white,
                      ),
                label: Text(
                  _isAnalyzing ? "PROCESANDO IA..." : "PREDECIR DIAGNÓSTICO",
                  style: TextStyle(
                    color: (_imageBytes == null)
                        ? PetScaniaColors.royalBlue.withValues(alpha: 0.45)
                        : Colors.white,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required bool filled,
  }) {
    return SizedBox(
      height: 48,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: PetScaniaColors.cloud,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: PetScaniaColors.line),
        ),
        child: ElevatedButton.icon(
          onPressed: onTap,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
          ),
          icon: Icon(
            icon,
            size: 19,
            color: PetScaniaColors.royalBlue,
          ),
          label: Text(
            label,
            style: const TextStyle(
              color: PetScaniaColors.royalBlue,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHistoryCard(Map<String, dynamic> scan, int index) {
    final scoreRaw = scan['confidence_score'] ?? 0.0;
    final score = (scoreRaw as num).toDouble();

    Color historyConfColor = const Color(0xFFD84A4A);

    if (score >= 90.0) {
      historyConfColor = const Color(0xFF16A34A);
    } else if (score >= 50.0) {
      historyConfColor = const Color(0xFFF59E0B);
    }

    final imageUrl = scan['image_url']?.toString() ?? '';

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: PetScaniaSurfaceCard(
        padding: const EdgeInsets.all(12),
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            final info = DiseaseDictionary.getInfo(scan['ai_diagnosis']);

            _showDiagnosisResult(
              scan['ai_diagnosis'] ?? 'Sin diagnóstico',
              score / 100,
              {
                'urgencia': info['urgencia'],
                'descripcion': scan['descripcion'] ?? "",
                'recomendaciones':
                    List<String>.from(scan['recomendaciones'] ?? []),
              },
            );
          },
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: imageUrl.isNotEmpty
                    ? Image.network(
                        imageUrl,
                        width: 68,
                        height: 68,
                        fit: BoxFit.cover,
                      )
                    : Container(
                        width: 68,
                        height: 68,
                        color: PetScaniaColors.cloud,
                        child: const Icon(
                          Icons.image_not_supported_rounded,
                          color: PetScaniaColors.royalBlue,
                        ),
                      ),
              ),

              const SizedBox(width: 14),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      scan['ai_diagnosis'] ?? "---",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: PetScaniaColors.ink,
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
                      ),
                    ),

                    const SizedBox(height: 6),

                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: historyConfColor.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        "Certeza IA: ${score.toStringAsFixed(1)}%",
                        style: TextStyle(
                          color: historyConfColor,
                          fontWeight: FontWeight.w900,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              IconButton(
                icon: const Icon(
                  Icons.delete_sweep_rounded,
                  color: Color(0xFFD84A4A),
                ),
                onPressed: () => _deleteScan(scan['id'].toString(), index),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyHistory() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 34),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: PetScaniaColors.line),
        boxShadow: PetScaniaDecor.softShadow,
      ),
      child: Column(
        children: [
          Container(
            width: 84,
            height: 84,
            decoration: BoxDecoration(
              color: PetScaniaColors.cloud,
              borderRadius: BorderRadius.circular(26),
            ),
            child: const Icon(
              Icons.medical_information_rounded,
              color: PetScaniaColors.royalBlue,
              size: 42,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            "Aún no tienes análisis.",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: PetScaniaColors.ink,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Cuando subas una imagen y VetIA genere un diagnóstico, aparecerá aquí tu historial clínico.",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: PetScaniaColors.ink.withValues(alpha: 0.65),
              height: 1.45,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}