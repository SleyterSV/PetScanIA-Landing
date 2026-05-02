import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:petscania/services/user_service.dart'; 

class PhotoReel extends StatefulWidget {
  final String? petId;

  const PhotoReel({super.key, required this.petId});

  @override
  State<PhotoReel> createState() => _PhotoReelState();
}

class _PhotoReelState extends State<PhotoReel> {
  final SupabaseClient _supabase = Supabase.instance.client;
  final ImagePicker _picker = ImagePicker();
  final UserService _userService = UserService();
  
  List<Map<String, dynamic>> _memories = [];

  @override
  void initState() {
    super.initState();
    _loadMemories();
  }

  @override
  void didUpdateWidget(covariant PhotoReel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.petId != oldWidget.petId) {
      _loadMemories();
    }
  }

  // 1. CARGAR FOTOS DE SUPABASE
  Future<void> _loadMemories() async {
    if (widget.petId == null) return;

    try {
      final data = await _supabase
          .from('memories')
          .select()
          .eq('pet_id', widget.petId!)
          .order('created_at', ascending: false);

      if (mounted) {
        setState(() {
          _memories = List<Map<String, dynamic>>.from(data);
        });
      }
    } catch (e) {
      debugPrint("Error cargando recuerdos: $e");
    }
  }

  // 2. LÓGICA AL PRESIONAR EL BOTÓN '+'
  Future<void> _handleNewMemoryTap() async {
    if (widget.petId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Primero registra una mascota 🐾")));
      return;
    }

    int currentCount = await _userService.getSpecialMomentsCount();
    
    if (currentCount >= 7) {
      if (mounted) _showPremiumDialog();
      return; 
    }

    await _uploadNewMemory();
  }

  // 3. SUBIR FOTO REAL
  Future<void> _uploadNewMemory() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (image == null) return;

    if (!mounted) return;
    String? label = await _showLabelDialog();
    if (label == null || label.isEmpty) label = "Recuerdo Especial"; 

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Subiendo recuerdo... ☁️")));
    }

    try {
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      final path = 'memories/$fileName';
      final imageBytes = await image.readAsBytes();

      await _supabase.storage.from('pet-photos').uploadBinary(path, imageBytes);
      final imageUrl = _supabase.storage.from('pet-photos').getPublicUrl(path);

      await _supabase.from('memories').insert({
        'user_id': _supabase.auth.currentUser?.id, 
        'pet_id': widget.petId,
        'photo_url': imageUrl,
        'label': label,
      });

      await _loadMemories(); 
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("¡Recuerdo guardado! ✨", style: TextStyle(fontWeight: FontWeight.bold)), backgroundColor: Color(0xFF10B981)));
      }

    } catch (e) {
      debugPrint("Error subiendo: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Error al subir foto", style: TextStyle(color: Colors.white)), backgroundColor: Colors.red));
      }
    }
  }

  // 4. DIÁLOGO PREMIUM
  void _showPremiumDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF0F172A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.stars_rounded, color: Color(0xFFF59E0B)),
            SizedBox(width: 10),
            Text("Límite Alcanzado", style: TextStyle(color: Colors.white, fontSize: 18)),
          ],
        ),
        content: const Text(
          "Has alcanzado el límite de 7 momentos gratuitos.\n\n¿Te gustaría tener espacio ilimitado para guardar todos los recuerdos de tu mascota en el futuro?",
          style: TextStyle(color: Colors.white70, height: 1.5),
        ),
        actionsAlignment: MainAxisAlignment.spaceBetween,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("No, gracias", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context); 
              await _userService.registerPremiumInterest(); 
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("¡Anotado! 🚀 Te avisaremos cuando esté disponible.", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                    backgroundColor: Color(0xFFF59E0B),
                  )
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF59E0B),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text("Sí, ¡me interesa!", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          )
        ],
      ),
    );
  }

  // 5. FUNCIÓN PARA BORRAR FOTO (SEGURO Y ESTABLE)
  void _showDeleteDialog(Map<String, dynamic> memory) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF0F172A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("¿Borrar Recuerdo?", style: TextStyle(color: Colors.white)),
        content: const Text("Esta acción liberará espacio para una foto nueva, pero no se puede deshacer.", style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text("Cancelar", style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext); 
              
              final String url = memory['photo_url'] ?? '';
              String? storagePath;
              if (url.isNotEmpty) {
                final uri = Uri.parse(url);
                final fileName = uri.pathSegments.last;
                storagePath = 'memories/$fileName';
              }
              
              try {
                // Envía la orden y ESPERA la confirmación del backend
                await _userService.deleteSpecialMoment(memory['id'].toString(), storagePath);
                await _loadMemories(); 
                
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Foto borrada exitosamente"), backgroundColor: Colors.green)
                  );
                }
              } catch (e) {
                await _loadMemories(); 
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("$e"), 
                      backgroundColor: Colors.redAccent, 
                      duration: const Duration(seconds: 4) 
                    )
                  );
                }
              }
            },
            child: const Text("Borrar", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // --- INTERFAZ VISUAL ORIGINAL ---

  Future<String?> _showLabelDialog() async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Nombre del recuerdo"),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: "Ej: Cumpleaños, Paseo..."),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancelar")),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text("Guardar"),
          ),
        ],
      ),
    );
  }

  void _showFullImage(String url, String label) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.network(url, fit: BoxFit.contain),
                ),
              ),
              const SizedBox(height: 15),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                child: Text(label, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              )
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.petId == null) {
      return const SizedBox(height: 50, child: Center(child: Text("Registra tu mascota para guardar fotos", style: TextStyle(color: Colors.white70))));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: _memories.length + 1,
            itemBuilder: (context, index) {
              if (index == _memories.length) {
                return _buildAddButton();
              }

              final memory = _memories[index];
              return GestureDetector(
                onTap: () => _showFullImage(memory['photo_url'], memory['label'] ?? ""),
                onLongPress: () => _showDeleteDialog(memory),
                child: _buildPhotoCard(memory),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPhotoCard(Map<String, dynamic> memory) {
    return Container(
      width: 100,
      margin: const EdgeInsets.only(right: 15),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white24),
        image: DecorationImage(
          image: NetworkImage(memory['photo_url']),
          fit: BoxFit.cover,
        ),
      ),
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 4),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.7),
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(11)),
          ),
          child: Text(
            memory['label'] ?? "", 
            textAlign: TextAlign.center, 
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)
          ),
        ),
      ),
    );
  }

  Widget _buildAddButton() {
    return GestureDetector(
      onTap: _handleNewMemoryTap, 
      child: Container(
        width: 80,
        margin: const EdgeInsets.only(right: 15),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white24),
        ),
        child: const Center(child: Icon(Icons.add, color: Colors.white, size: 30)),
      ),
    );
  }
}