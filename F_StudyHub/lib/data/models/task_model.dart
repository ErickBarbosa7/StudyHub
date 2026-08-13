class Task {
  const Task({
    required this.taskId,
    required this.title,
    required this.stateCode,
    required this.stateLabel,
    this.createdAt,
  });

  final String taskId;
  final String title;
  final String stateCode;
  final String stateLabel;
  final DateTime? createdAt;

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      taskId: json['taskId'] as String,
      title: json['title'] as String,
      stateCode: json['stateCode'] as String,
      stateLabel: json['stateLabel'] as String,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String)
          : null,
    );
  }
}