import 'package:flutter/material.dart';
import 'package:petscania/screens/chatbot_screen.dart'; // IMPORTANTE: Importar el Chatbot

class QuickAccessGrid extends StatelessWidget {
  final Function(int) onTabSelected; 

  const QuickAccessGrid({super.key, required this.onTabSelected});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 15,
      mainAxisSpacing: 15,
      childAspectRatio: 1.5,
      children: [
        // 1. CHATBOT (Abre pantalla nueva)
        _buildSketchButton(
          "CHATBOT\n(IA)", 
          Icons.chat_bubble_outline_rounded, 
          () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ChatbotScreen()),
            );
          }
        ),
        
        // 2. ANÁLISIS (Va a la pestaña del Escáner - Index 1)
        _buildSketchButton(
          "ANÁLISIS\n(IA)", 
          Icons.document_scanner_outlined, 
          () => onTabSelected(1) // Cambia a la pestaña Vet IA
        ),
        
        // 3. MARKET (Index 2)
        _buildSketchButton("MARKETPLACE", Icons.storefront_outlined, () => onTabSelected(2)),
        
        // 4. HISTORIAL (Index 3 - Agenda)
        _buildSketchButton("HISTORIAL", Icons.history_edu_outlined, () => onTabSelected(3)),
      ],
    );
  }

  Widget _buildSketchButton(String text, IconData icon, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.black, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 4,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 28, color: const Color(0xFF2D3436)),
              const SizedBox(height: 8),
              Text(
                text,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFF2D3436)),
              )
            ],
          ),
        ),
      ),
    );
  }
}