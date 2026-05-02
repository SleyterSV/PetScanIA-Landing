import 'package:supabase_flutter/supabase_flutter.dart';

class UserService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // ==========================================
  // SECCIÓN 1: PERFIL Y MASCOTAS
  // ==========================================

  Future<String> getUserName() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return "Invitado";
      
      final data = await _supabase
          .from('profiles')
          .select('full_name')
          .eq('id', userId)
          .single();
          
      return data['full_name'] ?? "Usuario";
    } catch (e) {
      return "Amante de mascotas";
    }
  }

  Future<Map<String, dynamic>?> getMainPet() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return null;
      
      return await _supabase
          .from('pets')
          .select()
          .eq('owner_id', userId)
          .limit(1)
          .maybeSingle();
    } catch (e) {
      return null;
    }
  }

  Future<void> registerPet(String name, String breed, String age) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception("Usuario no autenticado");
      
      await _supabase.from('pets').insert({
        'owner_id': userId, 
        'name': name, 
        'breed': breed, 
        'age': age,
        'photo_url': 'https://cdn-icons-png.flaticon.com/512/616/616408.png',
      });
    } catch (e) {
      rethrow;
    }
  }

  // ==========================================
  // SECCIÓN 2: LÍMITES Y BORRADO DE FOTOS
  // ==========================================

  Future<int> getSpecialMomentsCount() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return 0;

      final List<dynamic> response = await _supabase
          .from('memories')
          .select('id')
          .eq('user_id', userId);
      
      return response.length;
    } catch (e) {
      print("🔴 Error contando momentos: $e");
      return 0; 
    }
  }

  // 🔥 FUNCIÓN PROFESIONAL: Borrado blindado contra fallos de Supabase
  Future<void> deleteSpecialMoment(String momentId, String? imagePathInStorage) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception("No autorizado");

      // 1. PRIMERO: Borramos de la Base de Datos (Esto quita la foto de la pantalla)
      final response = await _supabase.from('memories')
          .delete()
          .eq('id', momentId)
          .select(); // Exigimos respuesta para evitar borrados fantasmas

      if (response.isEmpty) {
        throw Exception("Supabase bloqueó el borrado. Verifica tu política RLS (DELETE) en 'memories'.");
      }

      // 2. SEGUNDO: Intentamos borrar el archivo del Storage de forma independiente
      if (imagePathInStorage != null && imagePathInStorage.isNotEmpty) {
        try {
          await _supabase.storage.from('pet-photos').remove([imagePathInStorage]);
        } catch (storageError) {
          print("⚠️ Aviso: El storage bloqueó borrar el archivo, pero la foto ya se quitó del perfil.");
        }
      }

    } catch (e) {
      print("🔴 Error borrando foto: $e");
      rethrow;
    }
  }

  // ==========================================
  // SECCIÓN 3: VALIDACIÓN DE MERCADO
  // ==========================================

  Future<void> registerPremiumInterest() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;
      
      await _supabase.from('market_validation').insert({
        'user_id': userId,
        'feature': 'unlimited_moments_premium',
      });
    } catch (e) {
      print("Error registrando interés: $e");
    }
  }

  Future<int> getTotalPremiumInterestCount() async {
    try {
      final List<dynamic> response = await _supabase
          .from('market_validation')
          .select('id')
          .eq('feature', 'unlimited_moments_premium');
          
      return response.length; 
    } catch (e) {
      print("🔴 Error contando interesados: $e");
      return 0;
    }
  }

  // ==========================================
  // SECCIÓN 4: AGENDA Y CITAS
  // ==========================================

  Future<Map<String, dynamic>?> getNextUpcomingAppointment() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return null;

      final now = DateTime.now().toUtc().toIso8601String();

      final data = await _supabase
          .from('appointments')
          .select()
          .eq('user_id', userId)
          .inFilter('status', ['pending', 'confirmed']) 
          .gte('appointment_date', now) 
          .order('appointment_date', ascending: true) 
          .limit(1)
          .maybeSingle();

      return data;
    } catch (e) {
      print("🔴 Error obteniendo próxima cita: $e");
      return null;
    }
  }
}