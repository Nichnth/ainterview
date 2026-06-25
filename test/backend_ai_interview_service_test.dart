import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:ainterview/models/interview_enums.dart';
import 'package:ainterview/models/interview_message.dart';
import 'package:ainterview/services/backend_ai_interview_service.dart';

void main() {
  group('BackendAiInterviewService', () {
    test('sends authenticated start requests to the backend proxy', () async {
      Uri? requestedUrl;
      Map<String, String>? requestHeaders;
      Map<String, dynamic>? requestBody;
      final service = BackendAiInterviewService(
        baseUrl: Uri.parse('https://api.example.test/interview'),
        idTokenProvider: () async => 'firebase-id-token',
        client: MockClient((request) async {
          requestedUrl = request.url;
          requestHeaders = request.headers;
          requestBody = jsonDecode(request.body) as Map<String, dynamic>;
          return http.Response(jsonEncode({'text': 'Opening question'}), 200);
        }),
      );

      final response = await service.startInterview(
        level: InterviewLevel.junior,
        stage: InterviewStage.hr,
        language: InterviewLanguage.indonesian,
      );

      expect(response, 'Opening question');
      expect(
        requestedUrl,
        Uri.parse('https://api.example.test/interview/start'),
      );
      expect(requestHeaders?['authorization'], 'Bearer firebase-id-token');
      expect(requestHeaders?['content-type'], contains('application/json'));
      expect(requestBody, {
        'level': 'junior',
        'stage': 'hr',
        'language': 'indonesian',
      });
    });

    test('sends reply requests with serialized transcript messages', () async {
      Map<String, dynamic>? requestBody;
      final service = BackendAiInterviewService(
        baseUrl: Uri.parse('https://api.example.test/interview/'),
        idTokenProvider: () async => 'firebase-id-token',
        client: MockClient((request) async {
          requestBody = jsonDecode(request.body) as Map<String, dynamic>;
          return http.Response(jsonEncode({'text': 'Follow-up question'}), 200);
        }),
      );

      final response = await service.sendMessage(
        level: InterviewLevel.senior,
        stage: InterviewStage.technical,
        language: InterviewLanguage.english,
        messages: [
          InterviewMessage(
            sender: InterviewMessageSender.user,
            text: 'I use integration tests for API flows.',
            createdAt: DateTime.utc(2026, 6, 24),
          ),
        ],
      );

      expect(response, 'Follow-up question');
      expect(requestBody?['messages'], [
        {
          'sender': 'user',
          'text': 'I use integration tests for API flows.',
          'createdAt': '2026-06-24T00:00:00.000Z',
        },
      ]);
    });

    test('parses review responses returned by the backend proxy', () async {
      final service = BackendAiInterviewService(
        baseUrl: Uri.parse('https://api.example.test/interview'),
        idTokenProvider: () async => 'firebase-id-token',
        client: MockClient((request) async {
          return http.Response(
            jsonEncode({
              'review': {
                'id': 'review_1',
                'level': 'Senior Dev',
                'stage': 'Technical',
                'language': 'English',
                'createdAt': '2026-06-24T01:00:00.000Z',
                'summary': 'Strong session.',
                'communicationFeedback': 'Clear structure.',
                'technicalFeedback': 'Good testing depth.',
                'improvementAreas': ['Architecture trade-offs'],
                'recommendations': [
                  {
                    'id': 'recommendation_1',
                    'title': 'Practice architecture review',
                    'description':
                        'Explain one trade-off with measurable risk.',
                    'level': 'Senior Dev',
                    'stage': 'Technical',
                  },
                ],
              },
            }),
            200,
          );
        }),
      );

      final review = await service.reviewInterview(
        level: InterviewLevel.senior,
        stage: InterviewStage.technical,
        language: InterviewLanguage.english,
        messages: [
          InterviewMessage(
            sender: InterviewMessageSender.user,
            text: 'I design testable layers.',
            createdAt: DateTime.utc(2026, 6, 24),
          ),
        ],
      );

      expect(review.id, 'review_1');
      expect(review.summary, 'Strong session.');
      expect(
        review.recommendations.single.title,
        'Practice architecture review',
      );
    });

    test(
      'fails before calling the backend when no Firebase token is available',
      () async {
        var called = false;
        final service = BackendAiInterviewService(
          baseUrl: Uri.parse('https://api.example.test/interview'),
          idTokenProvider: () async => null,
          client: MockClient((request) async {
            called = true;
            return http.Response('{}', 200);
          }),
        );

        await expectLater(
          service.startInterview(
            level: InterviewLevel.junior,
            stage: InterviewStage.hr,
            language: InterviewLanguage.english,
          ),
          throwsA(isA<BackendAiInterviewException>()),
        );
        expect(called, isFalse);
      },
    );

    test('surfaces backend error codes as user-facing exceptions', () async {
      final service = BackendAiInterviewService(
        baseUrl: Uri.parse('https://api.example.test/interview'),
        idTokenProvider: () async => 'firebase-id-token',
        client: MockClient((request) async {
          return http.Response(
            jsonEncode({
              'code': 'AI_RATE_LIMITED',
              'message': 'Daily AI practice limit reached.',
            }),
            429,
          );
        }),
      );

      await expectLater(
        service.sendMessage(
          level: InterviewLevel.junior,
          stage: InterviewStage.technical,
          language: InterviewLanguage.english,
          messages: const [],
        ),
        throwsA(
          isA<BackendAiInterviewException>()
              .having((error) => error.code, 'code', 'AI_RATE_LIMITED')
              .having(
                (error) => error.toString(),
                'message',
                'Daily AI practice limit reached.',
              ),
        ),
      );
    });
  });
}
