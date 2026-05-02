import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:petscania/screens/home_screen.dart';
import 'package:petscania/theme/petscania_brand.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:table_calendar/table_calendar.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;

  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  List<Map<String, dynamic>> _appointments = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _fetchRealAppointments();
  }

  Future<void> _fetchRealAppointments() async {
    final userId = _supabase.auth.currentUser?.id;

    if (userId == null) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
      return;
    }

    try {
      final data = await _supabase.from('appointments').select('''
        *,
        clinics (name)
      ''').eq('user_id', userId).order('appointment_date', ascending: true);

      if (mounted) {
        setState(() {
          _appointments = List<Map<String, dynamic>>.from(data);
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error cargando agenda: $e");

      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _updateAppointmentStatus(String id, String newStatus) async {
    setState(() => _isLoading = true);

    try {
      await _supabase
          .from('appointments')
          .update({'status': newStatus}).eq('id', id);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            newStatus == 'aprobada'
                ? 'Cita confirmada exitosamente'
                : 'Cita cancelada',
          ),
          backgroundColor: newStatus == 'aprobada'
              ? const Color(0xFF16A34A)
              : const Color(0xFFD84A4A),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      );

      await _fetchRealAppointments();
    } catch (e) {
      debugPrint("Error actualizando estado: $e");

      if (!mounted) return;

      setState(() => _isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Error al actualizar la cita.'),
          backgroundColor: const Color(0xFFD84A4A),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      );
    }
  }

  List<String> _getEventsForDay(DateTime day) {
    List<String> events = [];

    for (var appt in _appointments) {
      if (appt['status'] == 'aprobada' || appt['status'] == 'confirmed') {
        DateTime apptDate = DateTime.parse(
          appt['appointment_date'],
        ).toLocal();

        if (apptDate.year == day.year &&
            apptDate.month == day.month &&
            apptDate.day == day.day) {
          events.add(appt['type'] ?? appt['title'] ?? 'Cita');
        }
      }
    }

    return events;
  }

  void _navigateToMapToBook() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (context) => const HomeScreen(),
      ),
      (Route<dynamic> route) => false,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text(
          "Selecciona una Clínica Aliada en el mapa para agendar.",
        ),
        backgroundColor: PetScaniaColors.royalBlue,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );
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
    List<Map<String, dynamic>> sortedAppointments = List.from(_appointments);

    sortedAppointments.sort(
      (a, b) => DateTime.parse(a['appointment_date']).compareTo(
        DateTime.parse(b['appointment_date']),
      ),
    );

    return Scaffold(
      backgroundColor: PetScaniaColors.mist,
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'calendar_fab',
        onPressed: _navigateToMapToBook,
        backgroundColor: PetScaniaColors.royalBlue,
        elevation: 8,
        icon: const Icon(
          Icons.add_rounded,
          color: Colors.white,
        ),
        label: const Text(
          "Nueva Cita",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      body: Stack(
        children: [
          Container(
            height: 330,
            decoration: const BoxDecoration(
              gradient: PetScaniaDecor.primaryGradient,
            ),
          ),

          Positioned(
            top: -45,
            left: -35,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
            ),
          ),

          Positioned(
            top: 75,
            right: -40,
            child: Container(
              width: 190,
              height: 190,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 14, 18, 12),
                  child: Row(
                    children: [
                      _buildBackButton(),

                      const SizedBox(width: 12),

                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Mi Agenda',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 25,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            SizedBox(height: 5),
                            Text(
                              'Revisa tus citas y próximos eventos.',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Color(0xD8FFFFFF),
                                height: 1.3,
                                fontWeight: FontWeight.w600,
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

                Expanded(
                  child: Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      color: PetScaniaColors.mist,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(34),
                      ),
                    ),
                    child: _isLoading
                        ? const Center(
                            child: CircularProgressIndicator(
                              color: PetScaniaColors.royalBlue,
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _fetchRealAppointments,
                            color: PetScaniaColors.royalBlue,
                            child: SingleChildScrollView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: const EdgeInsets.fromLTRB(
                                18,
                                22,
                                18,
                                110,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildCalendar(),

                                  const SizedBox(height: 24),

                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text(
                                        "Próximos Eventos",
                                        style: TextStyle(
                                          color: PetScaniaColors.ink,
                                          fontSize: 20,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 7,
                                        ),
                                        decoration: BoxDecoration(
                                          color: PetScaniaColors.cloud,
                                          borderRadius:
                                              BorderRadius.circular(999),
                                        ),
                                        child: Text(
                                          "${sortedAppointments.length} citas",
                                          style: const TextStyle(
                                            color: PetScaniaColors.royalBlue,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w900,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 14),

                                  if (sortedAppointments.isEmpty)
                                    _buildEmptyState()
                                  else
                                    Column(
                                      children: sortedAppointments.map((appt) {
                                        return _buildEventCard(appt);
                                      }).toList(),
                                    ),
                                ],
                              ),
                            ),
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

  Widget _buildCalendar() {
    return PetScaniaSurfaceCard(
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 14),
      borderRadius: BorderRadius.circular(30),
      child: TableCalendar(
        firstDay: DateTime.utc(2020, 10, 16),
        lastDay: DateTime.utc(2030, 3, 14),
        focusedDay: _focusedDay,
        calendarFormat: _calendarFormat,
        selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
        eventLoader: _getEventsForDay,
        onDaySelected: (selectedDay, focusedDay) {
          setState(() {
            _selectedDay = selectedDay;
            _focusedDay = focusedDay;
          });
        },
        onFormatChanged: (format) {
          if (_calendarFormat != format) {
            setState(() => _calendarFormat = format);
          }
        },
        calendarStyle: CalendarStyle(
          outsideDaysVisible: false,
          selectedDecoration: const BoxDecoration(
            color: PetScaniaColors.royalBlue,
            shape: BoxShape.circle,
          ),
          todayDecoration: BoxDecoration(
            color: PetScaniaColors.skyBlue.withOpacity(0.55),
            shape: BoxShape.circle,
          ),
          markerDecoration: const BoxDecoration(
            color: Color(0xFF16A34A),
            shape: BoxShape.circle,
          ),
          defaultTextStyle: const TextStyle(
            color: PetScaniaColors.ink,
            fontWeight: FontWeight.w700,
          ),
          weekendTextStyle: const TextStyle(
            color: PetScaniaColors.royalBlue,
            fontWeight: FontWeight.w800,
          ),
          selectedTextStyle: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
          ),
          todayTextStyle: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
          ),
        ),
        daysOfWeekStyle: DaysOfWeekStyle(
          weekdayStyle: TextStyle(
            color: PetScaniaColors.ink.withOpacity(0.55),
            fontWeight: FontWeight.w900,
          ),
          weekendStyle: TextStyle(
            color: PetScaniaColors.royalBlue.withOpacity(0.75),
            fontWeight: FontWeight.w900,
          ),
        ),
        headerStyle: const HeaderStyle(
          formatButtonVisible: false,
          titleCentered: true,
          titleTextStyle: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w900,
            color: PetScaniaColors.ink,
          ),
          leftChevronIcon: Icon(
            Icons.chevron_left_rounded,
            color: PetScaniaColors.royalBlue,
            size: 30,
          ),
          rightChevronIcon: Icon(
            Icons.chevron_right_rounded,
            color: PetScaniaColors.royalBlue,
            size: 30,
          ),
        ),
      ),
    );
  }

  Widget _buildEventCard(Map<String, dynamic> appt) {
    DateTime apptDate = DateTime.parse(appt['appointment_date']).toLocal();

    String formattedDate = DateFormat('dd/MM/yyyy').format(apptDate);
    String formattedTime = DateFormat('hh:mm a').format(apptDate);

    String status = appt['status'] ?? 'pendiente';

    Color statusColor;
    String statusLabel;
    IconData statusIcon;

    switch (status) {
      case 'aprobada':
      case 'confirmed':
        statusColor = const Color(0xFF16A34A);
        statusLabel = 'Confirmada';
        statusIcon = Icons.check_circle_rounded;
        break;

      case 'reprogramada':
        statusColor = PetScaniaColors.royalBlue;
        statusLabel = 'Reprogramada';
        statusIcon = Icons.update_rounded;
        break;

      case 'cancelada':
        statusColor = const Color(0xFFD84A4A);
        statusLabel = 'Cancelada';
        statusIcon = Icons.cancel_rounded;
        break;

      default:
        statusColor = const Color(0xFFF59E0B);
        statusLabel = 'En Espera';
        statusIcon = Icons.access_time_rounded;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: PetScaniaSurfaceCard(
        padding: EdgeInsets.zero,
        borderRadius: BorderRadius.circular(26),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.11),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Icon(
                      statusIcon,
                      color: statusColor,
                      size: 29,
                    ),
                  ),

                  const SizedBox(width: 14),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          appt['type'] ?? 'Consulta General',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: PetScaniaColors.ink,
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                          ),
                        ),

                        const SizedBox(height: 4),

                        Text(
                          '"${appt['title'] ?? appt['reason'] ?? ''}"',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: PetScaniaColors.ink.withOpacity(0.58),
                            fontStyle: FontStyle.italic,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),

                        const SizedBox(height: 8),

                        Text(
                          appt['clinics']?['name'] ?? 'Clínica',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: PetScaniaColors.ink.withOpacity(0.48),
                            fontWeight: FontWeight.w900,
                            fontSize: 11,
                            letterSpacing: 0.5,
                          ),
                        ),

                        const SizedBox(height: 5),

                        Row(
                          children: [
                            Icon(
                              Icons.calendar_month_rounded,
                              size: 15,
                              color: PetScaniaColors.ink.withOpacity(0.50),
                            ),
                            const SizedBox(width: 5),
                            Expanded(
                              child: Text(
                                "$formattedDate, $formattedTime",
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color:
                                      PetScaniaColors.ink.withOpacity(0.72),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 10),

                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.10),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      statusLabel,
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.w900,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            if (status == 'reprogramada')
              Container(
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
                decoration: BoxDecoration(
                  color: PetScaniaColors.cloud.withOpacity(0.70),
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(26),
                  ),
                  border: Border(
                    top: BorderSide(
                      color: PetScaniaColors.line.withOpacity(0.9),
                    ),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "La clínica ha sugerido este nuevo horario.",
                      style: TextStyle(
                        fontSize: 12,
                        color: PetScaniaColors.royalBlue,
                        fontWeight: FontWeight.w900,
                      ),
                    ),

                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 44,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: const Color(0xFF16A34A),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                onPressed: () => _updateAppointmentStatus(
                                  appt['id'],
                                  'aprobada',
                                ),
                                child: const Text(
                                  "Aceptar",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(width: 10),

                        Expanded(
                          child: SizedBox(
                            height: 44,
                            child: TextButton(
                              style: TextButton.styleFrom(
                                foregroundColor: const Color(0xFFD84A4A),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  side: const BorderSide(
                                    color: Color(0xFFD84A4A),
                                  ),
                                ),
                              ),
                              onPressed: () => _updateAppointmentStatus(
                                appt['id'],
                                'cancelada',
                              ),
                              child: const Text(
                                "Rechazar",
                                style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 13,
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
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 34),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: PetScaniaColors.line),
        boxShadow: PetScaniaDecor.softShadow,
      ),
      child: Column(
        children: [
          Container(
            width: 84,
            height: 84,
            decoration: BoxDecoration(
              color: PetScaniaColors.cloud,
              borderRadius: BorderRadius.circular(26),
            ),
            child: const Icon(
              Icons.event_available_rounded,
              color: PetScaniaColors.royalBlue,
              size: 42,
            ),
          ),

          const SizedBox(height: 16),

          const Text(
            "No tienes citas programadas.",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: PetScaniaColors.ink,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            "Cuando agendes una cita con una clínica aliada, aparecerá aquí en tu agenda.",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: PetScaniaColors.ink.withOpacity(0.65),
              height: 1.45,
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 20),

          SizedBox(
            height: 48,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: PetScaniaDecor.primaryGradient,
                borderRadius: BorderRadius.circular(18),
              ),
              child: ElevatedButton.icon(
                onPressed: _navigateToMapToBook,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                icon: const Icon(
                  Icons.add_rounded,
                  color: Colors.white,
                ),
                label: const Text(
                  "Agendar una cita",
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
}