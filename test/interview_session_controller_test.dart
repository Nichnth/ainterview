import 'package:flutter_test/flutter_test.dart';

import 'package:ainterview/models/interview_enums.dart';
import 'package:ainterview/models/interview_message.dart';
import 'package:ainterview/models/interview_plan.dart';
import 'package:ainterview/models/interview_preparation_context.dart';
import 'package:ainterview/models/interview_session.dart';
import 'package:ainterview/providers/interview_session_controller.dart';
import 'package:ainterview/services/ai_interview_service.dart';
import 'package:ainterview/services/interview_plan_generator.dart';
import 'package:ainterview/services/interview_session_repository.dart';

void main() {
  group('InterviewSessionController', () {
    test('starts a Junior HR session and sends contextual follow-up', () async {
      final controller = InterviewSessionController(
        aiService: MockAiInterviewService(),
      );

      await controller.start(
        level: InterviewLevel.junior,
        stage: InterviewStage.hr,
        language: InterviewLanguage.indonesian,
      );

      expect(controller.messages, hasLength(1));
      expect(controller.messages.single.sender, InterviewMessageSender.ai);
      expect(controller.messages.single.text, contains('Junior Dev'));
      expect(controller.messages.single.text, contains('HR'));

      await controller.sendUserAnswer(
        'Saya pernah membangun aplikasi Flutter dengan integrasi API.',
      );

      expect(controller.messages, hasLength(3));
      expect(controller.messages[1].sender, InterviewMessageSender.user);
      expect(controller.messages[2].sender, InterviewMessageSender.ai);
      expect(controller.messages[2].text, contains('Junior Dev'));
      expect(controller.isBusy, isFalse);
    });

    test('ends a Senior Technical session with structured review', () async {
      final controller = InterviewSessionController(
        aiService: MockAiInterviewService(),
      );

      await controller.start(
        level: InterviewLevel.senior,
        stage: InterviewStage.technical,
        language: InterviewLanguage.english,
      );
      await controller.sendUserAnswer(
        'I would split presentation, domain, and data layers.',
      );

      final review = await controller.endAndReview();

      expect(controller.isEnded, isTrue);
      expect(review.summary, contains('Senior Dev Technical'));
      expect(review.level, InterviewLevel.senior);
      expect(review.stage, InterviewStage.technical);
      expect(review.language, InterviewLanguage.english);
      expect(review.communicationFeedback, isNotEmpty);
      expect(review.technicalFeedback, contains('architecture'));
      expect(review.improvementAreas, isNotEmpty);
      expect(review.recommendations, isNotEmpty);
      expect(review.recommendations.first.level, InterviewLevel.senior);
      expect(review.recommendations.first.stage, InterviewStage.technical);
    });

    test('rejects answers after the session has ended', () async {
      final controller = InterviewSessionController(
        aiService: MockAiInterviewService(),
      );

      await controller.start(
        level: InterviewLevel.intern,
        stage: InterviewStage.hr,
        language: InterviewLanguage.indonesian,
      );
      await controller.sendUserAnswer(
        'Saya pernah menyelesaikan project mobile bersama tim.',
      );
      await controller.endAndReview();

      expect(
        () => controller.sendUserAnswer('Saya ingin menjawab lagi.'),
        throwsStateError,
      );
    });

    test(
      'redirects irrelevant candidate answers without advancing AI prompt',
      () async {
        final controller = InterviewSessionController(
          aiService: MockAiInterviewService(),
        );

        await controller.start(
          level: InterviewLevel.junior,
          stage: InterviewStage.technical,
          language: InterviewLanguage.indonesian,
        );
        await controller.sendUserAnswer('asdf qwer zzzz');

        expect(controller.messages, hasLength(3));
        expect(controller.messages[1].sender, InterviewMessageSender.user);
        expect(controller.messages[2].sender, InterviewMessageSender.ai);
        expect(controller.messages[2].text, contains('belum sesuai konteks'));
        expect(controller.messages[2].text, contains('Junior Dev Technical'));
      },
    );

    test('accepts relevant technical answers that mention unit test', () async {
      final controller = InterviewSessionController(
        aiService: MockAiInterviewService(),
      );

      await controller.start(
        level: InterviewLevel.junior,
        stage: InterviewStage.technical,
        language: InterviewLanguage.english,
      );
      await controller.sendUserAnswer(
        'I wrote a unit test for the API retry state and test coverage improved.',
      );

      expect(controller.messages, hasLength(3));
      expect(controller.messages[2].text, startsWith('Thanks.'));
    });

    test('redirects unrelated English answers', () async {
      final controller = InterviewSessionController(
        aiService: MockAiInterviewService(),
      );

      await controller.start(
        level: InterviewLevel.junior,
        stage: InterviewStage.hr,
        language: InterviewLanguage.english,
      );
      await controller.sendUserAnswer(
        'Yesterday I watched a movie on vacation and ate pizza.',
      );

      expect(controller.messages, hasLength(3));
      expect(controller.messages[2].text, contains('not yet aligned'));
    });

    test('rejects review before the candidate sends an answer', () async {
      final controller = InterviewSessionController(
        aiService: MockAiInterviewService(),
      );

      await controller.start(
        level: InterviewLevel.junior,
        stage: InterviewStage.hr,
        language: InterviewLanguage.english,
      );

      await expectLater(controller.endAndReview(), throwsStateError);
      expect(controller.isEnded, isFalse);
      expect(controller.errorMessage, contains('answer at least once'));
    });

    test('keeps ended session retryable when repository save fails', () async {
      final repository = _FailingSessionRepository();
      final controller = InterviewSessionController(
        aiService: MockAiInterviewService(),
        sessionRepository: repository,
        userId: 'user_1',
      );

      await controller.start(
        level: InterviewLevel.junior,
        stage: InterviewStage.hr,
        language: InterviewLanguage.english,
      );
      await controller.sendUserAnswer(
        'I worked with my team to solve a deadline problem.',
      );

      await expectLater(controller.endAndReview(), throwsException);

      expect(controller.review, isNotNull);
      expect(controller.isEnded, isFalse);
      repository.shouldFail = false;

      final review = await controller.endAndReview();

      expect(review, controller.review);
      expect(controller.isEnded, isTrue);
      expect(repository.savedSessions, hasLength(1));
    });

    test(
      'saves ended sessions with filterable level and interview type metadata',
      () async {
        final repository = InMemoryInterviewSessionRepository();
        final controller = InterviewSessionController(
          aiService: MockAiInterviewService(),
          sessionRepository: repository,
          userId: 'user_1',
        );

        await controller.start(
          level: InterviewLevel.senior,
          stage: InterviewStage.technical,
          language: InterviewLanguage.indonesian,
          linkedPlanId: 'plan_1',
        );
        await controller.sendUserAnswer(
          'Saya akan memakai Clean Architecture dan test pyramid.',
        );

        final review = await controller.endAndReview();
        final seniorTechnicalSessions = await repository.fetchSessions(
          'user_1',
          level: InterviewLevel.senior,
          stage: InterviewStage.technical,
        );
        final juniorHrSessions = await repository.fetchSessions(
          'user_1',
          level: InterviewLevel.junior,
          stage: InterviewStage.hr,
        );

        expect(seniorTechnicalSessions, hasLength(1));
        expect(seniorTechnicalSessions.single.level, InterviewLevel.senior);
        expect(seniorTechnicalSessions.single.stage, InterviewStage.technical);
        expect(
          seniorTechnicalSessions.single.language,
          InterviewLanguage.indonesian,
        );
        expect(seniorTechnicalSessions.single.linkedPlanId, 'plan_1');
        expect(seniorTechnicalSessions.single.messages, hasLength(3));
        expect(seniorTechnicalSessions.single.review?.id, review.id);
        expect(seniorTechnicalSessions.single.endedAt, isNotNull);
        expect(juniorHrSessions, isEmpty);
      },
    );

    test('saves plan topic metadata for topic-guided sessions', () async {
      final repository = InMemoryInterviewSessionRepository();
      final items = InterviewPlanGenerator.generate(
        today: DateTime(2026, 5, 25),
        targetDate: DateTime(2026, 6, 15),
        level: InterviewLevel.junior,
        language: InterviewLanguage.indonesian,
      );
      final focusItem = items.firstWhere(
        (item) => item.title.contains('State Management'),
      );
      final plan = InterviewPlan(
        id: 'plan_1',
        targetDate: DateTime(2026, 6, 15),
        level: InterviewLevel.junior,
        language: InterviewLanguage.indonesian,
        createdAt: DateTime.utc(2026, 5, 25),
        scheduleItems: items,
      );
      final context = InterviewPreparationContext.fromPlan(
        plan,
        selectedScheduleItemId: focusItem.id,
      );
      final controller = InterviewSessionController(
        aiService: MockAiInterviewService(),
        sessionRepository: repository,
        userId: 'user_1',
      );

      await controller.start(
        level: plan.level,
        stage: context.suggestedStage!,
        language: plan.language,
        linkedPlanId: plan.id,
        linkedScheduleItemId: focusItem.id,
        preparationContext: context,
      );
      await controller.sendUserAnswer(
        'Saya memakai Provider dan BLoC sesuai kebutuhan state aplikasi.',
      );

      await controller.endAndReview();
      final sessions = await repository.fetchSessions('user_1');

      expect(sessions, hasLength(1));
      expect(sessions.single.linkedPlanId, plan.id);
      expect(sessions.single.linkedScheduleItemId, focusItem.id);
      expect(sessions.single.preparationFocusTitle, focusItem.title);
      expect(sessions.single.stage, InterviewStage.technical);
    });

    test(
      'fetches bounded completed session history with server-like filters',
      () async {
        final repository = InMemoryInterviewSessionRepository();
        await repository.saveSession(
          'user_1',
          _savedSession(
            id: 'old_completed',
            level: InterviewLevel.senior,
            stage: InterviewStage.technical,
            startedAt: DateTime.utc(2026, 6, 1),
            endedAt: DateTime.utc(2026, 6, 1, 1),
          ),
        );
        await repository.saveSession(
          'user_1',
          _savedSession(
            id: 'active',
            level: InterviewLevel.senior,
            stage: InterviewStage.technical,
            startedAt: DateTime.utc(2026, 6, 2),
          ),
        );
        await repository.saveSession(
          'user_1',
          _savedSession(
            id: 'other_stage',
            level: InterviewLevel.senior,
            stage: InterviewStage.hr,
            startedAt: DateTime.utc(2026, 6, 3),
            endedAt: DateTime.utc(2026, 6, 3, 1),
          ),
        );
        await repository.saveSession(
          'user_1',
          _savedSession(
            id: 'new_completed',
            level: InterviewLevel.senior,
            stage: InterviewStage.technical,
            startedAt: DateTime.utc(2026, 6, 4),
            endedAt: DateTime.utc(2026, 6, 4, 1),
          ),
        );

        final sessions = await repository.fetchSessions(
          'user_1',
          level: InterviewLevel.senior,
          stage: InterviewStage.technical,
          completedOnly: true,
          limit: 1,
        );

        expect(sessions.map((session) => session.id), ['new_completed']);
      },
    );
  });
}

InterviewSession _savedSession({
  required String id,
  required InterviewLevel level,
  required InterviewStage stage,
  required DateTime startedAt,
  DateTime? endedAt,
}) {
  return InterviewSession(
    id: id,
    level: level,
    stage: stage,
    language: InterviewLanguage.english,
    startedAt: startedAt,
    endedAt: endedAt,
    messages: const [],
  );
}

class _FailingSessionRepository implements InterviewSessionRepository {
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
      throw Exception('Database unavailable');
    }

    final savedSession = session.id.isEmpty
        ? session.copyWith(id: 'session_1')
        : session;
    savedSessions.add(savedSession);
    return savedSession;
  }
}
