class CommunityCampaign {
  final String id;
  final String title;
  final String category;
  final String city;
  final String district;
  final String location;
  final String dateLabel;
  final String organizer;
  final String description;
  final String requirements;
  final String imageUrl;
  final int capacity;
  final int reserved;
  final bool isVerified;

  const CommunityCampaign({
    required this.id,
    required this.title,
    required this.category,
    required this.city,
    required this.district,
    required this.location,
    required this.dateLabel,
    required this.organizer,
    required this.description,
    required this.requirements,
    required this.imageUrl,
    required this.capacity,
    required this.reserved,
    required this.isVerified,
  });

  String get placeLabel => '$district, $city';

  int get remainingSlots => capacity - reserved;
}
