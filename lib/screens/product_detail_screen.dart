import 'package:flutter/material.dart';
import 'package:petscania/screens/cart_screen.dart';
import 'package:petscania/theme/petscania_brand.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProductDetailScreen extends StatefulWidget {
  final Map<String, dynamic> product;

  const ProductDetailScreen({super.key, required this.product});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  int _quantity = 1;
  bool _isAddingToCart = false;

  void _incrementQuantity(int maxStock) {
    if (_quantity < maxStock) {
      setState(() => _quantity++);
    }
  }

  void _decrementQuantity() {
    if (_quantity > 1) {
      setState(() => _quantity--);
    }
  }

  Future<void> _addToCart() async {
    setState(() => _isAddingToCart = true);

    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;
      if (user == null) {
        throw Exception('Debes iniciar sesion para comprar.');
      }

      final existingCartItem = await supabase
          .from('cart')
          .select()
          .eq('user_id', user.id)
          .eq('product_id', widget.product['id'])
          .maybeSingle();

      if (existingCartItem != null) {
        final newQuantity = existingCartItem['quantity'] + _quantity;
        await supabase
            .from('cart')
            .update({'quantity': newQuantity})
            .eq('id', existingCartItem['id']);
      } else {
        await supabase.from('cart').insert({
          'user_id': user.id,
          'product_id': widget.product['id'],
          'quantity': _quantity,
        });
      }

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Producto agregado al carrito.')),
      );

      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const CartScreen()),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No pude anadirlo al carrito: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isAddingToCart = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    final sellerId = widget.product['seller_id']?.toString() ?? '';
    final isMyOwnProduct = sellerId == currentUserId;

    final profiles = widget.product['profiles'] as Map<String, dynamic>?;
    final sellerName = profiles?['full_name']?.toString() ?? 'Socio PetScanIA';
    final sellerAvatar = profiles?['avatar_url']?.toString();

    final stock = widget.product['stock'] ?? 0;
    final hasStock = stock > 0;
    final price =
        num.tryParse(
          widget.product['price']?.toString() ?? '0',
        )?.toStringAsFixed(2) ??
        '0.00';
    final category = (widget.product['category']?.toString() ?? 'General')
        .toUpperCase();
    final description =
        widget.product['description']?.toString().trim().isNotEmpty == true
        ? widget.product['description'].toString()
        : 'Este producto acompana el bienestar diario de tu mascota con una presentacion mas clara y confiable.';

    return Scaffold(
      backgroundColor: PetScaniaColors.mist,
      body: Stack(
        children: [
          Container(
            height: 290,
            decoration: const BoxDecoration(
              gradient: PetScaniaDecor.primaryGradient,
            ),
          ),
          Positioned(
            top: 40,
            right: -30,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.09),
                shape: BoxShape.circle,
              ),
            ),
          ),
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 14, 18, 8),
                  child: Row(
                    children: [
                      _buildBackButton(),
                      const Spacer(),
                      const PetScaniaBrandMark(size: 46),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(18, 10, 18, 140),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Hero(
                          tag: 'product_image_${widget.product['id']}',
                          child: PetScaniaSurfaceCard(
                            padding: const EdgeInsets.all(12),
                            borderRadius: BorderRadius.circular(32),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(24),
                              child: AspectRatio(
                                aspectRatio: 1.1,
                                child:
                                    (widget.product['image_url'] != null &&
                                        widget.product['image_url']
                                            .toString()
                                            .isNotEmpty)
                                    ? Image.network(
                                        widget.product['image_url'],
                                        fit: BoxFit.contain,
                                      )
                                    : Container(
                                        color: PetScaniaColors.cloud,
                                        child: const Icon(
                                          Icons.shopping_bag_rounded,
                                          color: PetScaniaColors.royalBlue,
                                          size: 64,
                                        ),
                                      ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        PetScaniaSurfaceCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  _buildPill(category),
                                  _buildPill(
                                    hasStock ? 'EN STOCK: $stock' : 'AGOTADO',
                                    background: hasStock
                                        ? PetScaniaColors.cloud
                                        : const Color(0xFFFFE6E6),
                                    foreground: hasStock
                                        ? PetScaniaColors.royalBlue
                                        : const Color(0xFFD84A4A),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 18),
                              Text(
                                widget.product['name']?.toString() ??
                                    'Producto',
                                style: const TextStyle(
                                  color: PetScaniaColors.ink,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 30,
                                  height: 1.05,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'S/ $price',
                                style: const TextStyle(
                                  color: PetScaniaColors.royalBlue,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 34,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                        PetScaniaSurfaceCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Descripcion',
                                style: TextStyle(
                                  color: PetScaniaColors.ink,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 18,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                description,
                                style: TextStyle(
                                  color: PetScaniaColors.ink.withValues(
                                    alpha: 0.72,
                                  ),
                                  fontSize: 15,
                                  height: 1.6,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                        PetScaniaSurfaceCard(
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 28,
                                backgroundColor: PetScaniaColors.cloud,
                                backgroundImage:
                                    sellerAvatar != null &&
                                        sellerAvatar.isNotEmpty
                                    ? NetworkImage(sellerAvatar)
                                    : null,
                                child:
                                    sellerAvatar == null || sellerAvatar.isEmpty
                                    ? const Icon(
                                        Icons.person_rounded,
                                        color: PetScaniaColors.royalBlue,
                                      )
                                    : null,
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      sellerName,
                                      style: const TextStyle(
                                        color: PetScaniaColors.ink,
                                        fontWeight: FontWeight.w900,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Vendedor dentro del ecosistema PetScanIA',
                                      style: TextStyle(
                                        color: PetScaniaColors.ink.withValues(
                                          alpha: 0.6,
                                        ),
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(
                                Icons.verified_rounded,
                                color: PetScaniaColors.skyBlue,
                                size: 28,
                              ),
                            ],
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
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          boxShadow: [
            BoxShadow(
              color: PetScaniaColors.ink.withValues(alpha: 0.10),
              blurRadius: 24,
              offset: const Offset(0, -8),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!isMyOwnProduct && hasStock)
                Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Cantidad',
                        style: TextStyle(
                          color: PetScaniaColors.ink,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        decoration: BoxDecoration(
                          color: PetScaniaColors.cloud,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Row(
                          children: [
                            IconButton(
                              onPressed: _decrementQuantity,
                              icon: const Icon(
                                Icons.remove_rounded,
                                color: PetScaniaColors.royalBlue,
                              ),
                            ),
                            Text(
                              '$_quantity',
                              style: const TextStyle(
                                color: PetScaniaColors.ink,
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            IconButton(
                              onPressed: () => _incrementQuantity(stock),
                              icon: Icon(
                                Icons.add_rounded,
                                color: _quantity < stock
                                    ? PetScaniaColors.royalBlue
                                    : PetScaniaColors.ink.withValues(
                                        alpha: 0.30,
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              SizedBox(
                width: double.infinity,
                height: 58,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: isMyOwnProduct || !hasStock
                        ? null
                        : PetScaniaDecor.primaryGradient,
                    color: isMyOwnProduct || !hasStock
                        ? PetScaniaColors.line
                        : null,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: ElevatedButton.icon(
                    onPressed: (isMyOwnProduct || !hasStock || _isAddingToCart)
                        ? null
                        : _addToCart,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      disabledBackgroundColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    icon: _isAddingToCart
                        ? const SizedBox.shrink()
                        : Icon(
                            isMyOwnProduct
                                ? Icons.storefront_rounded
                                : Icons.shopping_cart_checkout_rounded,
                            color: isMyOwnProduct || !hasStock
                                ? PetScaniaColors.royalBlue.withValues(
                                    alpha: 0.45,
                                  )
                                : Colors.white,
                          ),
                    label: _isAddingToCart
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.6,
                            ),
                          )
                        : Text(
                            isMyOwnProduct
                                ? 'ESTE ES TU PRODUCTO'
                                : hasStock
                                ? 'ANADIR AL CARRITO'
                                : 'PRODUCTO AGOTADO',
                            style: TextStyle(
                              color: isMyOwnProduct || !hasStock
                                  ? PetScaniaColors.royalBlue.withValues(
                                      alpha: 0.45,
                                    )
                                  : Colors.white,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.5,
                            ),
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
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

  Widget _buildPill(
    String label, {
    Color background = PetScaniaColors.cloud,
    Color foreground = PetScaniaColors.royalBlue,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: foreground,
          fontWeight: FontWeight.w900,
          fontSize: 11,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}
