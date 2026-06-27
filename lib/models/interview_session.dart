import 'interview_enums.dart';
import 'interview_message.dart';
import 'interview_review.dart';

class InterviewSession {
  const InterviewSession({
    required this.id,
    required this.level,
    required this.stage,
    required this.language,
    required this.startedAt,
    required this.messages,
    this.endedAt,
    this.linkedPlanId,
    this.linkedScheduleItemId,
    this.preparationFocusTitle,
    this.review,
    this.isFavorite = false,
  });

  final String id;
  final InterviewLevel level;
  final InterviewStage stage;
  final InterviewLanguage language;
  final DateTime startedAt;
  final DateTime? endedAt;
  final String? linkedPlanId;
  final String? linkedScheduleItemId;
  final String? preparationFocusTitle;
  final List<InterviewMessage> messages;
  final InterviewReview? review;
  final bool isFavorite;

  InterviewSession copyWith({
    String? id,
    InterviewLevel? level,
    InterviewStage? stage,
    InterviewLanguage? language,
    DateTime? startedAt,
    DateTime? endedAt,
    String? linkedPlanId,
    String? linkedScheduleItemId,
    String? preparationFocusTitle,
    List<InterviewMessage>? messages,
    InterviewReview? review,
    bool? isFavorite,
  }) {
    return InterviewSession(
      id: id ?? this.id,
      level: level ?? this.level,
      stage: stage ?? this.stage,
      language: language ?? this.language,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
      linkedPlanId: linkedPlanId ?? this.linkedPlanId,
      linkedScheduleItemId: linkedScheduleItemId ?? this.linkedScheduleItemId,
      preparationFocusTitle:
          preparationFocusTitle ?? this.preparationFocusTitle,
      messages: messages ?? this.messages,
      review: review ?? this.review,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'level': level.label,
      'stage': stage.label,
      'language': language.label,
      'startedAt': startedAt.toIso8601String(),
      'endedAt': endedAt?.toIso8601String(),
      'linkedPlanId': linkedPlanId,
      'linkedScheduleItemId': linkedScheduleItemId,
      'preparationFocusTitle': preparationFocusTitle,
      'messages': messages.map((m) => m.toMap()).toList(),
      'review': review?.toMap(),
      'isFavorite': isFavorite,
    };
  }

  factory InterviewSession.fromMap(Object arg1, [Object? arg2]) {
    final String id;
    final Map<String, dynamic> map;

    if (arg1 is String) {
      id = arg1;
      map = Map<String, dynamic>.from(arg2 as Map);
    } else {
      map = Map<String, dynamic>.from(arg1 as Map);
      id = arg2 as String? ?? map['id'] as String? ?? '';
    }

    final rawMessages = map['messages'] as List? ?? const [];
    final rawReview = map['review'];

    return InterviewSession(
      id: id,
      level: InterviewLevel.fromLabel(map['level'] as String? ?? ''),
      stage: InterviewStage.fromLabel(map['stage'] as String? ?? ''),
      language: InterviewLanguage.fromLabel(map['language'] as String? ?? ''),
      startedAt: _readDate(map['startedAt']),
      endedAt: _readNullableDate(map['endedAt']),
      linkedPlanId: map['linkedPlanId'] as String?,
      linkedScheduleItemId: map['linkedScheduleItemId'] as String?,
      preparationFocusTitle: map['preparationFocusTitle'] as String?,
      messages: rawMessages
          .map(
            (message) => InterviewMessage.fromMap(
              Map<String, dynamic>.from(message as Map),
            ),
          )
          .toList(),
      review: rawReview is Map
          ? InterviewReview.fromMap(Map<String, dynamic>.from(rawReview))
          : null,
      isFavorite: map['isFavorite'] as bool? ?? false,
    );
  }

  static DateTime? _readNullableDate(Object? value) {
    if (value == null) {
      return null;
    }

    return _readDate(value);
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
