class Challenge {
  final String id;
  final String title;
  final String description;
  final String startDate;
  final String endDate;
  final String status;
  final String targetActionId;
  final String targetActionTitle;
  final int targetCount;
  final int bonusPoints;
  final int? maxParticipants;
  final int participantCount;
  final bool joined;
  final String? participationStatus;
  final int? progressCount;
  final String? completedAt;

  Challenge({
    required this.id,
    required this.title,
    required this.description,
    required this.startDate,
    required this.endDate,
    required this.status,
    required this.targetActionId,
    required this.targetActionTitle,
    required this.targetCount,
    required this.bonusPoints,
    this.maxParticipants,
    required this.participantCount,
    required this.joined,
    this.participationStatus,
    this.progressCount,
    this.completedAt,
  });

  bool get isCompleted => participationStatus == 'COMPLETED';
  bool get isJoined => joined || participationStatus == 'JOINED';

  int get currentProgress => progressCount ?? 0;

  double get progressRatio {
    if (targetCount <= 0) return 0.0;
    return (currentProgress / targetCount).clamp(0.0, 1.0);
  }

  int get daysRemaining {
    try {
      final end = DateTime.parse(endDate);
      final remaining = end.difference(DateTime.now()).inDays;
      return remaining < 0 ? 0 : remaining;
    } catch (_) {
      return 0;
    }
  }

  factory Challenge.fromJson(Map<String, dynamic> json) {
    return Challenge(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      startDate: json['startDate'] as String? ?? '',
      endDate: json['endDate'] as String? ?? '',
      status: json['status'] as String? ?? 'DRAFT',
      targetActionId: json['targetActionId'] as String? ?? '',
      targetActionTitle: json['targetActionTitle'] as String? ?? '',
      targetCount: (json['targetCount'] as num?)?.toInt() ?? 1,
      bonusPoints: (json['bonusPoints'] as num?)?.toInt() ?? 0,
      maxParticipants: (json['maxParticipants'] as num?)?.toInt(),
      participantCount: (json['participantCount'] as num?)?.toInt() ?? 0,
      joined: json['joined'] as bool? ?? false,
      participationStatus: json['participationStatus'] as String?,
      progressCount: (json['progressCount'] as num?)?.toInt(),
      completedAt: json['completedAt'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'startDate': startDate,
      'endDate': endDate,
      'status': status,
      'targetActionId': targetActionId,
      'targetActionTitle': targetActionTitle,
      'targetCount': targetCount,
      'bonusPoints': bonusPoints,
      if (maxParticipants != null) 'maxParticipants': maxParticipants,
      'participantCount': participantCount,
      'joined': joined,
      if (participationStatus != null) 'participationStatus': participationStatus,
      if (progressCount != null) 'progressCount': progressCount,
      if (completedAt != null) 'completedAt': completedAt,
    };
  }
}
