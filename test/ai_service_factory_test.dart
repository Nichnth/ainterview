import 'package:flutter_test/flutter_test.dart';

import 'package:ainterview/models/interview_enums.dart';
import 'package:ainterview/screens/main_navigation_wrapper.dart';
import 'package:ainterview/services/backend_ai_interview_service.dart';
import 'package:ainterview/services/open_router_ai_interview_service.dart';

void main() {
  group('buildDefaultAiInterviewService', () {
    test('uses backend proxy when a proxy base URL is configured', () {
      final service = buildDefaultAiInterviewService(
        proxyBaseUrl: 'https://api.example.test/interview',
        idTokenProvider: () async => 'firebase-id-token',
      );

      expect(service, isA<BackendAiInterviewService>());
    });

    test('uses client-side OpenRouter key when proxy URL is missing', () {
      final service = buildDefaultAiInterviewService(
        proxyBaseUrl: '',
        openRouterApiKey: 'openrouter-key',
        idTokenProvider: () async => 'firebase-id-token',
      );

      expect(service, isA<OpenRouterAiInterviewService>());
    });

    test(
      'prefers backend proxy when both proxy URL and OpenRouter key are configured',
      () {
        final service = buildDefaultAiInterviewService(
          proxyBaseUrl: 'https://api.example.test/interview',
          openRouterApiKey: 'openrouter-key',
          idTokenProvider: () async => 'firebase-id-token',
        );

        expect(service, isA<BackendAiInterviewService>());
      },
    );

    test(
      'reports missing AI config when proxy and OpenRouter key are missing',
      () async {
        final service = buildDefaultAiInterviewService(
          proxyBaseUrl: '',
          openRouterApiKey: '',
          idTokenProvider: () async => 'firebase-id-token',
        );

        await expectLater(
          service.startInterview(
            level: InterviewLevel.junior,
            stage: InterviewStage.hr,
            language: InterviewLanguage.english,
          ),
          throwsA(
            isA<StateError>().having(
              (error) => error.message,
              'message',
              contains('AI service is not configured'),
            ),
          ),
        );
      },
    );
  });
}
