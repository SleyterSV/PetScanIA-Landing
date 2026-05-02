import 'package:flutter/material.dart';
import 'package:petscania/screens/community/community_hub_screen.dart';
import 'package:petscania/screens/home_screen.dart';
import 'package:petscania/screens/terms_screen.dart';
import 'package:petscania/services/account_service.dart';
import 'package:petscania/theme/petscania_brand.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

enum _AccessStep { phone, code, profile }

class PhoneAccessScreen extends StatefulWidget {
  const PhoneAccessScreen({super.key});

  @override
  State<PhoneAccessScreen> createState() => _PhoneAccessScreenState();
}

class _PhoneAccessScreenState extends State<PhoneAccessScreen>
    with SingleTickerProviderStateMixin {
  final AccountService _accountService = AccountService();
  final TextEditingController _countryController = TextEditingController(
    text: '+51',
  );
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _codeController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _cityController = TextEditingController(
    text: 'Lima',
  );
  final TextEditingController _familyController = TextEditingController();

  late final AnimationController _animationController;
  late final Animation<double> _animation;

  _AccessStep _step = _AccessStep.phone;
  bool _isLoading = false;
  bool _demoOtpMode = false;
  String _normalizedPhone = '';

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: -8, end: 8).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _countryController.dispose();
    _phoneController.dispose();
    _codeController.dispose();
    _nameController.dispose();
    _cityController.dispose();
    _familyController.dispose();
    super.dispose();
  }

  Future<void> _sendCode() async {
    final normalized = _accountService.normalizePhone(
      countryCode: _countryController.text.trim(),
      phone: _phoneController.text.trim(),
    );
    final digits = normalized.replaceAll(RegExp(r'[^0-9]'), '');

    if (digits.length < 10) {
      _showError('Escribe tu numero con WhatsApp activo.');
      return;
    }

    setState(() {
      _isLoading = true;
      _normalizedPhone = normalized;
      _demoOtpMode = false;
    });

    try {
      await _accountService.requestWhatsAppOtp(normalized);
      if (!mounted) return;
      setState(() => _step = _AccessStep.code);
      _showInfo('Te enviamos un codigo por WhatsApp a $normalized.');
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() {
        _step = _AccessStep.code;
        _demoOtpMode = true;
      });
      _showInfo(
        'WhatsApp OTP aun no esta activo en Supabase: ${e.message}. Usa 123456 para probar.',
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _step = _AccessStep.code;
        _demoOtpMode = true;
      });
      _showInfo('Modo demo activo. Usa el codigo 123456 para probar el flujo.');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _verifyCode() async {
    final code = _codeController.text.trim();
    if (code.length < 6) {
      _showError('Ingresa el codigo de 6 digitos.');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final result = _demoOtpMode
          ? const PhoneAccessResult(
              hasBasicProfile: false,
              hasAcceptedTerms: false,
            )
          : await _accountService.verifyWhatsAppOtp(
              normalizedPhone: _normalizedPhone,
              code: code,
            );

      if (_demoOtpMode && code != '123456') {
        throw const AuthException('Codigo incorrecto en modo demo.');
      }

      if (!mounted) return;
      _finishAccess(result);
    } on AuthException catch (e) {
      _showError(e.message);
    } catch (_) {
      _showError('No pudimos validar el codigo. Intenta nuevamente.');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _completeProfile() async {
    final name = _nameController.text.trim();
    final city = _cityController.text.trim();
    final family = _familyController.text.trim().isEmpty
        ? 'Familia de $name'
        : _familyController.text.trim();

    if (name.length < 3 || city.length < 2) {
      _showError('Completa tu nombre y ciudad.');
      return;
    }

    setState(() => _isLoading = true);
    try {
      if (!_demoOtpMode) {
        await _accountService.completePhoneProfile(
          fullName: name,
          city: city,
          normalizedPhone: _normalizedPhone,
          familyName: family,
        );
      }

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const TermsScreen()),
      );
    } catch (e) {
      _showError('No pudimos guardar tu perfil: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _finishAccess(PhoneAccessResult result) {
    if (!result.hasBasicProfile) {
      setState(() => _step = _AccessStep.profile);
      return;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) =>
            result.hasAcceptedTerms ? const HomeScreen() : const TermsScreen(),
      ),
    );
  }

  void _enterCommunityDemo() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CommunityHubScreen()),
    );
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: PetScaniaColors.alert),
    );
  }

  void _showInfo(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PetScaniaBackground(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: PetScaniaGlassCard(
                  padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                  child: Column(
                    children: [
                      AnimatedBuilder(
                        animation: _animation,
                        builder: (context, child) => Transform.translate(
                          offset: Offset(0, _animation.value),
                          child: child,
                        ),
                        child: const PetScaniaBrandMark(size: 96),
                      ),
                      const SizedBox(height: 18),
                      const PetScaniaWordmark(fontSize: 40),
                      const SizedBox(height: 10),
                      Text(
                        _copyForStep(),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.86),
                          fontSize: 14,
                          height: 1.45,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 26),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 220),
                        child: switch (_step) {
                          _AccessStep.phone => _buildPhoneStep(),
                          _AccessStep.code => _buildCodeStep(),
                          _AccessStep.profile => _buildProfileStep(),
                        },
                      ),
                      const SizedBox(height: 18),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: OutlinedButton.icon(
                          onPressed: _enterCommunityDemo,
                          icon: const Icon(Icons.volunteer_activism_rounded),
                          label: const Text('EXPLORAR ADOPTA Y AYUDA'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: BorderSide(
                              color: Colors.white.withValues(alpha: 0.42),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                            textStyle: const TextStyle(
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _copyForStep() {
    switch (_step) {
      case _AccessStep.phone:
        return 'Entra con tu numero de WhatsApp. Si es nuevo, creamos tu cuenta en segundos.';
      case _AccessStep.code:
        return 'Escribe el codigo que recibiste. Este numero sera tu acceso principal.';
      case _AccessStep.profile:
        return 'Crea tu casa familiar para compartir mascotas, historial medico y permisos.';
    }
  }

  Widget _buildPhoneStep() {
    return Column(
      key: const ValueKey('phone'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel('Numero de WhatsApp'),
        const SizedBox(height: 8),
        Row(
          children: [
            SizedBox(
              width: 86,
              child: _buildInput(
                controller: _countryController,
                hint: '+51',
                icon: Icons.flag_rounded,
                keyboardType: TextInputType.phone,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildInput(
                controller: _phoneController,
                hint: '999 999 999',
                icon: Icons.phone_iphone_rounded,
                keyboardType: TextInputType.phone,
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        _AccessHint(
          icon: Icons.family_restroom_rounded,
          title: 'Cuenta familiar',
          text:
              'Luego podras invitar familiares por numero y todos veran las mismas mascotas.',
        ),
        const SizedBox(height: 22),
        _PrimaryAccessButton(
          isLoading: _isLoading,
          label: 'ENVIAR CODIGO POR WHATSAPP',
          icon: Icons.chat_rounded,
          onPressed: _sendCode,
        ),
      ],
    );
  }

  Widget _buildCodeStep() {
    return Column(
      key: const ValueKey('code'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel('Codigo recibido'),
        const SizedBox(height: 8),
        _buildInput(
          controller: _codeController,
          hint: '123456',
          icon: Icons.password_rounded,
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            const Icon(
              Icons.verified_user_rounded,
              color: Colors.white,
              size: 18,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _demoOtpMode
                    ? 'Modo demo activo mientras Supabase WhatsApp OTP queda configurado.'
                    : 'Codigo enviado a $_normalizedPhone',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.78),
                  fontWeight: FontWeight.w700,
                  height: 1.35,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 22),
        _PrimaryAccessButton(
          isLoading: _isLoading,
          label: 'VALIDAR Y ENTRAR',
          icon: Icons.login_rounded,
          onPressed: _verifyCode,
        ),
        const SizedBox(height: 10),
        Center(
          child: TextButton(
            onPressed: _isLoading ? null : _sendCode,
            child: const Text(
              'Reenviar codigo',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProfileStep() {
    return Column(
      key: const ValueKey('profile'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel('Tu nombre'),
        const SizedBox(height: 8),
        _buildInput(
          controller: _nameController,
          hint: 'Miguel Solano',
          icon: Icons.person_rounded,
          keyboardType: TextInputType.name,
        ),
        const SizedBox(height: 16),
        _buildLabel('Ciudad'),
        const SizedBox(height: 8),
        _buildInput(
          controller: _cityController,
          hint: 'Lima',
          icon: Icons.location_city_rounded,
          keyboardType: TextInputType.text,
        ),
        const SizedBox(height: 16),
        _buildLabel('Nombre de tu familia'),
        const SizedBox(height: 8),
        _buildInput(
          controller: _familyController,
          hint: 'Casa de Pupi',
          icon: Icons.home_rounded,
          keyboardType: TextInputType.text,
        ),
        const SizedBox(height: 18),
        _AccessHint(
          icon: Icons.admin_panel_settings_rounded,
          title: 'Roles preparados',
          text:
              'Empiezas como cliente/familia y luego puedes activar veterinario, refugio o rescatista.',
        ),
        const SizedBox(height: 22),
        _PrimaryAccessButton(
          isLoading: _isLoading,
          label: 'CREAR MI FAMILIA',
          icon: Icons.group_add_rounded,
          onPressed: _completeProfile,
        ),
      ],
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontWeight: FontWeight.w900,
        color: Colors.white,
        fontSize: 14,
      ),
    );
  }

  Widget _buildInput({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required TextInputType keyboardType,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(
        color: PetScaniaColors.ink,
        fontWeight: FontWeight.w900,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          color: PetScaniaColors.ink.withValues(alpha: 0.42),
        ),
        prefixIcon: Icon(icon, color: PetScaniaColors.royalBlue),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 18,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

class _PrimaryAccessButton extends StatelessWidget {
  final bool isLoading;
  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  const _PrimaryAccessButton({
    required this.isLoading,
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 58,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: PetScaniaColors.royalBlue,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          elevation: 0,
        ),
        onPressed: isLoading ? null : onPressed,
        icon: isLoading
            ? const SizedBox.shrink()
            : Icon(icon, color: PetScaniaColors.royalBlue),
        label: isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: PetScaniaColors.royalBlue,
                  strokeWidth: 2.8,
                ),
              )
            : Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.4,
                ),
              ),
      ),
    );
  }
}

class _AccessHint extends StatelessWidget {
  final IconData icon;
  final String title;
  final String text;

  const _AccessHint({
    required this.icon,
    required this.title,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.20)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(icon, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  text,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.76),
                    height: 1.35,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
