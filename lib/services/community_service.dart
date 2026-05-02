import 'package:flutter/foundation.dart';
import 'package:petscania/models/community_campaign.dart';
import 'package:petscania/models/community_pet.dart';
import 'package:petscania/services/community_seed_data.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CommunityService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<PetCommunityPost>> getPosts({CommunityPostType? type}) async {
    try {
      var query = _supabase.from('community_posts').select();
      if (type != null) {
        query = query.eq('type', _typeToDb(type));
      }

      final response = await query.order('created_at', ascending: false);
      final posts = List<Map<String, dynamic>>.from(response)
          .map(_postFromMap)
          .toList();

      if (posts.isNotEmpty) {
        return posts;
      }
    } catch (e) {
      debugPrint('CommunityService.getPosts fallback: $e');
    }

    if (type == null) {
      return CommunitySeedData.posts;
    }
    return CommunitySeedData.postsByType(type);
  }

  Future<List<CommunityCampaign>> getCampaigns() async {
    try {
      final response = await _supabase
          .from('community_campaigns')
          .select()
          .eq('is_active', true)
          .order('campaign_date', ascending: true);
      final campaigns = List<Map<String, dynamic>>.from(response)
          .map(_campaignFromMap)
          .toList();
      if (campaigns.isNotEmpty) {
        return campaigns;
      }
    } catch (e) {
      debugPrint('CommunityService.getCampaigns fallback: $e');
    }

    return CommunitySeedData.campaigns;
  }

  Future<bool> createPost({
    required CommunityPostType type,
    required String name,
    required String species,
    required String breed,
    required String color,
    required String age,
    required String size,
    required String city,
    required String district,
    required String location,
    required String dateLabel,
    required String healthStatus,
    required String vaccines,
    required String contactPhone,
    required String reward,
    required String description,
    String? imageUrl,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      await _supabase.from('community_posts').insert({
        'user_id': user?.id,
        'type': _typeToDb(type),
        'name': name,
        'species': species,
        'breed': breed,
        'color': color,
        'age': age,
        'size': size,
        'city': city,
        'district': district,
        'location': location,
        'date_label': dateLabel,
        'health_status': healthStatus,
        'vaccines': vaccines,
        'contact_name':
            user?.userMetadata?['full_name'] ?? 'Comunidad PetScanIA',
        'contact_phone': contactPhone,
        'reward': reward,
        'description': description,
        'image_url': imageUrl,
        'status': type == CommunityPostType.lost ? 'Urgente' : 'Con seguimiento',
        'verified': false,
        'spread_count': 0,
        'distance_km': 0,
      });
      return true;
    } catch (e) {
      debugPrint('CommunityService.createPost fallback: $e');
      return false;
    }
  }

  Future<void> markHelped(String postId) async {
    try {
      await _supabase.from('community_spreads').insert({
        'post_id': postId,
        'user_id': _supabase.auth.currentUser?.id,
        'channel': 'app',
      });
    } catch (e) {
      debugPrint('CommunityService.markHelped ignored: $e');
    }
  }

  Future<void> saveMatchAction({
    required String postId,
    required String action,
  }) async {
    try {
      await _supabase.from('community_match_actions').insert({
        'post_id': postId,
        'user_id': _supabase.auth.currentUser?.id,
        'action': action,
      });
    } catch (e) {
      debugPrint('CommunityService.saveMatchAction ignored: $e');
    }
  }

  Future<void> reserveCampaign(String campaignId) async {
    await _supabase.from('community_campaign_reservations').insert({
      'campaign_id': campaignId,
      'user_id': _supabase.auth.currentUser?.id,
      'status': 'reserved',
    });
  }

  String _typeToDb(CommunityPostType type) {
    switch (type) {
      case CommunityPostType.adoption:
        return 'adoption';
      case CommunityPostType.lost:
        return 'lost';
      case CommunityPostType.found:
        return 'found';
    }
  }

  CommunityPostType _typeFromDb(String? value) {
    switch (value) {
      case 'lost':
        return CommunityPostType.lost;
      case 'found':
        return CommunityPostType.found;
      case 'adoption':
      default:
        return CommunityPostType.adoption;
    }
  }

  PetCommunityPost _postFromMap(Map<String, dynamic> map) {
    return PetCommunityPost(
      id: map['id']?.toString() ?? '',
      type: _typeFromDb(map['type']?.toString()),
      imageUrl:
          map['image_url']?.toString().trim().isNotEmpty == true
              ? map['image_url'].toString()
              : 'https://images.unsplash.com/photo-1548199973-03cce0bbc87b?auto=format&fit=crop&w=900&q=80',
      name: map['name']?.toString() ?? 'Mascota',
      species: map['species']?.toString() ?? 'Mascota',
      breed: map['breed']?.toString() ?? 'Sin dato',
      age: map['age']?.toString() ?? 'Sin dato',
      size: map['size']?.toString() ?? 'Mediano',
      city: map['city']?.toString() ?? 'Lima',
      district: map['district']?.toString() ?? 'Zona cercana',
      description: map['description']?.toString() ?? '',
      healthStatus: map['health_status']?.toString() ?? 'Sin dato',
      vaccines: map['vaccines']?.toString() ?? 'Sin dato',
      contactName: map['contact_name']?.toString() ?? 'Comunidad PetScanIA',
      contactPhone: map['contact_phone']?.toString() ?? '',
      location: map['location']?.toString() ?? '',
      dateLabel: map['date_label']?.toString() ?? 'Reciente',
      status: map['status']?.toString() ?? 'Con seguimiento',
      reward: map['reward']?.toString() ?? '',
      distanceKm: (map['distance_km'] as num?)?.toDouble() ?? 0,
      spreadCount: (map['spread_count'] as num?)?.toInt() ?? 0,
      verified: map['verified'] == true,
    );
  }

  CommunityCampaign _campaignFromMap(Map<String, dynamic> map) {
    return CommunityCampaign(
      id: map['id']?.toString() ?? '',
      title: map['title']?.toString() ?? 'Campana gratuita',
      category: map['category']?.toString() ?? 'Campana',
      city: map['city']?.toString() ?? 'Lima',
      district: map['district']?.toString() ?? 'Zona cercana',
      location: map['location']?.toString() ?? '',
      dateLabel: map['date_label']?.toString() ?? 'Fecha por confirmar',
      organizer: map['organizer']?.toString() ?? 'PetScanIA',
      description: map['description']?.toString() ?? '',
      requirements: map['requirements']?.toString() ?? 'Sin requisitos',
      imageUrl:
          map['image_url']?.toString().trim().isNotEmpty == true
              ? map['image_url'].toString()
              : 'https://images.unsplash.com/photo-1576201836106-db1758fd1c97?auto=format&fit=crop&w=900&q=80',
      capacity: (map['capacity'] as num?)?.toInt() ?? 0,
      reserved: (map['reserved'] as num?)?.toInt() ?? 0,
      isVerified: map['is_verified'] == true,
    );
  }
}
