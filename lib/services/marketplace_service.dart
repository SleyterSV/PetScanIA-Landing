import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';

class MarketplaceService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // --- SECCIÓN MARKETPLACE EXISTENTE ---

  Future<List<Map<String, dynamic>>> getProducts() async {
    try {
      final response = await _supabase
          .from('products')
          .select('*, profiles(full_name, avatar_url)')
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print("🔴 Error obteniendo productos: $e");
      return [];
    }
  }

  Future<void> addProduct(String name, double price, String description, int stock, String category, Uint8List? imageBytes) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception("Inicia sesión para publicar.");

      String? imageUrl;
      if (imageBytes != null) {
        final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
        final path = 'products/$fileName';
        await _supabase.storage.from('marketplace').uploadBinary(path, imageBytes);
        imageUrl = _supabase.storage.from('marketplace').getPublicUrl(path);
      }

      await _supabase.from('products').insert({
        'name': name,
        'price': price,
        'description': description,
        'category': category,
        'image_url': imageUrl ?? "https://cdn-icons-png.flaticon.com/512/3047/3047928.png", 
        'seller_id': user.id, 
        'stock': stock,
      });
    } catch (e) {
      print("🔴 Error publicando: $e");
      rethrow;
    }
  }

  // --- 🔥 NUEVA SECCIÓN: GESTIÓN DE CARRITO (PERSISTENTE) ---

  // Obtener items del carrito del usuario actual
  Future<List<Map<String, dynamic>>> getCartItems() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return [];

    final response = await _supabase
        .from('cart')
        .select('*, products(*)')
        .eq('user_id', user.id);
    
    return List<Map<String, dynamic>>.from(response);
  }

  // Añadir al carrito o aumentar cantidad
  Future<void> addToCart(String productId) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    // Verificar si ya existe en el carrito
    final existing = await _supabase
        .from('cart')
        .select()
        .eq('user_id', user.id)
        .eq('product_id', productId)
        .maybeSingle();

    if (existing != null) {
      await _supabase.from('cart').update({
        'quantity': existing['quantity'] + 1
      }).eq('id', existing['id']);
    } else {
      await _supabase.from('cart').insert({
        'user_id': user.id,
        'product_id': productId,
        'quantity': 1
      });
    }
  }

  // Actualizar cantidad (para los botones + y -)
  Future<void> updateCartQuantity(String cartId, int newQuantity) async {
    if (newQuantity <= 0) {
      await _supabase.from('cart').delete().eq('id', cartId);
    } else {
      await _supabase.from('cart').update({'quantity': newQuantity}).eq('id', cartId);
    }
  }

  // --- 💳 PROCESO DE PAGO (CHECKOUT) ---
  Future<void> processCheckout(List<Map<String, dynamic>> cartItems) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      // 1. Validar Stock y descontar (Transacción simple)
      for (var item in cartItems) {
        final product = item['products'];
        final int currentStock = product['stock'];
        final int quantityBought = item['quantity'];

        if (currentStock < quantityBought) {
          throw Exception("Stock insuficiente para ${product['name']}");
        }

        // Restar stock en la tabla products
        await _supabase.from('products').update({
          'stock': currentStock - quantityBought
        }).eq('id', product['id']);
      }

      // 2. Limpiar el carrito del usuario
      await _supabase.from('cart').delete().eq('user_id', user.id);

      print("🟢 Compra procesada con éxito");
    } catch (e) {
      print("🔴 Error en Checkout: $e");
      rethrow;
    }
  }
}