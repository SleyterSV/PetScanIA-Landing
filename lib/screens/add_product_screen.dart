import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:petscania/services/marketplace_service.dart';
import 'package:petscania/theme/petscania_brand.dart';

class AddProductScreen extends StatefulWidget {
  const AddProductScreen({super.key});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _descController = TextEditingController();
  final _stockController = TextEditingController();
  final MarketplaceService _service = MarketplaceService();

  String _selectedCategory = 'Comida';
  final List<String> _categories = const [
    'Comida',
    'Juguetes',
    'Salud',
    'Accesorios',
    'Ropa',
  ];

  Uint8List? _imageBytes;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _descController.dispose();
    _stockController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      setState(() => _imageBytes = bytes);
    }
  }

  Future<void> _submitProduct() async {
    if (_nameController.text.trim().isEmpty ||
        _priceController.text.trim().isEmpty ||
        _stockController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Completa los datos obligatorios.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _service.addProduct(
        _nameController.text.trim(),
        double.tryParse(_priceController.text.trim()) ?? 0.0,
        _descController.text.trim(),
        int.tryParse(_stockController.text.trim()) ?? 1,
        _selectedCategory,
        _imageBytes,
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Producto publicado con exito.')),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No pude publicar el producto: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PetScaniaColors.mist,
      body: Stack(
        children: [
          Container(
            height: 270,
            decoration: const BoxDecoration(
              gradient: PetScaniaDecor.primaryGradient,
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _buildBackButton(),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Publicar producto',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Tu formulario de venta ya habla el mismo lenguaje visual de la marca.',
                              style: TextStyle(color: Color(0xD8FFFFFF)),
                            ),
                          ],
                        ),
                      ),
                      const PetScaniaBrandMark(size: 46),
                    ],
                  ),
                  const SizedBox(height: 18),
                  PetScaniaSurfaceCard(
                    borderRadius: BorderRadius.circular(32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        GestureDetector(
                          onTap: _pickImage,
                          child: Container(
                            height: 210,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: PetScaniaColors.cloud,
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(color: PetScaniaColors.line),
                              image: _imageBytes != null
                                  ? DecorationImage(
                                      image: MemoryImage(_imageBytes!),
                                      fit: BoxFit.cover,
                                    )
                                  : null,
                            ),
                            child: _imageBytes == null
                                ? Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Container(
                                        width: 72,
                                        height: 72,
                                        decoration: const BoxDecoration(
                                          gradient:
                                              PetScaniaDecor.primaryGradient,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.add_a_photo_rounded,
                                          color: Colors.white,
                                          size: 30,
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      const Text(
                                        'Sube la foto principal del producto',
                                        style: TextStyle(
                                          color: PetScaniaColors.ink,
                                          fontWeight: FontWeight.w900,
                                          fontSize: 16,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        'Una portada limpia ayuda a que se vea mas confiable.',
                                        style: TextStyle(
                                          color: PetScaniaColors.ink.withValues(
                                            alpha: 0.62,
                                          ),
                                        ),
                                      ),
                                    ],
                                  )
                                : null,
                          ),
                        ),
                        const SizedBox(height: 22),
                        _buildInput(
                          label: 'Nombre del producto',
                          controller: _nameController,
                          icon: Icons.shopping_bag_rounded,
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: _buildInput(
                                label: 'Precio (S/)',
                                controller: _priceController,
                                icon: Icons.attach_money_rounded,
                                keyboardType: TextInputType.number,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildInput(
                                label: 'Stock',
                                controller: _stockController,
                                icon: Icons.inventory_2_rounded,
                                keyboardType: TextInputType.number,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        _buildCategoryDropdown(),
                        const SizedBox(height: 14),
                        _buildInput(
                          label: 'Descripcion',
                          controller: _descController,
                          icon: Icons.description_rounded,
                          maxLines: 4,
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          height: 58,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: PetScaniaDecor.primaryGradient,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: ElevatedButton.icon(
                              onPressed: _isLoading ? null : _submitProduct,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                disabledBackgroundColor: Colors.transparent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                              icon: _isLoading
                                  ? const SizedBox.shrink()
                                  : const Icon(
                                      Icons.rocket_launch_rounded,
                                      color: Colors.white,
                                    ),
                              label: _isLoading
                                  ? const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2.6,
                                      ),
                                    )
                                  : const Text(
                                      'PUBLICAR EN LA TIENDA',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 0.4,
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
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(16),
      ),
      child: IconButton(
        onPressed: () => Navigator.pop(context),
        icon: const Icon(
          Icons.arrow_back_ios_new_rounded,
          color: Colors.white,
          size: 18,
        ),
      ),
    );
  }

  Widget _buildInput({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      style: const TextStyle(
        color: PetScaniaColors.ink,
        fontWeight: FontWeight.w700,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Color(0xFF7D96BF)),
        prefixIcon: Padding(
          padding: EdgeInsets.only(bottom: maxLines > 1 ? 64 : 0),
          child: Icon(icon, color: PetScaniaColors.royalBlue),
        ),
        filled: true,
        fillColor: PetScaniaColors.mist,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: PetScaniaColors.line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(
            color: PetScaniaColors.royalBlue,
            width: 1.6,
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: PetScaniaColors.mist,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: PetScaniaColors.line),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedCategory,
          isExpanded: true,
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: PetScaniaColors.royalBlue,
          ),
          items: _categories.map((category) {
            return DropdownMenuItem<String>(
              value: category,
              child: Text(
                category,
                style: const TextStyle(
                  color: PetScaniaColors.ink,
                  fontWeight: FontWeight.w700,
                ),
              ),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              setState(() => _selectedCategory = value);
            }
          },
        ),
      ),
    );
  }
}
