import 'package:flutter/material.dart';
import 'package:petscania/services/services_service.dart';

class ConsumptionHistoryScreen extends StatefulWidget {
  const ConsumptionHistoryScreen({super.key});

  @override
  State<ConsumptionHistoryScreen> createState() => _ConsumptionHistoryScreenState();
}

class _ConsumptionHistoryScreenState extends State<ConsumptionHistoryScreen> {
  final ServicesService _service = ServicesService();
  List<Map<String, dynamic>> _history = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final data = await _service.getMyConsumptionHistory();
    if (mounted) {
      setState(() {
        _history = data;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Mis Reservas', 
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 22, color: Colors.white, letterSpacing: 0.5)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Opacity(
              opacity: 0.8,
              child: Image.asset("assets/images/Fondo_Principal.png", fit: BoxFit.cover),
            ),
          ),
          SafeArea(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFFB2D826)))
                : _history.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        itemCount: _history.length,
                        itemBuilder: (context, index) => _buildHistoryCard(_history[index]),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.calendar_today_rounded, size: 80, color: const Color(0xFFB2D826).withValues(alpha: 0.5)),
          const SizedBox(height: 20),
          const Text("¡Tu mascota no tiene planes!", 
            style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 40, vertical: 10),
            child: Text("Encuentra cuidadores verificados ahora mismo.", 
              textAlign: TextAlign.center, style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFB2D826)),
            child: const Text("EXPLORAR", style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold)),
          )
        ],
      ),
    );
  }

  Widget _buildHistoryCard(Map<String, dynamic> booking) {
    final service = booking['services'] ?? {};
    final provider = booking['service_providers']?['profiles'] ?? {};
    final price = booking['price_at_booking']?.toString() ?? '0.00';
    final status = booking['status'] ?? 'pending';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10)],
      ),
      child: Row(
        children: [
          const CircleAvatar(backgroundColor: Color(0xFFF1F5F9), child: Icon(Icons.pets, color: Color(0xFF3B82F6))),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(service['name'] ?? 'Servicio', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Text("Cargado por: ${provider['full_name'] ?? 'Anonimo'}", style: const TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text("S/ $price", style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
              Text(status.toUpperCase(), style: const TextStyle(fontSize: 10, color: Color(0xFFF59E0B), fontWeight: FontWeight.bold)),
            ],
          )
        ],
      ),
    );
  }
}