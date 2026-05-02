import 'dart:ui'; 
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Importaciones de tus pantallas de destino
import 'package:petscania/screens/home_screen.dart';
import 'package:petscania/screens/add_product_screen.dart';
import 'package:petscania/screens/provider_hub_screen.dart'; // 🔥 Importación añadida para navegar al Hub

enum TermsUserType { customer, providerMarketplace, providerService }

class TermsScreen extends StatefulWidget {
  final bool isViewOnly;
  final TermsUserType userType;

  const TermsScreen({
    super.key, 
    this.isViewOnly = false, 
    this.userType = TermsUserType.customer,
  });

  @override
  State<TermsScreen> createState() => _TermsScreenState();
}

class _TermsScreenState extends State<TermsScreen> {
  bool _hasAccepted = false;
  bool _isLoading = false;

  Future<void> _continuar() async {
    if (!_hasAccepted) return;
    
    setState(() => _isLoading = true);

    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;

      if (user != null) {
        final userId = user.id;

        // 🔥 PASO 1: ACTUALIZACIÓN GLOBAL DE PERFIL
        await supabase.from('profiles').update({
          'has_accepted_terms': true,
          'role': 'user', 
        }).eq('id', userId);

        // 🔥 PASO 2: ACTUALIZACIÓN ESPECÍFICA SEGÚN EL TIPO DE SOCIO
        if (widget.userType == TermsUserType.providerService) {
          // Se guarda en la columna NUEVA específica de servicios
          await supabase.from('service_providers').update({
            'accepted_services_terms': true,
          }).eq('id', userId); 
        } else if (widget.userType == TermsUserType.providerMarketplace) {
          // Se guarda en la columna ANTIGUA de marketplace
          await supabase.from('service_providers').update({
            'has_accepted_provider_terms': true,
          }).eq('id', userId); 
        }
      }

      if (!mounted) return;

      // 🔥 PASO 3: REDIRECCIÓN PROFESIONAL SEGÚN FLUJO
      if (widget.userType == TermsUserType.providerMarketplace) {
        Navigator.pushReplacement(
          context, 
          MaterialPageRoute(builder: (_) => const AddProductScreen())
        );
      } else if (widget.userType == TermsUserType.providerService) {
        // AHORA SÍ: Vamos directo al Hub de Negocios en lugar de regresar atrás
        Navigator.pushReplacement(
          context, 
          MaterialPageRoute(builder: (_) => const ProviderHubScreen())
        );
      } else {
        Navigator.pushReplacement(
          context, 
          MaterialPageRoute(builder: (_) => const HomeScreen())
        );
      }

    } catch (e) {
      debugPrint("Error crítico en términos: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error de conexión: $e"), 
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isCustomer = widget.userType == TermsUserType.customer;
    final String titleText = isCustomer ? "Términos y Privacidad" : "Acuerdo Comercial";
    final IconData iconData = isCustomer ? Icons.gavel_rounded : Icons.storefront_rounded;
    final String checkboxText = isCustomer 
        ? "Declaro haber leído, comprendido y aceptado las políticas de uso, privacidad y deslinde médico."
        : "Declaro bajo juramento que mi información es veraz y acepto la responsabilidad legal comercial.";

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        leading: widget.isViewOnly 
            ? IconButton(icon: const Icon(Icons.arrow_back_ios_new), onPressed: () => Navigator.pop(context))
            : null,
        title: Text(titleText, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          // Fondo con imagen PetScanIA
          Positioned.fill(
            child: Opacity(
              opacity: 0.5,
              child: Image.asset("assets/images/Fondo_Principal.png", fit: BoxFit.cover),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20.0),
                    physics: const BouncingScrollPhysics(),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(25),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                        child: Container(
                          padding: const EdgeInsets.all(25),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(25),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Center(child: Icon(iconData, size: 50, color: isCustomer ? const Color(0xFF3B82F6) : const Color(0xFFB2D826))),
                              const SizedBox(height: 20),
                              const Text("Contrato de Usuario PetScanIA", style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white)),
                              const SizedBox(height: 10),
                              Text("Última actualización: Abril 2026", style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12)),
                              const SizedBox(height: 25),
                              
                              if (widget.userType == TermsUserType.customer) 
                                ..._buildCustomerTerms() 
                              else if (widget.userType == TermsUserType.providerMarketplace) 
                                ..._buildMarketplaceTerms() 
                              else 
                                ..._buildServiceTerms(),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // Sección de Aceptación (Solo si no es modo lectura)
                if (!widget.isViewOnly)
                  Container(
                    padding: const EdgeInsets.all(25.0),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B).withValues(alpha: 0.95),
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                      border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Checkbox(
                              value: _hasAccepted,
                              activeColor: isCustomer ? const Color(0xFF3B82F6) : const Color(0xFFB2D826),
                              checkColor: const Color(0xFF0F172A),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                              onChanged: (v) => setState(() => _hasAccepted = v ?? false),
                            ),
                            Expanded(child: Text(checkboxText, style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.4))),
                          ],
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _hasAccepted ? (isCustomer ? const Color(0xFF3B82F6) : const Color(0xFFB2D826)) : Colors.white10,
                            minimumSize: const Size(double.infinity, 60),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                            elevation: _hasAccepted ? 5 : 0,
                          ),
                          onPressed: _hasAccepted && !_isLoading ? _continuar : null,
                          child: _isLoading 
                            ? const SizedBox(height: 25, width: 25, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 3))
                            : const Text("FIRMAR Y CONTINUAR", style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 0.5)),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- MÉTODOS DE CONTENIDO LEGAL ---

  List<Widget> _buildCustomerTerms() {
    return [
      _legalBlock("1. Naturaleza del Servicio de IA", "Los análisis, escaneos y predicciones generados por la Inteligencia Artificial de PetScanIA son estrictamente informativos. BAJO NINGUNA CIRCUNSTANCIA reemplazan el diagnóstico, tratamiento o criterio profesional de un médico veterinario colegiado y certificado."),
      _legalBlock("2. Responsabilidad Médica y Emergencias", "El usuario comprende y acepta que la plataforma no es un servicio para atención de emergencias. Ante cualquier síntoma grave, accidente o deterioro en la salud de su mascota, es su obligación legal y moral acudir inmediatamente a una clínica veterinaria presencial. PetScanIA no asume responsabilidad por daños o decesos derivados de la omisión de atención profesional."),
      _legalBlock("3. Privacidad y Manejo de Datos", "Sus datos personales y los registros médicos de sus mascotas son almacenados bajo estrictos protocolos de encriptación. Al aceptar este contrato, autoriza el procesamiento anónimo de las imágenes y síntomas cargados para el entrenamiento y mejora continua de nuestros modelos predictivos de IA."),
      _legalBlock("4. Interacciones y Compras de Terceros", "Al adquirir productos en el Marketplace o contratar servicios de cuidado a través de PetScanIA, usted interactúa comercialmente con proveedores independientes. PetScanIA actúa únicamente como intermediario tecnológico. Para garantizar su seguridad antifraude, toda transacción debe realizarse a través de nuestra pasarela oficial."),
      _legalBlock("5. Veracidad de la Información", "El usuario declara bajo juramento que los datos proporcionados sobre sus mascotas son reales. La manipulación intencional de la IA con imágenes falsas o datos erróneos resultará en la suspensión permanente de su cuenta."),
    ];
  }

  List<Widget> _buildMarketplaceTerms() {
    return [
      _legalBlock("1. Naturaleza de la Plataforma", "PetScanIA opera exclusivamente como un intermediario tecnológico y vitrina digital publicitaria. No somos dueños, fabricantes ni distribuidores de los artículos publicados."),
      _legalBlock("2. Deslinde de Responsabilidad", "Toda queja, reclamo por calidad, defecto de fábrica, intoxicación o daño derivado del uso de los productos adquiridos recae ÚNICA Y EXCLUSIVAMENTE sobre el vendedor (proveedor). PetScanIA no asume responsabilidad civil, penal ni administrativa."),
      _legalBlock("3. Transacciones y Pagos", "Para garantizar la trazabilidad y seguridad, toda transacción comercial DEBE realizarse a través de la pasarela de pagos oficial de PetScanIA. La empresa no se responsabiliza, no respalda y no intervendrá en fraudes, estafas o disputas derivadas de acuerdos, transferencias directas o pagos realizados por fuera de nuestra plataforma."),
      _legalBlock("4. Verificación de Identidad", "Los datos personales proporcionados durante el registro y verificación (incluyendo DNI/RUC) podrán ser entregados a las autoridades competentes (Indecopi, PNP, Fiscalía) en caso de fraudes o distribución de productos nocivos comprobados."),
    ];
  }

  List<Widget> _buildServiceTerms() {
    return [
      _legalBlock("1. Independencia Laboral", "El Proveedor de Servicios (Paseador, Entrenador, Peluquero, etc.) declara actuar como socio independiente. No existe relación de subordinación, dependencia ni vínculo laboral directo con PetScanIA."),
      _legalBlock("2. Deslinde Profesional", "Cualquier daño a la propiedad, negligencia, accidente o mala praxis durante la prestación del servicio es responsabilidad directa y exclusiva del Profesional contratado. PetScanIA no asume seguros de responsabilidad civil por terceros."),
      _legalBlock("3. Transacciones y Pagos", "Todo pago por la contratación de servicios DEBE gestionarse a través de la plataforma de PetScanIA. No nos responsabilizamos por cobros indebidos, incumplimientos o estafas derivadas de acuerdos económicos por fuera de nuestro sistema."),
      _legalBlock("4. Política de Bienestar Animal", "PetScanIA mantiene tolerancia cero frente al maltrato animal. Ante reportes sustentados de violencia o negligencia, el perfil del proveedor será bloqueado permanentemente y su información de identidad será compartida de inmediato con las autoridades legales y de protección animal correspondientes."),
    ];
  }

  Widget _legalBlock(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          Text(content, style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.5, letterSpacing: 0.3), textAlign: TextAlign.justify),
        ],
      ),
    );
  }
}