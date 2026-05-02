import 'dart:typed_data';

import 'package:google_generative_ai/google_generative_ai.dart';

class GeminiService {
  static const String _apiKey = String.fromEnvironment(
    'GEMINI_API_KEY',
    defaultValue: '',
  );
  static const String _defaultModel = 'gemini-2.0-flash';

  late final GenerativeModel _textModel;
  late final GenerativeModel _visionModel;

  GeminiService() {
    _textModel = GenerativeModel(model: _defaultModel, apiKey: _apiKey);
    _visionModel = GenerativeModel(model: _defaultModel, apiKey: _apiKey);
  }

  Future<String> askVetIA(String question) async {
    try {
      if (_apiKey.isEmpty) {
        return 'Falta configurar GEMINI_API_KEY.';
      }
      final content = [Content.text(question)];
      final response = await _textModel.generateContent(content);
      return response.text ?? 'Lo siento, no pude procesar tu consulta.';
    } catch (e) {
      return 'Error de conexion con Gemini: $e';
    }
  }

  Future<String> analyzePetPhoto(List<int> imageBytes) async {
    try {
      if (_apiKey.isEmpty) {
        return 'Falta configurar GEMINI_API_KEY.';
      }
      final content = [
        Content.multi([
          TextPart(
            'Analiza esta mascota y describe su raza, color y caracteristicas.',
          ),
          DataPart('image/jpeg', Uint8List.fromList(imageBytes)),
        ]),
      ];
      final response = await _visionModel.generateContent(content);
      return response.text ?? 'No pude ver bien a la mascota.';
    } catch (e) {
      return 'Error analizando imagen: $e';
    }
  }
}
