import 'package:flutter_test/flutter_test.dart';

import 'package:ainterview/models/interview_enums.dart';
import 'package:ainterview/models/interview_message.dart';
import 'package:ainterview/models/interview_plan.dart';
import 'package:ainterview/models/interview_preparation_context.dart';
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
  });
}
