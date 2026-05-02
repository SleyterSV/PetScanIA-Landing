import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:petscania/models/community_pet.dart';
import 'package:petscania/screens/community/publish_pet_screen.dart';
import 'package:petscania/services/community_service.dart';
import 'package:petscania/services/community_seed_data.dart';
import 'package:petscania/theme/petscania_brand.dart';
import 'package:url_launcher/url_launcher.dart';

class AdoptionScreen extends StatelessWidget {
  const AdoptionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const CommunityListScreen(
      type: CommunityPostType.adoption,
      title: 'Adopta y ayuda',
      subtitle: 'Mascotas listas para una familia cerca de tu zona.',
      actionLabel: 'Dar en adopcion',
    );
  }
}

class LostPetsScreen extends StatelessWidget {
  const LostPetsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const CommunityListScreen(
      type: CommunityPostType.lost,
      title: 'Mascotas perdidas',
      subtitle: 'Alertas recientes para activar a vecinos cercanos.',
      actionLabel: 'Reportar perdida',
    );
  }
}

class FoundPetsScreen extends StatelessWidget {
  const FoundPetsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const CommunityListScreen(
      type: CommunityPostType.found,
      title: 'Mascotas encontradas',
      subtitle: 'Publicaciones para ayudarles a volver a casa.',
      actionLabel: 'Encontre una mascota',
    );
  }
}

class CommunityListScreen extends StatefulWidget {
  final CommunityPostType type;
  final String title;
  final String subtitle;
  final String actionLabel;

  const CommunityListScreen({
    super.key,
    required this.type,
    required this.title,
    required this.subtitle,
    required this.actionLabel,
  });

  @override
  State<CommunityListScreen> createState() => _CommunityListScreenState();
}

class _CommunityListScreenState extends State<CommunityListScreen> {
  final CommunityService _communityService = CommunityService();

  String _city = 'Todas';
  String _species = 'Todos';
  String _size = 'Todos';
  String _age = 'Todos';
  String _status = 'Todos';
  String _query = '';
  bool _nearFirst = true;
  bool _isLoading = true;
  List<PetCommunityPost> _posts = [];

  @override
  void initState() {
    super.initState();
    _loadPosts();
  }

  @override
  void didUpdateWidget(covariant CommunityListScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.type != widget.type) {
      _loadPosts();
    }
  }

  Future<void> _loadPosts() async {
    setState(() => _isLoading = true);
    final posts = await _communityService.getPosts(type: widget.type);
    if (!mounted) {
      return;
    }
    setState(() {
      _posts = posts;
      _isLoading = false;
    });
  }

  List<PetCommunityPost> get _filteredPosts {
    final posts = _posts.where((post) {
      final haystack = [
        post.name,
        post.species,
        post.breed,
        post.city,
        post.district,
        post.status,
        post.description,
      ].join(' ').toLowerCase();

      final matchesQuery =
          _query.trim().isEmpty || haystack.contains(_query.toLowerCase());
      final matchesCity = _city == 'Todas' || post.city == _city;
      final matchesSpecies = _species == 'Todos' || post.species == _species;
      final matchesSize = _size == 'Todos' || post.size == _size;
      final matchesAge = _age == 'Todos' || post.age == _age;
      final matchesStatus =
          _status == 'Todos' ||
          (_status == 'Verificado' && post.verified) ||
          post.status == _status;

      return matchesQuery &&
          matchesCity &&
          matchesSpecies &&
          matchesSize &&
          matchesAge &&
          matchesStatus;
    }).toList();

    if (_nearFirst) {
      posts.sort((a, b) => a.distanceKm.compareTo(b.distanceKm));
    }

    return posts;
  }

  Future<void> _openPublishFlow() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PublishPetScreen(initialType: widget.type),
      ),
    );
    if (result == true) {
      _loadPosts();
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredPosts = _filteredPosts;

    return RefreshIndicator(
      color: PetScaniaColors.royalBlue,
      onRefresh: _loadPosts,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
            sliver: SliverToBoxAdapter(
              child: _CommunityHeader(
                title: widget.title,
                subtitle: widget.subtitle,
                actionLabel: widget.actionLabel,
                onAction: _openPublishFlow,
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: _FiltersPanel(
              query: _query,
              city: _city,
              species: _species,
              size: _size,
              age: _age,
              status: _status,
              nearFirst: _nearFirst,
              onQueryChanged: (value) => setState(() => _query = value),
              onCityChanged: (value) => setState(() => _city = value),
              onSpeciesChanged: (value) => setState(() => _species = value),
              onSizeChanged: (value) => setState(() => _size = value),
              onAgeChanged: (value) => setState(() => _age = value),
              onStatusChanged: (value) => setState(() => _status = value),
              onNearFirstChanged: (value) => setState(() => _nearFirst = value),
            ),
          ),
          if (_isLoading)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: CircularProgressIndicator(
                  color: PetScaniaColors.skyBlue,
                ),
              ),
            )
          else if (filteredPosts.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: _EmptyCommunityState(type: widget.type),
            )
          else
            SliverList.separated(
              itemCount: filteredPosts.length,
              separatorBuilder: (_, __) => const SizedBox(height: 14),
              itemBuilder: (context, index) {
                return Padding(
                  padding: EdgeInsets.fromLTRB(
                    20,
                    index == 0 ? 8 : 0,
                    20,
                    index == filteredPosts.length - 1 ? 26 : 0,
                  ),
                  child: PetCommunityCard(post: filteredPosts[index]),
                );
              },
            ),
        ],
      ),
    );
  }
}

