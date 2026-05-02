import 'dart:typed_data';
import 'dart:convert';
import 'package:http/http.dart' as http;

class CustomAIService {
  static const String _apiUrl = 'https://dr-ia-backend.onrender.com/predict';

  // ⚠️ IMPORTANTE:
  // No es recomendable poner tu API Key en Flutter.
  // Lo ideal es mover esta validación a tu backend.
  static const String _openAiKey = String.fromEnvironment(
    'OPENAI_API_KEY',
    defaultValue: '',
  );

  // 🛡️ PASO 1: FILTRO DE IMAGEN CON OPENAI
  Future<bool> _verifyImageWithOpenAI(Uint8List imageBytes) async {
    try {
      if (_openAiKey.isEmpty) {
        return true;
      }
      print("🛡️ Iniciando filtro de imagen con OpenAI...");

      final String base64Image = base64Encode(imageBytes);

      final response = await http.post(
        Uri.parse('https://api.openai.com/v1/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_openAiKey',
        },
        body: jsonEncode({
          "model": "gpt-4o-mini",
          "messages": [
            {
              "role": "user",
              "content": [
                {
                  "type": "text",
                  "text":
                      "Analiza esta imagen. Debes responder únicamente con SI o NO. "
                      "Responde SI solo si la imagen muestra claramente un perro, un gato "
                      "o una parte real y visible de su cuerpo, como piel, oreja, pata, hocico, ojo, cola o herida. "
                      "Responde NO si la imagen muestra una persona, mesa, silla, carro, paisaje, comida, ropa, juguete, "
                      "objeto, dibujo, pantalla, documento, piso, pared, planta o cualquier cosa que no sea claramente un perro o gato. "
                      "No expliques nada. Solo responde SI o NO.",
                },
                {
                  "type": "image_url",
                  "image_url": {"url": "data:image/jpeg;base64,$base64Image"},
                },
              ],
            },
          ],
          "max_tokens": 5,
          "temperature": 0.0,
        }),
      );

      print("📩 Código respuesta OpenAI: ${response.statusCode}");

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));

        final String respuestaIA = data['choices'][0]['message']['content']
            .toString()
            .trim()
            .toUpperCase();

        print("🤖 OpenAI respondió: $respuestaIA");

        if (respuestaIA == "SI") {
          return true;
        }

        if (respuestaIA == "NO") {
          return false;
        }

        // Si responde algo extraño, bloqueamos por seguridad
        print("⚠️ Respuesta inesperada de OpenAI: $respuestaIA");
        return false;
      }

      // Si OpenAI responde error, bloqueamos
      print("❌ Error OpenAI statusCode: ${response.statusCode}");
      print("❌ Body OpenAI: ${response.body}");
      return false;
    } catch (e) {
      // Si ocurre cualquier error, bloqueamos
      print("⚠️ Error en filtro OpenAI: $e");
      return false;
    }
  }

  // 🧬 PASO 2: ANÁLISIS PRINCIPAL
  Future<Map<String, dynamic>> analyzeImage(
    Uint8List imageBytes,
    String symptoms,
  ) async {
    try {
      // 1. Validar que la imagen sea de perro/gato
      final bool isPet = await _verifyImageWithOpenAI(imageBytes);

      if (!isPet) {
        print("🛑 Filtro activado: La imagen no es de una mascota.");

        return {
          'success': false,
          'error':
              "La imagen no parece ser de una mascota. Por favor, sube una foto clara de tu perro o gato, enfocada en la zona afectada.",
        };
      }

      // 2. Si sí es mascota, enviar al backend de Render
      final request = http.MultipartRequest('POST', Uri.parse(_apiUrl));

      final multipartFile = http.MultipartFile.fromBytes(
        'file',
        imageBytes,
        filename: 'pet_scan.jpg',
      );

      request.files.add(multipartFile);

      request.fields['sintomas'] = symptoms.trim().isEmpty
          ? "Análisis visual general"
          : symptoms.trim();

      print("📡 Enviando imagen al modelo IA en Render: $_apiUrl");

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      print("📩 Código respuesta Render: ${response.statusCode}");
      print("📦 Body Render: ${response.body}");

      if (response.statusCode == 200) {
        try {
          final data = jsonDecode(response.body);

          print("========================================");
          print("✅ JSON COMPLETO DE RENDER: $data");
          print("========================================");

          // EXTRAER DIAGNÓSTICO
          String diagnosis = "";

          if (data['diagnostico'] != null) {
            diagnosis = data['diagnostico'].toString();
          } else if (data['diagnosis'] != null) {
            diagnosis = data['diagnosis'].toString();
          } else if (data['prediccion'] != null) {
            diagnosis = data['prediccion'].toString();
          } else if (data['enfermedad'] != null) {
            diagnosis = data['enfermedad'].toString();
          } else if (data['class'] != null) {
            diagnosis = data['class'].toString();
          } else if (data['resultado'] != null) {
            diagnosis = data['resultado'].toString();
          } else {
            diagnosis = "Resultado API: ${response.body}";
          }

          // EXTRAER CONFIANZA
          double confidence = 0.85;

          final scoreValue =
              data['probabilidad'] ??
              data['confianza'] ??
              data['score'] ??
              data['confidence'] ??
              data['certeza'] ??
              data['porcentaje'] ??
              data['accuracy'];

          if (scoreValue != null) {
            final cleanScore = scoreValue
                .toString()
                .replaceAll('%', '')
                .replaceAll(',', '.')
                .trim();

            confidence = double.tryParse(cleanScore) ?? 0.85;
          }

          if (confidence > 1.0) {
            confidence = confidence / 100.0;
          }

          return {
            'success': true,
            'diagnosis': diagnosis,
            'confidence': confidence,
          };
        } catch (e) {
          print("⚠️ Error parseando JSON de Render: $e");

          return {
            'success': true,
            'diagnosis': response.body,
            'confidence': 0.90,
          };
        }
      }

      return {
        'success': false,
        'error':
            "Error del servidor (${response.statusCode}). Intenta nuevamente.",
      };
    } catch (e) {
      print("⚠️ Error general en analyzeImage: $e");

      return {
        'success': false,
        'error':
            "Error de conexión con la IA. Verifica tu red e intenta nuevamente.",
      };
    }
  }
}
