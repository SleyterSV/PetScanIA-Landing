import 'package:flutter/material.dart';
import 'package:petscania/models/community_campaign.dart';
import 'package:petscania/services/community_service.dart';
import 'package:petscania/theme/petscania_brand.dart';
import 'package:url_launcher/url_launcher.dart';

class CampaignsScreen extends StatefulWidget {
  const CampaignsScreen({super.key});

  @override
  State<CampaignsScreen> createState() => _CampaignsScreenState();
}

class _CampaignsScreenState extends State<CampaignsScreen> {
  final CommunityService _service = CommunityService();
  late Future<List<CommunityCampaign>> _campaignsFuture;

  @override
  void initState() {
    super.initState();
    _campaignsFuture = _service.getCampaigns();
  }

  Future<void> _reload() async {
    setState(() {
      _campaignsFuture = _service.getCampaigns();
    });
    await _campaignsFuture;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PetScaniaColors.royalBlue,
      appBar: AppBar(
        title: const Text(
          'Campanas gratuitas',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: PetScaniaBackground(
        showPaws: false,
        child: SafeArea(
          top: false,
          child: FutureBuilder<List<CommunityCampaign>>(
            future: _campaignsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(
                    color: PetScaniaColors.skyBlue,
                  ),
                );
              }

              final campaigns = snapshot.data ?? [];

              return RefreshIndicator(
                onRefresh: _reload,
                color: PetScaniaColors.royalBlue,
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
                  itemCount: campaigns.length + 1,
                  separatorBuilder: (_, __) => const SizedBox(height: 14),
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return const _CampaignHero();
                    }
                    return _CampaignCard(campaign: campaigns[index - 1]);
                  },
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _CampaignHero extends StatelessWidget {
  const _CampaignHero();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          Container(
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.local_activity_rounded,
              color: PetScaniaColors.royalBlue,
              size: 32,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Ayuda gratuita cerca de ti',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'Vacunatones, desparasitaciones, esterilizaciones, placas y jornadas solidarias.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.78),
                    height: 1.35,
                    fontWeight: FontWeight.w700,
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

class _CampaignCard extends StatefulWidget {
  final CommunityCampaign campaign;

  const _CampaignCard({required this.campaign});

  @override
  State<_CampaignCard> createState() => _CampaignCardState();
}

class _CampaignCardState extends State<_CampaignCard> {
  final CommunityService _service = CommunityService();
  bool _reserved = false;

  CommunityCampaign get campaign => widget.campaign;

  Future<void> _share() async {
    final text =
        '${campaign.title} en ${campaign.placeLabel}. ${campaign.dateLabel}. ${campaign.description} #PetScanIA #${campaign.category}';
    final uri = Uri.parse('https://wa.me/?text=${Uri.encodeComponent(text)}');
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _reserve() async {
    setState(() => _reserved = true);
    try {
      await _service.reserveCampaign(campaign.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cupo reservado en Supabase.')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Reserva marcada. Falta tabla de reservas en Supabase.',
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final progress = campaign.capacity == 0
        ? 0.0
        : (campaign.reserved / campaign.capacity).clamp(0.0, 1.0);

    return PetScaniaSurfaceCard(
      padding: EdgeInsets.zero,
      borderRadius: BorderRadius.circular(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 1.9,
            child: Stack(
              children: [
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
                    child: Image.network(
                      campaign.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: PetScaniaColors.cloud,
                        child: const Icon(
                          Icons.local_activity_rounded,
                          color: PetScaniaColors.royalBlue,
                          size: 42,
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 12,
                  top: 12,
                  child: _Badge(
                    label: campaign.category,
                    color: PetScaniaColors.leaf,
                  ),
                ),
                if (campaign.isVerified)
                  const Positioned(
                    right: 12,
                    top: 12,
                    child: _VerifiedBadge(),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  campaign.title,
                  style: const TextStyle(
                    color: PetScaniaColors.ink,
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                _InfoLine(
                  icon: Icons.event_rounded,
                  text: campaign.dateLabel,
                ),
                const SizedBox(height: 6),
                _InfoLine(
                  icon: Icons.place_rounded,
                  text: '${campaign.location} · ${campaign.placeLabel}',
                ),
                const SizedBox(height: 10),
                Text(
                  campaign.description,
                  style: TextStyle(
                    color: PetScaniaColors.ink.withValues(alpha: 0.68),
                    height: 1.35,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 8,
                    backgroundColor: PetScaniaColors.cloud,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      PetScaniaColors.royalBlue,
                    ),
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  '${campaign.remainingSlots} cupos disponibles · ${campaign.organizer}',
                  style: const TextStyle(
                    color: PetScaniaColors.royalBlue,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: _reserved ? null : _reserve,
                        icon: Icon(
                          _reserved
                              ? Icons.check_circle_rounded
                              : Icons.bookmark_add_rounded,
                          size: 18,
                        ),
                        label: Text(_reserved ? 'Reservado' : 'Reservar'),
                        style: FilledButton.styleFrom(
                          backgroundColor: PetScaniaColors.royalBlue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    IconButton(
                      tooltip: 'Compartir campana',
                      onPressed: _share,
                      icon: const Icon(Icons.ios_share_rounded),
                      color: PetScaniaColors.royalBlue,
                      style: IconButton.styleFrom(
                        backgroundColor: PetScaniaColors.cloud,
                        fixedSize: const Size(48, 48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoLine({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: PetScaniaColors.royalBlue, size: 17),
        const SizedBox(width: 7),
        Expanded(
          child: Text(
            text,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: PetScaniaColors.ink.withValues(alpha: 0.68),
              fontWeight: FontWeight.w800,
              height: 1.25,
            ),
          ),
        ),
      ],
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;

  const _Badge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _VerifiedBadge extends StatelessWidget {
  const _VerifiedBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(999),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.verified_rounded, size: 14, color: PetScaniaColors.leaf),
          SizedBox(width: 4),
          Text(
            'Verificado',
            style: TextStyle(
              color: PetScaniaColors.ink,
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}
