import 'dart:convert';
import 'dart:io';
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:petscania/screens/maps/clinic_map_screen.dart';
import 'package:petscania/theme/petscania_brand.dart';
import 'package:record/record.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({super.key});

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  static const String openAiKey = String.fromEnvironment(
    'OPENAI_API_KEY',
    defaultValue: '',
  );
  static const String _geminiApiKey = String.fromEnvironment(
    'GEMINI_API_KEY',
    defaultValue: '',
  );
  static const String _geminiModel = 'gemini-2.5-flash';
  static const double _telemedBasePrice = 10.0;
  static const List<String> _criticalKeywords = [
    'dificultad para respirar',
    'no puede respirar',
    'convulsion',
    'convulsiones',
    'sangre',
    'sangrado',
    'vomita sangre',
    'vomito con sangre',
    'vomitos con sangre',
    'hematemesis',
    'hemorragia',
    'vomitos persistentes',
    'vomito persistente',
    'diarrea con sangre',
    'decaimiento extremo',
    'abdomen hinchado',
    'dolor intenso',
    'intoxicacion',
    'envenenamiento',
    'atropello',
    'perdida de conciencia',
    'desmayo',
  ];

  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late final AudioRecorder _audioRecorder;
  final List<Map<String, String>> _messages = [];

  bool _isRecording = false;
  bool _isLoading = false;
  bool _isProcessingAudio = false;
  bool _triageCompleted = false;
  bool _telemedOfferShown = false;

  @override
  void initState() {
    super.initState();
    _audioRecorder = AudioRecorder();
  }

  @override
  void dispose() {
    _audioRecorder.dispose();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _toggleRecording() async {
    if (kIsWeb) {
      _showError('El audio aun no esta disponible en la version web.');
      return;
    }

    if (_isRecording) {
      final path = await _audioRecorder.stop();
      setState(() => _isRecording = false);
      if (path != null) {
        final bytes = await File(path).readAsBytes();
        await _transcribeAudioBytesWithWhisper(bytes, 'audio.m4a');
      }
      return;
    }

    if (await _checkMicrophonePermission()) {
      final tempDir = await getTemporaryDirectory();
      final path = '${tempDir.path}/temp_audio.m4a';
      await _audioRecorder.start(const RecordConfig(), path: path);
      setState(() => _isRecording = true);
    } else {
      _showError('Necesitamos permiso de microfono.');
    }
  }

  Future<bool> _checkMicrophonePermission() async {
    var status = await Permission.microphone.status;
    if (!status.isGranted) {
      status = await Permission.microphone.request();
    }
    return status.isGranted;
  }

  Future<void> _transcribeAudioBytesWithWhisper(
    Uint8List audioBytes,
    String filename,
  ) async {
    setState(() => _isProcessingAudio = true);
    try {
      if (openAiKey.isEmpty) {
        _showError(
          'Falta configurar OPENAI_API_KEY para transcripcion de audio.',
        );
        return;
      }

      final request = http.MultipartRequest(
        'POST',
        Uri.parse('https://api.openai.com/v1/audio/transcriptions'),
      );
      request.headers['Authorization'] = 'Bearer $openAiKey';
      request.fields['model'] = 'whisper-1';
      request.files.add(
        http.MultipartFile.fromBytes('file', audioBytes, filename: filename),
      );

      final response = await request.send();
      if (response.statusCode == 200) {
        final responseBody = await response.stream.bytesToString();
        final data = jsonDecode(responseBody) as Map<String, dynamic>;
        _controller.text = (data['text'] ?? '').toString();
        await _sendMessage();
      } else {
        _showError('No pude entender el audio.');
      }
    } catch (_) {
      _showError('Error de conexion con Whisper.');
    } finally {
      if (mounted) {
        setState(() => _isProcessingAudio = false);
      }
    }
  }

  Future<void> _sendMessage({String? textOverride}) async {
    final text = textOverride ?? _controller.text.trim();
    if (text.isEmpty) {
      return;
    }

    setState(() {
      _messages.add({'role': 'user', 'content': text});
      _isLoading = true;
    });
    _controller.clear();
    _scrollToBottom();

    try {
      if (_geminiApiKey.isEmpty) {
        final fallback = _buildResilientLocalReply(providerLimited: false);
        setState(() {
          _messages.add({'role': 'assistant', 'content': fallback});
          if (_shouldCloseTriageInFallback) {
            _triageCompleted = true;
          }
        });
        await _maybeShowTelemedicineOffer();
        return;
      }

      final payload = jsonEncode({
        'contents': [
          {
            'parts': [
              {
                'text': _buildVetPrompt(
                  assistantTurns: _assistantTurnCount,
                  forceEmergencyClose: _hasCriticalEmergencySignals,
                ),
              },
            ],
          },
        ],
        'generationConfig': {
          'temperature': 0.7,
          'maxOutputTokens': 320,
          'thinkingConfig': {'thinkingBudget': 0},
        },
      });

      final response = await _postGeminiWithRetry(
        endpoint: Uri.parse(_chatEndpoint()),
        body: payload,
      );

      if (response.statusCode != 200) {
        if (_isRateLimitError(response)) {
          final fallback = _buildResilientLocalReply(providerLimited: true);
          setState(() {
            _messages.add({'role': 'assistant', 'content': fallback});
            if (_shouldCloseTriageInFallback) {
              _triageCompleted = true;
            }
          });
          await _maybeShowTelemedicineOffer();
          return;
        }
        throw Exception('Gemini devolvio ${response.statusCode}');
      }

      final data =
          jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      final rawReply =
          data['candidates']?[0]?['content']?['parts']?[0]?['text']
              ?.toString()
              .trim() ??
          '';

      final parsed = _extractTriageCompletion(rawReply);
      final cleaned = _sanitizeVetReply(parsed.message);

      setState(() {
        _messages.add({
          'role': 'assistant',
          'content': cleaned.isEmpty
              ? 'No pude generar una respuesta en este momento.'
              : cleaned,
        });
        if (parsed.completed) {
          _triageCompleted = true;
        }
      });

      await _maybeShowTelemedicineOffer();
    } catch (_) {
      final fallback = _buildResilientLocalReply(providerLimited: false);
      setState(() {
        _messages.add({'role': 'assistant', 'content': fallback});
        if (_shouldCloseTriageInFallback) {
          _triageCompleted = true;
        }
      });
      await _maybeShowTelemedicineOffer();
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
      _scrollToBottom();
    }
  }

  String _chatEndpoint() {
    if (_geminiApiKey.isEmpty) {
      return '';
    }
    return 'https://generativelanguage.googleapis.com/v1beta/models/$_geminiModel:generateContent?key=$_geminiApiKey';
  }

  Future<http.Response> _postGeminiWithRetry({
    required Uri endpoint,
    required String body,
  }) async {
    const maxAttempts = 3;
    var attempt = 0;

    while (true) {
      attempt += 1;
      try {
        final response = await http.post(
          endpoint,
          headers: const {'Content-Type': 'application/json'},
          body: body,
        );

        if (!_isRetryableStatus(response.statusCode) ||
            attempt >= maxAttempts) {
          return response;
        }
      } catch (_) {
        if (attempt >= maxAttempts) {
          rethrow;
        }
      }

      final waitMs = 700 * attempt;
      await Future<void>.delayed(Duration(milliseconds: waitMs));
    }
  }

  bool _isRetryableStatus(int statusCode) {
    return statusCode == 429 || statusCode == 503 || statusCode == 504;
  }

  bool _isRateLimitError(http.Response response) {
    final body = response.body.toLowerCase();
    return response.statusCode == 429 ||
        body.contains('resource_exhausted') ||
        body.contains('too many requests') ||
        body.contains('quota');
  }

  // ignore: unused_element
  String _buildRateLimitedAssistantReply() {
    if (_hasCriticalEmergencySignals) {
      return '''
Posible causa principal:
Podria estar relacionado con irritacion gastrointestinal importante, sangrado digestivo u otra complicacion que requiere revision pronta.

Otras causas posibles:
Una posibilidad es ingestion de un cuerpo extrano, gastritis severa, ulcera, intoxicacion o una enfermedad sistemica.

Senales de alarma:
Vomito con sangre, vomitos repetidos, decaimiento marcado, dolor abdominal, encías palidas, deshidratacion o dificultad para respirar.

Nivel de urgencia:
Emergencia

Advertencia:
Esta orientacion no reemplaza una consulta veterinaria.

Estoy recibiendo muchas consultas en este momento. Por los signos que describes, te recomiendo atencion veterinaria presencial urgente ahora.
''';
    }
    return 'Estoy recibiendo muchas consultas en este momento y la respuesta puede tardar un poco. Intenta de nuevo en unos segundos para continuar el triaje. Esta orientacion no reemplaza una consulta veterinaria.';
  }

  // ignore: unused_element
  String _buildFallbackReplyWhenUnavailable() {
    if (_hasCriticalEmergencySignals) {
      return '''
Posible causa principal:
Podria estar relacionado con un problema digestivo o sistemico que necesita evaluacion veterinaria pronta.

Otras causas posibles:
Una posibilidad es sangrado digestivo, intoxicacion, irritacion severa, cuerpo extrano o una complicacion metabolica.

Senales de alarma:
Presencia de sangre, vomitos continuos, debilidad, dolor intenso, abdomen hinchado o perdida de conciencia.

Nivel de urgencia:
Emergencia

Advertencia:
Esta orientacion no reemplaza una consulta veterinaria.

No pude conectarme al asistente en este momento. Por seguridad, te recomiendo llevar a tu mascota a atencion veterinaria presencial urgente ahora.
''';
    }
    return 'No pude conectarme al asistente en este momento. Intenta nuevamente en unos segundos para continuar el triaje. Esta orientacion no reemplaza una consulta veterinaria.';
  }

  bool get _shouldCloseTriageInFallback {
    return _assistantTurnCount >= 3 || _hasCriticalEmergencySignals;
  }

  String get _latestUserMessage {
    for (final message in _messages.reversed) {
      if (message['role'] == 'user') {
        return (message['content'] ?? '').toLowerCase();
      }
    }
    return '';
  }

  String _buildResilientLocalReply({required bool providerLimited}) {
    if (_shouldCloseTriageInFallback) {
      return _buildLocalTriageClosing(providerLimited: providerLimited);
    }
    return _buildLocalTriageFollowUp(providerLimited: providerLimited);
  }

  String _buildLocalTriageFollowUp({required bool providerLimited}) {
    final continuityLine = providerLimited
        ? 'Estoy continuando el triaje en modo de respaldo para no cortar la conversacion.'
        : 'Voy a continuar el triaje en modo de respaldo para no perder el hilo de la conversacion.';

    return '''
$continuityLine

${_inferSymptomFocus()}

${_nextFallbackQuestion()}
''';
  }

  String _buildLocalTriageClosing({required bool providerLimited}) {
    final continuityLine = providerLimited
        ? 'Estoy cerrando esta orientacion en modo de respaldo para que no se interrumpa la conversacion.'
        : 'Estoy cerrando esta orientacion en modo de respaldo para que puedas seguir avanzando aunque el asistente externo falle.';

    return '''
$continuityLine

Posible causa principal:
${_inferPrimaryCause()}

Otras causas posibles:
${_inferOtherPossibleCauses()}

Senales de alarma:
${_inferAlarmSignals()}

Nivel de urgencia:
${_inferUrgencyLevel()}

Advertencia:
Esta orientacion no reemplaza una consulta veterinaria.
''';
  }

  String _inferSymptomFocus() {
    final text = _latestUserMessage;
    if (_containsAny(text, const ['vomit', 'vomito', 'vomita', 'nausea'])) {
      return 'Estos sintomas pueden aparecer en casos de irritacion gastrointestinal, cambios bruscos en la dieta o un problema digestivo que necesita seguimiento.';
    }
    if (_containsAny(text, const ['diarrea', 'heces', 'suelta'])) {
      return 'Podria estar relacionado con un trastorno digestivo, parasitos o sensibilidad alimentaria, aunque no puedo confirmarlo sin evaluacion veterinaria.';
    }
    if (_containsAny(text, const ['no quiere comer', 'no come', 'apetito'])) {
      return 'La falta de apetito puede aparecer en cuadros digestivos, dolor, estres o malestar general, y conviene revisar como evoluciona.';
    }
    if (_containsAny(text, const ['tos', 'respira', 'jadea'])) {
      return 'Una posibilidad es irritacion respiratoria, dolor o una condicion que necesita valoracion clinica si va en aumento.';
    }
    if (_containsAny(text, const ['rasca', 'piel', 'herida', 'oreja'])) {
      return 'Podria estar relacionado con irritacion local, alergia, infeccion o molestias en piel u oidos.';
    }
    return 'Podria estar relacionado con un cuadro leve o con algo que necesita mas datos para orientarlo mejor. No puedo confirmarlo sin evaluacion veterinaria.';
  }

  String _nextFallbackQuestion() {
    final turn = _assistantTurnCount;
    final text = _latestUserMessage;

    if (turn <= 1) {
      if (_containsAny(text, const ['vomit', 'vomito', 'vomita'])) {
        return 'Para seguir orientandote, los vomitos han sido una sola vez o se han repetido, y ha podido tomar agua?';
      }
      if (_containsAny(text, const ['diarrea', 'heces'])) {
        return 'Para seguir orientandote, desde cuando esta asi y has notado sangre, fiebre o mucho decaimiento?';
      }
      return 'Para seguir orientandote, desde cuando notas este problema y que otro cambio has observado en su comportamiento?';
    }

    if (turn == 2) {
      if (_containsAny(text, const ['vomit', 'vomito', 'vomita', 'diarrea'])) {
        return 'Has notado decaimiento, dolor abdominal, encias palidas o que no quiera beber agua?';
      }
      return 'Ha seguido comiendo, bebiendo agua y haciendo sus actividades con relativa normalidad?';
    }

    return 'Hay alguna senal adicional como dolor intenso, dificultad para respirar, desmayo o empeoramiento rapido?';
  }

  String _inferPrimaryCause() {
    final allUserText = _allUserText;
    if (_containsAny(allUserText, const [
      'vomit',
      'vomito',
      'vomita',
      'diarrea',
    ])) {
      return 'Podria estar relacionado con un problema gastrointestinal que requiere seguimiento cercano.';
    }
    if (_containsAny(allUserText, const [
      'no quiere comer',
      'no come',
      'apetito',
    ])) {
      return 'Podria estar relacionado con malestar digestivo, dolor, estres o una condicion general que afecta el apetito.';
    }
    if (_containsAny(allUserText, const ['rasca', 'piel', 'oreja', 'herida'])) {
      return 'Podria estar relacionado con irritacion local, alergia, infeccion o molestias dermatologicas.';
    }
    if (_containsAny(allUserText, const ['tos', 'respira', 'jadea'])) {
      return 'Podria estar relacionado con una molestia respiratoria o con dolor que requiere valoracion si persiste.';
    }
    return 'Podria estar relacionado con un cuadro inespecifico que necesita evaluacion clinica para confirmarse.';
  }

  String _inferOtherPossibleCauses() {
    final allUserText = _allUserText;
    if (_containsAny(allUserText, const ['sangre', 'sangrado', 'hemorragia'])) {
      return 'Una posibilidad es irritacion severa, sangrado digestivo, intoxicacion, cuerpo extrano o una enfermedad sistemica.';
    }
    if (_containsAny(allUserText, const ['vomit', 'vomito', 'vomita'])) {
      return 'Tambien podria aparecer en gastritis, indiscrecion alimentaria, parasitos, pancreatitis o ingestion de algo no habitual.';
    }
    if (_containsAny(allUserText, const ['diarrea'])) {
      return 'Tambien podria aparecer en infecciones, parasitos, cambios de alimento, sensibilidad digestiva o estres.';
    }
    return 'Tambien podria estar relacionado con dolor, infeccion, estres, cambios en la dieta o una enfermedad metabolica.';
  }

  String _inferAlarmSignals() {
    final allUserText = _allUserText;
    if (_containsAny(allUserText, const ['sangre', 'sangrado', 'hemorragia'])) {
      return 'Presencia de sangre, vomitos repetidos, debilidad marcada, dolor abdominal, encias palidas, deshidratacion o dificultad para respirar.';
    }
    if (_containsAny(allUserText, const [
      'vomit',
      'vomito',
      'vomita',
      'diarrea',
    ])) {
      return 'Vomitos persistentes, diarrea con sangre, decaimiento extremo, no tolerar agua, dolor intenso o abdomen hinchado.';
    }
    return 'Empeoramiento rapido, dificultad para respirar, convulsiones, dolor intenso, desmayo, abdomen hinchado o falta total de respuesta.';
  }

  String _inferUrgencyLevel() {
    if (_hasCriticalEmergencySignals) {
      return 'Emergencia';
    }

    final allUserText = _allUserText;
    if (_containsAny(allUserText, const [
      'vomit',
      'vomito',
      'vomita',
      'diarrea',
    ])) {
      return 'Alta';
    }
    if (_containsAny(allUserText, const [
      'no quiere comer',
      'no come',
      'apetito',
      'rasca',
      'oreja',
    ])) {
      return 'Media';
    }
    return 'Baja';
  }

  String get _allUserText {
    return _messages
        .where((m) => m['role'] == 'user')
        .map((m) => (m['content'] ?? '').toLowerCase())
        .join(' ');
  }

  bool _containsAny(String text, List<String> needles) {
    for (final needle in needles) {
      if (text.contains(needle)) {
        return true;
      }
    }
    return false;
  }

  String _buildConversationHistory() {
    return _messages
        .map(
          (m) =>
              '${m['role'] == 'user' ? 'Usuario' : 'VetIA'}: ${m['content']}',
        )
        .join('\n');
  }

  int get _assistantTurnCount =>
      _messages.where((m) => m['role'] == 'assistant').length;

  bool get _hasCriticalEmergencySignals {
    return _criticalKeywords.any(_allUserText.contains);
  }

  String _buildVetPrompt({
    required int assistantTurns,
    required bool forceEmergencyClose,
  }) {
    final isClosingStage = assistantTurns >= 3 || forceEmergencyClose;
    return '''
Eres VetIA, asistente veterinario de triaje orientativo para mascotas.

Objetivo:
- Sugerir posibles causas o enfermedades relacionadas con sintomas.
- Nunca dar diagnostico definitivo.

Prohibido usar:
- "Tu mascota tiene..."
- "El diagnostico es..."
- "Definitivamente es..."
- "Estoy seguro de que es..."

Permitido usar:
- "Podria estar relacionado con..."
- "Una posibilidad es..."
- "Estos sintomas pueden aparecer en casos de..."
- "No puedo confirmarlo sin evaluacion veterinaria."
- "Un veterinario debe revisar el caso para confirmar."

Reglas de triaje:
- En fase inicial: maximo 1 pregunta puntual por respuesta.
- Triaje total corto: 4 a 5 respuestas tuyas (8 a 10 interacciones totales con usuario).
- Si hay signos graves (dificultad para respirar, convulsiones, sangrado, vomitos persistentes, diarrea con sangre, decaimiento extremo, abdomen hinchado, dolor intenso, intoxicacion, atropello o perdida de conciencia), recomendar atencion veterinaria urgente presencial.

Cierre obligatorio del triaje:
- Posible causa principal
- Otras causas posibles
- Senales de alarma
- Nivel de urgencia: baja, media, alta o emergencia
- Advertencia literal: "Esta orientacion no reemplaza una consulta veterinaria."

Estado:
- Respuestas de VetIA hasta ahora: $assistantTurns
- Debes cerrar triaje ahora: ${isClosingStage ? 'SI' : 'NO'}

Formato:
- Si NO cierras: 2 parrafos breves + 1 pregunta puntual.
- Si cierras: usa titulos exactos:
  Posible causa principal:
  Otras causas posibles:
  Senales de alarma:
  Nivel de urgencia:
  Advertencia:
- Ultima linea obligatoria: [TRIAJE_COMPLETO:SI] o [TRIAJE_COMPLETO:NO]

Historial del chat:
${_buildConversationHistory()}
''';
  }

  _TriageParsedResponse _extractTriageCompletion(String raw) {
    final normalized = raw.replaceAll('\r', '');
    final completed = normalized.contains('[TRIAJE_COMPLETO:SI]');
    final message = normalized
        .replaceAll('[TRIAJE_COMPLETO:SI]', '')
        .replaceAll('[TRIAJE_COMPLETO:NO]', '')
        .trim();
    return _TriageParsedResponse(message: message, completed: completed);
  }

  String _sanitizeVetReply(String reply) {
    return reply
        .replaceAll('Tu mascota tiene', 'Podria estar relacionado con')
        .replaceAll('El diagnostico es', 'Una posibilidad es')
        .replaceAll('Definitivamente es', 'Una posibilidad importante es')
        .replaceAll('Estoy seguro de que es', 'Podria estar relacionado con');
  }

  Future<void> _openTelemedicineFlow() async {
    if (!mounted) {
      return;
    }
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ClinicMapScreen()),
    );
  }

  Future<bool> _hasAvailableVeterinariansNow() async {
    try {
      final providers = await Supabase.instance.client
          .from('service_providers')
          .select('*')
          .eq('is_verified', true)
          .limit(40);
      final rows = List<Map<String, dynamic>>.from(providers);
      if (rows.isEmpty) {
        return false;
      }

      final hasSignals = rows.any(
        (row) =>
            row.containsKey('available_now') ||
            row.containsKey('is_online') ||
            row.containsKey('last_seen_at'),
      );

      if (!hasSignals) {
        return rows.isNotEmpty;
      }

      for (final row in rows) {
        final availableNow = row['available_now'] == true;
        final isOnline = row['is_online'] == true;

        var recentlyActive = false;
        final lastSeenRaw = row['last_seen_at']?.toString();
        if (lastSeenRaw != null && lastSeenRaw.isNotEmpty) {
          final lastSeen = DateTime.tryParse(lastSeenRaw)?.toUtc();
          if (lastSeen != null) {
            final diff = DateTime.now().toUtc().difference(lastSeen);
            recentlyActive = diff.inMinutes <= 15;
          }
        }

        if (availableNow || isOnline || recentlyActive) {
          return true;
        }
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<void> _maybeShowTelemedicineOffer() async {
    if (!_triageCompleted || _telemedOfferShown || !mounted) {
      return;
    }
    _telemedOfferShown = true;
    await _showTelemedicineOfferModal();
  }

  Future<void> _showTelemedicineOfferModal() async {
    if (!mounted) {
      return;
    }

    var checking = false;
    bool? isAvailableNow;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final checked = isAvailableNow != null;
            final available = isAvailableNow == true;

            return Dialog(
              insetPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 24,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 520),
                padding: const EdgeInsets.fromLTRB(22, 20, 22, 18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: PetScaniaColors.ink.withValues(alpha: 0.16),
                      blurRadius: 26,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          gradient: PetScaniaDecor.primaryGradient,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: const Text(
                          'Oferta especial',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 52,
                            height: 52,
                            decoration: const BoxDecoration(
                              gradient: PetScaniaDecor.primaryGradient,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.video_call_rounded,
                              color: Colors.white,
                              size: 30,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              'Teleconsulta veterinaria por solo S/ 10',
                              style: TextStyle(
                                color: PetScaniaColors.ink,
                                fontWeight: FontWeight.w900,
                                fontSize: 22,
                                height: 1.1,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'Un veterinario puede revisar el caso de tu mascota por telemedicina. Buscaremos un doctor disponible ahora. Si no hay doctores libres en este momento, podras reservar el horario mas cercano.',
                        style: TextStyle(
                          color: PetScaniaColors.ink.withValues(alpha: 0.78),
                          fontSize: 14,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: PetScaniaColors.cloud,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Text(
                          'Precio promocional por tiempo limitado.',
                          style: TextStyle(
                            color: PetScaniaColors.royalBlue,
                            fontWeight: FontWeight.w900,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Monto promocional actual: S/ ${_telemedBasePrice.toStringAsFixed(0)}',
                        style: TextStyle(
                          color: PetScaniaColors.ink.withValues(alpha: 0.58),
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (checked) ...[
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: available
                                ? const Color(0xFFEAF9F1)
                                : const Color(0xFFFFF3E9),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: available
                                  ? const Color(
                                      0xFF16A34A,
                                    ).withValues(alpha: 0.25)
                                  : const Color(
                                      0xFFF59E0B,
                                    ).withValues(alpha: 0.35),
                            ),
                          ),
                          child: Text(
                            available
                                ? 'Encontramos un veterinario disponible para revisar el caso de tu mascota ahora.'
                                : 'En este momento no hay veterinarios libres, pero puedes reservar el horario mas cercano.',
                            style: TextStyle(
                              color: available
                                  ? const Color(0xFF166534)
                                  : const Color(0xFF92400E),
                              fontWeight: FontWeight.w700,
                              height: 1.35,
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                      if (!checked)
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: PetScaniaDecor.primaryGradient,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: ElevatedButton(
                              onPressed: checking
                                  ? null
                                  : () async {
                                      setDialogState(() => checking = true);
                                      final availableNow =
                                          await _hasAvailableVeterinariansNow();
                                      if (!mounted) {
                                        return;
                                      }
                                      setDialogState(() {
                                        checking = false;
                                        isAvailableNow = availableNow;
                                      });
                                    },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: checking
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2.6,
                                      ),
                                    )
                                  : const Text(
                                      'Buscar veterinario ahora',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                            ),
                          ),
                        ),
                      if (checked)
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: PetScaniaDecor.primaryGradient,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: ElevatedButton(
                              onPressed: () async {
                                Navigator.pop(dialogContext);
                                await _openTelemedicineFlow();
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: Text(
                                available
                                    ? 'Iniciar teleconsulta'
                                    : 'Reservar cita',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ),
                        ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: OutlinedButton(
                          onPressed: () async {
                            Navigator.pop(dialogContext);
                            await _openTelemedicineFlow();
                          },
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: PetScaniaColors.line),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: const Text(
                            'Reservar horario cercano',
                            style: TextStyle(
                              color: PetScaniaColors.royalBlue,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: TextButton(
                          onPressed: () => Navigator.pop(dialogContext),
                          child: const Text(
                            'Continuar sin atencion',
                            style: TextStyle(
                              color: PetScaniaColors.ink,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _showError(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PetScaniaColors.royalBlue,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          'VetIA Asistente',
          style: TextStyle(fontWeight: FontWeight.w900, color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: PetScaniaBackground(
        child: SafeArea(
          child: Column(
            children: [
              _buildTopIntro(),
              Expanded(
                child: _messages.isEmpty
                    ? _buildWelcomeState()
                    : ListView(
                        controller: _scrollController,
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 20,
                        ),
                        children: [..._messages.map(_buildModernBubble)],
                      ),
              ),
              if (_isLoading || _isProcessingAudio) _buildStatusIndicator(),
              _buildInputArea(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopIntro() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
      ),
      child: const Row(
        children: [
          PetScaniaBrandMark(size: 54),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'VetIA, tu apoyo petfriendly',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Haz preguntas sobre sintomas, cuidados y bienestar diario.',
                  style: TextStyle(
                    color: Colors.white70,
                    height: 1.35,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const PetScaniaBrandMark(size: 112),
            const SizedBox(height: 24),
            const PetScaniaWordmark(fontSize: 34),
            const SizedBox(height: 12),
            Text(
              'Tu companero digital para dudas de salud, cuidados y bienestar animal.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.82),
                fontSize: 15,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 24),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              alignment: WrapAlignment.center,
              children: [
                _buildPromptChip('Mi perro no quiere comer'),
                _buildPromptChip('Que hago si se rasca mucho'),
                _buildPromptChip('Consejos para el bano'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPromptChip(String label) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: () => _sendMessage(textOverride: label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildModernBubble(Map<String, String> msg) {
    final isUser = msg['role'] == 'user';
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Row(
        mainAxisAlignment: isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser)
            Padding(
              padding: const EdgeInsets.only(right: 8, top: 4),
              child: Container(
                width: 35,
                height: 35,
                decoration: const BoxDecoration(
                  color: Colors.white10,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.pets_rounded,
                  size: 18,
                  color: PetScaniaColors.cloud,
                ),
              ),
            ),
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              decoration: BoxDecoration(
                gradient: isUser ? PetScaniaDecor.primaryGradient : null,
                color: isUser ? null : Colors.white.withValues(alpha: 0.98),
                borderRadius: BorderRadius.only(
                  topLeft: isUser
                      ? const Radius.circular(20)
                      : const Radius.circular(2),
                  topRight: isUser
                      ? const Radius.circular(2)
                      : const Radius.circular(20),
                  bottomLeft: const Radius.circular(20),
                  bottomRight: const Radius.circular(20),
                ),
              ),
              child: Text(
                msg['content'] ?? '',
                style: TextStyle(
                  color: isUser ? Colors.white : PetScaniaColors.ink,
                  fontSize: 15,
                  height: 1.4,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(999),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 15,
              height: 15,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: PetScaniaColors.cloud,
              ),
            ),
            SizedBox(width: 12),
            Text(
              'Pensando...',
              style: TextStyle(
                color: PetScaniaColors.cloud,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      margin: const EdgeInsets.only(left: 15, right: 15, bottom: 25, top: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: _toggleRecording,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: kIsWeb
                    ? Colors.white.withValues(alpha: 0.03)
                    : (_isRecording
                          ? Colors.redAccent
                          : Colors.white.withValues(alpha: 0.05)),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _isRecording ? Icons.stop_rounded : Icons.mic_none_rounded,
                color: kIsWeb ? Colors.white24 : PetScaniaColors.white,
                size: 24,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _controller,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: 'Escribe aqui...',
                hintStyle: TextStyle(color: Colors.white54),
                border: InputBorder.none,
              ),
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          Container(
            decoration: const BoxDecoration(
              gradient: PetScaniaDecor.primaryGradient,
              shape: BoxShape.circle,
            ),
            child: GestureDetector(
              onTap: () => _sendMessage(),
              child: const Padding(
                padding: EdgeInsets.all(12),
                child: Icon(Icons.send_rounded, color: Colors.white, size: 20),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TriageParsedResponse {
  final String message;
  final bool completed;

  _TriageParsedResponse({required this.message, required this.completed});
}
