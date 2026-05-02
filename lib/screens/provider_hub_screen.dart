import 'dart:async';
import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:petscania/services/services_service.dart';
import 'package:petscania/screens/identity_verification_screen.dart';
import 'package:petscania/screens/terms_screen.dart';

class ProviderHubScreen extends StatefulWidget {
  const ProviderHubScreen({super.key});
  @override
  State<ProviderHubScreen> createState() => _ProviderHubScreenState();
}

class _ProviderHubScreenState extends State<ProviderHubScreen> {
  final ServicesService _service = ServicesService();
  final SupabaseClient _supabase = Supabase.instance.client;

  Map<String, dynamic>? _profile;
  Map<String, dynamic>? _providerInfo;
  List<Map<String, dynamic>> _myServices = [];
  double _earnings = 0.0;
  bool _isLoadingData = true;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  // 🔥 CARGA ESTÁTICA Y SEGURA (Adiós bug de JSArray)
  Future<void> _loadDashboardData() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      final p = await _service.getFullProfileData();
      final provInfo = await _supabase.from('service_providers').select().eq('id', userId).maybeSingle();
      
      double tempEarnings = 0.0;
      try {
        final earningsResponse = await _supabase.rpc('get_provider_earnings', params: {'provider_uuid': userId});
        tempEarnings = (earningsResponse ?? 0).toDouble();
      } catch (e) {
        debugPrint("Ganancias error: $e");
      }
      
      List<Map<String, dynamic>> tempServices = [];
      try {
        final servicesResponse = await _supabase.from('services').select().eq('provider_id', userId);
        tempServices = List<Map<String, dynamic>>.from(servicesResponse);
      } catch (e) {
        debugPrint("Servicios error: $e");
      }
      
      if (mounted) {
        setState(() { 
          _profile = p; 
          _providerInfo = provInfo;
          _earnings = tempEarnings; 
          _myServices = tempServices; 
          _isLoadingData = false; 
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingData = false);
    }
  }

