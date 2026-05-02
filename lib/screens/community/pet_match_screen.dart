import 'package:flutter/material.dart';
import 'package:petscania/models/community_pet.dart';
import 'package:petscania/services/community_service.dart';
import 'package:petscania/theme/petscania_brand.dart';
import 'package:url_launcher/url_launcher.dart';

class PetMatchScreen extends StatefulWidget {
  const PetMatchScreen({super.key});

  @override
  State<PetMatchScreen> createState() => _PetMatchScreenState();
}

class _PetMatchScreenState extends State<PetMatchScreen> {
  final CommunityService _service = CommunityService();
  final PageController _controller = PageController(viewportFraction: 0.92);

  List<PetCommunityPost> _posts = [];
  int _index = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final posts = await _service.getPosts(type: CommunityPostType.adoption);
    if (!mounted) {
      return;
    }
    setState(() {
      _posts = posts;
      _isLoading = false;
    });
  }

  Future<void> _next(String action) async {
    if (_posts.isEmpty) {
      return;
    }
    await _service.saveMatchAction(postId: _posts[_index].id, action: action);
    if (_index < _posts.length - 1) {
      await _controller.nextPage(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOut,
      );
    } else {
      setState(() => _index = 0);
      _controller.jumpToPage(0);
    }
  }

  Future<void> _contact() async {
    final post = _posts[_index];
    await _service.saveMatchAction(postId: post.id, action: 'contact');
    final phone = post.contactPhone.replaceAll(RegExp(r'\D'), '');
    final text =
        'Hola, vi a ${post.name} en PetScanIA y quiero saber mas sobre su adopcion.';
    final uri = Uri.parse('https://wa.me/$phone?text=${Uri.encodeComponent(text)}');
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PetScaniaColors.royalBlue,
      appBar: AppBar(
        title: const Text(
          'Modo Match',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: PetScaniaBackground(
        showPaws: false,
        child: SafeArea(
          top: false,
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(
                    color: PetScaniaColors.skyBlue,
                  ),
                )
              : _posts.isEmpty
                  ? const Center(
                      child: Text(
                        'Aun no hay mascotas para adoptar.',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    )
                  : Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                          child: _MatchHeader(
                            index: _index + 1,
                            total: _posts.length,
                          ),
                        ),
                        Expanded(
                          child: PageView.builder(
                            controller: _controller,
                            itemCount: _posts.length,
                            onPageChanged: (value) =>
                                setState(() => _index = value),
                            itemBuilder: (context, index) {
                              return Padding(
                                padding: const EdgeInsets.only(
                                  left: 4,
                                  right: 4,
                                  bottom: 14,
                                ),
                                child: _MatchPetCard(post: _posts[index]),
                              );
                            },
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(22, 0, 22, 24),
                          child: Row(
                            children: [
                              _RoundAction(
                                icon: Icons.close_rounded,
                                color: PetScaniaColors.alert,
                                onTap: () => _next('skip'),
                              ),
                              const Spacer(),
                              _RoundAction(
                                icon: Icons.campaign_rounded,
                                color: PetScaniaColors.warmSun,
                                onTap: () => _next('share_intent'),
                              ),
                              const Spacer(),
                              _RoundAction(
                                icon: Icons.favorite_rounded,
                                color: PetScaniaColors.leaf,
                                large: true,
                                onTap: _contact,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
        ),
      ),
    );
  }
}

class _MatchHeader extends StatelessWidget {
  final int index;
  final int total;

  const _MatchHeader({required this.index, required this.total});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          const Icon(Icons.favorite_rounded, color: Colors.white),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Desliza y encuentra a quien puedes ayudar',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          Text(
            '$index/$total',
            style: const TextStyle(
              color: Colors.white70,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _MatchPetCard extends StatelessWidget {
  final PetCommunityPost post;

  const _MatchPetCard({required this.post});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: PetScaniaColors.ink.withValues(alpha: 0.22),
            blurRadius: 28,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: Stack(
          children: [
            Positioned.fill(
              child: Image.network(
                post.imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: PetScaniaColors.cloud,
                  child: const Icon(
                    Icons.pets_rounded,
                    color: PetScaniaColors.royalBlue,
                    size: 72,
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.10),
                      Colors.black.withValues(alpha: 0.88),
                    ],
                    stops: const [0, 0.48, 1],
                  ),
                ),
              ),
            ),
            Positioned(
              top: 18,
              left: 18,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '${post.distanceKm.toStringAsFixed(1)} km',
                  style: const TextStyle(
                    color: PetScaniaColors.royalBlue,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
            Positioned(
              left: 22,
              right: 22,
              bottom: 22,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    post.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 42,
                      fontWeight: FontWeight.w900,
                      height: 1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${post.species} · ${post.age} · ${post.size} · ${post.placeLabel}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    post.description,
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.86),
                      height: 1.35,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _MatchChip(text: post.healthStatus),
                      _MatchChip(text: post.vaccines),
                      if (post.verified) const _MatchChip(text: 'Verificado'),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MatchChip extends StatelessWidget {
  final String text;

  const _MatchChip({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: PetScaniaColors.ink,
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _RoundAction extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final bool large;

  const _RoundAction({
    required this.icon,
    required this.color,
    required this.onTap,
    this.large = false,
  });

  @override
  Widget build(BuildContext context) {
    final size = large ? 74.0 : 60.0;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: PetScaniaDecor.softShadow,
        ),
        child: Icon(icon, color: color, size: large ? 34 : 28),
      ),
    );
  }
}
