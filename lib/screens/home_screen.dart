import 'package:flutter/material.dart';
import 'package:petscania/models/community_campaign.dart';
import 'package:petscania/screens/calendar_screen.dart';
import 'package:petscania/screens/chatbot_screen.dart';
import 'package:petscania/screens/community/campaigns_screen.dart';
import 'package:petscania/screens/community/community_hub_screen.dart';
import 'package:petscania/screens/family/family_medical_history_screen.dart';
import 'package:petscania/screens/family/family_roles_screen.dart';
import 'package:petscania/screens/maps/clinic_map_screen.dart';
import 'package:petscania/screens/marketplace_screen.dart';
import 'package:petscania/screens/register_pet_screen.dart';
import 'package:petscania/screens/services_screen.dart';
import 'package:petscania/screens/vet_ia_screen.dart';
import 'package:petscania/services/account_service.dart';
import 'package:petscania/services/community_service.dart';
import 'package:petscania/services/user_service.dart';
import 'package:petscania/theme/petscania_brand.dart';
import 'package:petscania/widgets/app_drawer.dart';
import 'package:petscania/widgets/photo_reel.dart';
import 'package:petscania/widgets/upcoming_appointment_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const DashboardTab(),
    const MarketplaceScreen(),
    const ClinicMapScreen(),
    const CalendarScreen(),
  ];

  void _switchTab(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PetScaniaColors.royalBlue,
      endDrawer: AppDrawer(onTabSelected: _switchTab),
      body: PetScaniaBackground(
        child: SafeArea(
          child: IndexedStack(index: _selectedIndex, children: _pages),
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: PetScaniaColors.white,
        boxShadow: [
          BoxShadow(
            color: PetScaniaColors.ink.withValues(alpha: 0.12),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: PetScaniaColors.white,
        selectedItemColor: PetScaniaColors.royalBlue,
        unselectedItemColor: const Color(0xFF94A3B8),
        showUnselectedLabels: true,
        selectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w900,
          fontSize: 12,
        ),
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 11,
        ),
        elevation: 0,
        currentIndex: _selectedIndex,
        onTap: _switchTab,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home_filled),
            label: 'Inicio',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.storefront_outlined),
            activeIcon: Icon(Icons.storefront_rounded),
            label: 'Market',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.local_hospital_outlined),
            activeIcon: Icon(Icons.local_hospital_rounded),
            label: 'Clinicas',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today_outlined),
            activeIcon: Icon(Icons.calendar_today_rounded),
            label: 'Agenda',
          ),
        ],
      ),
    );
  }
}

class DashboardTab extends StatefulWidget {
  const DashboardTab({super.key});

  @override
  State<DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<DashboardTab> {
  final UserService _userService = UserService();
  final CommunityService _communityService = CommunityService();
  final AccountService _accountService = AccountService();

  String _userName = 'Cargando...';
  Map<String, dynamic>? _currentPet;
  bool _isLoadingData = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    if (!mounted) {
      return;
    }
    setState(() => _isLoadingData = true);

    final name = await _userService.getUserName();
    final pet = await _userService.getMainPet();

    if (mounted) {
      setState(() {
        _userName = name;
        _currentPet = pet;
        _isLoadingData = false;
      });
    }
  }

