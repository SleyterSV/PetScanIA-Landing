import 'package:flutter/material.dart';
import 'package:petscania/screens/add_product_screen.dart';
import 'package:petscania/screens/cart_screen.dart';
import 'package:petscania/screens/home_screen.dart';
import 'package:petscania/screens/identity_verification_screen.dart';
import 'package:petscania/screens/product_detail_screen.dart';
import 'package:petscania/screens/terms_screen.dart';
import 'package:petscania/services/marketplace_service.dart';
import 'package:petscania/theme/petscania_brand.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MarketplaceScreen extends StatefulWidget {
  const MarketplaceScreen({super.key});

  @override
  State<MarketplaceScreen> createState() => _MarketplaceScreenState();
}

class _MarketplaceScreenState extends State<MarketplaceScreen> {
  final MarketplaceService _service = MarketplaceService();
  final SupabaseClient _supabase = Supabase.instance.client;

  final List<String> _categories = const [
    'Todos',
    'Comida',
    'Juguetes',
    'Salud',
    'Accesorios',
    'Ropa',
  ];

  List<Map<String, dynamic>> _products = [];
  bool _isLoading = true;
  String _selectedCategory = 'Todos';
  String _searchText = '';

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    try {
      final products = await _service.getProducts();

      if (mounted) {
        setState(() {
          _products = products;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error cargando productos: $e');

      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  List<Map<String, dynamic>> get _filteredProducts {
    return _products.where((product) {
      final matchesCategory =
          _selectedCategory == 'Todos' ||
          product['category']?.toString() == _selectedCategory;

      final haystack = [
        product['name'],
        product['description'],
        product['category'],
        product['profiles']?['full_name'],
      ].join(' ').toLowerCase();

      final matchesSearch =
          _searchText.isEmpty ||
          haystack.contains(_searchText.trim().toLowerCase());

      return matchesCategory && matchesSearch;
    }).toList();
  }

  Future<void> _handleSellerFlow() async {
    final userId = _supabase.auth.currentUser?.id;

    if (userId == null) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Inicia sesión para vender productos.'),
        ),
      );
      return;
    }

    final providerData = await _supabase
        .from('service_providers')
        .select('verification_status, is_verified, has_accepted_provider_terms')
        .eq('id', userId)
        .maybeSingle();

    if (!mounted) return;

    final status = providerData?['verification_status'] ?? 'unverified';

    final isDniVerified =
        status == 'verified' || providerData?['is_verified'] == true;

    final hasAcceptedTerms =
        providerData?['has_accepted_provider_terms'] == true;

    if (isDniVerified && hasAcceptedTerms) {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const AddProductScreen(),
        ),
      );

      if (result == true) {
        _loadProducts();
      }

      return;
    }

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const IdentityVerificationScreen(
          userType: TermsUserType.providerMarketplace,
        ),
      ),
    );

    _loadProducts();
  }

  void _goToHome() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => const HomeScreen(),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = _supabase.auth.currentUser?.id;
    final filteredProducts = _filteredProducts;

    return Scaffold(
      backgroundColor: PetScaniaColors.mist,
      body: Stack(
        children: [
          Container(
            height: 330,
            decoration: const BoxDecoration(
              gradient: PetScaniaDecor.primaryGradient,
            ),
          ),

          Positioned(
            top: -40,
            left: -30,
            child: Container(
              width: 170,
              height: 170,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
            ),
          ),

          Positioned(
            top: 60,
            right: -30,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.07),
                shape: BoxShape.circle,
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 16, 18, 10),
                  child: Row(
                    children: [
                      _buildBackButton(),

                      const SizedBox(width: 12),

                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Marketplace PetScanIA',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 23,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            SizedBox(height: 6),
                            Text(
                              'Productos con una vitrina más limpia, fresca y petfriendly.',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Color(0xD8FFFFFF),
                                height: 1.35,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(width: 8),

                      const PetScaniaBrandMark(size: 44),
                    ],
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildHeaderAction(
                          icon: Icons.shopping_bag_rounded,
                          label: 'Compras',
                          filled: false,
                          onTap: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const CartScreen(),
                              ),
                            );

                            _loadProducts();
                          },
                        ),
                      ),

                      const SizedBox(width: 12),

                      Expanded(
                        child: _buildHeaderAction(
                          icon: Icons.storefront_rounded,
                          label: 'Vender',
                          filled: true,
                          onTap: _handleSellerFlow,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                Expanded(
                  child: Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      color: PetScaniaColors.mist,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(34),
                      ),
                    ),
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(18, 18, 18, 10),
                          child: _buildSearchBar(),
                        ),

                        SizedBox(
                          height: 48,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 18),
                            itemCount: _categories.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(width: 10),
                            itemBuilder: (context, index) {
                              final category = _categories[index];
                              final isSelected = category == _selectedCategory;

                              return GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _selectedCategory = category;
                                  });
                                },
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 180),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 18,
                                  ),
                                  decoration: BoxDecoration(
                                    gradient: isSelected
                                        ? PetScaniaDecor.primaryGradient
                                        : null,
                                    color: isSelected ? null : Colors.white,
                                    borderRadius: BorderRadius.circular(999),
                                    border: Border.all(
                                      color: isSelected
                                          ? Colors.transparent
                                          : PetScaniaColors.line,
                                    ),
                                  ),
                                  child: Center(
                                    child: Text(
                                      category,
                                      style: TextStyle(
                                        color: isSelected
                                            ? Colors.white
                                            : PetScaniaColors.ink,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),

                        const SizedBox(height: 12),

                        Expanded(
                          child: _isLoading
                              ? const Center(
                                  child: CircularProgressIndicator(
                                    color: PetScaniaColors.royalBlue,
                                  ),
                                )
                              : filteredProducts.isEmpty
                                  ? _buildEmptyState()
                                  : RefreshIndicator(
                                      onRefresh: _loadProducts,
                                      color: PetScaniaColors.royalBlue,
                                      child: GridView.builder(
                                        physics:
                                            const AlwaysScrollableScrollPhysics(),
                                        padding: const EdgeInsets.fromLTRB(
                                          18,
                                          8,
                                          18,
                                          28,
                                        ),
                                        gridDelegate:
                                            const SliverGridDelegateWithFixedCrossAxisCount(
                                          crossAxisCount: 2,
                                          childAspectRatio: 0.69,
                                          crossAxisSpacing: 14,
                                          mainAxisSpacing: 14,
                                        ),
                                        itemCount: filteredProducts.length,
                                        itemBuilder: (context, index) {
                                          return _buildProductCard(
                                            filteredProducts[index],
                                            currentUserId,
                                          );
                                        },
                                      ),
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
    );
  }

  Widget _buildBackButton() {
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.16),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.18),
        ),
      ),
      child: IconButton(
        onPressed: _goToHome,
        icon: const Icon(
          Icons.arrow_back_ios_new_rounded,
          color: Colors.white,
          size: 18,
        ),
      ),
    );
  }

  Widget _buildHeaderAction({
    required IconData icon,
    required String label,
    required bool filled,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      height: 48,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: filled ? PetScaniaDecor.surfaceGradient : null,
          color: filled ? null : Colors.white.withOpacity(0.14),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: filled
                ? Colors.transparent
                : Colors.white.withOpacity(0.18),
          ),
        ),
        child: ElevatedButton.icon(
          onPressed: onTap,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
          ),
          icon: Icon(
            icon,
            size: 18,
            color: filled ? PetScaniaColors.royalBlue : Colors.white,
          ),
          label: Text(
            label,
            style: TextStyle(
              color: filled ? PetScaniaColors.royalBlue : Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return PetScaniaSurfaceCard(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
      borderRadius: BorderRadius.circular(22),
      child: TextField(
        onChanged: (value) {
          setState(() {
            _searchText = value;
          });
        },
        style: const TextStyle(
          color: PetScaniaColors.ink,
          fontWeight: FontWeight.w700,
        ),
        decoration: const InputDecoration(
          icon: Icon(
            Icons.search_rounded,
            color: PetScaniaColors.royalBlue,
          ),
          hintText: 'Busca comida, juguetes o accesorios...',
          hintStyle: TextStyle(
            color: Color(0xFF7D96BF),
          ),
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _buildProductCard(
    Map<String, dynamic> product,
    String? currentUserId,
  ) {
    final imageUrl = product['image_url']?.toString() ?? '';
    final sellerId = product['seller_id']?.toString() ?? '';
    final stock = product['stock'] ?? 0;
    final price = product['price']?.toString() ?? '0.00';

    final profiles = product['profiles'] as Map<String, dynamic>?;
    final sellerName = profiles?['full_name']?.toString() ?? 'Socio PetScanIA';

    final isMyOwnProduct = sellerId == currentUserId;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ProductDetailScreen(product: product),
          ),
        ).then((_) => _loadProducts());
      },
      child: PetScaniaSurfaceCard(
        padding: EdgeInsets.zero,
        borderRadius: BorderRadius.circular(28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 11,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(28),
                      ),
                      child: imageUrl.isNotEmpty
                          ? Hero(
                              tag: 'product_image_${product['id']}',
                              child: Image.network(
                                imageUrl,
                                fit: BoxFit.cover,
                              ),
                            )
                          : Container(
                              color: PetScaniaColors.cloud,
                              child: const Icon(
                                Icons.shopping_bag_rounded,
                                color: PetScaniaColors.royalBlue,
                                size: 44,
                              ),
                            ),
                    ),
                  ),

                  Positioned(
                    top: 10,
                    left: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.92),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        product['category']?.toString() ?? 'General',
                        style: const TextStyle(
                          color: PetScaniaColors.royalBlue,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),

                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: stock == 0
                            ? const Color(0xFFFFE5E5)
                            : Colors.white.withOpacity(0.92),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        stock == 0 ? 'Agotado' : 'Stock $stock',
                        style: TextStyle(
                          color: stock == 0
                              ? const Color(0xFFD84A4A)
                              : PetScaniaColors.ink,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),

                  if (isMyOwnProduct)
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: PetScaniaColors.royalBlue.withOpacity(0.88),
                        ),
                        child: const Text(
                          'ESTE ES TU PRODUCTO',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.6,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            Expanded(
              flex: 9,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      sellerName.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: PetScaniaColors.ink.withOpacity(0.45),
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.7,
                      ),
                    ),

                    const SizedBox(height: 6),

                    Text(
                      product['name']?.toString() ?? 'Producto',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: PetScaniaColors.ink,
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
                      ),
                    ),

                    const SizedBox(height: 6),

                    Expanded(
                      child: Text(
                        product['description']?.toString().trim().isNotEmpty ==
                                true
                            ? product['description'].toString()
                            : 'Una opción pensada para el bienestar y la rutina de tu mascota.',
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: PetScaniaColors.ink.withOpacity(0.62),
                          fontSize: 12,
                          height: 1.35,
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'S/ $price',
                          style: const TextStyle(
                            color: PetScaniaColors.royalBlue,
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                          ),
                        ),

                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            gradient: isMyOwnProduct || stock == 0
                                ? null
                                : PetScaniaDecor.primaryGradient,
                            color: isMyOwnProduct || stock == 0
                                ? PetScaniaColors.line
                                : null,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.arrow_forward_rounded,
                            color: isMyOwnProduct || stock == 0
                                ? PetScaniaColors.royalBlue.withOpacity(0.45)
                                : Colors.white,
                            size: 18,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 92,
              height: 92,
              decoration: BoxDecoration(
                color: PetScaniaColors.cloud,
                borderRadius: BorderRadius.circular(28),
              ),
              child: const Icon(
                Icons.storefront_rounded,
                color: PetScaniaColors.royalBlue,
                size: 44,
              ),
            ),

            const SizedBox(height: 18),

            const Text(
              'Todavía no hay productos para ese filtro.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: PetScaniaColors.ink,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              'Prueba otra categoría o una búsqueda distinta.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: PetScaniaColors.ink.withOpacity(0.65),
                height: 1.45,
              ),
            ),
          ],
        ),
      ),
    );
  }
}