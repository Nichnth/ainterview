class ScheduleItem {
  const ScheduleItem({
    required this.dayOffset,
    required this.title,
    required this.description,
    this.isCompleted = false,
  });

  final int dayOffset;
  final String title;
  final String description;
  final bool isCompleted;

  ScheduleItem copyWith({
    int? dayOffset,
    String? title,
    String? description,
    bool? isCompleted,
  }) {
    return ScheduleItem(
      dayOffset: dayOffset ?? this.dayOffset,
      title: title ?? this.title,
      description: description ?? this.description,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  Map<String, Object> toMap() {
    return {
      'dayOffset': dayOffset,
      'title': title,
      'description': description,
      'isCompleted': isCompleted,
    };
  }

  factory ScheduleItem.fromMap(Map<String, dynamic> map) {
    return ScheduleItem(
      dayOffset: map['dayOffset'] as int? ?? 1,
      title: map['title'] as String? ?? '',
      description: map['description'] as String? ?? '',
      isCompleted: map['isCompleted'] as bool? ?? false,
    );
  }
}
