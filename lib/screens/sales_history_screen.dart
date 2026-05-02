import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class SalesHistoryScreen extends StatefulWidget {
  const SalesHistoryScreen({super.key});

  @override
  State<SalesHistoryScreen> createState() => _SalesHistoryScreenState();
}

class _SalesHistoryScreenState extends State<SalesHistoryScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _sales = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSales();
  }

  Future<void> _loadSales() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      final response = await _supabase
          .from('orders')
          .select('id, quantity, total_price, status, created_at, products(name), buyer:buyer_id(full_name, phone)')
          .eq('seller_id', user.id)
          .order('created_at', ascending: false);

      if (mounted) {
        setState(() {
          _sales = List<Map<String, dynamic>>.from(response);
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error cargando ventas: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _contactBuyer(Map<String, dynamic> sale) async {
    final buyerInfo = sale['buyer'];
    final String? phone = buyerInfo?['phone'];
    
    if (phone == null || phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("El comprador no tiene número registrado."), backgroundColor: Colors.orange));
      return;
    }

    final cleanPhone = phone.replaceAll(RegExp(r'\D'), '');
    final message = "Hola ${buyerInfo['full_name']}, soy el vendedor de PetScanIA. Vi que acordaste la compra de ${sale['quantity']}x ${sale['products']['name']}. Te escribo para coordinar la entrega y el pago de S/ ${sale['total_price']}.";
    final url = Uri.parse("https://wa.me/51$cleanPhone?text=${Uri.encodeComponent(message)}");
    
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  double get _totalEarnings {
    return _sales.fold(0, (sum, item) => sum + (item['total_price'] as num));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: const Text("Mis Ventas (Alertas)", style: TextStyle(fontWeight: FontWeight.w900, color: Colors.white)),
        backgroundColor: Colors.transparent, elevation: 0, centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: Color(0xFFB2D826)))
        : Column(
            children: [
              Container(
                margin: const EdgeInsets.all(20),
                padding: const EdgeInsets.all(25),
                decoration: BoxDecoration(color: const Color(0xFFB2D826), borderRadius: BorderRadius.circular(25)),
                child: Row(
                  children: [
                    const Expanded(child: Text("Ganancias Acumuladas", style: TextStyle(color: Color(0xFF0F172A), fontSize: 18, fontWeight: FontWeight.bold))),
                    Text("S/ ${_totalEarnings.toStringAsFixed(2)}", style: const TextStyle(color: Color(0xFF0F172A), fontSize: 26, fontWeight: FontWeight.w900)),
                  ],
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Align(alignment: Alignment.centerLeft, child: Text("Últimos Pedidos", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold))),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: _sales.length,
                  itemBuilder: (context, index) {
                    final sale = _sales[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 15),
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white10)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(child: Text("${sale['quantity']}x ${sale['products']['name']}", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16))),
                              Text("S/ ${sale['total_price']}", style: const TextStyle(color: Color(0xFFB2D826), fontWeight: FontWeight.w900, fontSize: 18)),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text("Comprador: ${sale['buyer']['full_name']}", style: const TextStyle(color: Colors.white70)),
                          const SizedBox(height: 15),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF25D366), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                              onPressed: () => _contactBuyer(sale),
                              icon: const Icon(Icons.chat_bubble_rounded, color: Colors.white, size: 18),
                              label: const Text("COORDINAR ENTREGA", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            ),
                          )
                        ],
                      ),
                    );
                  },
                ),
              )
            ],
          ),
    );
  }
}