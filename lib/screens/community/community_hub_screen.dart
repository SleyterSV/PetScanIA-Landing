import 'package:flutter/material.dart';
import 'package:petscania/models/community_campaign.dart';
import 'package:petscania/models/community_pet.dart';
import 'package:petscania/screens/chatbot_screen.dart';
import 'package:petscania/screens/community/campaigns_screen.dart';
import 'package:petscania/screens/community/community_list_screen.dart';
import 'package:petscania/screens/community/community_map_screen.dart';
import 'package:petscania/screens/community/happy_stories_screen.dart';
import 'package:petscania/screens/community/pet_match_screen.dart';
import 'package:petscania/screens/community/publish_pet_screen.dart';
import 'package:petscania/services/community_service.dart';
import 'package:petscania/services/community_seed_data.dart';
import 'package:petscania/theme/petscania_brand.dart';

class CommunityHubScreen extends StatefulWidget {
  const CommunityHubScreen({super.key});

  @override
  State<CommunityHubScreen> createState() => _CommunityHubScreenState();
}

class _CommunityHubScreenState extends State<CommunityHubScreen> {
  int _selectedIndex = 0;

  late final List<Widget> _pages = [
    _CommunityOverviewTab(onTabSelected: _switchTab),
    const AdoptionScreen(),
    const LostPetsScreen(),
    const FoundPetsScreen(),
    const CommunityMapScreen(),
  ];

  void _switchTab(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PetScaniaColors.royalBlue,
      appBar: AppBar(
        title: const Text(
          'Adopta y ayuda',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: PetScaniaBackground(
        child: SafeArea(
          top: false,
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
          fontSize: 11,
        ),
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 10,
        ),
        elevation: 0,
        currentIndex: _selectedIndex,
        onTap: _switchTab,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            activeIcon: Icon(Icons.dashboard_rounded),
            label: 'Resumen',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite_border_rounded),
            activeIcon: Icon(Icons.favorite_rounded),
            label: 'Adopta',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.campaign_outlined),
            activeIcon: Icon(Icons.campaign_rounded),
            label: 'Perdidas',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.travel_explore_outlined),
            activeIcon: Icon(Icons.travel_explore_rounded),
            label: 'Halladas',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.map_outlined),
            activeIcon: Icon(Icons.map_rounded),
            label: 'Mapa',
          ),
        ],
      ),
    );
  }
}

class _CommunityOverviewTab extends StatelessWidget {
  final ValueChanged<int> onTabSelected;

  const _CommunityOverviewTab({required this.onTabSelected});

  Future<void> _openPublish(
    BuildContext context,
    CommunityPostType type,
  ) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => PublishPetScreen(initialType: type)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final adoptions = CommunitySeedData.postsByType(CommunityPostType.adoption);
    final lost = CommunitySeedData.postsByType(CommunityPostType.lost);
    final found = CommunitySeedData.postsByType(CommunityPostType.found);

