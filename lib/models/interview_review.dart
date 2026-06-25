import 'interview_enums.dart';
import 'review_recommendation.dart';

class InterviewReview {
  const InterviewReview({
    required this.id,
    required this.level,
    required this.stage,
    required this.language,
    required this.createdAt,
    required this.summary,
    required this.communicationFeedback,
    required this.technicalFeedback,
    required this.improvementAreas,
    required this.recommendations,
  });

  final String id;
  final InterviewLevel level;
  final InterviewStage stage;
  final InterviewLanguage language;
  final DateTime createdAt;
  final String summary;
  final String communicationFeedback;
  final String technicalFeedback;
  final List<String> improvementAreas;
  final List<ReviewRecommendation> recommendations;

  Map<String, Object> toMap() {
    return {
      'id': id,
      'level': level.key,
      'stage': stage.key,
      'language': language.key,
      'createdAt': createdAt.toIso8601String(),
      'summary': summary,
      'communicationFeedback': communicationFeedback,
      'technicalFeedback': technicalFeedback,
      'improvementAreas': improvementAreas,
      'recommendations': recommendations
          .map((recommendation) => recommendation.toMap())
          .toList(),
    };
  }

  factory InterviewReview.fromMap(Map<String, dynamic> map) {
    final rawRecommendations = map['recommendations'] as List? ?? const [];

    return InterviewReview(
      id: map['id'] as String? ?? '',
      level: InterviewLevel.fromLabel(map['level'] as String? ?? ''),
      stage: InterviewStage.fromLabel(map['stage'] as String? ?? ''),
      language: InterviewLanguage.fromLabel(map['language'] as String? ?? ''),
      createdAt: _readDate(map['createdAt']),
      summary: map['summary'] as String? ?? '',
      communicationFeedback: map['communicationFeedback'] as String? ?? '',
      technicalFeedback: map['technicalFeedback'] as String? ?? '',
      improvementAreas: _stringList(map['improvementAreas']),
      recommendations: rawRecommendations
          .map(
            (recommendation) => ReviewRecommendation.fromMap(
              Map<String, dynamic>.from(recommendation as Map),
            ),
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

    return DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
  }

  static List<String> _stringList(Object? value) {
    if (value is! List) {
      return const [];
    }

    return value.map((item) => item.toString()).toList();
  }
}
