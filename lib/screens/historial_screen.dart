import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show ByteData, rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:petscania/theme/petscania_brand.dart';
import 'package:printing/printing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HistorialScreen extends StatefulWidget {
  const HistorialScreen({super.key});

  @override
  State<HistorialScreen> createState() => _HistorialScreenState();
}

class _HistorialScreenState extends State<HistorialScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _consultas = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
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

      if (petData == null) {
        if (mounted) {
          setState(() => _isLoading = false);
        }
        return;
      }

      final data = await _supabase
          .from('medical_scans')
          .select()
          .eq('pet_id', petData['id'])
          .order('created_at', ascending: false);

      if (mounted) {
        setState(() {
          _consultas = List<Map<String, dynamic>>.from(data);
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error historial: $e");
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _abrirVistaPreviaPDF(Map<String, dynamic> consulta) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VisorPdfScreen(consulta: consulta),
      ),
    );
  }

  String _formatDate(String? isoDate) {
    if (isoDate == null) return "Fecha desconocida";

    try {
      final date = DateTime.parse(isoDate).toLocal();

      return "${date.day.toString().padLeft(2, '0')}/"
          "${date.month.toString().padLeft(2, '0')}/"
          "${date.year} "
          "${date.hour.toString().padLeft(2, '0')}:"
          "${date.minute.toString().padLeft(2, '0')}";
    } catch (e) {
      return "Fecha reciente";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PetScaniaColors.mist,
      body: Stack(
        children: [
          Container(
            height: 315,
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
                              'Historial Médico',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 23,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Reportes clínicos generados por IA para tu mascota.',
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

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: _buildSummaryCard(),
                ),

                const SizedBox(height: 18),

                Expanded(
                  child: Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      color: PetScaniaColors.mist,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(34),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 22, 20, 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Diagnósticos recientes',
                                style: TextStyle(
                                  color: PetScaniaColors.ink,
                                  fontSize: 19,
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
                                  '${_consultas.length} reportes',
                                  style: const TextStyle(
                                    color: PetScaniaColors.royalBlue,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        Expanded(
                          child: _isLoading
                              ? const Center(
                                  child: CircularProgressIndicator(
                                    color: PetScaniaColors.royalBlue,
                                  ),
                                )
                              : _consultas.isEmpty
                                  ? _buildEmptyState()
                                  : RefreshIndicator(
                                      onRefresh: _loadHistory,
                                      color: PetScaniaColors.royalBlue,
                                      child: ListView.builder(
                                        physics:
                                            const AlwaysScrollableScrollPhysics(),
                                        padding: const EdgeInsets.fromLTRB(
                                          20,
                                          10,
                                          20,
                                          32,
                                        ),
                                        itemCount: _consultas.length,
                                        itemBuilder: (context, index) {
                                          final consulta = _consultas[index];
                                          return _buildConsultaCard(consulta);
                                        },
                                      ),
                                    ),
                        ),
                      ],
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

  Widget _buildSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: PetScaniaDecor.surfaceGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: PetScaniaColors.royalBlue.withValues(alpha: 0.18),
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: PetScaniaColors.royalBlue.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.assignment_rounded,
              color: PetScaniaColors.royalBlue,
              size: 28,
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Reportes Clínicos IA',
                  style: TextStyle(
                    color: PetScaniaColors.ink,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  'Visualiza, revisa y exporta diagnósticos oficiales en PDF.',
                  style: TextStyle(
                    color: Color(0xFF6B7F9F),
                    height: 1.35,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConsultaCard(Map<String, dynamic> consulta) {
    final score = (consulta['confidence_score'] ?? 0.0).toDouble();
    final diagnostico = consulta['ai_diagnosis'] ?? 'Sin diagnóstico';
    final mascota = consulta['mascota_nombre'] ?? 'Mascota';
    final fecha = _formatDate(consulta['created_at']);

    Color colorConfianza = PetScaniaColors.royalBlue;

    if (score < 50) {
      colorConfianza = const Color(0xFFD84A4A);
    } else if (score < 80) {
      colorConfianza = const Color(0xFFF59E0B);
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: PetScaniaSurfaceCard(
        padding: const EdgeInsets.all(18),
        borderRadius: BorderRadius.circular(28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: PetScaniaColors.cloud,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Icon(
                    Icons.pets_rounded,
                    color: PetScaniaColors.royalBlue,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        diagnostico.toString(),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: PetScaniaColors.ink,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          height: 1.15,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        'Paciente: $mascota',
                        style: TextStyle(
                          color: PetScaniaColors.ink.withValues(alpha: 0.55),
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: PetScaniaColors.mist,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: PetScaniaColors.line),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.calendar_today_rounded,
                    size: 17,
                    color: PetScaniaColors.royalBlue,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      fecha,
                      style: TextStyle(
                        color: PetScaniaColors.ink.withValues(alpha: 0.68),
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: colorConfianza.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '${score.toStringAsFixed(1)}% IA',
                      style: TextStyle(
                        color: colorConfianza,
                        fontWeight: FontWeight.w900,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: PetScaniaDecor.primaryGradient,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: PetScaniaColors.royalBlue.withValues(alpha: 0.22),
                      blurRadius: 14,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: ElevatedButton.icon(
                  onPressed: () => _abrirVistaPreviaPDF(consulta),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  icon: const Icon(
                    Icons.picture_as_pdf_rounded,
                    size: 20,
                    color: Colors.white,
                  ),
                  label: const Text(
                    'Ver Reporte Oficial',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 34),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 92,
              height: 92,
              decoration: BoxDecoration(
                color: PetScaniaColors.cloud,
                borderRadius: BorderRadius.circular(28),
              ),
              child: const Icon(
                Icons.history_rounded,
                color: PetScaniaColors.royalBlue,
                size: 46,
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Aún no tienes diagnósticos.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: PetScaniaColors.ink,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Cuando realices un escaneo, tus reportes clínicos aparecerán aquí listos para revisar o exportar.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: PetScaniaColors.ink.withValues(alpha: 0.65),
                height: 1.45,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// PANTALLA: VISOR DE PDF OFICIAL
// ---------------------------------------------------------------------------

class VisorPdfScreen extends StatelessWidget {
  final Map<String, dynamic> consulta;

  const VisorPdfScreen({super.key, required this.consulta});

  String _formatDate(String? isoDate) {
    if (isoDate == null) return "Fecha desconocida";

    try {
      final date = DateTime.parse(isoDate).toLocal();

      return "${date.day.toString().padLeft(2, '0')}/"
          "${date.month.toString().padLeft(2, '0')}/"
          "${date.year} "
          "${date.hour.toString().padLeft(2, '0')}:"
          "${date.minute.toString().padLeft(2, '0')}";
    } catch (e) {
      return "Fecha reciente";
    }
  }

  Future<Uint8List> _generarDocumentoPdf(PdfPageFormat format) async {
    final pdf = pw.Document(version: PdfVersion.pdf_1_5, compress: true);

    final ByteData bytes =
        await rootBundle.load('assets/images/PetScanIA_PDF.png');
    final Uint8List logoBytes = bytes.buffer.asUint8List();
    final logoImage = pw.MemoryImage(logoBytes);

    pw.ImageProvider? scanImage;

    if (consulta['image_url'] != null &&
        consulta['image_url'].toString().isNotEmpty) {
      try {
        scanImage = await networkImage(consulta['image_url']);
      } catch (e) {
        debugPrint("No se pudo cargar la imagen de internet para el PDF");
      }
    }

    final mascota = consulta['mascota_nombre'] ?? 'Mascota';
    final fecha = _formatDate(consulta['created_at']);
    final diagnostico = consulta['ai_diagnosis'] ?? 'Sin diagnóstico';
    final descripcion =
        consulta['descripcion'] ?? 'Descripción visual generada por modelo IA.';
    final sintomas =
        consulta['sintomas'] == null || consulta['sintomas'].toString().isEmpty
            ? 'Ningún síntoma adicional registrado.'
            : consulta['sintomas'];

    List<String> recomendaciones = [];

    if (consulta['recomendaciones'] is List) {
      recomendaciones = List<String>.from(consulta['recomendaciones']);
    } else if (consulta['recomendaciones'] is String) {
      recomendaciones = [consulta['recomendaciones']];
    }

    final blueColor = PdfColor.fromHex('#0253B3');
    final darkColor = PdfColor.fromHex('#0F172A');
    final lightGreenBg = PdfColor.fromHex('#EEF7FF');
    final lightGreyBg = PdfColor.fromHex('#F8FAFC');
    final orangeBg = PdfColor.fromHex('#FFF7ED');
    final orangeText = PdfColor.fromHex('#C2410C');

    pdf.addPage(
      pw.Page(
        pageFormat: format,
        margin: const pw.EdgeInsets.symmetric(horizontal: 40, vertical: 50),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Expanded(
                    flex: 2,
                    child: pw.Container(
                      height: 80,
                      decoration: pw.BoxDecoration(
                        color: lightGreenBg,
                        borderRadius: pw.BorderRadius.circular(10),
                      ),
                      child: pw.Center(
                        child: pw.Image(logoImage, height: 50),
                      ),
                    ),
                  ),
                  pw.SizedBox(width: 15),
                  pw.Expanded(
                    flex: 4,
                    child: pw.Container(
                      height: 80,
                      padding: const pw.EdgeInsets.symmetric(
                        horizontal: 15,
                        vertical: 10,
                      ),
                      decoration: pw.BoxDecoration(
                        color: lightGreenBg,
                        borderRadius: pw.BorderRadius.circular(10),
                      ),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        mainAxisAlignment: pw.MainAxisAlignment.center,
                        children: [
                          pw.Text(
                            'PetScanIA cuida contigo. Te damos orientación inmediata para tu amigo especial.',
                            style: pw.TextStyle(
                              color: blueColor,
                              fontWeight: pw.FontWeight.bold,
                              fontSize: 10,
                            ),
                          ),
                          pw.SizedBox(height: 4),
                          pw.Text(
                            'Aún aprendemos cada día; verifica siempre con tu veterinario si ves algo raro o urgente.',
                            style: pw.TextStyle(
                              color: blueColor,
                              fontSize: 9,
                            ),
                          ),
                          pw.SizedBox(height: 4),
                          pw.Align(
                            alignment: pw.Alignment.centerRight,
                            child: pw.Text(
                              'Señales claras en segundos.',
                              style: pw.TextStyle(
                                color: blueColor,
                                fontStyle: pw.FontStyle.italic,
                                fontSize: 9,
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              pw.SizedBox(height: 25),

              pw.Text(
                'Reporte de Diagnóstico',
                style: pw.TextStyle(
                  fontSize: 20,
                  fontWeight: pw.FontWeight.bold,
                  color: darkColor,
                ),
              ),

              pw.SizedBox(height: 15),

              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Expanded(
                    flex: 3,
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Container(
                          padding: const pw.EdgeInsets.all(12),
                          decoration: pw.BoxDecoration(
                            color: lightGreyBg,
                            borderRadius: pw.BorderRadius.circular(8),
                            border: pw.Border.all(
                              color: PdfColors.grey300,
                              width: 0.5,
                            ),
                          ),
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text(
                                'Mascota: $mascota',
                                style: pw.TextStyle(
                                  fontSize: 12,
                                  fontWeight: pw.FontWeight.bold,
                                ),
                              ),
                              pw.SizedBox(height: 4),
                              pw.Text(
                                'Propietario: Sleyter Saldaña',
                                style: const pw.TextStyle(fontSize: 11),
                              ),
                              pw.SizedBox(height: 4),
                              pw.Text(
                                'Fecha: $fecha',
                                style: const pw.TextStyle(
                                  fontSize: 11,
                                  color: PdfColors.grey800,
                                ),
                              ),
                            ],
                          ),
                        ),

                        pw.SizedBox(height: 20),

                        pw.Text(
                          'Diagnóstico',
                          style: pw.TextStyle(
                            fontSize: 14,
                            fontWeight: pw.FontWeight.bold,
                            color: darkColor,
                          ),
                        ),

                        pw.SizedBox(height: 4),

                        pw.RichText(
                          text: pw.TextSpan(
                            children: [
                              pw.TextSpan(
                                text: '$diagnostico - ',
                                style: pw.TextStyle(
                                  fontSize: 12,
                                  fontWeight: pw.FontWeight.bold,
                                  color: blueColor,
                                ),
                              ),
                              pw.TextSpan(
                                text: descripcion.toString(),
                                style: const pw.TextStyle(
                                  fontSize: 12,
                                  lineSpacing: 1.2,
                                ),
                              ),
                            ],
                          ),
                        ),

                        pw.SizedBox(height: 20),

                        pw.Text(
                          'Recomendaciones / Notas',
                          style: pw.TextStyle(
                            fontSize: 14,
                            fontWeight: pw.FontWeight.bold,
                            color: darkColor,
                          ),
                        ),

                        pw.SizedBox(height: 4),

                        pw.Text(
                          'Recomendaciones:',
                          style: pw.TextStyle(
                            fontSize: 12,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),

                        pw.SizedBox(height: 4),

                        if (recomendaciones.isEmpty)
                          pw.Text(
                            '- Sin recomendaciones registradas.',
                            style: const pw.TextStyle(
                              fontSize: 12,
                              lineSpacing: 1.2,
                            ),
                          )
                        else
                          ...recomendaciones.map(
                            (r) => pw.Padding(
                              padding: const pw.EdgeInsets.only(bottom: 3),
                              child: pw.Text(
                                '- $r',
                                style: const pw.TextStyle(
                                  fontSize: 12,
                                  lineSpacing: 1.2,
                                ),
                              ),
                            ),
                          ),

                        pw.SizedBox(height: 15),

                        pw.Text(
                          'Síntomas/Notas:',
                          style: pw.TextStyle(
                            fontSize: 12,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),

                        pw.SizedBox(height: 4),

                        pw.Text(
                          sintomas.toString(),
                          style: const pw.TextStyle(
                            fontSize: 12,
                            lineSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),

                  pw.SizedBox(width: 20),

                  pw.Expanded(
                    flex: 2,
                    child: scanImage != null
                        ? pw.Container(
                            height: 200,
                            decoration: pw.BoxDecoration(
                              borderRadius: pw.BorderRadius.circular(10),
                              border: pw.Border.all(
                                color: PdfColors.grey300,
                                width: 1,
                              ),
                              image: pw.DecorationImage(
                                image: scanImage,
                                fit: pw.BoxFit.cover,
                              ),
                            ),
                          )
                        : pw.Container(
                            height: 200,
                            decoration: pw.BoxDecoration(
                              color: PdfColors.grey100,
                              borderRadius: pw.BorderRadius.circular(10),
                              border: pw.Border.all(
                                color: PdfColors.grey300,
                                width: 1,
                              ),
                            ),
                            child: pw.Center(
                              child: pw.Text(
                                'Sin imagen disponible',
                                style: const pw.TextStyle(
                                  fontSize: 10,
                                  color: PdfColors.grey,
                                ),
                              ),
                            ),
                          ),
                  ),
                ],
              ),

              pw.Spacer(),

              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  color: orangeBg,
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Aviso:',
                      style: pw.TextStyle(
                        fontSize: 11,
                        fontWeight: pw.FontWeight.bold,
                        color: orangeText,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'Este reporte es orientativo. Si observas signos de alarma o la situación empeora, consulta con un veterinario profesional.',
                      style: pw.TextStyle(
                        fontSize: 10,
                        color: orangeText,
                      ),
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 15),

              pw.Text(
                'Firmado digitalmente por PetScanIA',
                style: pw.TextStyle(
                  fontSize: 10,
                  fontStyle: pw.FontStyle.italic,
                  color: PdfColors.grey700,
                ),
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PetScaniaColors.mist,
      appBar: AppBar(
        backgroundColor: PetScaniaColors.mist,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        iconTheme: const IconThemeData(color: PetScaniaColors.ink),
        title: const Text(
          "Previsualización de Reporte",
          style: TextStyle(
            color: PetScaniaColors.ink,
            fontSize: 16,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      body: PdfPreview(
        build: (format) => _generarDocumentoPdf(format),
        allowPrinting: true,
        allowSharing: true,
        canChangeOrientation: false,
        canChangePageFormat: false,
        pdfFileName: 'Reporte_PetScanIA_${consulta['mascota_nombre']}.pdf',
      ),
    );
  }
}