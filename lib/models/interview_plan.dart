import 'interview_enums.dart';
import 'schedule_item.dart';

class InterviewPlan {
  const InterviewPlan({
    required this.id,
    required this.targetDate,
    required this.level,
    required this.language,
    required this.createdAt,
    required this.scheduleItems,
  });

  final String id;
  final DateTime targetDate;
  final InterviewLevel level;
  final InterviewLanguage language;
  final DateTime createdAt;
  final List<ScheduleItem> scheduleItems;

  double get progress {
    if (scheduleItems.isEmpty) {
      return 0;
    }

    final completedCount = scheduleItems
        .where((item) => item.isCompleted)
        .length;
    return completedCount / scheduleItems.length;
  }

  InterviewPlan copyWith({
    String? id,
    DateTime? targetDate,
    InterviewLevel? level,
    InterviewLanguage? language,
    DateTime? createdAt,
    List<ScheduleItem>? scheduleItems,
  }) {
    return InterviewPlan(
      id: id ?? this.id,
      targetDate: targetDate ?? this.targetDate,
      level: level ?? this.level,
      language: language ?? this.language,
      createdAt: createdAt ?? this.createdAt,
      scheduleItems: scheduleItems ?? this.scheduleItems,
    );
  }

  Map<String, Object> toMap() {
    return {
      'targetDate': targetDate.toIso8601String(),
      'level': level.label,
      'language': language.label,
      'createdAt': createdAt.toIso8601String(),
      'scheduleItems': scheduleItems.map((item) => item.toMap()).toList(),
    };
  }

  factory InterviewPlan.fromMap(String id, Map<String, dynamic> map) {
    final rawItems = map['scheduleItems'] as List? ?? const [];

    return InterviewPlan(
      id: id,
      targetDate: _readDate(map['targetDate']),
      level: InterviewLevel.fromLabel(map['level'] as String? ?? ''),
      language: InterviewLanguage.fromLabel(map['language'] as String? ?? ''),
      createdAt: _readDate(map['createdAt']),
      scheduleItems: rawItems
          .map(
            (item) =>
                ScheduleItem.fromMap(Map<String, dynamic>.from(item as Map)),
          )
          .toList(),
    );
  }

  static DateTime _readDate(Object? value) {
    if (value is DateTime) {
      return value;
    }

    if (value is String) {
      return DateTime.parse(value);
    }

    throw ArgumentError('Expected DateTime or ISO-8601 string.');
  }
}
