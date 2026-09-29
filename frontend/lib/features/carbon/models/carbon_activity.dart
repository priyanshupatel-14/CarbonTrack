class CarbonActivity {
  final String id;
  final String category;
  final String activityType;
  final double quantity;
  final String unit;
  final String activityDate;
  final double co2e;
  final int factorVersion;

  CarbonActivity({
    required this.id,
    required this.category,
    required this.activityType,
    required this.quantity,
    required this.unit,
    required this.activityDate,
    required this.co2e,
    required this.factorVersion,
  });

  factory CarbonActivity.fromJson(Map<String, dynamic> json) {
    return CarbonActivity(
      id: json['id'],
      category: json['category'],
      activityType: json['activityType'],
      quantity: (json['quantity'] as num).toDouble(),
      unit: json['unit'],
      activityDate: json['activityDate'],
      co2e: (json['co2e'] as num).toDouble(),
      factorVersion: json['factorVersion'],
    );
  }
}
