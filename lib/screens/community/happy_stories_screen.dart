import 'package:flutter/material.dart';
import 'package:petscania/services/community_seed_data.dart';
import 'package:petscania/theme/petscania_brand.dart';

class HappyStoriesScreen extends StatelessWidget {
  const HappyStoriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final stories = CommunitySeedData.happyStories;

    return Scaffold(
      backgroundColor: PetScaniaColors.royalBlue,
      appBar: AppBar(
        title: const Text(
          'Historias felices',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: PetScaniaBackground(
        showPaws: false,
        child: SafeArea(
          top: false,
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
            itemCount: stories.length + 1,
            separatorBuilder: (_, __) => const SizedBox(height: 14),
            itemBuilder: (context, index) {
              if (index == 0) {
                return _ImpactHeader(totalStories: stories.length);
              }

              final story = stories[index - 1];
              return PetScaniaSurfaceCard(
                padding: EdgeInsets.zero,
                borderRadius: BorderRadius.circular(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AspectRatio(
                      aspectRatio: 1.65,
                      child: ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(24),
                        ),
                        child: Image.network(
                          story.imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: PetScaniaColors.cloud,
                            child: const Icon(
                              Icons.favorite_rounded,
                              color: PetScaniaColors.royalBlue,
                              size: 42,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  story.title,
                                  style: const TextStyle(
                                    color: PetScaniaColors.ink,
                                    fontSize: 21,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 7,
                                ),
                                decoration: BoxDecoration(
                                  color: PetScaniaColors.cloud,
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  story.city,
                                  style: const TextStyle(
                                    color: PetScaniaColors.royalBlue,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            story.summary,
                            style: TextStyle(
                              color: PetScaniaColors.ink.withValues(
                                alpha: 0.72,
                              ),
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              const Icon(
                                Icons.celebration_rounded,
                                color: PetScaniaColors.rescueCoral,
                                size: 19,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  story.impact,
                                  style: const TextStyle(
                                    color: PetScaniaColors.ink,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                              IconButton(
                                tooltip: 'Compartir historia',
                                onPressed: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Historia lista para compartir.',
                                      ),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.ios_share_rounded),
                                color: PetScaniaColors.royalBlue,
                              ),
                            ],
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
      ),
    );
  }
}

class _ImpactHeader extends StatelessWidget {
  final int totalStories;

  const _ImpactHeader({required this.totalStories});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.20)),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.favorite_rounded,
              color: Colors.white,
              size: 30,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$totalStories historias destacadas',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Adopciones, reencuentros y vecinos que ayudaron a tiempo.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.78),
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
