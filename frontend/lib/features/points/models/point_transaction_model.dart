class PointTransaction {
  final String id;
  final String type;
  final int points;
  final String referenceType;
  final String referenceId;
  final String description;
  final String createdAt;

  PointTransaction({
    required this.id,
    required this.type,
    required this.points,
    required this.referenceType,
    required this.referenceId,
    required this.description,
    required this.createdAt,
  });

  factory PointTransaction.fromJson(Map<String, dynamic> json) {
    return PointTransaction(
      id: json['id']?.toString() ?? '',
      type: json['type']?.toString() ?? 'EARN',
      points: (json['points'] as num?)?.toInt() ?? 0,
      referenceType: json['referenceType']?.toString() ?? '',
      referenceId: json['referenceId']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      createdAt: json['createdAt']?.toString() ?? '',
    );
  }
}
