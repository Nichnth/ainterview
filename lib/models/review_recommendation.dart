import 'interview_enums.dart';

class ReviewRecommendation {
  const ReviewRecommendation({
    required this.id,
    required this.title,
    required this.description,
    required this.level,
    required this.stage,
    this.linkedPlanId,
    this.linkedScheduleItemIndex,
  });

  final String id;
  final String title;
  final String description;
  final InterviewLevel level;
  final InterviewStage stage;
  final String? linkedPlanId;
  final int? linkedScheduleItemIndex;

  ReviewRecommendation copyWith({
    String? id,
    String? title,
    String? description,
    InterviewLevel? level,
    InterviewStage? stage,
    String? linkedPlanId,
    int? linkedScheduleItemIndex,
  }) {
    return ReviewRecommendation(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      level: level ?? this.level,
      stage: stage ?? this.stage,
      linkedPlanId: linkedPlanId ?? this.linkedPlanId,
      linkedScheduleItemIndex:
          linkedScheduleItemIndex ?? this.linkedScheduleItemIndex,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'level': level.key,
      'stage': stage.key,
      'linkedPlanId': linkedPlanId,
      'linkedScheduleItemIndex': linkedScheduleItemIndex,
    };
  }

  factory ReviewRecommendation.fromMap(Map<String, dynamic> map) {
    return ReviewRecommendation(
      id: map['id'] as String? ?? '',
      title: map['title'] as String? ?? '',
      description: map['description'] as String? ?? '',
      level: InterviewLevel.fromLabel(map['level'] as String? ?? ''),
      stage: InterviewStage.fromLabel(map['stage'] as String? ?? ''),
      linkedPlanId: map['linkedPlanId'] as String?,
      linkedScheduleItemIndex: _readNullableInt(map['linkedScheduleItemIndex']),
    );
  }

  static int? _readNullableInt(Object? value) {
    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    if (value is String) {
      return int.tryParse(value);
    }

    return null;
  }
}
