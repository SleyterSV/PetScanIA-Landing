import 'package:flutter/material.dart';
import 'package:petscania/screens/identity_verification_screen.dart';
import 'package:petscania/screens/provider_hub_screen.dart';
import 'package:petscania/screens/service_history_screen.dart';
import 'package:petscania/screens/terms_screen.dart';
import 'package:petscania/theme/petscania_brand.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ServicesScreen extends StatefulWidget {
  const ServicesScreen({super.key});

  @override
  State<ServicesScreen> createState() => _ServicesScreenState();
}

class _ServicesScreenState extends State<ServicesScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;

  String _selectedCategory = 'Todos';
  String _searchText = '';
  bool _isLoading = true;
  int _customerPending = 0;
  int _providerPending = 0;
  List<Map<String, dynamic>> _allServices = [];

  final List<String> _categories = const [
    'Todos',
    'Ba\u00f1os',
    'Cortes',
    'Paseos',
    'Guarder\u00eda',
    'Entrenamiento',
  ];

  @override
  void initState() {
    super.initState();
    _loadStaticData();
  }

  Future<void> _loadStaticData() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      final services = await _supabase
          .from('services')
          .select()
          .order('created_at', ascending: false);

      var customerPending = 0;
      var providerPending = 0;

      if (userId != null) {
        final customerBookings = await _supabase
            .from('service_bookings')
            .select('id')
            .eq('customer_id', userId)
            .eq('status', 'pending');
        final providerBookings = await _supabase
            .from('service_bookings')
            .select('id')
            .eq('provider_id', userId)
            .eq('status', 'pending');
        customerPending = customerBookings.length;
        providerPending = providerBookings.length;
      }

      if (mounted) {
        setState(() {
          _allServices = List<Map<String, dynamic>>.from(services);
          _customerPending = customerPending;
          _providerPending = providerPending;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  List<Map<String, dynamic>> get _filteredServices {
    return _allServices.where((service) {
      final matchesCategory =
          _selectedCategory == 'Todos' ||
          service['category']?.toString() == _selectedCategory;
      final haystack = [
        service['name'],
        service['description'],
        service['category'],
      ].join(' ').toLowerCase();
      final matchesSearch =
          _searchText.isEmpty ||
          haystack.contains(_searchText.trim().toLowerCase());
      return matchesCategory && matchesSearch;
    }).toList();
  }

  Future<void> _handleProviderAction(String? userId) async {
    if (userId == null) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Inicia sesion para ofrecer servicios.')),
      );
      return;
    }

    try {
      final providerData = await _supabase
          .from('service_providers')
          .select('is_verified, is_verified_services, accepted_services_terms')
          .eq('id', userId)
          .maybeSingle();

      if (!mounted) {
        return;
      }

      if (providerData == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Perfil no encontrado.')));
        return;
      }

      final isVerified =
          providerData['is_verified_services'] == true ||
          providerData['is_verified'] == true;
      final hasAcceptedTerms = providerData['accepted_services_terms'] == true;

      if (!isVerified) {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const IdentityVerificationScreen(
              userType: TermsUserType.providerService,
            ),
          ),
        );
      } else if (!hasAcceptedTerms) {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                const TermsScreen(userType: TermsUserType.providerService),
          ),
        );
      } else {
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ProviderHubScreen()),
        );
      }
      _loadStaticData();
    } catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('No pude abrir el panel: $e')));
    }
  }

  void _showServicePreview(Map<String, dynamic> service) {
    final currentUserId = _supabase.auth.currentUser?.id;
    final providerId = service['provider_id'];
    final isMyOwnService = currentUserId == providerId;
    final price =
        num.tryParse(service['price']?.toString() ?? '0')?.toStringAsFixed(2) ??
        '0.00';

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return Container(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
          decoration: const BoxDecoration(
            color: PetScaniaColors.mist,
            borderRadius: BorderRadius.vertical(top: Radius.circular(34)),
          ),
          child: SafeArea(
            top: false,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 46,
                      height: 5,
                      decoration: BoxDecoration(
                        color: PetScaniaColors.line,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(28),
                    child: AspectRatio(
                      aspectRatio: 1.45,
                      child:
                          (service['image_url'] != null &&
                              service['image_url'].toString().isNotEmpty)
                          ? Image.network(
                              service['image_url'],
                              fit: BoxFit.cover,
                            )
                          : Container(
                              color: PetScaniaColors.cloud,
                              child: const Center(
                                child: Icon(
                                  Icons.content_cut_rounded,
                                  color: PetScaniaColors.royalBlue,
                                  size: 56,
                                ),
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildInfoPill(
                        service['category']?.toString() ?? 'General',
                      ),
                      if ((service['discount_label'] ?? '')
                          .toString()
                          .isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: PetScaniaColors.skyBlue.withValues(
                              alpha: 0.16,
                            ),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            service['discount_label'].toString(),
                            style: const TextStyle(
                              color: PetScaniaColors.royalBlue,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    service['name']?.toString() ?? 'Servicio',
                    style: const TextStyle(
                      color: PetScaniaColors.ink,
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      height: 1.05,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    service['description']?.toString().trim().isNotEmpty == true
                        ? service['description'].toString()
                        : 'Un servicio pensado para cuidar a tu mascota con una experiencia amable y profesional.',
                    style: TextStyle(
                      color: PetScaniaColors.ink.withValues(alpha: 0.75),
                      fontSize: 15,
                      height: 1.55,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Precio',
                            style: TextStyle(
                              color: PetScaniaColors.ink.withValues(
                                alpha: 0.55,
                              ),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            'S/ $price',
                            style: const TextStyle(
                              color: PetScaniaColors.royalBlue,
                              fontSize: 32,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(left: 16),
                          child: SizedBox(
                            height: 56,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: isMyOwnService
                                    ? null
                                    : PetScaniaDecor.primaryGradient,
                                color: isMyOwnService
                                    ? PetScaniaColors.line
                                    : null,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: ElevatedButton(
                                onPressed: isMyOwnService
                                    ? null
                                    : () async {
                                        try {
                                          await _supabase
                                              .from('service_bookings')
                                              .insert({
                                                'service_id': service['id'],
                                                'customer_id': currentUserId,
                                                'provider_id': providerId,
                                                'price_at_booking':
                                                    service['price'],
                                                'status': 'pending',
                                                'booking_date': DateTime.now()
                                                    .toIso8601String(),
                                              });

                                          if (!sheetContext.mounted ||
                                              !mounted) {
                                            return;
                                          }

                                          Navigator.pop(sheetContext);
                                          _loadStaticData();
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                'Servicio agregado a tus reservas.',
                                              ),
                                            ),
                                          );
                                        } catch (e) {
                                          if (!mounted) {
                                            return;
                                          }
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                'No pude reservar este servicio: $e',
                                              ),
                                            ),
                                          );
                                        }
                                      },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  disabledBackgroundColor: PetScaniaColors.line,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                ),
                                child: Text(
                                  isMyOwnService
                                      ? 'ES TU SERVICIO'
                                      : 'RESERVAR AHORA',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: isMyOwnService
                                        ? PetScaniaColors.royalBlue
                                        : Colors.white,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final userId = _supabase.auth.currentUser?.id;
    final filteredServices = _filteredServices;

    return Scaffold(
      backgroundColor: PetScaniaColors.mist,
      body: Stack(
        children: [
          Container(
            height: 320,
            decoration: const BoxDecoration(
              gradient: PetScaniaDecor.primaryGradient,
            ),
          ),
          Positioned(
            top: -30,
            right: -20,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.10),
                shape: BoxShape.circle,
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 14, 18, 12),
                  child: Row(
                    children: [
                      _buildBackButton(),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Servicios para mascotas',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Banos, paseos y cuidados con una imagen mas amable.',
                              style: TextStyle(
                                color: Color(0xD8FFFFFF),
                                height: 1.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const PetScaniaBrandMark(size: 48),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildHeaderAction(
                          icon: Icons.receipt_long_rounded,
                          label: 'Reservas',
                          count: _customerPending,
                          filled: false,
                          onTap: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const ServiceHistoryScreen(),
                              ),
                            );
                            _loadStaticData();
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildHeaderAction(
                          icon: Icons.auto_awesome_rounded,
                          label: 'Ofrecer',
                          count: _providerPending,
                          filled: true,
                          onTap: () => _handleProviderAction(userId),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
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
                            itemBuilder: (context, index) {
                              final category = _categories[index];
                              final isSelected = category == _selectedCategory;
                              return GestureDetector(
                                onTap: () {
                                  setState(() => _selectedCategory = category);
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
                            separatorBuilder: (_, __) =>
                                const SizedBox(width: 10),
                            itemCount: _categories.length,
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
                              : filteredServices.isEmpty
                              ? _buildEmptyState()
                              : RefreshIndicator(
                                  onRefresh: _loadStaticData,
                                  color: PetScaniaColors.royalBlue,
                                  child: GridView.builder(
                                    padding: const EdgeInsets.fromLTRB(
                                      18,
                                      8,
                                      18,
                                      28,
                                    ),
                                    physics:
                                        const AlwaysScrollableScrollPhysics(),
                                    gridDelegate:
                                        const SliverGridDelegateWithFixedCrossAxisCount(
                                          crossAxisCount: 2,
                                          childAspectRatio: 0.69,
                                          crossAxisSpacing: 14,
                                          mainAxisSpacing: 14,
                                        ),
                                    itemCount: filteredServices.length,
                                    itemBuilder: (context, index) {
                                      return _buildServiceCard(
                                        filteredServices[index],
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
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(16),
      ),
      child: IconButton(
        onPressed: () => Navigator.of(context).pop(),
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
    required int count,
    required bool filled,
    required VoidCallback onTap,
  }) {
    return Badge(
      isLabelVisible: count > 0,
      label: Text(
        '$count',
        style: const TextStyle(fontWeight: FontWeight.w900),
      ),
      backgroundColor: Colors.white,
      textColor: PetScaniaColors.royalBlue,
      child: SizedBox(
        height: 48,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: filled ? PetScaniaDecor.surfaceGradient : null,
            color: filled ? null : Colors.white.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: filled
                  ? Colors.transparent
                  : Colors.white.withValues(alpha: 0.18),
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
      ),
    );
  }

  Widget _buildSearchBar() {
    return PetScaniaSurfaceCard(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
      borderRadius: BorderRadius.circular(22),
      child: TextField(
        onChanged: (value) => setState(() => _searchText = value),
        style: const TextStyle(
          color: PetScaniaColors.ink,
          fontWeight: FontWeight.w700,
        ),
        decoration: const InputDecoration(
          icon: Icon(Icons.search_rounded, color: PetScaniaColors.royalBlue),
          hintText: 'Busca cuidados para tu mascota...',
          hintStyle: TextStyle(color: Color(0xFF7D96BF)),
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _buildServiceCard(Map<String, dynamic> service) {
    final price =
        num.tryParse(service['price']?.toString() ?? '0')?.toStringAsFixed(2) ??
        '0.00';
    final imageUrl = service['image_url']?.toString() ?? '';
    final discount = service['discount_label']?.toString() ?? '';

    return GestureDetector(
      onTap: () => _showServicePreview(service),
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
                          ? Image.network(imageUrl, fit: BoxFit.cover)
                          : Container(
                              color: PetScaniaColors.cloud,
                              child: const Icon(
                                Icons.auto_fix_high_rounded,
                                color: PetScaniaColors.royalBlue,
                                size: 46,
                              ),
                            ),
                    ),
                  ),
                  Positioned(
                    top: 10,
                    left: 10,
                    child: _buildInfoPill(
                      service['category']?.toString() ?? 'General',
                    ),
                  ),
                  if (discount.isNotEmpty)
                    Positioned(
                      top: 10,
                      right: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          gradient: PetScaniaDecor.primaryGradient,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          discount,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
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
                      service['name']?.toString() ?? 'Servicio',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: PetScaniaColors.ink,
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
                        height: 1.15,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: Text(
                        service['description']?.toString().trim().isNotEmpty ==
                                true
                            ? service['description'].toString()
                            : 'Cuidado pensado para una experiencia comoda y segura.',
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: PetScaniaColors.ink.withValues(alpha: 0.62),
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
                            fontWeight: FontWeight.w900,
                            fontSize: 18,
                          ),
                        ),
                        Container(
                          width: 38,
                          height: 38,
                          decoration: const BoxDecoration(
                            gradient: PetScaniaDecor.primaryGradient,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.arrow_forward_rounded,
                            color: Colors.white,
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

  Widget _buildInfoPill(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: PetScaniaColors.royalBlue,
          fontSize: 11,
          fontWeight: FontWeight.w800,
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
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: PetScaniaColors.cloud,
                borderRadius: BorderRadius.circular(28),
              ),
              child: const Icon(
                Icons.pets_rounded,
                color: PetScaniaColors.royalBlue,
                size: 44,
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'No encontramos servicios con ese filtro.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: PetScaniaColors.ink,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Prueba otra categoria o una palabra distinta. La pantalla ya quedo alineada a la nueva identidad PetScanIA.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: PetScaniaColors.ink.withValues(alpha: 0.65),
                height: 1.45,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
