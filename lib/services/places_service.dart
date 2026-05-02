import 'dart:convert';
import 'dart:math'
    show asin, cos, sqrt, pow, sin; // Requerido para calcular distancias
import 'package:http/http.dart' as http;

class GooglePlacesService {
  // 🔑 Llave de API proporcionada
  static const String _apiKey = String.fromEnvironment(
    'GOOGLE_PLACES_API_KEY',
    defaultValue: '',
  );

  /// Busca veterinarias cercanas usando Google Places API
  /// Incluye geolocalización sutil para priorizar resultados cercanos al usuario
  static Future<List<dynamic>> searchVeterinaries(
    String userQuery,
    double lat,
    double lng,
  ) async {
    if (_apiKey.isEmpty) {
      return [];
    }

    // Definimos el término de búsqueda: Priorizamos lo que el usuario escribe
    String finalQuery = userQuery.trim().isEmpty
        ? "clinica veterinaria"
        : "$userQuery veterinaria";

    // Armamos la URL oficial de Google
    // location + radius ayudan a que Google priorice lo que está cerca de tu GPS
    final String googleUrl =
        'https://maps.googleapis.com/maps/api/place/textsearch/json'
        '?query=${Uri.encodeComponent(finalQuery)}'
        '&location=$lat,$lng'
        '&radius=5000' // Radio de 5km de prioridad
        '&key=$_apiKey';

    // Mantener el túnel CORS para desarrollo en Flutter Web
    final String url =
        'https://corsproxy.io/?${Uri.encodeComponent(googleUrl)}';

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['status'] == 'OK' || data['status'] == 'ZERO_RESULTS') {
          print(
            "✅ Google API: ${data['results'].length} resultados encontrados.",
          );
          return data['results'] ?? [];
        } else {
          print("⚠️ Google API Error Status: ${data['status']}");
          if (data['error_message'] != null)
            print("Mensaje: ${data['error_message']}");
        }
      } else {
        print("❌ Error de red: Código ${response.statusCode}");
      }
    } catch (e) {
      print("❌ Excepción en GooglePlacesService: $e");
    }
    return [];
  }

  /// 📐 FUNCIÓN PROFESIONAL: Calcular distancia en Kilómetros (Fórmula Haversine)
  /// Esto te permitirá mostrar en la App: "A 1.2 km de ti"
  static double calculateDistance(
    double startLat,
    double startLng,
    double endLat,
    double endLng,
  ) {
    const double p = 0.017453292519943295; // Pi / 180
    final double a =
        0.5 -
        cos((endLat - startLat) * p) / 2 +
        cos(startLat * p) *
            cos(endLat * p) *
            (1 - cos((endLng - startLng) * p)) /
            2;

    // 12742 es el diámetro de la Tierra en km
    return 12742 * asin(sqrt(a));
  }

  /// Formatea la distancia para mostrarla de forma elegante en la UI
  static String formatDistance(double kms) {
    if (kms < 1) {
      return "${(kms * 1000).toInt()} m"; // Muestra metros si es menos de 1km
    } else {
      return "${kms.toStringAsFixed(1)} km"; // Muestra "1.5 km"
    }
  }
}
