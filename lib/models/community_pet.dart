enum CommunityPostType { adoption, lost, found }

class PetCommunityPost {
  final String id;
  final CommunityPostType type;
  final String imageUrl;
  final String name;
  final String species;
  final String breed;
  final String age;
  final String size;
  final String city;
  final String district;
  final String description;
  final String healthStatus;
  final String vaccines;
  final String contactName;
  final String contactPhone;
  final String location;
  final String dateLabel;
  final String status;
  final String reward;
  final double distanceKm;
  final int spreadCount;
  final bool verified;

  const PetCommunityPost({
    required this.id,
    required this.type,
    required this.imageUrl,
    required this.name,
    required this.species,
    required this.breed,
    required this.age,
    required this.size,
    required this.city,
    required this.district,
    required this.description,
    required this.healthStatus,
    required this.vaccines,
    required this.contactName,
    required this.contactPhone,
    required this.location,
    required this.dateLabel,
    required this.status,
    required this.reward,
    required this.distanceKm,
    required this.spreadCount,
    required this.verified,
  });

  String get placeLabel => '$district, $city';

  String get typeLabel {
    switch (type) {
      case CommunityPostType.adoption:
        return 'Adopcion';
      case CommunityPostType.lost:
        return 'Perdida';
      case CommunityPostType.found:
        return 'Encontrada';
    }
  }

  String get primaryActionLabel {
    switch (type) {
      case CommunityPostType.adoption:
        return 'Solicitar adopcion';
      case CommunityPostType.lost:
        return 'Tengo informacion';
      case CommunityPostType.found:
        return 'Es mi mascota';
    }
  }
}

class HappyStory {
  final String id;
  final String title;
  final String imageUrl;
  final String city;
  final String summary;
  final String impact;

  const HappyStory({
    required this.id,
    required this.title,
    required this.imageUrl,
    required this.city,
    required this.summary,
    required this.impact,
  });
}
