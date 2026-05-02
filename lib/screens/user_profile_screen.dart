import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:petscania/theme/petscania_brand.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({super.key});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  String? _avatarUrl;
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    final user = _supabase.auth.currentUser;

    if (user == null) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
      return;
    }

    try {
      final data = await _supabase
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      if (data != null && mounted) {
        setState(() {
          _nameController.text = data['full_name'] ?? '';
          _phoneController.text = data['phone'] ?? '';
          _avatarUrl = data['avatar_url'];
        });
      }
    } catch (e) {
      debugPrint('Error al cargar perfil: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _pickAndUploadAvatar() async {
    final user = _supabase.auth.currentUser;

    if (user == null) return;

    final picker = ImagePicker();

    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      imageQuality: 80,
    );

    if (image == null) return;

    setState(() => _isUploading = true);

    try {
      final bytes = await image.readAsBytes();
      final String fileExtension = image.name.split('.').last;
      final String filePath = 'avatars/${user.id}.$fileExtension';

      await _supabase.storage.from('profiles').uploadBinary(
            filePath,
            bytes,
            fileOptions: const FileOptions(upsert: true),
          );

      final String publicUrl =
          _supabase.storage.from('profiles').getPublicUrl(filePath);

      if (mounted) {
        setState(() => _avatarUrl = publicUrl);

        _showMsg(
          'Imagen actualizada correctamente',
          const Color(0xFF16A34A),
        );
      }
    } catch (e) {
      debugPrint('Error subiendo imagen: $e');

      if (mounted) {
        _showMsg(
          'No se pudo subir la imagen',
          const Color(0xFFD84A4A),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  Future<void> _saveProfile() async {
    final user = _supabase.auth.currentUser;

    if (user == null) return;

    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();

    if (name.isEmpty || phone.isEmpty) {
      _showMsg(
        'Nombre y teléfono son obligatorios',
        const Color(0xFFF59E0B),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      await _supabase.from('profiles').update({
        'full_name': name,
        'phone': phone,
        'avatar_url': _avatarUrl,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', user.id);

      if (!mounted) return;

      _showMsg(
        'Tus datos han sido actualizados',
        const Color(0xFF16A34A),
      );

      _goToHome();
    } catch (e) {
      debugPrint('Error al guardar: $e');

      if (mounted) {
        _showMsg(
          'Error de conexión con el servidor',
          const Color(0xFFD84A4A),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _showMsg(String text, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );
  }

  void _goToHome() {
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PetScaniaColors.mist,
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
                              'Mi Perfil',
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
                              'Actualiza tus datos personales desde aquí.',
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
                        : SingleChildScrollView(
                            physics: const BouncingScrollPhysics(),
                            padding: const EdgeInsets.fromLTRB(18, 24, 18, 34),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildProfileCard(),

                                const SizedBox(height: 22),

                                _buildFormCard(),

                                const SizedBox(height: 28),

                                _buildActionButton(),
                              ],
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

  Widget _buildProfileCard() {
    return PetScaniaSurfaceCard(
      padding: const EdgeInsets.fromLTRB(22, 24, 22, 24),
      borderRadius: BorderRadius.circular(30),
      child: Column(
        children: [
          const Text(
            'ACTUALIZA TUS DATOS',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: PetScaniaColors.royalBlue,
              fontSize: 12,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.4,
            ),
          ),

          const SizedBox(height: 8),

          const Text(
            'Mantén tu perfil al día',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: PetScaniaColors.ink,
              fontSize: 21,
              fontWeight: FontWeight.w900,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            'Tu información ayuda a personalizar mejor la experiencia de PetScanIA.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: PetScaniaColors.ink.withOpacity(0.62),
              height: 1.4,
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 28),

          _buildAvatarSection(),
        ],
      ),
    );
  }

  Widget _buildAvatarSection() {
    return Center(
      child: GestureDetector(
        onTap: _isUploading ? null : _pickAndUploadAvatar,
        child: Stack(
          alignment: Alignment.bottomRight,
          children: [
            Container(
              width: 142,
              height: 142,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: PetScaniaDecor.surfaceGradient,
                border: Border.all(
                  color: PetScaniaColors.skyBlue,
                  width: 3,
                ),
                boxShadow: [
                  BoxShadow(
                    color: PetScaniaColors.royalBlue.withOpacity(0.18),
                    blurRadius: 22,
                    offset: const Offset(0, 12),
                  ),
                ],
                image: _avatarUrl != null && _avatarUrl!.isNotEmpty
                    ? DecorationImage(
                        image: NetworkImage(_avatarUrl!),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: _avatarUrl == null || _avatarUrl!.isEmpty
                  ? _isUploading
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: PetScaniaColors.royalBlue,
                          ),
                        )
                      : const Icon(
                          Icons.person_rounded,
                          size: 78,
                          color: PetScaniaColors.royalBlue,
                        )
                  : _isUploading
                      ? Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.70),
                            shape: BoxShape.circle,
                          ),
                          child: const Center(
                            child: CircularProgressIndicator(
                              color: PetScaniaColors.royalBlue,
                            ),
                          ),
                        )
                      : null,
            ),

            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: PetScaniaDecor.primaryGradient,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white,
                  width: 3,
                ),
                boxShadow: [
                  BoxShadow(
                    color: PetScaniaColors.royalBlue.withOpacity(0.24),
                    blurRadius: 14,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Icon(
                Icons.camera_alt_rounded,
                color: Colors.white,
                size: 21,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormCard() {
    return PetScaniaSurfaceCard(
      padding: const EdgeInsets.all(20),
      borderRadius: BorderRadius.circular(30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Datos personales',
            style: TextStyle(
              color: PetScaniaColors.ink,
              fontSize: 19,
              fontWeight: FontWeight.w900,
            ),
          ),

          const SizedBox(height: 6),

          Text(
            'Edita tu nombre y teléfono de contacto.',
            style: TextStyle(
              color: PetScaniaColors.ink.withOpacity(0.60),
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 22),

          _buildInputField(
            label: "Nombre completo",
            icon: Icons.person_outline_rounded,
            controller: _nameController,
          ),

          const SizedBox(height: 20),

          _buildInputField(
            label: "Teléfono / WhatsApp",
            icon: Icons.phone_android_rounded,
            controller: _phoneController,
            isNumber: true,
          ),
        ],
      ),
    );
  }

  Widget _buildInputField({
    required String label,
    required IconData icon,
    required TextEditingController controller,
    bool isNumber = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: PetScaniaColors.ink.withOpacity(0.70),
            fontWeight: FontWeight.w900,
            fontSize: 13,
          ),
        ),

        const SizedBox(height: 10),

        TextField(
          controller: controller,
          keyboardType: isNumber ? TextInputType.phone : TextInputType.name,
          style: const TextStyle(
            color: PetScaniaColors.ink,
            fontWeight: FontWeight.w800,
          ),
          decoration: InputDecoration(
            prefixIcon: Icon(
              icon,
              color: PetScaniaColors.royalBlue,
              size: 21,
            ),
            filled: true,
            fillColor: PetScaniaColors.mist,
            hintStyle: const TextStyle(
              color: Color(0xFF7D96BF),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: const BorderSide(
                color: PetScaniaColors.line,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: const BorderSide(
                color: PetScaniaColors.royalBlue,
                width: 1.4,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton() {
    return SizedBox(
      width: double.infinity,
      height: 58,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: _isSaving ? null : PetScaniaDecor.primaryGradient,
          color: _isSaving ? PetScaniaColors.line : null,
          borderRadius: BorderRadius.circular(20),
          boxShadow: _isSaving
              ? []
              : [
                  BoxShadow(
                    color: PetScaniaColors.royalBlue.withOpacity(0.22),
                    blurRadius: 16,
                    offset: const Offset(0, 9),
                  ),
                ],
        ),
        child: ElevatedButton(
          onPressed: _isSaving ? null : _saveProfile,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            disabledBackgroundColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          child: _isSaving
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    color: PetScaniaColors.royalBlue,
                    strokeWidth: 2,
                  ),
                )
              : const Text(
                  "GUARDAR CAMBIOS",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                    letterSpacing: 0.8,
                  ),
                ),
        ),
      ),
    );
  }
}