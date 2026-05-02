import 'package:flutter/material.dart';
import 'package:petscania/theme/petscania_brand.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class ServiceHistoryScreen extends StatefulWidget {
  const ServiceHistoryScreen({super.key});

  @override
  State<ServiceHistoryScreen> createState() => _ServiceHistoryScreenState();
}

class _ServiceHistoryScreenState extends State<ServiceHistoryScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _allBookings = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchBookings();
  }

  Future<void> _fetchBookings() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      return;
    }

    try {
      final response = await _supabase
          .from('service_bookings')
          .select('''
            *,
            services(name, image_url),
            vendedor:profiles!provider_id(full_name, phone)
          ''')
          .eq('customer_id', userId)
          .order('created_at', ascending: false);

      if (mounted) {
        setState(() {
          _allBookings = List<Map<String, dynamic>>.from(response);
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error en el historial: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _confirmarReservas() async {
    final userId = _supabase.auth.currentUser?.id;
    setState(() => _isLoading = true);

    try {
      await _supabase
          .from('service_bookings')
          .update({'status': 'confirmed'})
          .eq('customer_id', userId!)
          .eq('status', 'pending');

      await _fetchBookings();

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Reservas confirmadas con exito.')),
      );
    } catch (e) {
      debugPrint('Error confirmando: $e');
    }
  }

  Future<void> _abrirWhatsApp(String? phone, String? serviceName) async {
    if (phone == null || phone.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Sin telefono registrado.')));
      return;
    }

    final cleanPhone = phone.replaceAll(RegExp(r'\D'), '');
    final finalPhone = cleanPhone.startsWith('51')
        ? cleanPhone
        : '51$cleanPhone';
    final message =
        'Hola, he reservado tu servicio de $serviceName en PetScanIA. Quisiera coordinar los detalles.';
    final url = Uri.parse(
      'https://wa.me/$finalPhone?text=${Uri.encodeComponent(message)}',
    );
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pendingBookings = _allBookings
        .where((booking) => booking['status'] == 'pending')
        .toList();
    final historyBookings = _allBookings
        .where((booking) => booking['status'] != 'pending')
        .toList();

    final totalPending = pendingBookings.fold<double>(0, (sum, item) {
      final rawPrice = num.tryParse(
        item['price_at_booking']?.toString() ?? '0',
      );
      return sum + (rawPrice?.toDouble() ?? 0.0);
    });

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
                                      'Reservas y servicios',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 24,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      'Tu historial ahora respira la misma marca que el resto de la app.',
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
                            'Reservas pendientes',
                            style: TextStyle(
                              color: PetScaniaColors.ink,
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ),
                      if (pendingBookings.isEmpty)
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(18, 8, 18, 18),
                            child: _buildEmptySection(
                              icon: Icons.receipt_long_outlined,
                              title: 'No tienes reservas pendientes',
                              subtitle:
                                  'Cuando reserves un servicio, aparecera aqui con el nuevo estilo PetScanIA.',
                            ),
                          ),
                        )
                      else ...[
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(18, 8, 18, 0),
                          sliver: SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) => _buildBookingTile(
                                pendingBookings[index],
                                true,
                              ),
                              childCount: pendingBookings.length,
                            ),
                          ),
                        ),
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(18, 6, 18, 20),
                            child: _buildTotalConfirmCard(totalPending),
                          ),
                        ),
                      ],
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(18, 6, 18, 8),
                          child: const Text(
                            'Historial confirmado',
                            style: TextStyle(
                              color: PetScaniaColors.ink,
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ),
                      if (historyBookings.isEmpty)
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
                            child: _buildEmptySection(
                              icon: Icons.history_rounded,
                              title: 'Aun no hay historial',
                              subtitle:
                                  'Tus servicios ya coordinados apareceran aqui para contactar al experto.',
                            ),
                          ),
                        )
                      else
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(18, 8, 18, 30),
                          sliver: SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) =>
                                  _buildHistoryTile(historyBookings[index]),
                              childCount: historyBookings.length,
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
        onPressed: () => Navigator.pop(context),
        icon: const Icon(
          Icons.arrow_back_ios_new_rounded,
          color: Colors.white,
          size: 18,
        ),
      ),
    );
  }

  Widget _buildTotalConfirmCard(double total) {
    return PetScaniaSurfaceCard(
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Total por coordinar',
                  style: TextStyle(
                    color: PetScaniaColors.ink.withValues(alpha: 0.56),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'S/ ${total.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: PetScaniaColors.royalBlue,
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 54,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: PetScaniaDecor.primaryGradient,
                borderRadius: BorderRadius.circular(18),
              ),
              child: ElevatedButton(
                onPressed: _confirmarReservas,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                child: const Text(
                  'Acordar servicio',
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

  Widget _buildBookingTile(Map<String, dynamic> booking, bool isPending) {
    final service = booking['services'] ?? {};
    final rawPrice = num.tryParse(
      booking['price_at_booking']?.toString() ?? '0',
    );
    final price = rawPrice?.toStringAsFixed(2) ?? '0.00';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: PetScaniaSurfaceCard(
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child:
                  (service['image_url'] != null &&
                      service['image_url'].toString().isNotEmpty)
                  ? Image.network(
                      service['image_url'],
                      width: 76,
                      height: 76,
                      fit: BoxFit.cover,
                    )
                  : Container(
                      width: 76,
                      height: 76,
                      color: PetScaniaColors.cloud,
                      child: const Icon(
                        Icons.content_cut_rounded,
                        color: PetScaniaColors.royalBlue,
                      ),
                    ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    service['name']?.toString() ?? 'Servicio',
                    style: const TextStyle(
                      color: PetScaniaColors.ink,
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'S/ $price',
                    style: const TextStyle(
                      color: PetScaniaColors.royalBlue,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
            if (isPending)
              IconButton(
                onPressed: () async {
                  await _supabase
                      .from('service_bookings')
                      .delete()
                      .eq('id', booking['id']);
                  _fetchBookings();
                },
                icon: const Icon(
                  Icons.delete_outline_rounded,
                  color: Color(0xFFD84A4A),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryTile(Map<String, dynamic> booking) {
    final service = booking['services'] ?? {};
    final provider = booking['vendedor'] ?? {};
    final rawPrice = num.tryParse(
      booking['price_at_booking']?.toString() ?? '0',
    );
    final price = rawPrice?.toStringAsFixed(2) ?? '0.00';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: () => _abrirWhatsApp(
          provider['phone']?.toString(),
          service['name']?.toString(),
        ),
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
                      '1x ${service['name'] ?? 'Servicio'}',
                      style: const TextStyle(
                        color: PetScaniaColors.ink,
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Total: S/ $price · Experto: ${provider['full_name'] ?? 'Socio PetScanIA'}',
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
