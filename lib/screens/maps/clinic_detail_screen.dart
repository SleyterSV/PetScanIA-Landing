import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:petscania/services/places_service.dart';

class ClinicDetailScreen extends StatefulWidget {
  final Map<String, dynamic> clinic;
  final double distance;

  const ClinicDetailScreen({super.key, required this.clinic, required this.distance});

  @override
  State<ClinicDetailScreen> createState() => _ClinicDetailScreenState();
}

class _ClinicDetailScreenState extends State<ClinicDetailScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;
  List<dynamic> _promotions = [];
  bool _isLoadingPromos = true;
  bool _isPreparingBooking = false; 

  @override
  void initState() {
    super.initState();
    _loadPromotions();
  }

  Future<void> _loadPromotions() async {
    try {
      final data = await _supabase.from('flash_deals').select('*').eq('clinic_id', widget.clinic['id']).eq('active', true);
      if (mounted) setState(() { _promotions = data; _isLoadingPromos = false; });
    } catch (e) {
      if (mounted) setState(() => _isLoadingPromos = false);
    }
  }

  Future<void> _handleBookingClick() async {
    setState(() => _isPreparingBooking = true);
    final userId = _supabase.auth.currentUser?.id ?? '';
    
    List<dynamic> fetchedPets = [];
    List<dynamic> fetchedDiagnoses = [];

    try {
      fetchedPets = await _supabase.from('pets').select('id, name').eq('owner_id', userId);
      
      for (var pet in fetchedPets) {
        final scans = await _supabase
            .from('medical_scans')
            .select('id, mascota_nombre, ai_diagnosis, created_at')
            .eq('pet_id', pet['id'])
            .order('created_at', ascending: false)
            .limit(3);
        fetchedDiagnoses.addAll(scans);
      }
    } catch (e) {
      debugPrint("Error cargando historial de IA: $e");
    }

    if (!mounted) return;
    setState(() => _isPreparingBooking = false);
    _openBookingSheet(fetchedPets, fetchedDiagnoses);
  }

  void _openBookingSheet(List<dynamic> myPets, List<dynamic> myDiagnoses) {
    DateTime? selectedDate;
    TimeOfDay? selectedTime;
    final detailsController = TextEditingController();
    bool isBooking = false;
    
    String? selectedPetId = myPets.isNotEmpty ? myPets[0]['id'].toString() : null;
    String? selectedDiagnosisId;
    
    String selectedServiceType = 'Consulta General';
    final List<String> serviceTypes = [
      'Consulta General', 
      'Dermatología / Alergias', 
      'Problemas Gástricos', 
      'Vacunación', 
      'Desparasitación',
      'Emergencia', 
      'Revisión de IA'
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            height: MediaQuery.of(context).size.height * 0.88,
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A), 
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(35), topRight: Radius.circular(35)),
              border: Border.all(color: const Color(0x4D38BDF8), width: 1.5), 
            ),
            child: Stack(
              children: [
                Positioned.fill(
                  child: Image.asset('assets/images/Fondo_Principal.png', fit: BoxFit.cover, opacity: const AlwaysStoppedAnimation(0.08)),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(30, 20, 30, MediaQuery.of(context).viewInsets.bottom + 20),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Center(child: Container(width: 40, height: 5, decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(10)))),
                        const SizedBox(height: 10),
                        Align(
                          alignment: Alignment.topRight,
                          child: IconButton(icon: const Icon(Icons.close, color: Colors.white70), onPressed: () => Navigator.pop(modalContext)),
                        ),
                        
                        const Text("Solicitud de Cita", textAlign: TextAlign.center, style: TextStyle(fontSize: 16, color: Color(0xFF94A3B8), fontWeight: FontWeight.bold, letterSpacing: 1)),
                        const SizedBox(height: 4),
                        Text(widget.clinic['name'], textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 26)),
                        const SizedBox(height: 35),

                        if (myPets.isNotEmpty)
                          DropdownButtonFormField<String>(
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: Colors.white.withValues(alpha: 0.05),
                              prefixIcon: const Icon(Icons.pets, color: Color(0xFF38BDF8)),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                            ),
                            dropdownColor: const Color(0xFF1E293B),
                            icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white),
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 16),
                            value: selectedPetId,
                            items: myPets.map((pet) => DropdownMenuItem<String>(value: pet['id'].toString(), child: Text(pet['name'].toString(), style: const TextStyle(color: Colors.white)))).toList(),
                            onChanged: (val) => setModalState(() => selectedPetId = val),
                          )
                        else
                           const Text("⚠️ Agrega una mascota en tu perfil primero.", style: TextStyle(color: Colors.redAccent)),
                        
                        const SizedBox(height: 20),

                        const Text("Motivo Principal", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.white.withValues(alpha: 0.05),
                            prefixIcon: const Icon(Icons.medical_information, color: Color(0xFF10B981)),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                          ),
                          dropdownColor: const Color(0xFF1E293B),
                          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white),
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 16),
                          value: selectedServiceType,
                          items: serviceTypes.map((type) => DropdownMenuItem<String>(value: type, child: Text(type, style: const TextStyle(color: Colors.white)))).toList(),
                          onChanged: (val) => setModalState(() => selectedServiceType = val!),
                        ),
                        const SizedBox(height: 20),

                        const Text("Descripción o Síntomas", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
                        const SizedBox(height: 8),
                        _buildInputField("Ej. Tiene manchas en la piel desde ayer...", Icons.edit_note, detailsController, maxLines: 2),
                        const SizedBox(height: 30),

                        const Text("Adjuntar Análisis de IA", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
                        const SizedBox(height: 10),
                        if (myDiagnoses.isNotEmpty)
                          DropdownButtonFormField<String>(
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: Colors.white.withValues(alpha: 0.05),
                              prefixIcon: const Icon(Icons.memory, color: Color(0xFF38BDF8)),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                            ),
                            dropdownColor: const Color(0xFF1E293B),
                            icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white),
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                            hint: const Text("Seleccionar un reporte reciente (Opcional)", style: TextStyle(color: Colors.grey)),
                            value: selectedDiagnosisId,
                            items: myDiagnoses.map((diag) => DropdownMenuItem<String>(
                              value: diag['id'].toString(), 
                              child: SizedBox(
                                width: 220, 
                                child: Text("${diag['mascota_nombre']} - ${diag['ai_diagnosis']}", style: const TextStyle(color: Colors.white), maxLines: 1, overflow: TextOverflow.ellipsis)
                              )
                            )).toList(),
                            onChanged: (val) => setModalState(() => selectedDiagnosisId = val),
                          )
                        else
                          const Text("No tienes análisis de IA recientes con esta mascota.", style: TextStyle(color: Color(0xFF94A3B8), fontStyle: FontStyle.italic, fontSize: 13)),
                        
                        const SizedBox(height: 30),

                        const Text("Fecha y Hora", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () async {
                                  final date = await showDatePicker(
                                    context: context,
                                    initialDate: DateTime.now().add(const Duration(days: 1)),
                                    firstDate: DateTime.now(),
                                    lastDate: DateTime.now().add(const Duration(days: 60)),
                                    builder: (context, child) => Theme(
                                      data: ThemeData.dark().copyWith(
                                        colorScheme: const ColorScheme.dark(
                                          primary: Color(0xFF10B981), 
                                          onPrimary: Colors.white, 
                                          surface: Color(0xFF1E293B), 
                                          onSurface: Colors.white,
                                        ), dialogTheme: DialogThemeData(backgroundColor: const Color(0xFF0F172A)),
                                      ),
                                      child: child!,
                                    ),
                                  );
                                  if (date != null) setModalState(() => selectedDate = date);
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.white.withValues(alpha: 0.1))),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.calendar_month, color: Color(0xFF10B981), size: 20),
                                      const SizedBox(width: 8),
                                      Text(selectedDate != null ? "${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}" : "Día", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: GestureDetector(
                                onTap: () async {
                                  final time = await showTimePicker(
                                    context: context,
                                    initialTime: const TimeOfDay(hour: 10, minute: 0),
                                    builder: (context, child) => Theme(
                                      data: ThemeData.dark().copyWith(
                                        colorScheme: const ColorScheme.dark(
                                          primary: Color(0xFF38BDF8), 
                                          onPrimary: Colors.white, 
                                          surface: Color(0xFF1E293B),
                                          onSurface: Colors.white,
                                        ), dialogTheme: DialogThemeData(backgroundColor: const Color(0xFF0F172A)),
                                      ), 
                                      child: child!
                                    ),
                                  );
                                  if (time != null) setModalState(() => selectedTime = time);
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.white.withValues(alpha: 0.1))),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.access_time, color: Color(0xFF38BDF8), size: 20),
                                      const SizedBox(width: 8),
                                      Text(selectedTime != null ? selectedTime!.format(context) : "Hora", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 50),

                        SizedBox(
                          width: double.infinity,
                          height: 60,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF10B981),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                              elevation: 10,
                              shadowColor: const Color(0xFF10B981).withValues(alpha: 0.5),
                            ),
                            onPressed: (isBooking || selectedPetId == null) ? null : () async {
                              if (selectedDate == null || selectedTime == null) {
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Faltan datos: Por favor indica fecha y hora.')));
                                return;
                              }

                              setModalState(() => isBooking = true);
                              final nav = Navigator.of(modalContext);
                              final messenger = ScaffoldMessenger.of(modalContext);

                              try {
                                // 1. Creamos la fecha local
                                final DateTime combinedDateTime = DateTime(
                                  selectedDate!.year, selectedDate!.month, selectedDate!.day, 
                                  selectedTime!.hour, selectedTime!.minute
                                );

                                // 🚀 2. LA SOLUCIÓN: .toUtc() FUERZA EL CAMBIO DE ZONA HORARIA ANTES DE ENVIAR
                                await _supabase.from('appointments').insert({
                                  'clinic_id': widget.clinic['id'],
                                  'user_id': _supabase.auth.currentUser?.id,
                                  'pet_id': selectedPetId, 
                                  'type': selectedServiceType, 
                                  'title': detailsController.text.trim().isEmpty ? "Sin detalles" : detailsController.text.trim(), 
                                  'appointment_date': combinedDateTime.toUtc().toIso8601String(), 
                                  'status': 'pending' 
                                });

                                if (selectedDiagnosisId != null) {
                                  await _supabase.from('medical_scans').update({'clinic_id': widget.clinic['id']}).eq('id', selectedDiagnosisId!);
                                }

                                if (!mounted) return;
                                nav.pop(); 
                                messenger.showSnackBar(
                                  SnackBar(
                                    content: Text(selectedDiagnosisId != null ? '¡Cita y Reporte IA enviados a la clínica!' : '¡Cita solicitada exitosamente!'),
                                    backgroundColor: const Color(0xFF10B981),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                );
                              } catch (e) {
                                debugPrint("Error reservando: $e");
                                if (!mounted) return;
                                messenger.showSnackBar(const SnackBar(content: Text('Error al procesar la reserva.')));
                              } finally {
                                if (mounted) setModalState(() => isBooking = false);
                              }
                            },
                            child: isBooking 
                              ? const SizedBox(height: 25, width: 25, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
                              : const Text("CONFIRMAR CITA", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: 1)),
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        }
      ),
    );
  }

  Widget _buildInputField(String hint, IconData icon, TextEditingController controller, {int maxLines = 1}) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500, fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey[500], fontWeight: FontWeight.normal),
        prefixIcon: Icon(icon, color: const Color(0xFF38BDF8)),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.05),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color emeraldSuccess = Color(0xFF10B981);
    List<dynamic> servicesList = widget.clinic['services_json'] ?? [];

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(child: Image.asset('assets/images/Fondo_Principal.png', fit: BoxFit.cover)),
          Positioned.fill(child: Container(color: const Color(0x66000000))), 

          CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 300.0,
                pinned: true,
                backgroundColor: Colors.transparent,
                elevation: 0,
                leading: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(50),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        color: const Color(0x4D000000),
                        child: IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20), onPressed: () => Navigator.pop(context)),
                      ),
                    ),
                  ),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.network(
                        widget.clinic['logo_url'] ?? widget.clinic['image_url'] ?? 'https://images.unsplash.com/photo-1599443015574-be5fe8a05783?q=80&w=600&auto=format&fit=crop',
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(color: Colors.grey[200], child: const Icon(Icons.local_hospital, size: 80, color: Colors.grey)),
                      ),
                      Container(decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.transparent, Color(0xE60F172A)]))),
                    ],
                  ),
                ),
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 120), 
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildGlassCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(child: Text(widget.clinic['name'] ?? 'Clínica', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.white, height: 1.1))),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(color: const Color(0x3310B981), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0x8010B981))),
                                  child: Row(
                                    children: [
                                      Text("${widget.clinic['rating'] ?? '4.9'}", style: const TextStyle(fontWeight: FontWeight.w900, color: emeraldSuccess, fontSize: 16)),
                                      const SizedBox(width: 4),
                                      const Icon(Icons.star_rounded, color: emeraldSuccess, size: 18),
                                    ],
                                  ),
                                )
                              ],
                            ),
                            const SizedBox(height: 15),
                            Row(
                              children: [
                                const Icon(Icons.location_on_rounded, size: 20, color: emeraldSuccess),
                                const SizedBox(width: 6),
                                Text(GooglePlacesService.formatDistance(widget.distance), style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.white, fontSize: 15)),
                                const Text(" • ", style: TextStyle(color: Colors.grey)),
                                Expanded(child: Text(widget.clinic['address'] ?? 'Dirección no especificada', style: const TextStyle(color: Color(0xFFE2E8F0), fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis)),
                              ],
                            ),
                            const Padding(padding: EdgeInsets.symmetric(vertical: 15), child: Divider(color: Color(0x33FFFFFF))),
                            const Text("Sobre Nosotros", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white)),
                            const SizedBox(height: 8),
                            Text(widget.clinic['description'] ?? "Centro veterinario de alta tecnología.", style: const TextStyle(color: Color(0xFFE2E8F0), height: 1.5, fontSize: 14)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 15),

                      _buildGlassCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("Servicios y Tarifas", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white)),
                            const SizedBox(height: 15),
                            servicesList.isEmpty 
                              ? const Text("Servicios no detallados.", style: TextStyle(color: Color(0xFF94A3B8), fontStyle: FontStyle.italic))
                              : Column(
                                  children: servicesList.map((service) => Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          children: [
                                            const Icon(Icons.check_circle_rounded, color: emeraldSuccess, size: 18),
                                            const SizedBox(width: 8),
                                            Text(service['name'] ?? 'Servicio', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                                          ],
                                        ),
                                        Text(service['price'] ?? 'Consultar', style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF38BDF8), fontSize: 16)),
                                      ],
                                    ),
                                  )).toList(),
                                ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 15),

                      _buildGlassCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.bolt_rounded, color: Colors.orange, size: 24),
                                SizedBox(width: 5),
                                Text("Flash Deals", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white)),
                              ],
                            ),
                            const SizedBox(height: 15),
                            _isLoadingPromos 
                              ? const Center(child: CircularProgressIndicator(color: emeraldSuccess))
                              : _promotions.isEmpty
                                ? const Text("No hay promociones flash.", style: TextStyle(color: Color(0xFF94A3B8)))
                                : Column(children: _promotions.map((promo) => _buildPremiumPromoCard(promo)).toList()),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          Positioned(
            bottom: 0, left: 0, right: 0,
            child: ClipRRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(25, 15, 25, 30),
                  decoration: const BoxDecoration(
                    color: Color(0x990F172A), 
                    border: Border(top: BorderSide(color: Color(0x1AFFFFFF))),
                  ),
                  child: SizedBox(
                    height: 60,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: emeraldSuccess,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)), 
                        elevation: 10,
                        shadowColor: const Color(0x8010B981),
                      ),
                      onPressed: _isPreparingBooking ? null : _handleBookingClick, 
                      child: _isPreparingBooking 
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
                          : const Text("AGENDAR CITA AHORA", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 1)),
                    ),
                  ),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildGlassCard({required Widget child}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0x1AFFFFFF), 
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0x33FFFFFF), width: 1.5),
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _buildPremiumPromoCard(Map<String, dynamic> promo) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFFF59E0B), Color(0xFFFBBF24)]), 
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: Color(0x33F59E0B), blurRadius: 10, offset: Offset(0, 4))],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 25),
            decoration: const BoxDecoration(
              color: Color(0x33FFFFFF), 
              border: Border(right: BorderSide(color: Color(0x4DFFFFFF), width: 1, style: BorderStyle.solid))
            ),
            child: Text("-${promo['discount']}%", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 22)),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(promo['title'], style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Colors.white)),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
                    child: Text("Válido hasta: ${promo['valid_until']}", style: const TextStyle(fontSize: 11, color: Color(0xFFF59E0B), fontWeight: FontWeight.bold)),
                  )
                ],
              ),
            )
          )
        ],
      ),
    );
  }
}