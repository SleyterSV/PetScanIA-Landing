import 'package:flutter/material.dart';
import 'package:petscania/services/user_service.dart';

class UpcomingAppointmentCard extends StatefulWidget {
  final VoidCallback onEmptyTap;

  const UpcomingAppointmentCard({super.key, required this.onEmptyTap});

  @override
  State<UpcomingAppointmentCard> createState() => _UpcomingAppointmentCardState();
}

class _UpcomingAppointmentCardState extends State<UpcomingAppointmentCard> {
  final UserService _service = UserService();
  Map<String, dynamic>? _nextAppointment;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNextAppointment();
  }

  Future<void> _loadNextAppointment() async {
    final appointment = await _service.getNextUpcomingAppointment();
    if (mounted) {
      setState(() {
        _nextAppointment = appointment;
        _isLoading = false;
      });
    }
  }

  String _formatAppointmentDate(String dateString) {
    DateTime date = DateTime.parse(dateString).toLocal();
    DateTime now = DateTime.now();
    DateTime tomorrow = now.add(const Duration(days: 1));

    String timeFormated = "${date.hour > 12 ? date.hour - 12 : (date.hour == 0 ? 12 : date.hour)}:${date.minute.toString().padLeft(2, '0')} ${date.hour >= 12 ? 'PM' : 'AM'}";

    if (date.year == now.year && date.month == now.month && date.day == now.day) {
      return "Hoy • $timeFormated";
    } else if (date.year == tomorrow.year && date.month == tomorrow.month && date.day == tomorrow.day) {
      return "Mañana • $timeFormated";
    } else {
      return "${date.day}/${date.month}/${date.year} • $timeFormated";
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox(height: 80, child: Center(child: CircularProgressIndicator(color: Colors.white)));
    }

    if (_nextAppointment == null) {
      return GestureDetector(
        onTap: widget.onEmptyTap, 
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white24),
          ),
          child: const Row(
            children: [
              Icon(Icons.local_hospital_rounded, color: Color(0xFFEF4444), size: 30),
              SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("No tienes citas próximas", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                    SizedBox(height: 4),
                    Text("Toca aquí para visitar nuestras clínicas aliadas.", style: TextStyle(color: Colors.white70, fontSize: 12)),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios_rounded, color: Colors.white54, size: 16),
            ],
          ),
        ),
      );
    }

    final title = _nextAppointment!['title'] ?? 'Cita Programada';
    final dateStr = _nextAppointment!['appointment_date'];
    final formattedDate = _formatAppointmentDate(dateStr);
    bool isVaccine = title.toLowerCase().contains('vacuna');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 15, offset: const Offset(0, 8))]
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF7ED),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(
              isVaccine ? Icons.vaccines_rounded : Icons.pets_rounded, 
              color: const Color(0xFFF97316),
              size: 28
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Color(0xFF1E293B)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.access_time_rounded, color: Color(0xFF64748B), size: 14),
                    const SizedBox(width: 5),
                    Text(
                      formattedDate,
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(color: const Color(0xFFF97316), borderRadius: BorderRadius.circular(20)),
            child: const Text("Próximo", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
          ),
        ],
      ),
    );
  }
}