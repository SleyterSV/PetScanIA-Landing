import 'package:flutter/material.dart';
import 'package:petscania/screens/chatbot_screen.dart';
import 'package:petscania/screens/community/campaigns_screen.dart';
import 'package:petscania/screens/community/community_hub_screen.dart';
import 'package:petscania/screens/family/family_medical_history_screen.dart';
import 'package:petscania/screens/family/family_roles_screen.dart';
import 'package:petscania/screens/login_screen.dart';
import 'package:petscania/screens/terms_screen.dart';
import 'package:petscania/screens/user_profile_screen.dart';
import 'package:petscania/screens/vet_ia_screen.dart';
import 'package:petscania/theme/petscania_brand.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AppDrawer extends StatelessWidget {
  final Function(int) onTabSelected;

  const AppDrawer({super.key, required this.onTabSelected});

  Future<void> _logout(BuildContext context) async {
    await Supabase.instance.client.auth.signOut();
    if (context.mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  void _openScreen(BuildContext context, Widget screen) {
    Navigator.pop(context);
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Container(
        decoration: const BoxDecoration(
          gradient: PetScaniaDecor.primaryGradient,
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(20, 60, 20, 30),
              child: const Column(
                children: [
                  PetScaniaBrandMark(size: 88),
                  SizedBox(height: 20),
                  PetScaniaWordmark(fontSize: 30),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 15),
                children: [
                  _buildMenuItem(
                    context,
                    Icons.home_rounded,
                    'Panel de inicio',
                    () {
                      Navigator.pop(context);
                      onTabSelected(0);
                    },
                  ),
                  _buildMenuItem(
                    context,
                    Icons.volunteer_activism_rounded,
                    'Adopta y ayuda',
                    () => _openScreen(context, const CommunityHubScreen()),
                  ),
                  _buildMenuItem(
                    context,
                    Icons.local_activity_rounded,
                    'Campanas gratuitas',
                    () => _openScreen(context, const CampaignsScreen()),
                  ),
                  _buildMenuItem(
                    context,
                    Icons.health_and_safety_rounded,
                    'Historial medico familiar',
                    () => _openScreen(
                      context,
                      const FamilyMedicalHistoryScreen(),
                    ),
                  ),
                  _buildMenuItem(
                    context,
                    Icons.family_restroom_rounded,
                    'Familia y roles',
                    () => _openScreen(context, const FamilyRolesScreen()),
                  ),
                  _buildMenuItem(
                    context,
                    Icons.document_scanner_rounded,
                    'Escaner medico IA',
                    () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const VetIAScreen(),
                        ),
                      );
                    },
                  ),
                  _buildMenuItem(
                    context,
                    Icons.chat_bubble_rounded,
                    'VetIA asistente',
                    () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ChatbotScreen(),
                        ),
                      );
                    },
                  ),
                  _buildMenuItem(
                    context,
                    Icons.storefront_rounded,
                    'Marketplace',
                    () {
                      Navigator.pop(context);
                      onTabSelected(1);
                    },
                  ),
                  _buildMenuItem(
                    context,
                    Icons.local_hospital_rounded,
                    'Clinicas y mapa',
                    () {
                      Navigator.pop(context);
                      onTabSelected(2);
                    },
                  ),
                  _buildMenuItem(
                    context,
                    Icons.calendar_month_rounded,
                    'Agenda digital',
                    () {
                      Navigator.pop(context);
                      onTabSelected(3);
                    },
                  ),
                  _buildMenuItem(
                    context,
                    Icons.person_rounded,
                    'Mi perfil',
                    () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const UserProfileScreen(),
                        ),
                      );
                    },
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 15),
                    child: Divider(color: Color(0x24FFFFFF), thickness: 1),
                  ),
                  _buildMenuItem(
                    context,
                    Icons.gavel_rounded,
                    'Terminos y privacidad',
                    () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              const TermsScreen(isViewOnly: true),
                        ),
                      );
                    },
                    isSmall: true,
                  ),
                  _buildMenuItem(
                    context,
                    Icons.logout_rounded,
                    'Cerrar sesion',
                    () => _logout(context),
                    isDestructive: true,
                  ),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(20.0),
              child: Text(
                'PetScanIA v2.0 - 2026',
                style: TextStyle(
                  color: Colors.white38,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context,
    IconData icon,
    String title,
    VoidCallback onTap, {
    bool isDestructive = false,
    bool isSmall = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isDestructive
            ? Colors.red.withValues(alpha: 0.12)
            : Colors.white.withValues(alpha: 0.11),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDestructive
              ? Colors.red.withValues(alpha: 0.26)
              : Colors.white.withValues(alpha: 0.24),
          width: 1,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
        leading: Icon(
          icon,
          color: isDestructive ? Colors.redAccent : PetScaniaColors.cloud,
          size: isSmall ? 20 : 24,
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: isSmall ? FontWeight.normal : FontWeight.bold,
            color: isDestructive ? Colors.redAccent : Colors.white,
            fontSize: isSmall ? 13 : 15,
          ),
        ),
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
    );
  }
}