  void _showAddServiceModal() {
    final nameC = TextEditingController();
    final priceC = TextEditingController();
    final descC = TextEditingController();
    final discC = TextEditingController();
    String category = 'Baños'; 
    Uint8List? serviceImage;
    bool isPublishing = false; 

    showModalBottomSheet(
      context: context, 
      isScrollControlled: true, 
      backgroundColor: Colors.transparent, 
      builder: (ctx) => StatefulBuilder(
        builder: (BuildContext context, StateSetter setModalState) {
          return BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              height: MediaQuery.of(ctx).size.height * 0.9, 
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 20, 
                left: 20, right: 20, top: 20
              ),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A).withValues(alpha: 0.95),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(35)),
                border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.15))),
              ),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  mainAxisSize: MainAxisSize.min, 
                  children: [
                    Container(height: 5, width: 40, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(10))),
                    const SizedBox(height: 25),
                    Row(
                      children: [
                        IconButton(icon: const Icon(Icons.arrow_back_rounded, color: Colors.white), onPressed: () => Navigator.pop(ctx)),
                        const Expanded(child: Text("Publicar Servicio", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 22, letterSpacing: 0.5))),
                      ],
                    ),
                    const SizedBox(height: 25),
                    
                    GestureDetector(
                      onTap: () async {
                        final picker = ImagePicker();
                        final img = await picker.pickImage(source: ImageSource.gallery);
                        if (img != null) {
                          final bytes = await img.readAsBytes();
                          setModalState(() => serviceImage = bytes);
                        }
                      },
                      child: Container(
                        height: 180, width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.03), 
                          borderRadius: BorderRadius.circular(25), 
                          border: Border.all(color: Colors.white.withValues(alpha: 0.1))
                        ),
                        child: serviceImage != null 
                          ? ClipRRect(borderRadius: BorderRadius.circular(25), child: Image.memory(serviceImage!, fit: BoxFit.cover))
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center, 
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(15),
                                  decoration: BoxDecoration(color: const Color(0xFFB2D826).withValues(alpha: 0.2), shape: BoxShape.circle),
                                  child: const Icon(Icons.add_a_photo_rounded, color: Color(0xFFB2D826), size: 35)
                                ), 
                                const SizedBox(height: 15), 
                                const Text("Sube la foto del servicio", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16))
                              ]
                            ),
                      ),
                    ),
                    const SizedBox(height: 30),
                    
                    _modalField(nameC, "Nombre del Servicio", Icons.spa_rounded),
                    
                    Row(
                      children: [
                        Expanded(child: _modalField(priceC, "Precio (S/)", Icons.attach_money_rounded, isNum: true)),
                        const SizedBox(width: 15),
                        Expanded(child: _modalField(discC, "Etiqueta Descuento", Icons.local_offer_outlined)),
                      ],
                    ),
                    
                    Container(
                      margin: const EdgeInsets.only(bottom: 20),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8), 
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.03), 
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.1))
                      ), 
                      child: Row(
                        children: [
                          const Icon(Icons.pets_rounded, color: Color(0xFFB2D826), size: 22),
                          const SizedBox(width: 15),
                          Expanded(
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: category, 
                                dropdownColor: const Color(0xFF1E293B), 
                                isExpanded: true, 
                                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold), 
                                icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white38), 
                                items: ['Baños', 'Cortes', 'Paseos', 'Guardería', 'Entrenamiento'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(), 
                                onChanged: (v) => setModalState(() => category = v!),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    _modalField(descC, "Descripción del servicio", Icons.description_outlined),
                    
                    const SizedBox(height: 25),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFB2D826), 
                        minimumSize: const Size(double.infinity, 60), 
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        elevation: 5
                      ), 
                      onPressed: isPublishing ? null : () async { 
                        if (nameC.text.trim().isEmpty || priceC.text.trim().isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Completa nombre y precio"), backgroundColor: Colors.redAccent));
                          return;
                        } 
                        
                        final parsedPrice = double.tryParse(priceC.text.trim());
                        if (parsedPrice == null) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("El precio debe ser un número válido"), backgroundColor: Colors.redAccent));
                          return;
                        }

                        setModalState(() => isPublishing = true);

                        try {
                          await _service.addService(
                            name: nameC.text.trim(), 
                            price: parsedPrice, 
                            description: descC.text.trim(), 
                            category: category, 
                            discountLabel: discC.text.trim(), 
                            imageBytes: serviceImage
                          ); 
                          
                          if(context.mounted) { 
                            Navigator.pop(ctx); 
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("¡Servicio publicado con éxito!"), backgroundColor: Colors.green));
                            setState(() => _isLoadingData = true);
                            _loadDashboardData(); // Recargamos manual sin streams
                          } 
                        } catch (e) {
                          setModalState(() => isPublishing = false);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: Colors.redAccent, duration: const Duration(seconds: 4)));
                          }
                        }
                      }, 
                      child: isPublishing 
                          ? const SizedBox(height: 25, width: 25, child: CircularProgressIndicator(color: Color(0xFF0F172A), strokeWidth: 3))
                          : const Text("PUBLICAR SERVICIO", style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 0.5)),
                    ),
                    const SizedBox(height: 20),
                  ]
                ),
              ),
            ),
          );
        }
      ),
    );
  }

  Widget _modalField(TextEditingController c, String h, IconData icon, {bool isNum = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: TextField(
        controller: c, 
        keyboardType: isNum ? TextInputType.number : TextInputType.text, 
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold), 
        decoration: InputDecoration(
          hintText: h, 
          hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 14, fontWeight: FontWeight.normal), 
          prefixIcon: Icon(icon, color: const Color(0xFFB2D826), size: 22),
          filled: true, 
          fillColor: Colors.white.withValues(alpha: 0.03), 
          contentPadding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20), 
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: const BorderSide(color: Color(0xFFB2D826))),
        )
      ),
    );
  }

  void _showServicePreview(Map<String, dynamic> s) {
    showDialog(
      context: context, 
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent, 
        child: Container(
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)), 
          child: Column(
            mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, 
            children: [
              Container(
                height: 180, width: double.infinity, 
                decoration: const BoxDecoration(color: Color(0xFFF1F5F9), borderRadius: BorderRadius.vertical(top: Radius.circular(20))), 
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)), 
                  child: (s['image_url'] != null && s['image_url'].toString().isNotEmpty) ? Image.network(s['image_url'], fit: BoxFit.cover) : const Icon(Icons.spa_rounded, color: Colors.grey, size: 60),
                ),
              ), 
              Padding(
                padding: const EdgeInsets.all(20), 
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start, 
                  children: [
                    Text(_profile?['full_name']?.toString().toUpperCase() ?? "PROVEEDOR", style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Color(0xFF94A3B8))), 
                    const SizedBox(height: 5), 
                    Text(s['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Color(0xFF1E293B))), 
                    const SizedBox(height: 10), 
                    Text(s['description'] ?? 'Sin descripción detallada.', style: const TextStyle(color: Color(0xFF64748B), fontSize: 14)), 
                    const SizedBox(height: 20), 
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween, 
                      children: [
                        Text("S/ ${s['price']}", style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 22, color: Color(0xFF3B82F6))), 
                        ElevatedButton(
                          onPressed: () => Navigator.pop(ctx), 
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E293B), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))), 
                          child: const Text("Cerrar", style: TextStyle(color: Colors.white))
                        )
                      ]
                    ),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('CENTRO DE NEGOCIOS', style: TextStyle(fontWeight: FontWeight.w900, color: Colors.white, fontSize: 16, letterSpacing: 1.2)), 
        backgroundColor: Colors.transparent, elevation: 0, centerTitle: true, iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Stack(
        children: [
          Container(decoration: const BoxDecoration(image: DecorationImage(image: AssetImage("assets/images/Fondo_Principal.png"), fit: BoxFit.cover, opacity: 0.6))),
          SafeArea(
            child: _isLoadingData 
              ? const Center(child: CircularProgressIndicator(color: Color(0xFFB2D826)))
              : _buildMainContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent() {
    if (_providerInfo == null) {
      return _buildLockedState("Únete a la red", "Verifica tu identidad para empezar a ofrecer servicios.", Icons.security_rounded, "INICIAR VERIFICACIÓN", () => _goToIdentity(context));
    }
    
    final String status = _providerInfo!['verification_status'] ?? 'unverified';
    final bool isDniVerified = (status == 'verified') || (_providerInfo!['is_verified'] == true);
    final bool hasAcceptedTerms = _providerInfo!['accepted_services_terms'] == true;

    if (status == 'pending') {
      return _buildLockedState("En Revisión", "Tu DNI está siendo analizado por la IA.", Icons.hourglass_empty_rounded, "VER ESTADO", () => _goToIdentity(context));
    }
    if (status == 'rejected') {
      return _buildLockedState("Validación Fallida", "La IA no pudo leer tu DNI. Inténtalo de nuevo.", Icons.error_outline_rounded, "REINTENTAR", () => _goToIdentity(context));
    }
    
    if (isDniVerified && !hasAcceptedTerms) {
      return _buildLockedState("Último paso", "Solo falta firmar el acuerdo comercial para activar tu cuenta.", Icons.gavel_rounded, "FIRMAR TÉRMINOS", () => _goToTerms(context));
    }

    if (isDniVerified && hasAcceptedTerms) {
      return _buildVerifiedDashboard();
    }
    
    return _buildLockedState("Verificación requerida", "Completa los pasos para continuar.", Icons.lock_outline, "CONTINUAR", () => _goToIdentity(context));
  }

  void _goToIdentity(BuildContext context) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => IdentityVerificationScreen(userType: TermsUserType.values.first)));
  }

  void _goToTerms(BuildContext context) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => TermsScreen(userType: TermsUserType.values.first, isViewOnly: false)));
  }

  Widget _buildLockedState(String title, String subtitle, IconData icon, String btnText, VoidCallback onTap) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: const Color(0xFFB2D826), size: 80),
            const SizedBox(height: 20),
            Text(title, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900)),
            const SizedBox(height: 15),
            Text(subtitle, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white54, fontSize: 16, height: 1.4)),
            const SizedBox(height: 35),
            ElevatedButton(
              onPressed: onTap, 
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFB2D826), foregroundColor: const Color(0xFF0F172A), minimumSize: const Size(double.infinity, 55), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))), 
              child: Text(btnText, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildVerifiedDashboard() {
    final String rawAvatar = _profile?['avatar_url']?.toString().trim() ?? '';
    final String avatarUrl = rawAvatar;
    final String rawName = _profile?['full_name']?.toString().trim() ?? '';
    final String fullName = rawName.isNotEmpty ? rawName : "Socio PetScanIA";
    final String email = _supabase.auth.currentUser?.email ?? "Sin correo";
    final String fullDni = _providerInfo?['dni_number']?.toString() ?? "00000000";

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(24),
      children: [
        Container(
          padding: const EdgeInsets.all(25),
          decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(30), border: Border.all(color: Colors.white10)),
          child: Column(
            children: [
              CircleAvatar(
                radius: 45, 
                backgroundColor: const Color(0xFFB2D826), 
                backgroundImage: avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null, 
                child: avatarUrl.isEmpty 
                    ? Text(fullName[0].toUpperCase(), style: const TextStyle(fontSize: 40, color: Color(0xFF0F172A), fontWeight: FontWeight.bold)) 
                    : null, 
              ),
              const SizedBox(height: 15),
              Row(
                mainAxisAlignment: MainAxisAlignment.center, 
                children: [
                  Text(fullName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 22)), 
                  const SizedBox(width: 8), 
                  const Icon(Icons.verified, color: Color(0xFF3B82F6), size: 20),
                ],
              ),
              const SizedBox(height: 5),
              Text(email, style: const TextStyle(color: Colors.white54, fontSize: 13)),
              const SizedBox(height: 15),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8), 
                decoration: BoxDecoration(color: const Color(0xFFB2D826).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFFB2D826).withValues(alpha: 0.3))), 
                child: Row(
                  mainAxisSize: MainAxisSize.min, 
                  children: [
                    const Icon(Icons.badge_rounded, color: Color(0xFFB2D826), size: 16), const SizedBox(width: 8), 
                    Text("DNI: $fullDni", style: const TextStyle(color: Color(0xFFB2D826), fontWeight: FontWeight.bold, fontSize: 13)),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 25),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 20),
          decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFFB2D826), Color(0xFF8CAF1D)]), borderRadius: BorderRadius.circular(25)),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start, 
                children: [
                  const Text("GANANCIAS TOTALES", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Color(0xFF1E293B), letterSpacing: 1)), 
                  Text("S/ ${_earnings.toStringAsFixed(2)}", style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 32, color: Color(0xFF0F172A))),
                ]
              ),
              Container(
                padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), shape: BoxShape.circle), 
                child: const Icon(Icons.account_balance_wallet_rounded, color: Color(0xFF0F172A), size: 30),
              )
            ],
          ),
        ),
        const SizedBox(height: 35),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween, 
          children: [
            const Text("MIS SERVICIOS", style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 1)), 
            ElevatedButton.icon(
              onPressed: _showAddServiceModal, icon: const Icon(Icons.add, size: 16), label: const Text("NUEVO"), 
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFB2D826), foregroundColor: const Color(0xFF0F172A), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)))
            )
          ]
        ),
        const SizedBox(height: 15),
        ..._myServices.map((s) => _buildServiceTile(s)),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildServiceTile(Map<String, dynamic> s) {
    return GestureDetector(
      onTap: () => _showServicePreview(s),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white10)),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
          leading: Container(
            height: 45, width: 45, decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(12)), 
            child: s['image_url'] != null && s['image_url'].toString().isNotEmpty ? ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.network(s['image_url'], fit: BoxFit.cover)) : const Icon(Icons.spa_rounded, color: Color(0xFFB2D826)),
          ),
          title: Text(s['name'] ?? '', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          subtitle: Text("${s['category']} • S/ ${s['price']}", style: const TextStyle(color: Color(0xFFB2D826), fontSize: 12, fontWeight: FontWeight.w600)),
          trailing: IconButton(icon: const Icon(Icons.delete_outline, color: Colors.redAccent), onPressed: () async { 
            await _service.deleteService(s['id']); 
            setState(() => _isLoadingData = true);
            _loadDashboardData(); 
          }),
        ),
      ),
    );
  }
}