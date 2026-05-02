import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';

class SupabaseService {
  // Instancia única (Singleton) para usar en toda la app
  final SupabaseClient _client = Supabase.instance.client;

  // 1. OBTENER USUARIO ACTUAL
  User? get currentUser => _client.auth.currentUser;

  // 2. GUARDAR FOTO EN "MOMENTOS ESPECIALES"
  Future<String?> uploadPetPhoto(File photoFile, String petName) async {
    try {
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_$petName.jpg';
      await _client.storage.from('photos').upload(fileName, photoFile);
      final imageUrl = _client.storage.from('photos').getPublicUrl(fileName);
      return imageUrl;
    } catch (e) {
      print("Error subiendo foto: $e");
      return null;
    }
  }

  // 3. GUARDAR CITA EN LA AGENDA PERSONAL DEL USUARIO
  Future<void> addAppointment(String title, DateTime date) async {
    await _client.from('agenda').insert({
      'user_id': currentUser?.id,
      'title': title,
      'date': date.toIso8601String(),
    });
  }

  // 4. LEER RECORDATORIOS (Para el Home)
  Stream<List<Map<String, dynamic>>> getReminders() {
    return _client
        .from('agenda')
        .stream(primaryKey: ['id'])
        .order('date', ascending: true);
  }

  // ============================================================
  // NUEVAS FUNCIONES PARA CONEXIÓN CON CLÍNICAS Y MAPA (PASO 1)
  // ============================================================

  // 5. OBTENER TODAS LAS CLÍNICAS (Para el Mapa)
  // Filtramos los datos necesarios para saber quién es aliado y su ubicación
  Future<List<Map<String, dynamic>>> fetchClinics() async {
    try {
      final response = await _client
          .from('clinics')
          .select('id, name, address, latitude, longitude, terms_accepted_at, logo_url, description, rating, phone');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print("Error obteniendo clínicas: $e");
      return [];
    }
  }

  // 6. OBTENER PROMOCIONES ACTIVAS DE UNA CLÍNICA
  // Esto se mostrará cuando el usuario abra el detalle de una clínica aliada
  Future<List<Map<String, dynamic>>> getClinicPromotions(String clinicId) async {
    try {
      final response = await _client
          .from('flash_deals')
          .select('*')
          .eq('clinic_id', clinicId)
          .eq('active', true);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print("Error obteniendo promociones: $e");
      return [];
    }
  }

  // 7. CREAR RESERVA REAL (Conecta con el Panel del Veterinario)
  // Esta función inserta en 'appointments', que es la tabla que arreglamos ayer
  Future<void> bookClinicAppointment({
    required String clinicId,
    required String petName,
    required DateTime date,
    required String time,
    required String reason,
  }) async {
    try {
      await _client.from('appointments').insert({
        'clinic_id': clinicId,
        'user_id': currentUser?.id,
        'pet_name_manual': petName, // Usamos manual si no tenemos el pet_id a la mano
        'appointment_date': date.toIso8601String(),
        'appointment_time': time,
        'reason': reason,
        'status': 'pendiente', // Por defecto para que el doctor la apruebe
      });
    } catch (e) {
      print("Error al reservar cita: $e");
      rethrow;
    }
  }
}