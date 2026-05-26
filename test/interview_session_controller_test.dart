import 'package:flutter_test/flutter_test.dart';

import 'package:ainterview/models/interview_enums.dart';
import 'package:ainterview/models/interview_message.dart';
import 'package:ainterview/providers/interview_session_controller.dart';
import 'package:ainterview/services/ai_interview_service.dart';

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
      expect(review.communicationFeedback, isNotEmpty);
      expect(review.technicalFeedback, contains('architecture'));
      expect(review.improvementAreas, isNotEmpty);
      expect(review.recommendations, isNotEmpty);
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
  });
}
