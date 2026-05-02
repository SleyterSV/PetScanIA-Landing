import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ServicesService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // ==========================================
  // SECCIÓN: PERFIL Y USUARIO
  // ==========================================

  /// Obtiene los datos del perfil (nombre, email, teléfono, avatar_url)
  Future<Map<String, dynamic>?> getFullProfileData() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return null;
      return await _supabase.from('profiles').select().eq('id', userId).maybeSingle();
    } catch (e) {
      debugPrint("Error en getFullProfileData: $e");
      return null;
    }
  }

  /// Actualiza el número de teléfono del usuario
  Future<void> updateProfilePhone(String phone) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;
      await _supabase.from('profiles').update({'phone': phone}).eq('id', userId);
    } catch (e) {
      debugPrint("Error en updateProfilePhone: $e");
      rethrow;
    }
  }

  /// 🔥 NUEVO: Actualiza la foto de perfil en el bucket 'avatars' y en la tabla
  Future<void> updateProfilePhoto(Uint8List imageBytes) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      final String fileName = 'avatar_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final String path = '$userId/$fileName';

      // Sube la imagen al bucket
      await _supabase.storage.from('avatars').uploadBinary(path, imageBytes);
      final String imageUrl = _supabase.storage.from('avatars').getPublicUrl(path);

      // Actualiza la tabla profiles
      await _supabase.from('profiles').update({'avatar_url': imageUrl}).eq('id', userId);
    } catch (e) {
      debugPrint("Error en updateProfilePhoto: $e");
      rethrow;
    }
  }

  // ==========================================
  // SECCIÓN: MARKETPLACE (SERVICIOS GENERALES)
  // ==========================================

  /// Trae todos los servicios para la pantalla principal
  Future<List<Map<String, dynamic>>> getServices() async {
    try {
      final List<dynamic> response = await _supabase
          .from('services')
          .select('*, profiles(full_name, avatar_url)')
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint("Error en getServices: $e");
      return [];
    }
  }

  // ==========================================
  // SECCIÓN: NEGOCIO (GESTIÓN DEL VENDEDOR)
  // ==========================================

  /// Trae estatus de verificación + DNI + Datos de Perfil
  Future<Map<String, dynamic>?> getProviderVerificationStatus() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return null;

      final response = await _supabase
          .from('service_providers')
          .select('*, profiles(*)')
          .eq('id', userId)
          .maybeSingle();
      
      return response;
    } catch (e) {
      debugPrint("Error en getProviderVerificationStatus: $e");
      return null;
    }
  }

  /// 🔥 ACTUALIZADO: Registra un nuevo servicio con soporte para IMAGEN
  Future<void> addService({
    required String name,
    required double price,
    required String description,
    required String category,
    String? discountLabel,
    Uint8List? imageBytes, // Parámetro añadido
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      String? finalImageUrl;

      // Si el usuario subió una imagen, la guardamos en el storage
      if (imageBytes != null) {
        final String fileName = 'service_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final String path = '$userId/$fileName';
        
        await _supabase.storage.from('services_images').uploadBinary(path, imageBytes);
        finalImageUrl = _supabase.storage.from('services_images').getPublicUrl(path);
      }

      await _supabase.from('services').insert({
        'provider_id': userId,
        'name': name,
        'price': price,
        'description': description,
        'category': category,
        'discount_label': discountLabel,
        'image_url': finalImageUrl, // Si es null, Supabase lo guarda como null
      });
    } catch (e) {
      debugPrint("Error en addService: $e");
      rethrow;
    }
  }

  /// Trae solo los servicios que yo ofrezco
  Future<List<Map<String, dynamic>>> getMyOfferedServices() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return [];
      final response = await _supabase
          .from('services')
          .select('*')
          .eq('provider_id', userId)
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      return [];
    }
  }

  /// Elimina un servicio publicado
  Future<void> deleteService(String serviceId) async {
    try {
      await _supabase.from('services').delete().eq('id', serviceId);
    } catch (e) {
      debugPrint("Error en deleteService: $e");
      rethrow;
    }
  }

  /// Calcula las ganancias acumuladas por servicios completados
  Future<double> getProviderTotalEarnings() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return 0.0;
      final response = await _supabase
          .from('service_bookings')
          .select('price_at_booking')
          .eq('provider_id', userId)
          .eq('status', 'completed');
      
      double total = 0.0;
      for (var item in (response as List)) {
        total += (item['price_at_booking'] as num).toDouble();
      }
      return total;
    } catch (e) {
      return 0.0;
    }
  }

  // ==========================================
  // SECCIÓN: IA Y VERIFICACIÓN DE DNI
  // ==========================================

  /// Sube fotos al Storage y activa la IA de Supabase para validar el DNI
  Future<void> submitVerificationRequest({
    required String dniNumber,
    required Uint8List dniFrontBytes,
    required Uint8List dniBackBytes,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      final String time = DateTime.now().millisecondsSinceEpoch.toString();
      final String frontPath = '$userId/f_$time.jpg';
      final String backPath = '$userId/b_$time.jpg';

      await _supabase.storage.from('verifications').uploadBinary(frontPath, dniFrontBytes);
      await _supabase.storage.from('verifications').uploadBinary(backPath, dniBackBytes);

      final fUrl = _supabase.storage.from('verifications').getPublicUrl(frontPath);
      final bUrl = _supabase.storage.from('verifications').getPublicUrl(backPath);

      await _supabase.from('service_providers').upsert({
        'id': userId,
        'dni_number': dniNumber,
        'dni_front_url': fUrl,
        'dni_back_url': bUrl,
        'verification_status': 'pending',
        'is_verified': false,
      });

      await _supabase.functions.invoke('verify-dni-ai', body: {
        'user_id': userId,
        'dni_number': dniNumber,
        'front_url': fUrl,
        'back_url': bUrl,
      });
    } catch (e) {
      debugPrint("Error en submitVerificationRequest: $e");
      rethrow;
    }
  }

  // ==========================================
  // SECCIÓN: CONSUMO (CLIENTE)
  // ==========================================

  /// Obtiene el historial de servicios contratados por el usuario
  Future<List<Map<String, dynamic>>> getMyConsumptionHistory() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return [];
      final response = await _supabase
          .from('service_bookings')
          .select('*, services(*), service_providers(profiles(full_name))')
          .eq('customer_id', userId)
          .order('booking_date', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      return [];
    }
  }
}