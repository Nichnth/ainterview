import 'interview_enums.dart';

class ScheduleItem {
  const ScheduleItem({
    this.id = '',
    required this.dayOffset,
    required this.title,
    required this.description,
    this.suggestedStage,
    this.isCompleted = false,
    this.sourceReviewId,
    this.sourceRecommendationId,
  });

  final String id;
  final int dayOffset;
  final String title;
  final String description;
  final InterviewStage? suggestedStage;
  final bool isCompleted;
  final String? sourceReviewId;
  final String? sourceRecommendationId;

  ScheduleItem copyWith({
    String? id,
    int? dayOffset,
    String? title,
    String? description,
    InterviewStage? suggestedStage,
    bool? isCompleted,
    String? sourceReviewId,
    String? sourceRecommendationId,
  }) {
    return ScheduleItem(
      id: id ?? this.id,
      dayOffset: dayOffset ?? this.dayOffset,
      title: title ?? this.title,
      description: description ?? this.description,
      suggestedStage: suggestedStage ?? this.suggestedStage,
      isCompleted: isCompleted ?? this.isCompleted,
      sourceReviewId: sourceReviewId ?? this.sourceReviewId,
      sourceRecommendationId:
          sourceRecommendationId ?? this.sourceRecommendationId,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'dayOffset': dayOffset,
      'title': title,
      'description': description,
      'suggestedStage': suggestedStage?.key,
      'isCompleted': isCompleted,
      'sourceReviewId': sourceReviewId,
      'sourceRecommendationId': sourceRecommendationId,
    };
  }

  factory ScheduleItem.fromMap(Map<String, dynamic> map) {
    final title = map['title'] as String? ?? '';
    return ScheduleItem(
      id: map['id'] as String? ?? stableId(title),
      dayOffset: _readInt(map['dayOffset']) ?? 1,
      title: title,
      description: map['description'] as String? ?? '',
      suggestedStage: _stageFromValue(map['suggestedStage']),
      isCompleted: map['isCompleted'] as bool? ?? false,
      sourceReviewId: map['sourceReviewId'] as String?,
      sourceRecommendationId: map['sourceRecommendationId'] as String?,
    );
  }

  static String stableId(String title) {
    final normalized = title
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');

    return normalized.isEmpty ? 'schedule_item' : normalized;
  }

  static int? _readInt(Object? value) {
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

  static InterviewStage? _stageFromValue(Object? value) {
    if (value is InterviewStage) {
      return value;
    }

    if (value is String && value.trim().isNotEmpty) {
      return InterviewStage.tryFromLabel(value);
    }

    return null;
  }
}
