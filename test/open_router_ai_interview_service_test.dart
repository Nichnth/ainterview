import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:ainterview/models/interview_enums.dart';
import 'package:ainterview/models/interview_message.dart';
import 'package:ainterview/services/open_router_ai_interview_service.dart';

void main() {
  group('OpenRouterAiInterviewService', () {
    test('uses the configured free OpenRouter model order', () {
      expect(OpenRouterAiInterviewService.defaultModelIds, const [
        'nvidia/nemotron-3-nano-omni-30b-a3b-reasoning:free',
        'google/gemma-4-31b-it:free',
        'google/gemma-4-26b-a4b-it:free',
      ]);
    });

    test('sends OpenRouter chat completion payload with first model', () async {
      Map<String, dynamic>? requestBody;
      Map<String, String>? requestHeaders;
      final service = OpenRouterAiInterviewService(
        apiKey: 'test-key',
        client: MockClient((request) async {
          requestHeaders = request.headers;
          requestBody = jsonDecode(request.body) as Map<String, dynamic>;
          return http.Response(
            jsonEncode({
              'choices': [
                {
                  'message': {'content': 'Opening question from OpenRouter'},
                },
              ],
            }),
            200,
          );
        }),
      );

      final response = await service.startInterview(
        level: InterviewLevel.junior,
        stage: InterviewStage.hr,
        language: InterviewLanguage.indonesian,
      );

      expect(response, 'Opening question from OpenRouter');
      expect(requestHeaders?['authorization'], 'Bearer test-key');
      expect(
        requestBody?['model'],
        'nvidia/nemotron-3-nano-omni-30b-a3b-reasoning:free',
      );
      expect(requestBody?['temperature'], 0.7);
      expect(requestBody?['max_tokens'], 512);
      expect(requestBody?['messages'], isA<List<dynamic>>());
      expect(
        (requestBody?['messages'] as List<dynamic>).first['role'],
        'system',
      );
    });

    test('falls back to the next model when a model request fails', () async {
      final requestedModels = <String>[];
      final service = OpenRouterAiInterviewService(
        apiKey: 'test-key',
        modelIds: const ['first-model', 'second-model'],
        client: MockClient((request) async {
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          requestedModels.add(body['model'] as String);

          if (body['model'] == 'first-model') {
            return http.Response('rate limited', 429);
          }

          return http.Response(
            jsonEncode({
              'choices': [
                {
                  'message': {'content': 'Fallback model response'},
                },
              ],
            }),
            200,
          );
        }),
      );

      final response = await service.sendMessage(
        level: InterviewLevel.senior,
        stage: InterviewStage.technical,
        language: InterviewLanguage.english,
        messages: [
          InterviewMessage(
            sender: InterviewMessageSender.user,
            text: 'I use clean architecture.',
            createdAt: DateTime.utc(2026, 5, 26),
          ),
        ],
      );

      expect(response, 'Fallback model response');
      expect(requestedModels, ['first-model', 'second-model']);
    });

    test('parses structured JSON review content', () async {
      final service = OpenRouterAiInterviewService(
        apiKey: 'test-key',
        client: MockClient((request) async {
          return http.Response(
            jsonEncode({
              'choices': [
                {
                  'message': {
                    'content': jsonEncode({
                      'summary': 'Good Senior Technical session.',
                      'communicationFeedback': 'Clear and concise.',
                      'technicalFeedback': 'Add more architecture trade-offs.',
                      'improvementAreas': ['Testing strategy'],
                      'recommendations': ['Practice system design'],
                    }),
                  },
                },
              ],
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
            text: 'I use layers.',
            createdAt: DateTime.utc(2026, 5, 26),
          ),
        ],
      );

      expect(review.summary, 'Good Senior Technical session.');
      expect(review.communicationFeedback, 'Clear and concise.');
      expect(review.technicalFeedback, contains('architecture'));
      expect(review.improvementAreas, ['Testing strategy']);
      expect(review.recommendations, ['Practice system design']);
    });
  });
}
