import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RegisterPetScreen extends StatefulWidget {
  final Map<String, dynamic>? petToEdit; 

  const RegisterPetScreen({super.key, this.petToEdit});

  @override
  State<RegisterPetScreen> createState() => _RegisterPetScreenState();
}

class _RegisterPetScreenState extends State<RegisterPetScreen> {
  final _nameController = TextEditingController();
  final _breedController = TextEditingController();
  final _ageController = TextEditingController();
  final _weightController = TextEditingController();
  
  String? _selectedGender;
  Uint8List? _webImageBytes;
  String? _existingPhotoUrl;
  bool _isSaving = false; 

  final SupabaseClient _supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    if (widget.petToEdit != null) {
      _nameController.text = widget.petToEdit!['name'] ?? '';
      _breedController.text = widget.petToEdit!['breed'] ?? '';
      _ageController.text = widget.petToEdit!['age'] ?? '';
      _weightController.text = widget.petToEdit!['weight'] ?? '';
      _selectedGender = widget.petToEdit!['gender'];
      _existingPhotoUrl = widget.petToEdit!['photo_url'];
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(
      source: ImageSource.gallery, 
      imageQuality: 80,
      maxWidth: 800,
    );
    
    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      setState(() => _webImageBytes = bytes);
    }
  }

  Future<void> _savePet() async {
    final name = _nameController.text.trim();
    final breed = _breedController.text.trim();

    if (name.isEmpty || breed.isEmpty || _selectedGender == null || (_webImageBytes == null && _existingPhotoUrl == null)) {
      _showSnackBar("Nombre, Raza, Género y Foto son obligatorios", Colors.orangeAccent);
      return;
    }

    setState(() => _isSaving = true);

    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      String? finalPhotoUrl = _existingPhotoUrl;

      if (_webImageBytes != null) {
        final String fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
        final String path = '${user.id}/$fileName';
        
        await _supabase.storage.from('pet-photos').uploadBinary(
          path, 
          _webImageBytes!, 
          fileOptions: const FileOptions(contentType: 'image/jpeg', upsert: true)
        );
        
        finalPhotoUrl = _supabase.storage.from('pet-photos').getPublicUrl(path);
      }

      final petData = {
        'owner_id': user.id,
        'name': name,
        'breed': breed,
        'age': _ageController.text.trim(),
        'weight': _weightController.text.trim(),
        'gender': _selectedGender,
        'photo_url': finalPhotoUrl,
      };

      if (widget.petToEdit != null) {
        await _supabase.from('pets').update(petData).eq('id', widget.petToEdit!['id']);
      } else {
        await _supabase.from('pets').insert(petData);
      }

      if (!mounted) return;
      _showSnackBar("¡Datos guardados con éxito! 🐾", const Color(0xFF4ADE80));
      
      Navigator.pop(context, true); 

    } catch (e) {
      debugPrint("Error crítico al guardar mascota: $e");
      _showSnackBar("Error al guardar. Revisa tu conexión.", Colors.redAccent);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showSnackBar(String m, Color c) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(m, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black)), backgroundColor: c, behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isEditing = widget.petToEdit != null;

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(isEditing ? "Editar Mascota" : "Registrar Mascota", style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.white)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Stack(
        children: [
          // 🔥 SOLUCIÓN AL ERROR DE OPACITY
          Positioned.fill(
            child: Opacity(
              opacity: 0.2,
              child: Image.asset("assets/images/Fondo_Principal.png", fit: BoxFit.cover),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(25),
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  _buildPhotoSelector(),
                  const SizedBox(height: 30),
                  _buildFormCard(),
                  const SizedBox(height: 40),
                  _buildSubmitButton(isEditing),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoSelector() {
    return GestureDetector(
      onTap: _pickImage,
      child: Center(
        child: Stack(
          alignment: Alignment.bottomRight,
          children: [
            Container(
              height: 150, width: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF4ADE80), width: 3),
                color: Colors.white10,
                image: _webImageBytes != null 
                    ? DecorationImage(image: MemoryImage(_webImageBytes!), fit: BoxFit.cover)
                    : (_existingPhotoUrl != null ? DecorationImage(image: NetworkImage(_existingPhotoUrl!), fit: BoxFit.cover) : null),
              ),
              child: (_webImageBytes == null && _existingPhotoUrl == null) ? const Icon(Icons.pets, size: 60, color: Colors.white24) : null,
            ),
            const CircleAvatar(
              backgroundColor: Color(0xFF4ADE80), 
              radius: 20, 
              child: Icon(Icons.camera_alt, color: Colors.black, size: 20)
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormCard() {
    return Container(
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: Colors.white10, 
        borderRadius: BorderRadius.circular(30), 
        border: Border.all(color: Colors.white24)
      ),
      child: Column(
        children: [
          _buildInputField("Nombre", _nameController, Icons.edit),
          const SizedBox(height: 20),
          _buildInputField("Raza", _breedController, Icons.category),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(child: _buildInputField("Edad", _ageController, Icons.cake)),
              const SizedBox(width: 15),
              Expanded(child: _buildInputField("Peso", _weightController, Icons.monitor_weight)),
            ],
          ),
          const SizedBox(height: 25),
          _buildGenderSelector(),
        ],
      ),
    );
  }

  Widget _buildGenderSelector() {
    return Row(
      children: [
        _genderBtn("Macho", const Color(0xFF3B82F6)),
        const SizedBox(width: 15),
        _genderBtn("Hembra", const Color(0xFFEC4899)),
      ],
    );
  }

  Widget _genderBtn(String label, Color color) {
    bool isSel = _selectedGender == label;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedGender = label),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSel ? color.withAlpha(50) : Colors.black26,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: isSel ? color : Colors.transparent, width: 2),
          ),
          child: Center(
            child: Text(label, style: TextStyle(color: isSel ? Colors.white : Colors.white54, fontWeight: FontWeight.bold))
          ),
        ),
      ),
    );
  }

  Widget _buildInputField(String label, TextEditingController controller, IconData icon) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white38),
        prefixIcon: Icon(icon, color: const Color(0xFF4ADE80), size: 18),
        filled: true,
        fillColor: Colors.black26,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
      ),
    );
  }

  Widget _buildSubmitButton(bool isEditing) {
    return SizedBox(
      width: double.infinity, height: 60,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF4ADE80), 
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          elevation: 5,
        ),
        onPressed: _isSaving ? null : _savePet,
        child: _isSaving 
          ? const CircularProgressIndicator(color: Colors.black) 
          : Text(
              isEditing ? "ACTUALIZAR DATOS" : "GUARDAR Y EMPEZAR", 
              style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w900, letterSpacing: 1)
            ),
      ),
    );
  }
}