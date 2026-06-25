import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:ainterview/models/interview_enums.dart';
import 'package:ainterview/models/interview_message.dart';
import 'package:ainterview/services/backend_ai_interview_service.dart';

void main() {
  group('BackendAiInterviewService edge cases', () {
    test(
      'rejects empty start text returned by a successful backend response',
      () async {
        final service = BackendAiInterviewService(
          baseUrl: Uri.parse('https://api.example.test/interview'),
          idTokenProvider: () async => 'firebase-id-token',
          client: MockClient((request) async {
            return http.Response(jsonEncode({'text': '   '}), 200);
          }),
        );

        await expectLater(
          service.startInterview(
            level: InterviewLevel.junior,
            stage: InterviewStage.hr,
            language: InterviewLanguage.english,
          ),
          throwsA(
            isA<BackendAiInterviewException>().having(
              (error) => error.code,
              'code',
              'AI_EMPTY_RESPONSE',
            ),
          ),
        );
      },
    );

    test(
      'rejects review responses whose review field is not an object',
      () async {
        final service = BackendAiInterviewService(
          baseUrl: Uri.parse('https://api.example.test/interview'),
          idTokenProvider: () async => 'firebase-id-token',
          client: MockClient((request) async {
            return http.Response(jsonEncode({'review': []}), 200);
          }),
        );

        await expectLater(
          service.reviewInterview(
            level: InterviewLevel.junior,
            stage: InterviewStage.technical,
            language: InterviewLanguage.english,
            messages: [
              InterviewMessage(
                sender: InterviewMessageSender.user,
                text: 'I test retry behavior.',
                createdAt: DateTime.utc(2026, 6, 25),
              ),
            ],
          ),
          throwsA(
            isA<BackendAiInterviewException>().having(
              (error) => error.code,
              'code',
              'AI_INVALID_REVIEW',
            ),
          ),
        );
      },
    );

    test(
      'wraps non-JSON backend error bodies in a user-facing backend exception',
      () async {
        final service = BackendAiInterviewService(
          baseUrl: Uri.parse('https://api.example.test/interview'),
          idTokenProvider: () async => 'firebase-id-token',
          client: MockClient((request) async {
            return http.Response('<html>temporarily down</html>', 500);
          }),
        );

        await expectLater(
          service.sendMessage(
            level: InterviewLevel.junior,
            stage: InterviewStage.hr,
            language: InterviewLanguage.english,
            messages: [
              InterviewMessage(
                sender: InterviewMessageSender.user,
                text: 'I led a project debugging session.',
                createdAt: DateTime.utc(2026, 6, 25),
              ),
            ],
          ),
          throwsA(isA<BackendAiInterviewException>()),
        );
      },
    );
  });
}
