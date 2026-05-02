import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:petscania/services/services_service.dart';
import 'package:petscania/screens/terms_screen.dart'; // Importamos la pantalla de términos

class IdentityVerificationScreen extends StatefulWidget {
  final TermsUserType userType; // Para saber si viene de Marketplace o Servicios

  const IdentityVerificationScreen({
    super.key,
    required this.userType,
  });

  @override
  State<IdentityVerificationScreen> createState() => _IdentityVerificationScreenState();
}

class _IdentityVerificationScreenState extends State<IdentityVerificationScreen> {
  final ServicesService _service = ServicesService();
  final SupabaseClient _supabase = Supabase.instance.client;
  final ImagePicker _picker = ImagePicker();

  bool _isUploading = false;
  final _dniController = TextEditingController();
  Uint8List? _dniFront;
  Uint8List? _dniBack;

  @override
  void dispose() {
    _dniController.dispose();
    super.dispose();
  }

  // Enviar datos a Supabase/IA
  Future<void> _submitVerification() async {
    if (_dniController.text.isEmpty || _dniFront == null || _dniBack == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Complete todos los campos y suba ambas fotos"), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isUploading = true);

    try {
      await _service.submitVerificationRequest(
        dniNumber: _dniController.text,
        dniFrontBytes: _dniFront!,
        dniBackBytes: _dniBack!,
      );
      // No hacemos setState aquí porque el StreamBuilder se encargará de cambiar la vista a "pending"
    } catch (e) {
      debugPrint("Error enviando DNI: $e");
      if (mounted) {
        setState(() => _isUploading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: ${e.toString()}"), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final userId = _supabase.auth.currentUser?.id;

    if (userId == null) {
      return const Scaffold(body: Center(child: Text("Debes iniciar sesión primero")));
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('VALIDACIÓN DE IDENTIDAD', style: TextStyle(fontWeight: FontWeight.w900, color: Colors.white, fontSize: 16, letterSpacing: 1.2)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          // Fondo
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage("assets/images/Fondo_Principal.png"),
                fit: BoxFit.cover,
                opacity: 0.6,
              ),
            ),
          ),
          SafeArea(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _supabase.from('service_providers').stream(primaryKey: ['id']).eq('id', userId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Color(0xFFB2D826)));
                }

                final data = snapshot.data ?? [];

                // Si no hay registro previo, mostramos el formulario de validación
                if (data.isEmpty) {
                  return _buildFormState();
                }

                final provider = data.first;
                final status = provider['verification_status'];

                if (status == 'pending') {
                  return _buildPendingState();
                } else if (status == 'rejected') {
                  return _buildRejectedState(userId);
                } else if (provider['is_verified'] == true) {
                  // 🔥 REDIRECCIÓN MÁGICA: Si la IA lo aprueba, lo mandamos a los Términos
                  // Usamos un microtask para evitar errores de redibujado durante la construcción
                  Future.microtask(() {
                    if (mounted) {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (_) => TermsScreen(
                            userType: widget.userType,
                            isViewOnly: false,
                          ),
                        ),
                      );
                    }
                  });
                  // Mostramos un loader rápido mientras hace el salto de pantalla
                  return const Center(child: CircularProgressIndicator(color: Color(0xFFB2D826)));
                }

                // Fallback de seguridad
                return _buildFormState();
              },
            ),
          ),
        ],
      ),
    );
  }

  // --- 1. ESTADO: FORMULARIO PARA SUBIR DNI ---
  Widget _buildFormState() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          const Icon(Icons.security_rounded, color: Color(0xFFB2D826), size: 70),
          const SizedBox(height: 20),
          const Text(
            "Verificación Requerida",
            style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 10),
          const Text(
            "Por seguridad, analiza tu DNI físico. La IA validará tu identidad en segundos.",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white54, fontSize: 14),
          ),
          const SizedBox(height: 30),

          // Campo DNI
          _buildTextField(_dniController, "Número de DNI (8 dígitos)", isNum: true),
          const SizedBox(height: 20),

          // Botones de fotos
          Row(
            children: [
              Expanded(child: _buildImageButton("Frente del DNI", true, _dniFront)),
              const SizedBox(width: 15),
              Expanded(child: _buildImageButton("Reverso del DNI", false, _dniBack)),
            ],
          ),
          const SizedBox(height: 40),

          // Botón Enviar
          SizedBox(
            width: double.infinity,
            height: 55,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFB2D826),
                foregroundColor: const Color(0xFF0F172A),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                elevation: 4,
              ),
              onPressed: _isUploading ? null : _submitVerification,
              child: _isUploading
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                  : const Text("ANALIZAR CON IA", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          )
        ],
      ),
    );
  }

  // --- 2. ESTADO: PENDIENTE (IA ANALIZANDO) ---
  Widget _buildPendingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            height: 60,
            width: 60,
            child: CircularProgressIndicator(color: Color(0xFFB2D826), strokeWidth: 4),
          ),
          const SizedBox(height: 25),
          const Text(
            "IA Analizando DNI...",
            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1.5),
          ),
          const SizedBox(height: 10),
          Text(
            "Validando identidad y autenticidad.",
            style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 14),
          )
        ],
      ),
    );
  }

  // --- 3. ESTADO: RECHAZADO ---
  Widget _buildRejectedState(String userId) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 80),
            const SizedBox(height: 20),
            const Text(
              "DNI Rechazado",
              style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 15),
            const Text(
              "La Inteligencia Artificial no pudo validar tu documento. Asegúrate de que las fotos sean claras, sin reflejos y que el número coincida.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white54, fontSize: 15, height: 1.5),
            ),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white.withOpacity(0.1),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                side: const BorderSide(color: Colors.redAccent, width: 1),
              ),
              onPressed: () async {
                // Borramos el registro fallido para permitirle intentar de nuevo
                await _supabase.from('service_providers').delete().eq('id', userId);
                setState(() {
                  _dniFront = null;
                  _dniBack = null;
                  _dniController.clear();
                });
              },
              icon: const Icon(Icons.refresh_rounded),
              label: const Text("REINTENTAR VALIDACIÓN"),
            )
          ],
        ),
      ),
    );
  }

  // --- COMPONENTES UI AUXILIARES ---

  Widget _buildTextField(TextEditingController controller, String hint, {bool isNum = false}) {
    return TextField(
      controller: controller,
      keyboardType: isNum ? TextInputType.number : TextInputType.text,
      maxLength: isNum ? 8 : null, // DNI peruano tiene 8 dígitos
      style: const TextStyle(color: Colors.white, fontSize: 16, letterSpacing: 2),
      textAlign: TextAlign.center,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white38, letterSpacing: 0),
        counterText: "", // Oculta el contador de 8 caracteres
        filled: true,
        fillColor: Colors.white.withOpacity(0.05),
        contentPadding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
      ),
    );
  }

  Widget _buildImageButton(String title, bool isFront, Uint8List? imageBytes) {
    return GestureDetector(
      onTap: () async {
        final img = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
        if (img != null) {
          final bytes = await img.readAsBytes();
          setState(() {
            if (isFront) {
              _dniFront = bytes;
            } else {
              _dniBack = bytes;
            }
          });
        }
      },
      child: Container(
        height: 140,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: imageBytes != null ? const Color(0xFFB2D826) : Colors.white10, width: 2),
        ),
        child: imageBytes != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(13), // Un poco menos que el borde exterior
                child: Image.memory(imageBytes, fit: BoxFit.cover),
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.camera_alt_rounded, color: Colors.white38, size: 30),
                  const SizedBox(height: 10),
                  Text(title, style: const TextStyle(color: Colors.white54, fontWeight: FontWeight.bold, fontSize: 12)),
                ],
              ),
      ),
    );
  }
}