class SustainableAction {
  final String id;
  final String title;
  final String description;
  final String category;
  final String status;
  final double estimatedImpact;
  final String evidenceRequirements;
  final String verificationRequirements;

  SustainableAction({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.status,
    required this.estimatedImpact,
    required this.evidenceRequirements,
    required this.verificationRequirements,
  });

  factory SustainableAction.fromJson(Map<String, dynamic> json) {
    return SustainableAction(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Action',
      description: json['description']?.toString() ?? '',
      category: json['category']?.toString() ?? 'GENERAL',
      status: json['status']?.toString() ?? 'ACTIVE',
      estimatedImpact: (json['estimatedImpact'] as num?)?.toDouble() ?? 0.0,
      evidenceRequirements: json['evidenceRequirements']?.toString() ?? '',
      verificationRequirements: json['verificationRequirements']?.toString() ?? '',
    );
  }
}
