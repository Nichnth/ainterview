import 'package:flutter_test/flutter_test.dart';

import 'package:ainterview/models/interview_enums.dart';
import 'package:ainterview/models/interview_message.dart';
import 'package:ainterview/models/interview_preparation_context.dart';
import 'package:ainterview/models/interview_review.dart';
import 'package:ainterview/models/interview_session.dart';
import 'package:ainterview/models/review_recommendation.dart';
import 'package:ainterview/providers/interview_session_controller.dart';
import 'package:ainterview/services/ai_interview_service.dart';
import 'package:ainterview/services/interview_session_repository.dart';

void main() {
  group('InterviewSessionController edge cases', () {
    test(
      'clears the half-started session when the opening AI call fails',
      () async {
        final controller = InterviewSessionController(
          aiService: _ConfigurableAiService(failStart: true),
        );

        await controller.start(
          level: InterviewLevel.junior,
          stage: InterviewStage.hr,
          language: InterviewLanguage.english,
        );

        expect(controller.messages, isEmpty);
        expect(controller.currentSession, isNull);
        expect(controller.errorMessage, contains('start failed'));
        expect(controller.isBusy, isFalse);
        expect(controller.isEnded, isFalse);
      },
    );

    test(
      'reuses generated review when saving the ended session is retried',
      () async {
        final aiService = _ConfigurableAiService();
        final repository = _FailingOnceSessionRepository();
        final controller = InterviewSessionController(
          aiService: aiService,
          sessionRepository: repository,
          userId: 'user_1',
        );

        await controller.start(
          level: InterviewLevel.senior,
          stage: InterviewStage.technical,
          language: InterviewLanguage.english,
        );
        await controller.sendUserAnswer(
          'I would isolate API retry state behind a repository and test it.',
        );

        await expectLater(controller.endAndReview(), throwsException);
        expect(aiService.reviewCalls, 1);
        expect(controller.review, isNotNull);
        expect(controller.isEnded, isFalse);

        repository.shouldFail = false;
        final review = await controller.endAndReview();

        expect(review.id, 'review_1');
        expect(aiService.reviewCalls, 1);
        expect(controller.isEnded, isTrue);
        expect(repository.savedSessions, hasLength(1));
      },
    );

    test(
      'does not allow a redirected low-effort answer to qualify for final review',
      () async {
        final controller = InterviewSessionController(
          aiService: _ConfigurableAiService(),
        );

        await controller.start(
          level: InterviewLevel.junior,
          stage: InterviewStage.technical,
          language: InterviewLanguage.indonesian,
        );
        await controller.sendUserAnswer('asdf qwer zzzz');

        await expectLater(controller.endAndReview(), throwsStateError);
        expect(controller.isEnded, isFalse);
      },
    );

    test(
      'blocks a second answer while an AI follow-up is already in flight',
      () async {
        final aiService = _ConfigurableAiService(
          sendDelay: const Duration(milliseconds: 20),
        );
        final controller = InterviewSessionController(aiService: aiService);

        await controller.start(
          level: InterviewLevel.junior,
          stage: InterviewStage.hr,
          language: InterviewLanguage.english,
        );

        final firstSend = controller.sendUserAnswer(
          'I solved a Flutter project deadline with my team.',
        );
        final secondSend = controller.sendUserAnswer(
          'I also debugged the API state management issue.',
        );
        await Future.wait([firstSend, secondSend]);

        expect(aiService.sendCalls, 1);
      },
    );
  });
}

class _ConfigurableAiService implements AiInterviewService {
  _ConfigurableAiService({
    this.failStart = false,
    this.sendDelay = Duration.zero,
  });

  final bool failStart;
  final Duration sendDelay;
  int sendCalls = 0;
  int reviewCalls = 0;

  @override
  Future<String> startInterview({
    required InterviewLevel level,
    required InterviewStage stage,
    required InterviewLanguage language,
    InterviewPreparationContext? preparationContext,
  }) async {
    if (failStart) {
      throw Exception('start failed');
    }

    return 'Opening question';
  }

  @override
  Future<String> sendMessage({
    required InterviewLevel level,
    required InterviewStage stage,
    required InterviewLanguage language,
    required List<InterviewMessage> messages,
    InterviewPreparationContext? preparationContext,
  }) async {
    sendCalls += 1;
    if (sendDelay != Duration.zero) {
      await Future<void>.delayed(sendDelay);
    }

    return 'Follow-up question';
  }

  @override
  Future<InterviewReview> reviewInterview({
    required InterviewLevel level,
    required InterviewStage stage,
    required InterviewLanguage language,
    required List<InterviewMessage> messages,
    InterviewPreparationContext? preparationContext,
  }) async {
    reviewCalls += 1;
    return InterviewReview(
      id: 'review_1',
      level: level,
      stage: stage,
      language: language,
      createdAt: DateTime.utc(2026, 6, 25),
      summary: 'Review summary',
      communicationFeedback: 'Communication feedback',
      technicalFeedback: 'Technical feedback',
      improvementAreas: const ['Depth'],
      recommendations: [
        ReviewRecommendation(
          id: 'recommendation_1',
          title: 'Practice retry states',
          description: 'Explain loading, error, retry, and success states.',
          level: level,
          stage: stage,
        ),
      ],
    );
  }
}

class _FailingOnceSessionRepository implements InterviewSessionRepository {
  bool shouldFail = true;
  final savedSessions = <InterviewSession>[];

  @override
  Future<List<InterviewSession>> fetchSessions(
    String userId, {
    InterviewLevel? level,
    InterviewStage? stage,
    bool completedOnly = false,
    int? limit,
  }) async {
    return savedSessions;
  }

  @override
  Future<InterviewSession> saveSession(
    String userId,
    InterviewSession session,
  ) async {
    if (shouldFail) {
      throw Exception('save failed');
    }

    final savedSession = session.id.isEmpty
        ? session.copyWith(id: 'session_1')
        : session;
    savedSessions.add(savedSession);
    return savedSession;
  }
}
