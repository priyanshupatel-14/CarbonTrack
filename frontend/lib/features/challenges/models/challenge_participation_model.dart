class ChallengeParticipation {
  final String id;
  final String challengeId;
  final String challengeTitle;
  final String challengeDescription;
  final String targetActionId;
  final String targetActionTitle;
  final int targetCount;
  final int progressCount;
  final int bonusPoints;
  final String status;
  final String joinedAt;
  final String? completedAt;
  final String challengeStartDate;
  final String challengeEndDate;
  final String challengeStatus;

  ChallengeParticipation({
    required this.id,
    required this.challengeId,
    required this.challengeTitle,
    required this.challengeDescription,
    required this.targetActionId,
    required this.targetActionTitle,
    required this.targetCount,
    required this.progressCount,
    required this.bonusPoints,
    required this.status,
    required this.joinedAt,
    this.completedAt,
    required this.challengeStartDate,
    required this.challengeEndDate,
    required this.challengeStatus,
  });

  bool get isCompleted => status == 'COMPLETED';

  double get progressRatio {
    if (targetCount <= 0) return 0.0;
    return (progressCount / targetCount).clamp(0.0, 1.0);
  }

  factory ChallengeParticipation.fromJson(Map<String, dynamic> json) {
    return ChallengeParticipation(
      id: json['id'] as String? ?? '',
      challengeId: json['challengeId'] as String? ?? '',
      challengeTitle: json['challengeTitle'] as String? ?? '',
      challengeDescription: json['challengeDescription'] as String? ?? '',
      targetActionId: json['targetActionId'] as String? ?? '',
      targetActionTitle: json['targetActionTitle'] as String? ?? '',
      targetCount: (json['targetCount'] as num?)?.toInt() ?? 1,
      progressCount: (json['progressCount'] as num?)?.toInt() ?? 0,
      bonusPoints: (json['bonusPoints'] as num?)?.toInt() ?? 0,
      status: json['status'] as String? ?? 'JOINED',
      joinedAt: json['joinedAt'] as String? ?? '',
      completedAt: json['completedAt'] as String?,
      challengeStartDate: json['challengeStartDate'] as String? ?? '',
      challengeEndDate: json['challengeEndDate'] as String? ?? '',
      challengeStatus: json['challengeStatus'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'challengeId': challengeId,
      'challengeTitle': challengeTitle,
      'challengeDescription': challengeDescription,
      'targetActionId': targetActionId,
      'targetActionTitle': targetActionTitle,
      'targetCount': targetCount,
      'progressCount': progressCount,
      'bonusPoints': bonusPoints,
      'status': status,
      'joinedAt': joinedAt,
      if (completedAt != null) 'completedAt': completedAt,
      'challengeStartDate': challengeStartDate,
      'challengeEndDate': challengeEndDate,
      'challengeStatus': challengeStatus,
    };
  }
}