class PetCommunityCard extends StatefulWidget {
  final PetCommunityPost post;
  final bool compact;

  const PetCommunityCard({super.key, required this.post, this.compact = false});

  @override
  State<PetCommunityCard> createState() => _PetCommunityCardState();
}

class _PetCommunityCardState extends State<PetCommunityCard> {
  final CommunityService _communityService = CommunityService();
  bool _helped = false;

  PetCommunityPost get post => widget.post;

  Color get _accentColor {
    switch (post.type) {
      case CommunityPostType.adoption:
        return PetScaniaColors.leaf;
      case CommunityPostType.lost:
        return PetScaniaColors.alert;
      case CommunityPostType.found:
        return PetScaniaColors.warmSun;
    }
  }

  Future<void> _launchWhatsApp({required bool direct}) async {
    final text = _shareText();
    final phone = post.contactPhone.replaceAll(RegExp(r'\D'), '');
    final uri = direct && phone.isNotEmpty
        ? Uri.parse('https://wa.me/$phone?text=${Uri.encodeComponent(text)}')
        : Uri.parse('https://wa.me/?text=${Uri.encodeComponent(text)}');

    try {
      final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!opened && mounted) {
        _showSnack('No pude abrir WhatsApp en este dispositivo.');
      }
    } catch (_) {
      if (mounted) {
        _showSnack('No pude abrir WhatsApp en este dispositivo.');
      }
    }
  }

  Future<void> _openFacebookShare() async {
    final shareUrl = Uri.encodeComponent('https://petscania.app/community/${post.id}');
    final quote = Uri.encodeComponent(_shareText());
    final uri = Uri.parse(
      'https://www.facebook.com/sharer/sharer.php?u=$shareUrl&quote=$quote',
    );

    try {
      final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!opened && mounted) {
        _showSnack('No pude abrir Facebook en este dispositivo.');
      }
    } catch (_) {
      if (mounted) {
        _showSnack('No pude abrir Facebook en este dispositivo.');
      }
    }
  }

  Future<void> _openInstagramStory() async {
    final appUri = Uri.parse('instagram://story-camera');
    final webUri = Uri.parse('https://www.instagram.com/');

    try {
      if (kIsWeb) {
        await launchUrl(webUri, mode: LaunchMode.externalApplication);
        if (mounted) {
          _showSnack(
            'En web se abre Instagram. Para subir historias directo necesitamos la app movil.',
          );
        }
        return;
      }

      final opened = await launchUrl(
        appUri,
        mode: LaunchMode.externalApplication,
      );
      if (!opened) {
        await launchUrl(webUri, mode: LaunchMode.externalApplication);
      }
      if (mounted) {
        _showSnack(
          'Abri Instagram. En app movil luego podremos enviar el cartel directo a historia.',
        );
      }
    } catch (_) {
      try {
        await launchUrl(webUri, mode: LaunchMode.externalApplication);
      } catch (_) {
        if (mounted) {
          _showSnack('No pude abrir Instagram en este dispositivo.');
        }
      }
    }
  }

  void _showPosterPreview() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              bottom: 20 + MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        post.type == CommunityPostType.lost
                            ? 'Cartel para historia'
                            : 'Imagen para compartir',
                        style: const TextStyle(
                          color: PetScaniaColors.ink,
                          fontSize: 21,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Cerrar',
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 520),
                  child: _StoryPosterPreview(post: post),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _openInstagramStory();
                        },
                        icon: const Icon(Icons.camera_alt_rounded, size: 18),
                        label: const Text('Historia'),
                        style: FilledButton.styleFrom(
                          backgroundColor: PetScaniaColors.rescueCoral,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _launchWhatsApp(direct: false);
                        },
                        icon: const Icon(Icons.chat_rounded, size: 18),
                        label: const Text('WhatsApp'),
                        style: FilledButton.styleFrom(
                          backgroundColor: PetScaniaColors.leaf,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'La version nativa puede guardar esta imagen y enviarla directamente a Instagram Stories.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: PetScaniaColors.ink.withValues(alpha: 0.58),
                    fontSize: 12,
                    height: 1.35,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showShareSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Compartir ${post.name}',
                  style: const TextStyle(
                    color: PetScaniaColors.ink,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 14),
                _ShareOption(
                  icon: Icons.chat_rounded,
                  label: 'WhatsApp',
                  color: PetScaniaColors.leaf,
                  onTap: () {
                    Navigator.pop(context);
                    _launchWhatsApp(direct: false);
                  },
                ),
                _ShareOption(
                  icon: Icons.photo_camera_rounded,
                  label: 'Instagram Stories',
                  color: PetScaniaColors.rescueCoral,
                  onTap: () {
                    Navigator.pop(context);
                    _showPosterPreview();
                  },
                ),
                _ShareOption(
                  icon: Icons.facebook_rounded,
                  label: 'Facebook',
                  color: PetScaniaColors.royalBlue,
                  onTap: () {
                    Navigator.pop(context);
                    _openFacebookShare();
                  },
                ),
                _ShareOption(
                  icon: Icons.image_rounded,
                  label: 'Ver cartel automatico',
                  color: PetScaniaColors.warmSun,
                  onTap: () {
                    Navigator.pop(context);
                    _showPosterPreview();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _markHelped() {
    setState(() => _helped = true);
    _communityService.markHelped(post.id);
    _showSnack('Gracias. Sumaste una difusion para ${post.name}.');
  }

  void _showSnack(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  String _shareText() {
    final action = switch (post.type) {
      CommunityPostType.adoption => 'busca una familia',
      CommunityPostType.lost => 'esta perdida',
      CommunityPostType.found => 'fue encontrada',
    };

    return '${post.name} $action en ${post.placeLabel}. '
        '${post.description} Contacto: ${post.contactPhone}. '
        '#PetScanIA #${post.species} #${post.city}';
  }

  @override
  Widget build(BuildContext context) {
    final compact = widget.compact;
    final spreadCount = post.spreadCount + (_helped ? 1 : 0);

    return PetScaniaSurfaceCard(
      padding: EdgeInsets.zero,
      borderRadius: BorderRadius.circular(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: compact ? 1.28 : 1.95,
            child: Stack(
              children: [
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
                    child: Image.network(
                      post.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: PetScaniaColors.cloud,
                        child: const Icon(
                          Icons.pets_rounded,
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
                  child: _StatusBadge(label: post.status, color: _accentColor),
                ),
                if (post.verified)
                  const Positioned(right: 12, top: 12, child: _VerifiedBadge()),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(16, compact ? 13 : 16, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        post.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: PetScaniaColors.ink,
                          fontSize: compact ? 18 : 22,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    _DistancePill(distanceKm: post.distanceKm),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  '${post.species} · ${post.breed} · ${post.age} · ${post.size}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: PetScaniaColors.ink.withValues(alpha: 0.62),
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 9),
                _InfoLine(icon: Icons.place_rounded, text: post.placeLabel),
                if (!compact) ...[
                  const SizedBox(height: 7),
                  _InfoLine(
                    icon: post.type == CommunityPostType.lost
                        ? Icons.schedule_rounded
                        : Icons.health_and_safety_rounded,
                    text: post.type == CommunityPostType.lost
                        ? '${post.location} · ${post.dateLabel}'
                        : '${post.healthStatus} · ${post.vaccines}',
                  ),
                  if (post.reward.isNotEmpty) ...[
                    const SizedBox(height: 7),
                    _InfoLine(
                      icon: Icons.volunteer_activism_rounded,
                      text: 'Recompensa opcional: ${post.reward}',
                    ),
                  ],
                  const SizedBox(height: 12),
                  Text(
                    post.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: PetScaniaColors.ink.withValues(alpha: 0.72),
                      height: 1.38,
                    ),
                  ),
                  const SizedBox(height: 14),
                ] else
                  const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () => _launchWhatsApp(direct: true),
                        icon: const Icon(Icons.chat_rounded, size: 18),
                        label: Text(
                          compact ? 'Contactar' : post.primaryActionLabel,
                          overflow: TextOverflow.ellipsis,
                        ),
                        style: FilledButton.styleFrom(
                          backgroundColor: PetScaniaColors.royalBlue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          textStyle: const TextStyle(
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    _IconActionButton(
                      icon: Icons.ios_share_rounded,
                      tooltip: 'Compartir',
                      onTap: _showShareSheet,
                    ),
                  ],
                ),
                if (!compact) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _helped ? null : _markHelped,
                          icon: Icon(
                            _helped
                                ? Icons.check_circle_rounded
                                : Icons.campaign_rounded,
                            size: 18,
                          ),
                          label: Text(
                            _helped
                                ? 'Ya ayudaste'
                                : 'Ayude a difundir · $spreadCount',
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: PetScaniaColors.royalBlue,
                            side: const BorderSide(color: PetScaniaColors.line),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      _IconActionButton(
                        icon: Icons.auto_awesome_rounded,
                        tooltip: 'Apoyo IA',
                        onTap: () => _showSnack(
                          'IA sugirio descripcion, hashtags y cartel.',
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CommunityHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final String actionLabel;
  final VoidCallback onAction;

  const _CommunityHeader({
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                subtitle,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.82),
                  height: 1.35,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        FilledButton.icon(
          onPressed: onAction,
          icon: const Icon(Icons.add_rounded, size: 18),
          label: Text(actionLabel),
          style: FilledButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: PetScaniaColors.royalBlue,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            textStyle: const TextStyle(fontWeight: FontWeight.w900),
          ),
        ),
      ],
    );
  }
}

class _FiltersPanel extends StatelessWidget {
  final String query;
  final String city;
  final String species;
  final String size;
  final String age;
  final String status;
  final bool nearFirst;
  final ValueChanged<String> onQueryChanged;
  final ValueChanged<String> onCityChanged;
  final ValueChanged<String> onSpeciesChanged;
  final ValueChanged<String> onSizeChanged;
  final ValueChanged<String> onAgeChanged;
  final ValueChanged<String> onStatusChanged;
  final ValueChanged<bool> onNearFirstChanged;

  const _FiltersPanel({
    required this.query,
    required this.city,
    required this.species,
    required this.size,
    required this.age,
    required this.status,
    required this.nearFirst,
    required this.onQueryChanged,
    required this.onCityChanged,
    required this.onSpeciesChanged,
    required this.onSizeChanged,
    required this.onAgeChanged,
    required this.onStatusChanged,
    required this.onNearFirstChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: PetScaniaColors.line),
        boxShadow: PetScaniaDecor.softShadow,
      ),
      child: Column(
        children: [
          TextField(
            onChanged: onQueryChanged,
            style: const TextStyle(
              color: PetScaniaColors.ink,
              fontWeight: FontWeight.w700,
            ),
            decoration: InputDecoration(
              hintText: 'Buscar por nombre, zona, raza o estado',
              hintStyle: TextStyle(
                color: PetScaniaColors.ink.withValues(alpha: 0.42),
              ),
              prefixIcon: const Icon(
                Icons.search_rounded,
                color: PetScaniaColors.royalBlue,
              ),
              filled: true,
              fillColor: PetScaniaColors.mist,
              border: OutlineInputBorder(
                borderSide: BorderSide.none,
                borderRadius: BorderRadius.circular(18),
              ),
            ),
          ),
          const SizedBox(height: 12),
          _FilterRow(
            title: 'Ciudad',
            value: city,
            options: CommunitySeedData.cities,
            onChanged: onCityChanged,
          ),
          _FilterRow(
            title: 'Especie',
            value: species,
            options: CommunitySeedData.species,
            onChanged: onSpeciesChanged,
          ),
          _FilterRow(
            title: 'Estado',
            value: status,
            options: CommunitySeedData.statuses,
            onChanged: onStatusChanged,
          ),
          Row(
            children: [
              Expanded(
                child: _MiniFilterButton(
                  icon: Icons.straighten_rounded,
                  label: size,
                  onTap: () => _showOptionsSheet(
                    context,
                    title: 'Tamano',
                    value: size,
                    options: CommunitySeedData.sizes,
                    onChanged: onSizeChanged,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _MiniFilterButton(
                  icon: Icons.cake_rounded,
                  label: age,
                  onTap: () => _showOptionsSheet(
                    context,
                    title: 'Edad',
                    value: age,
                    options: CommunitySeedData.ages,
                    onChanged: onAgeChanged,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Tooltip(
                message: 'Ordenar por cercania',
                child: InkWell(
                  onTap: () => onNearFirstChanged(!nearFirst),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    width: 50,
                    height: 46,
                    decoration: BoxDecoration(
                      color: nearFirst
                          ? PetScaniaColors.royalBlue
                          : PetScaniaColors.mist,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: PetScaniaColors.line),
                    ),
                    child: Icon(
                      Icons.near_me_rounded,
                      color: nearFirst
                          ? Colors.white
                          : PetScaniaColors.royalBlue,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showOptionsSheet(
    BuildContext context, {
    required String title,
    required String value,
    required List<String> options,
    required ValueChanged<String> onChanged,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: PetScaniaColors.ink,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 10),
                ...options.map(
                  (option) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      value == option
                          ? Icons.check_circle_rounded
                          : Icons.circle_outlined,
                      color: value == option
                          ? PetScaniaColors.royalBlue
                          : PetScaniaColors.ink.withValues(alpha: 0.36),
                    ),
                    title: Text(
                      option,
                      style: const TextStyle(
                        color: PetScaniaColors.ink,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      onChanged(option);
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _FilterRow extends StatelessWidget {
  final String title;
  final String value;
  final List<String> options;
  final ValueChanged<String> onChanged;

  const _FilterRow({
    required this.title,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 64,
            child: Text(
              title,
              style: TextStyle(
                color: PetScaniaColors.ink.withValues(alpha: 0.62),
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: options.map((option) {
                  final selected = value == option;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(option),
                      selected: selected,
                      labelStyle: TextStyle(
                        color: selected
                            ? Colors.white
                            : PetScaniaColors.ink.withValues(alpha: 0.72),
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                      selectedColor: PetScaniaColors.royalBlue,
                      backgroundColor: PetScaniaColors.mist,
                      side: BorderSide(
                        color: selected
                            ? PetScaniaColors.royalBlue
                            : PetScaniaColors.line,
                      ),
                      onSelected: (_) => onChanged(option),
                    ),
                  );
                }).toList(),
              ),
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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 17, color: PetScaniaColors.royalBlue),
        const SizedBox(width: 7),
        Expanded(
          child: Text(
            text,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: PetScaniaColors.ink.withValues(alpha: 0.66),
              height: 1.28,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusBadge({required this.label, required this.color});

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
          fontWeight: FontWeight.w900,
          fontSize: 11,
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
              fontWeight: FontWeight.w900,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class _DistancePill extends StatelessWidget {
  final double distanceKm;

  const _DistancePill({required this.distanceKm});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: PetScaniaColors.cloud,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '${distanceKm.toStringAsFixed(1)} km',
        style: const TextStyle(
          color: PetScaniaColors.royalBlue,
          fontSize: 12,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _IconActionButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const _IconActionButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: PetScaniaColors.cloud,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(icon, color: PetScaniaColors.royalBlue, size: 21),
        ),
      ),
    );
  }
}

class _ShareOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ShareOption({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
      leading: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(icon, color: color),
      ),
      title: Text(
        label,
        style: const TextStyle(
          color: PetScaniaColors.ink,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _MiniFilterButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _MiniFilterButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 46,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: PetScaniaColors.mist,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: PetScaniaColors.line),
        ),
        child: Row(
          children: [
            Icon(icon, color: PetScaniaColors.royalBlue, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: PetScaniaColors.ink,
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                ),
              ),
            ),
            const Icon(
              Icons.keyboard_arrow_down_rounded,
              color: PetScaniaColors.royalBlue,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}

class _StoryPosterPreview extends StatelessWidget {
  final PetCommunityPost post;

  const _StoryPosterPreview({required this.post});

  Color get _accentColor {
    switch (post.type) {
      case CommunityPostType.adoption:
        return PetScaniaColors.leaf;
      case CommunityPostType.lost:
        return PetScaniaColors.alert;
      case CommunityPostType.found:
        return PetScaniaColors.warmSun;
    }
  }

  String get _headline {
    switch (post.type) {
      case CommunityPostType.adoption:
        return 'EN ADOPCION';
      case CommunityPostType.lost:
        return 'SE BUSCA';
      case CommunityPostType.found:
        return 'ENCONTRADA';
    }
  }

  IconData get _icon {
    switch (post.type) {
      case CommunityPostType.adoption:
        return Icons.favorite_rounded;
      case CommunityPostType.lost:
        return Icons.campaign_rounded;
      case CommunityPostType.found:
        return Icons.travel_explore_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 9 / 16,
      child: Container(
        decoration: BoxDecoration(
          color: _accentColor,
          borderRadius: BorderRadius.circular(28),
          boxShadow: PetScaniaDecor.softShadow,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
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
                      size: 64,
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
                        Colors.black.withValues(alpha: 0.22),
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.82),
                      ],
                      stops: const [0, 0.42, 1],
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 18,
                top: 18,
                right: 18,
                child: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Icon(_icon, color: _accentColor),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _headline,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                left: 18,
                right: 18,
                bottom: 18,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      post.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 34,
                        fontWeight: FontWeight.w900,
                        height: 1,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      post.type == CommunityPostType.lost
                          ? post.location
                          : post.placeLabel,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _PosterChip(text: post.species),
                        _PosterChip(text: post.size),
                        if (post.reward.isNotEmpty)
                          _PosterChip(text: 'Recompensa ${post.reward}'),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Contacto rapido',
                            style: TextStyle(
                              color: PetScaniaColors.ink,
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            post.contactPhone,
                            style: const TextStyle(
                              color: PetScaniaColors.royalBlue,
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'PetScanIA · Comparte para ayudar',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
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

class _PosterChip extends StatelessWidget {
  final String text;

  const _PosterChip({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.90),
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

class _EmptyCommunityState extends StatelessWidget {
  final CommunityPostType type;

  const _EmptyCommunityState({required this.type});

  @override
  Widget build(BuildContext context) {
    final label = switch (type) {
      CommunityPostType.adoption => 'adopciones',
      CommunityPostType.lost => 'alertas',
      CommunityPostType.found => 'publicaciones',
    };

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(26),
                border: Border.all(color: Colors.white.withValues(alpha: 0.24)),
              ),
              child: const Icon(
                Icons.search_off_rounded,
                color: Colors.white,
                size: 42,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'No hay $label con esos filtros',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Prueba otra ciudad, especie o estado.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.76),
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
