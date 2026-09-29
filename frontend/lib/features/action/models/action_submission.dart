class ActionSubmission {
  final String id;
  final String sustainableActionId;
  final String actionTitle;
  final String status;
  final String? submittedAt;
  final String? completedAt;

  ActionSubmission({
    required this.id,
    required this.sustainableActionId,
    required this.actionTitle,
    required this.status,
    this.submittedAt,
    this.completedAt,
  });

  factory ActionSubmission.fromJson(Map<String, dynamic> json) {
    return ActionSubmission(
      id: json['id']?.toString() ?? '',
      sustainableActionId: json['sustainableActionId']?.toString() ?? '',
      actionTitle: json['actionTitle']?.toString() ?? 'Sustainable Action',
      status: json['status']?.toString() ?? 'PENDING',
      submittedAt: json['submittedAt']?.toString(),
      completedAt: json['completedAt']?.toString(),
    );
  }
}
