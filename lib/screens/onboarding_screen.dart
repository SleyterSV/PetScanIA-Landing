import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:petscania/screens/home_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _userNameController = TextEditingController();
  final _petNameController = TextEditingController();
  final _petBreedController = TextEditingController();
  
  bool _isLoading = false;
  String _selectedPetType = 'Perro'; // Por defecto

  Future<void> _saveAndEnter() async {
    if (_userNameController.text.isEmpty || _petNameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Por favor completa los datos principales")));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final supabase = Supabase.instance.client;
      final userId = supabase.auth.currentUser!.id;

      // 1. ACTUALIZAR PERFIL DE USUARIO (Tu nombre real)
      await supabase.from('profiles').upsert({
        'id': userId,
        'full_name': _userNameController.text.trim(),
        'role': 'user',
      });

      // 2. CREAR PRIMERA MASCOTA
      await supabase.from('pets').insert({
        'owner_id': userId,
        'name': _petNameController.text.trim(),
        'breed': _petBreedController.text.trim(),
        'age': '1 año', // Valor inicial, luego editable
        // Foto genérica según perro o gato
        'photo_url': _selectedPetType == 'Perro' 
            ? 'https://cdn-icons-png.flaticon.com/512/616/616408.png' 
            : 'https://cdn-icons-png.flaticon.com/512/616/616430.png',
      });

      // 3. ENTRAR A LA APP
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      }

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error guardando: $e")));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Configuración Inicial 🚀", style: TextStyle(fontWeight: FontWeight.w900)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("¡Hablemos de ti!", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2563EB))),
            const SizedBox(height: 15),
            _buildInput("Tu Nombre Completo", _userNameController, Icons.person),
            
            const SizedBox(height: 30),
            
            const Text("Ahora, tu compañero fiel 🐾", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2563EB))),
            const SizedBox(height: 15),
            
            // SELECTOR PERRO / GATO
            Row(
              children: [
                _buildPetTypeBtn("Perro", Icons.pets),
                const SizedBox(width: 15),
                _buildPetTypeBtn("Gato", Icons.cruelty_free),
              ],
            ),
            const SizedBox(height: 20),

            _buildInput("Nombre de tu mascota", _petNameController, Icons.edit),
            const SizedBox(height: 15),
            _buildInput("Raza (Opcional)", _petBreedController, Icons.category),

            const SizedBox(height: 40),

            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveAndEnter,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isLoading 
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text("FINALIZAR Y ENTRAR", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInput(String label, TextEditingController controller, IconData icon) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.grey),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: const Color(0xFFF5F7FA),
      ),
    );
  }

  Widget _buildPetTypeBtn(String type, IconData icon) {
    final isSelected = _selectedPetType == type;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedPetType = type),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 15),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF2563EB) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isSelected ? const Color(0xFF2563EB) : Colors.grey.shade300),
          ),
          child: Column(
            children: [
              Icon(icon, color: isSelected ? Colors.white : Colors.grey, size: 30),
              const SizedBox(height: 5),
              Text(type, style: TextStyle(color: isSelected ? Colors.white : Colors.grey, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }
}