class ActionSubmission {
  final String id;
  final String sustainableActionId;
  final String actionTitle;
  final String status;
  final String submittedAt;
  final String? completedAt;

  ActionSubmission({
    required this.id,
    required this.sustainableActionId,
    required this.actionTitle,
    required this.status,
    required this.submittedAt,
    this.completedAt,
  });

  factory ActionSubmission.fromJson(Map<String, dynamic> json) {
    return ActionSubmission(
      id: json['id'],
      sustainableActionId: json['sustainableActionId'],
      actionTitle: json['actionTitle'],
      status: json['status'],
      submittedAt: json['submittedAt'],
      completedAt: json['completedAt'],
    );
  }
}