    return RefreshIndicator(
      onRefresh: () async =>
          Future<void>.delayed(const Duration(milliseconds: 450)),
      color: PetScaniaColors.skyBlue,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        children: [
          _buildHero(),
          const SizedBox(height: 16),
          _buildQuickActions(context),
          const SizedBox(height: 22),
          _buildMatchPromo(context),
          const SizedBox(height: 22),
          _CampaignPreviewSection(),
          const SizedBox(height: 22),
          _SectionHeader(
            title: 'Mascotas en adopcion cerca de ti',
            actionLabel: 'Ver todas',
            onAction: () => onTabSelected(1),
          ),
          const SizedBox(height: 10),
          _HorizontalPostList(posts: adoptions),
          const SizedBox(height: 22),
          _SectionHeader(
            title: 'Alertas recientes de mascotas perdidas',
            actionLabel: 'Ver alertas',
            onAction: () => onTabSelected(2),
          ),
          const SizedBox(height: 10),
          _HorizontalPostList(posts: lost),
          const SizedBox(height: 22),
          _SectionHeader(
            title: 'Mascotas encontradas',
            actionLabel: 'Ver halladas',
            onAction: () => onTabSelected(3),
          ),
          const SizedBox(height: 10),
          _HorizontalPostList(posts: found),
          const SizedBox(height: 22),
          _buildStories(context),
          const SizedBox(height: 14),
          _buildAiSupport(context),
        ],
      ),
    );
  }

  Widget _buildHero() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withValues(alpha: 0.20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: const Text(
                        'Lima y alrededores',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Adopta y ayuda',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 34,
                        fontWeight: FontWeight.w900,
                        height: 1.02,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Encuentra familias, activa alertas y mueve a tu barrio cuando una mascota necesita ayuda.',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.82),
                        height: 1.42,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: 88,
                height: 112,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Icon(
                  Icons.volunteer_activism_rounded,
                  color: PetScaniaColors.royalBlue,
                  size: 46,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _MetricPill(
                  value: '18',
                  label: 'adopciones',
                  color: PetScaniaColors.leaf,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MetricPill(
                  value: '41',
                  label: 'alertas',
                  color: PetScaniaColors.alert,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MetricPill(
                  value: '326',
                  label: 'difusiones',
                  color: PetScaniaColors.warmSun,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 620;
        return GridView.count(
          crossAxisCount: isWide ? 4 : 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: isWide ? 1.55 : 1.62,
          children: [
            _QuickActionCard(
              icon: Icons.favorite_rounded,
              label: 'Dar en adopcion',
              color: PetScaniaColors.leaf,
              onTap: () => _openPublish(context, CommunityPostType.adoption),
            ),
            _QuickActionCard(
              icon: Icons.campaign_rounded,
              label: 'Reportar perdida',
              color: PetScaniaColors.alert,
              onTap: () => _openPublish(context, CommunityPostType.lost),
            ),
            _QuickActionCard(
              icon: Icons.travel_explore_rounded,
              label: 'Encontre una mascota',
              color: PetScaniaColors.warmSun,
              onTap: () => _openPublish(context, CommunityPostType.found),
            ),
            _QuickActionCard(
              icon: Icons.pets_rounded,
              label: 'Quiero adoptar',
              color: PetScaniaColors.skyBlue,
              onTap: () => onTabSelected(1),
            ),
            _QuickActionCard(
              icon: Icons.style_rounded,
              label: 'Modo Match',
              color: PetScaniaColors.rescueCoral,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PetMatchScreen()),
              ),
            ),
            _QuickActionCard(
              icon: Icons.local_activity_rounded,
              label: 'Campanas gratis',
              color: PetScaniaColors.warmSun,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CampaignsScreen()),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMatchPromo(BuildContext context) {
    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const PetMatchScreen()),
      ),
      borderRadius: BorderRadius.circular(28),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: PetScaniaColors.line),
          boxShadow: PetScaniaDecor.softShadow,
        ),
        child: Row(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: PetScaniaColors.rescueCoral.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(22),
              ),
              child: const Icon(
                Icons.style_rounded,
                color: PetScaniaColors.rescueCoral,
                size: 34,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Modo Match de adopcion',
                    style: TextStyle(
                      color: PetScaniaColors.ink,
                      fontSize: 19,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'Desliza, conoce historias y contacta por WhatsApp cuando sientas conexion.',
                    style: TextStyle(
                      color: PetScaniaColors.ink.withValues(alpha: 0.64),
                      height: 1.35,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_rounded,
              color: PetScaniaColors.royalBlue,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStories(BuildContext context) {
    final stories = CommunitySeedData.happyStories;
    return Column(
      children: [
        _SectionHeader(
          title: 'Historias felices',
          actionLabel: 'Ver historias',
          onAction: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const HappyStoriesScreen()),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 218,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: stories.length,
            separatorBuilder: (_, __) => const SizedBox(width: 14),
            itemBuilder: (context, index) {
              final story = stories[index];
              return Container(
                width: 270,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: PetScaniaColors.line),
                  boxShadow: PetScaniaDecor.softShadow,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(24),
                        ),
                        child: Image.network(
                          story.imageUrl,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: PetScaniaColors.cloud,
                            child: const Icon(
                              Icons.favorite_rounded,
                              color: PetScaniaColors.royalBlue,
                              size: 38,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            story.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: PetScaniaColors.ink,
                              fontWeight: FontWeight.w900,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            story.impact,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: PetScaniaColors.ink.withValues(
                                alpha: 0.60,
                              ),
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAiSupport(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: PetScaniaColors.line),
        boxShadow: PetScaniaDecor.softShadow,
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: PetScaniaColors.cloud,
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              color: PetScaniaColors.royalBlue,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'IA de apoyo',
                  style: TextStyle(
                    color: PetScaniaColors.ink,
                    fontWeight: FontWeight.w900,
                    fontSize: 17,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Texto, hashtags, carteles y orientacion para actuar rapido.',
                  style: TextStyle(
                    color: PetScaniaColors.ink.withValues(alpha: 0.62),
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Abrir IA',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ChatbotScreen()),
            ),
            icon: const Icon(Icons.arrow_forward_rounded),
            color: PetScaniaColors.royalBlue,
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String actionLabel;
  final VoidCallback onAction;

  const _SectionHeader({
    required this.title,
    required this.actionLabel,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        TextButton(
          onPressed: onAction,
          child: Text(
            actionLabel,
            style: const TextStyle(
              color: PetScaniaColors.cloud,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }
}

class _CampaignPreviewSection extends StatelessWidget {
  final CommunityService _service = CommunityService();

  _CampaignPreviewSection();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<CommunityCampaign>>(
      future: _service.getCampaigns(),
      builder: (context, snapshot) {
        final campaigns = snapshot.data ?? CommunitySeedData.campaigns;
        final visible = campaigns.take(3).toList();

        return Column(
          children: [
            _SectionHeader(
              title: 'Campanas gratuitas',
              actionLabel: 'Ver todas',
              onAction: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CampaignsScreen()),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 172,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: visible.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final campaign = visible[index];
                  return InkWell(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const CampaignsScreen(),
                      ),
                    ),
                    borderRadius: BorderRadius.circular(22),
                    child: Container(
                      width: 252,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: PetScaniaColors.line),
                        boxShadow: PetScaniaDecor.softShadow,
                      ),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: const BorderRadius.horizontal(
                              left: Radius.circular(22),
                            ),
                            child: Image.network(
                              campaign.imageUrl,
                              width: 96,
                              height: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                width: 96,
                                color: PetScaniaColors.cloud,
                                child: const Icon(
                                  Icons.local_activity_rounded,
                                  color: PetScaniaColors.royalBlue,
                                ),
                              ),
                            ),
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
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: PetScaniaColors.leaf.withValues(
                                        alpha: 0.12,
                                      ),
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
                                      height: 1.14,
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    campaign.dateLabel,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: PetScaniaColors.ink.withValues(
                                        alpha: 0.58,
                                      ),
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
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
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

class _HorizontalPostList extends StatelessWidget {
  final List<PetCommunityPost> posts;

  const _HorizontalPostList({required this.posts});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 374,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: posts.length,
        separatorBuilder: (_, __) => const SizedBox(width: 14),
        itemBuilder: (context, index) {
          return SizedBox(
            width: 272,
            child: PetCommunityCard(post: posts[index], compact: true),
          );
        },
      ),
    );
  }
}

class _MetricPill extends StatelessWidget {
  final String value;
  final String label;
  final Color color;

  const _MetricPill({
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: PetScaniaColors.line),
            boxShadow: PetScaniaDecor.softShadow,
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  maxLines: 3,
                  overflow: TextOverflow.visible,
                  style: const TextStyle(
                    color: PetScaniaColors.ink,
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                    height: 1.12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
