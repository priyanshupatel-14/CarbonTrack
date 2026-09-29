class Reward {
  final String id;
  final String name;
  final String description;
  final int pointsRequired;
  final int inventory;
  final String? expiresAt;
  final String merchantName;

  Reward({
    required this.id,
    required this.name,
    required this.description,
    required this.pointsRequired,
    required this.inventory,
    this.expiresAt,
    required this.merchantName,
  });

  factory Reward.fromJson(Map<String, dynamic> json) {
    return Reward(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Reward',
      description: json['description']?.toString() ?? '',
      pointsRequired: (json['pointsRequired'] as num?)?.toInt() ?? 0,
      inventory: (json['inventory'] as num?)?.toInt() ?? 0,
      expiresAt: json['expiresAt']?.toString(),
      merchantName: json['merchantName']?.toString() ?? 'Campus Partner',
    );
  }
}
