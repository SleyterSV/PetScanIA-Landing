import 'package:flutter/material.dart';
import 'package:petscania/theme/petscania_brand.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;

  List<Map<String, dynamic>> _cartItems = [];
  List<Map<String, dynamic>> _orderHistory = [];
  bool _isLoading = true;
  bool _isProcessingPay = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        return;
      }

      final cartResponse = await _supabase
          .from('cart')
          .select(
            'id, quantity, product_id, products(id, name, price, image_url, stock, seller_id)',
          )
          .eq('user_id', user.id);

      final historyResponse = await _supabase
          .from('orders')
          .select(
            'id, quantity, total_price, created_at, products(name, image_url), seller:seller_id(full_name, phone)',
          )
          .eq('buyer_id', user.id)
          .order('created_at', ascending: false);

      if (mounted) {
        setState(() {
          _cartItems = List<Map<String, dynamic>>.from(cartResponse);
          _orderHistory = List<Map<String, dynamic>>.from(historyResponse);
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error cargando datos: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleCheckout() async {
    if (_cartItems.isEmpty) {
      return;
    }
    setState(() => _isProcessingPay = true);

    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('Sesion invalida');
      }

      for (final item in _cartItems) {
        final productInfo = item['products'];
        final buyQty = item['quantity'] as int;
        final currentStock = productInfo['stock'] ?? 0;

        if (buyQty > currentStock) {
          throw Exception('Stock insuficiente para ${productInfo['name']}');
        }

        await _supabase
            .from('products')
            .update({'stock': currentStock - buyQty})
            .eq('id', productInfo['id']);

        await _supabase.from('orders').insert({
          'buyer_id': user.id,
          'seller_id': productInfo['seller_id'],
          'product_id': productInfo['id'],
          'quantity': buyQty,
          'total_price': productInfo['price'] * buyQty,
        });
      }

      await _supabase.from('cart').delete().eq('user_id', user.id);
      await _loadData();

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Compra registrada. Revisa tu historial abajo.'),
        ),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('No pude procesar la compra: $e')));
    } finally {
      if (mounted) {
        setState(() => _isProcessingPay = false);
      }
    }
  }

  void _openWhatsAppWarning(Map<String, dynamic> order) {
    final sellerInfo = order['seller'];
    final productInfo = order['products'];
    final phone = sellerInfo?['phone']?.toString();

    if (phone == null || phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El vendedor aun no registro su numero.')),
      );
      return;
    }

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          title: const Row(
            children: [
              Icon(
                Icons.info_outline_rounded,
                color: PetScaniaColors.royalBlue,
              ),
              SizedBox(width: 10),
              Text(
                'Antes de abrir WhatsApp',
                style: TextStyle(
                  color: PetScaniaColors.ink,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          content: const Text(
            'Seras redirigido al chat con el vendedor. Mantengan la coordinacion clara y evita pagos por fuera sin validar los detalles de entrega.',
            style: TextStyle(color: PetScaniaColors.ink, height: 1.5),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text(
                'Cancelar',
                style: TextStyle(
                  color: PetScaniaColors.ink,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: PetScaniaDecor.primaryGradient,
                borderRadius: BorderRadius.circular(16),
              ),
              child: ElevatedButton(
                onPressed: () async {
                  Navigator.pop(dialogContext);
                  final cleanPhone = phone.replaceAll(RegExp(r'\D'), '');
                  final message =
                      'Hola ${sellerInfo['full_name']}, acabo de comprar ${order['quantity']}x ${productInfo['name']} por S/ ${order['total_price']} en PetScanIA. Quisiera coordinar la entrega.';
                  final url = Uri.parse(
                    'https://wa.me/51$cleanPhone?text=${Uri.encodeComponent(message)}',
                  );

                  if (await canLaunchUrl(url)) {
                    await launchUrl(url, mode: LaunchMode.externalApplication);
                  } else if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('No se pudo abrir WhatsApp.'),
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  'Abrir chat',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  double get _totalPrice {
    var total = 0.0;
    for (final item in _cartItems) {
      if (item['products'] != null) {
        total += item['products']['price'] * item['quantity'];
      }
    }
    return total;
  }

  Future<void> _updateQuantity(
    String cartId,
    int newQuantity,
    int maxStock,
  ) async {
    if (newQuantity < 1) {
      await _supabase.from('cart').delete().eq('id', cartId);
    } else if (newQuantity <= maxStock) {
      await _supabase
          .from('cart')
          .update({'quantity': newQuantity})
          .eq('id', cartId);
    }
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PetScaniaColors.mist,
      body: Stack(
        children: [
          Container(
            height: 260,
            decoration: const BoxDecoration(
              gradient: PetScaniaDecor.primaryGradient,
            ),
          ),
          Positioned(
            top: 40,
            right: -30,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
            ),
          ),
          SafeArea(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: PetScaniaColors.royalBlue,
                    ),
                  )
                : CustomScrollView(
                    physics: const BouncingScrollPhysics(),
                    slivers: [
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
                          child: Row(
                            children: [
                              _buildBackButton(),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Carrito y compras',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 24,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      'Una experiencia de compra mas clara y ordenada.',
                                      style: TextStyle(
                                        color: Color(0xD8FFFFFF),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const PetScaniaBrandMark(size: 46),
                            ],
                          ),
                        ),
                      ),
                      SliverToBoxAdapter(
                        child: Container(
                          decoration: const BoxDecoration(
                            color: PetScaniaColors.mist,
                            borderRadius: BorderRadius.vertical(
                              top: Radius.circular(34),
                            ),
                          ),
                          padding: const EdgeInsets.fromLTRB(18, 20, 18, 8),
                          child: const Text(
                            'Carrito actual',
                            style: TextStyle(
                              color: PetScaniaColors.ink,
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ),
                      if (_cartItems.isEmpty)
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(18, 8, 18, 18),
                            child: _buildEmptySection(
                              icon: Icons.shopping_cart_outlined,
                              title: 'Tu carrito esta vacio',
                              subtitle:
                                  'Cuando agregues productos, apareceran aqui con la nueva paleta.',
                            ),
                          ),
                        )
                      else
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(18, 8, 18, 0),
                          sliver: SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) =>
                                  _buildCartItem(_cartItems[index]),
                              childCount: _cartItems.length,
                            ),
                          ),
                        ),
                      if (_cartItems.isNotEmpty)
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(18, 6, 18, 20),
                            child: _buildCheckoutCard(),
                          ),
                        ),
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(18, 6, 18, 8),
                          child: const Text(
                            'Historial de compras',
                            style: TextStyle(
                              color: PetScaniaColors.ink,
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ),
                      if (_orderHistory.isEmpty)
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
                            child: _buildEmptySection(
                              icon: Icons.inventory_2_outlined,
                              title: 'Todavia no tienes compras',
                              subtitle:
                                  'Tus pedidos apareceran aqui para contactar al vendedor.',
                            ),
                          ),
                        )
                      else
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(18, 8, 18, 30),
                          sliver: SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) =>
                                  _buildHistoryItem(_orderHistory[index]),
                              childCount: _orderHistory.length,
                            ),
                          ),
                        ),
                    ],
                  ),
          ),
          if (_isProcessingPay)
            Positioned.fill(
              child: Container(
                color: Colors.black.withValues(alpha: 0.18),
                child: const Center(
                  child: CircularProgressIndicator(
                    color: PetScaniaColors.royalBlue,
                  ),
                ),
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
      ),
      child: IconButton(
        onPressed: () => Navigator.pop(context),
        icon: const Icon(
          Icons.arrow_back_ios_new_rounded,
          color: Colors.white,
          size: 18,
        ),
      ),
    );
  }

  Widget _buildCartItem(Map<String, dynamic> item) {
    final product = item['products'];
    if (product == null) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: PetScaniaSurfaceCard(
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Image.network(
                product['image_url'] ?? '',
                height: 78,
                width: 78,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  height: 78,
                  width: 78,
                  color: PetScaniaColors.cloud,
                  child: const Icon(
                    Icons.shopping_bag_rounded,
                    color: PetScaniaColors.royalBlue,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product['name']?.toString() ?? 'Producto',
                    style: const TextStyle(
                      color: PetScaniaColors.ink,
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'S/ ${product['price']}',
                    style: const TextStyle(
                      color: PetScaniaColors.royalBlue,
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: PetScaniaColors.cloud,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                children: [
                  _qtyBtn(
                    Icons.remove_rounded,
                    () => _updateQuantity(
                      item['id'],
                      item['quantity'] - 1,
                      product['stock'],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      '${item['quantity']}',
                      style: const TextStyle(
                        color: PetScaniaColors.ink,
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  _qtyBtn(
                    Icons.add_rounded,
                    () => _updateQuantity(
                      item['id'],
                      item['quantity'] + 1,
                      product['stock'],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryItem(Map<String, dynamic> order) {
    final productInfo = order['products'];
    final sellerInfo = order['seller'];

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: () => _openWhatsAppWarning(order),
        child: PetScaniaSurfaceCard(
          child: Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: const BoxDecoration(
                  gradient: PetScaniaDecor.primaryGradient,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.chat_bubble_outline_rounded,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${order['quantity']}x ${productInfo['name']}',
                      style: const TextStyle(
                        color: PetScaniaColors.ink,
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Total: S/ ${order['total_price']} · Vendedor: ${sellerInfo['full_name']}',
                      style: TextStyle(
                        color: PetScaniaColors.ink.withValues(alpha: 0.62),
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                color: PetScaniaColors.royalBlue,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _qtyBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: PetScaniaColors.royalBlue, size: 16),
      ),
    );
  }

  Widget _buildCheckoutCard() {
    return PetScaniaSurfaceCard(
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Total actual',
                  style: TextStyle(
                    color: PetScaniaColors.ink.withValues(alpha: 0.56),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'S/ ${_totalPrice.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: PetScaniaColors.royalBlue,
                    fontWeight: FontWeight.w900,
                    fontSize: 28,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          SizedBox(
            height: 54,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: PetScaniaDecor.primaryGradient,
                borderRadius: BorderRadius.circular(18),
              ),
              child: ElevatedButton(
                onPressed: _handleCheckout,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                child: const Text(
                  'Acordar compra',
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
    );
  }

  Widget _buildEmptySection({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return PetScaniaSurfaceCard(
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: PetScaniaColors.cloud,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Icon(icon, color: PetScaniaColors.royalBlue, size: 34),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: PetScaniaColors.ink,
              fontWeight: FontWeight.w900,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: PetScaniaColors.ink.withValues(alpha: 0.65),
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}
