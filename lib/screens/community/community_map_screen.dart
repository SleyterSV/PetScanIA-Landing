import 'package:flutter/material.dart';
import 'package:petscania/models/community_pet.dart';
import 'package:petscania/services/community_seed_data.dart';
import 'package:petscania/theme/petscania_brand.dart';

class CommunityMapScreen extends StatelessWidget {
  const CommunityMapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final alerts = CommunitySeedData.posts
        .where((post) => post.type != CommunityPostType.adoption)
        .toList();

    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
          sliver: SliverToBoxAdapter(
            child: Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Mapa comunitario',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        'Mascotas perdidas y encontradas por zona.',
                        style: TextStyle(
                          color: Colors.white70,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                FilledButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Vecinos cercanos seran notificados.'),
                      ),
                    );
                  },
                  icon: const Icon(Icons.notifications_active_rounded),
                  label: const Text('Alertar'),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: PetScaniaColors.royalBlue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    textStyle: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          sliver: SliverToBoxAdapter(
            child: Container(
              height: 380,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: PetScaniaColors.line),
                boxShadow: PetScaniaDecor.softShadow,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: Stack(
                  children: [
                    Positioned.fill(child: CustomPaint(painter: _MapPainter())),
                    Positioned(
                      top: 18,
                      left: 18,
                      child: _MapLegend(total: alerts.length),
                    ),
                    const _MapMarker(
                      left: 86,
                      top: 118,
                      label: 'Toby',
                      color: PetScaniaColors.alert,
                    ),
                    const _MapMarker(
                      right: 80,
                      top: 170,
                      label: 'Nina',
                      color: PetScaniaColors.alert,
                    ),
                    const _MapMarker(
                      left: 132,
                      bottom: 82,
                      label: 'Beagle',
                      color: PetScaniaColors.warmSun,
                    ),
                    const _MapMarker(
                      right: 54,
                      bottom: 66,
                      label: 'Gatito',
                      color: PetScaniaColors.warmSun,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          sliver: SliverList.separated(
            itemCount: alerts.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final alert = alerts[index];
              final color = alert.type == CommunityPostType.lost
                  ? PetScaniaColors.alert
                  : PetScaniaColors.warmSun;

              return PetScaniaSurfaceCard(
                padding: const EdgeInsets.all(14),
                borderRadius: BorderRadius.circular(22),
                child: Row(
                  children: [
                    Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(17),
                      ),
                      child: Icon(
                        alert.type == CommunityPostType.lost
                            ? Icons.campaign_rounded
                            : Icons.travel_explore_rounded,
                        color: color,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            alert.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: PetScaniaColors.ink,
                              fontWeight: FontWeight.w900,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${alert.location} · ${alert.distanceKm.toStringAsFixed(1)} km',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: PetScaniaColors.ink.withValues(
                                alpha: 0.62,
                              ),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Difundir',
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Alerta de ${alert.name} lista para compartir.',
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.ios_share_rounded),
                      color: PetScaniaColors.royalBlue,
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
}

class _MapLegend extends StatelessWidget {
  final int total;

  const _MapLegend({required this.total});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(18),
        boxShadow: PetScaniaDecor.softShadow,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.radar_rounded,
            color: PetScaniaColors.royalBlue,
            size: 18,
          ),
          const SizedBox(width: 8),
          Text(
            '$total alertas activas',
            style: const TextStyle(
              color: PetScaniaColors.ink,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _MapMarker extends StatelessWidget {
  final double? left;
  final double? top;
  final double? right;
  final double? bottom;
  final String label;
  final Color color;

  const _MapMarker({
    this.left,
    this.top,
    this.right,
    this.bottom,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: left,
      top: top,
      right: right,
      bottom: bottom,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(999),
              boxShadow: PetScaniaDecor.softShadow,
            ),
            child: Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 4),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.35),
                  blurRadius: 16,
                  spreadRadius: 3,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final water = Paint()..color = PetScaniaColors.paleBlue;
    final park = Paint()..color = const Color(0xFFE8F8EF);
    final road = Paint()
      ..color = PetScaniaColors.line
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;
    final minorRoad = Paint()
      ..color = const Color(0xFFEAF1F8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;

    canvas.drawRect(Offset.zero & size, Paint()..color = PetScaniaColors.mist);
    canvas.drawOval(
      Rect.fromLTWH(size.width * 0.58, -40, size.width * 0.58, 180),
      water,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(24, size.height * 0.58, size.width * 0.38, 110),
        const Radius.circular(30),
      ),
      park,
    );

    final mainPath = Path()
      ..moveTo(-20, size.height * 0.36)
      ..quadraticBezierTo(
        size.width * 0.36,
        size.height * 0.18,
        size.width + 30,
        size.height * 0.42,
      );
    canvas.drawPath(mainPath, road);

    final secondPath = Path()
      ..moveTo(size.width * 0.22, -20)
      ..quadraticBezierTo(
        size.width * 0.48,
        size.height * 0.46,
        size.width * 0.36,
        size.height + 20,
      );
    canvas.drawPath(secondPath, road);

    for (final dx in [0.18, 0.44, 0.72]) {
      final path = Path()
        ..moveTo(size.width * dx, size.height + 10)
        ..lineTo(size.width * (dx + 0.18), -10);
      canvas.drawPath(path, minorRoad);
    }

    for (final dy in [0.24, 0.52, 0.78]) {
      final path = Path()
        ..moveTo(-10, size.height * dy)
        ..lineTo(size.width + 10, size.height * (dy + 0.04));
      canvas.drawPath(path, minorRoad);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