  Future<void> _handlePetNavigation({Map<String, dynamic>? petToEdit}) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RegisterPetScreen(petToEdit: petToEdit),
      ),
    );

    if (result == true) {
      _loadUserData();
    }
  }

  void _navigateToTab(int index) {
    final homeState = context.findAncestorStateOfType<_HomeScreenState>();
    homeState?._switchTab(index);
  }

  void _openCommunityHub() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CommunityHubScreen()),
    );
  }

  void _openCampaigns() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CampaignsScreen()),
    );
  }

  void _openMedicalHistory() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const FamilyMedicalHistoryScreen()),
    );
  }

  void _openFamilyRoles() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const FamilyRolesScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _loadUserData,
      color: PetScaniaColors.skyBlue,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 20),
            Center(
              child: _isLoadingData
                  ? const CircularProgressIndicator(
                      color: PetScaniaColors.skyBlue,
                    )
                  : _buildSmartAvatar(),
            ),
            const SizedBox(height: 28),
            _buildAdoptAndHelpCard(),
            const SizedBox(height: 16),
            _buildCampaignsHomeSection(),
            const SizedBox(height: 16),
            _buildMedicalFamilyCard(),
            const SizedBox(height: 35),
            _buildSectionHeader('MOMENTOS ESPECIALES'),
            const SizedBox(height: 15),
            PhotoReel(petId: _currentPet?['id']),
            const SizedBox(height: 35),
            _buildSectionHeader('HERRAMIENTAS IA'),
            const SizedBox(height: 15),
            Row(
              children: [
                Expanded(
                  child: _buildToolCard(
                    'Escaner IA',
                    Icons.document_scanner_rounded,
                    PetScaniaColors.royalBlue,
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const VetIAScreen(),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: _buildToolCard(
                    'Chatbot IA',
                    Icons.smart_toy_rounded,
                    PetScaniaColors.skyBlue,
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ChatbotScreen(),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),
            _buildSecondaryToolsRow(),
            const SizedBox(height: 15),
            Row(
              children: [
                Expanded(
                  child: _buildToolCard(
                    'Marketplace',
                    Icons.storefront_rounded,
                    const Color(0xFF4A8CD8),
                    () => _navigateToTab(1),
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: _buildToolCard(
                    'Familia y roles',
                    Icons.family_restroom_rounded,
                    const Color(0xFF6BBDEB),
                    _openFamilyRoles,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 35),
            _buildSectionHeader('PROXIMAMENTE'),
            const SizedBox(height: 15),
            UpcomingAppointmentCard(onEmptyTap: () => _navigateToTab(2)),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Bienvenido de nuevo,',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.74),
                  fontSize: 15,
                ),
              ),
              Text(
                _userName,
                style: const TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: () => Scaffold.of(context).openEndDrawer(),
          icon: const Icon(Icons.menu_rounded, size: 32, color: Colors.white),
        ),
      ],
    );
  }

  Widget _buildSmartAvatar() {
    if (_currentPet == null) {
      return GestureDetector(
        onTap: () => _handlePetNavigation(),
        child: Container(
          height: 180,
          width: 180,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: 0.12),
            border: Border.all(color: Colors.white24, width: 2),
            boxShadow: [
              BoxShadow(
                color: PetScaniaColors.ink.withValues(alpha: 0.22),
                blurRadius: 24,
              ),
            ],
          ),
          child: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add_circle_outline, size: 50, color: Colors.white70),
              SizedBox(height: 10),
              Text(
                'Registrar\nMascota',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        GestureDetector(
          onTap: () => ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Manten presionado para editar perfil'),
              duration: Duration(seconds: 1),
            ),
          ),
          onLongPress: () => _handlePetNavigation(petToEdit: _currentPet),
          child: Container(
            height: 180,
            width: 180,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              border: Border.all(color: PetScaniaColors.skyBlue, width: 4),
              boxShadow: [
                BoxShadow(
                  color: PetScaniaColors.skyBlue.withValues(alpha: 0.35),
                  blurRadius: 25,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: ClipOval(
              child: Image.network(
                _currentPet!['photo_url'] ??
                    'https://cdn-icons-png.flaticon.com/512/616/616408.png',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    const Icon(Icons.pets, size: 80, color: Colors.grey),
              ),
            ),
          ),
        ),
        const SizedBox(height: 15),
        Text(
          _currentPet!['name'],
          style: const TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w900,
            color: Colors.white,
          ),
        ),
        Text(
          _currentPet!['breed'] ?? 'Raza no especificada',
          style: const TextStyle(
            fontSize: 14,
            color: Colors.white70,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildAdoptAndHelpCard() {
    return GestureDetector(
      onTap: _openCommunityHub,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: PetScaniaColors.paleBlue),
          boxShadow: [
            BoxShadow(
              color: PetScaniaColors.ink.withValues(alpha: 0.18),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                gradient: PetScaniaDecor.primaryGradient,
                borderRadius: BorderRadius.circular(22),
              ),
              child: const Icon(
                Icons.volunteer_activism_rounded,
                color: Colors.white,
                size: 34,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Adopta y ayuda',
                    style: TextStyle(
                      color: PetScaniaColors.ink,
                      fontSize: 23,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'Adopciones, mascotas perdidas, encontradas y comunidad local.',
                    style: TextStyle(
                      color: PetScaniaColors.ink.withValues(alpha: 0.64),
                      height: 1.35,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.arrow_forward_rounded,
              color: PetScaniaColors.royalBlue,
              size: 28,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCampaignsHomeSection() {
    return FutureBuilder<List<CommunityCampaign>>(
      future: _communityService.getCampaigns(),
      builder: (context, snapshot) {
        final campaigns = (snapshot.data ?? []).take(3).toList();

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: PetScaniaColors.paleBlue),
            boxShadow: [
              BoxShadow(
                color: PetScaniaColors.ink.withValues(alpha: 0.14),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: PetScaniaColors.warmSun.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Icon(
                      Icons.local_activity_rounded,
                      color: Color(0xFFD99100),
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Campanas gratuitas',
                          style: TextStyle(
                            color: PetScaniaColors.ink,
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        SizedBox(height: 3),
                        Text(
                          'Vacunatones, desparasitaciones y jornadas cerca.',
                          style: TextStyle(
                            color: Color(0xFF6B7F9F),
                            fontWeight: FontWeight.w700,
                            height: 1.25,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Ver campanas',
                    onPressed: _openCampaigns,
                    icon: const Icon(Icons.arrow_forward_rounded),
                    color: PetScaniaColors.royalBlue,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              if (snapshot.connectionState == ConnectionState.waiting)
                const LinearProgressIndicator(
                  minHeight: 3,
                  color: PetScaniaColors.royalBlue,
                  backgroundColor: PetScaniaColors.cloud,
                )
              else if (campaigns.isEmpty)
                const Text(
                  'Pronto apareceran campanas verificadas de tu zona.',
                  style: TextStyle(
                    color: Color(0xFF6B7F9F),
                    fontWeight: FontWeight.w700,
                  ),
                )
              else
                SizedBox(
                  height: 156,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: campaigns.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemBuilder: (context, index) {
                      return _HomeCampaignCard(
                        campaign: campaigns[index],
                        onTap: _openCampaigns,
                      );
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMedicalFamilyCard() {
    return FutureBuilder<FamilyOverview>(
      future: _accountService.getFamilyOverview(),
      builder: (context, snapshot) {
        final overview = snapshot.data;

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: PetScaniaColors.paleBlue),
            boxShadow: [
              BoxShadow(
                color: PetScaniaColors.ink.withValues(alpha: 0.14),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      gradient: PetScaniaDecor.primaryGradient,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(
                      Icons.health_and_safety_rounded,
                      color: Colors.white,
                      size: 31,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Historial medico',
                          style: TextStyle(
                            color: PetScaniaColors.ink,
                            fontSize: 21,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          overview == null
                              ? 'Familia, doctores y mascotas sincronizados.'
                              : '${overview.familyName}: ${overview.memberCount} miembros con acceso.',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF6B7F9F),
                            fontWeight: FontWeight.w700,
                            height: 1.25,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),
              Row(
                children: [
                  Expanded(
                    child: _MiniStat(
                      value: '${overview?.petCount ?? 0}',
                      label: 'mascotas',
                      icon: Icons.pets_rounded,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _MiniStat(
                      value: '${overview?.medicalRecordsCount ?? 0}',
                      label: 'registros',
                      icon: Icons.receipt_long_rounded,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _MiniStat(
                      value: '${overview?.memberCount ?? 0}',
                      label: 'familia',
                      icon: Icons.group_rounded,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _openMedicalHistory,
                      icon: const Icon(Icons.timeline_rounded, size: 18),
                      label: const Text('Ver historial'),
                      style: FilledButton.styleFrom(
                        backgroundColor: PetScaniaColors.royalBlue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        textStyle: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  IconButton(
                    tooltip: 'Familia y roles',
                    onPressed: _openFamilyRoles,
                    icon: const Icon(Icons.admin_panel_settings_rounded),
                    color: PetScaniaColors.royalBlue,
                    style: IconButton.styleFrom(
                      backgroundColor: PetScaniaColors.cloud,
                      fixedSize: const Size(52, 52),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHomeCampaignImage(CommunityCampaign campaign) {
    return ClipRRect(
      borderRadius: const BorderRadius.horizontal(left: Radius.circular(20)),
      child: Image.network(
        campaign.imageUrl,
        width: 94,
        height: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          width: 94,
          color: PetScaniaColors.cloud,
          child: const Icon(
            Icons.local_activity_rounded,
            color: PetScaniaColors.royalBlue,
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w900,
            color: Colors.white70,
            letterSpacing: 1.2,
          ),
        ),
        Container(
          margin: const EdgeInsets.only(top: 5),
          width: 40,
          height: 3,
          color: PetScaniaColors.skyBlue,
        ),
      ],
    );
  }

  Widget _buildToolCard(
    String title,
    IconData icon,
    Color iconColor,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(26),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 30, color: iconColor),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 13,
                color: PetScaniaColors.ink,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSecondaryToolsRow() {
    return Row(
      children: [
        Expanded(
          child: _buildSquareButton(
            title: 'Clinicas\nVeterinarias',
            icon: Icons.local_hospital_rounded,
            iconColor: PetScaniaColors.royalBlue,
            bgColor: PetScaniaColors.cloud,
            onTap: () => _navigateToTab(2),
          ),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: _buildSquareButton(
            title: 'Servicios\nMascotas',
            icon: Icons.auto_awesome_rounded,
            iconColor: PetScaniaColors.skyBlue,
            bgColor: PetScaniaColors.cloud,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ServicesScreen()),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSquareButton({
    required String title,
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 130,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
              child: Icon(icon, color: iconColor, size: 30),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 13,
                color: PetScaniaColors.ink,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeCampaignCard extends StatelessWidget {
  final CommunityCampaign campaign;
  final VoidCallback onTap;

  const _HomeCampaignCard({required this.campaign, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final dashboardState = context
        .findAncestorStateOfType<_DashboardTabState>();

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 268,
        decoration: BoxDecoration(
          color: PetScaniaColors.mist,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: PetScaniaColors.line),
        ),
        child: Row(
          children: [
            dashboardState?._buildHomeCampaignImage(campaign) ??
                Container(
                  width: 94,
                  color: PetScaniaColors.cloud,
                  child: const Icon(Icons.local_activity_rounded),
                ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: PetScaniaColors.leaf.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        campaign.category,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: PetScaniaColors.leaf,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      campaign.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: PetScaniaColors.ink,
                        fontWeight: FontWeight.w900,
                        height: 1.12,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      campaign.dateLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: PetScaniaColors.ink.withValues(alpha: 0.58),
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      campaign.placeLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: PetScaniaColors.royalBlue,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;

  const _MiniStat({
    required this.value,
    required this.label,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 10),
      decoration: BoxDecoration(
        color: PetScaniaColors.cloud,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(icon, color: PetScaniaColors.royalBlue, size: 18),
          const SizedBox(height: 5),
          Text(
            value,
            style: const TextStyle(
              color: PetScaniaColors.ink,
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: PetScaniaColors.ink.withValues(alpha: 0.58),
              fontSize: 10,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
