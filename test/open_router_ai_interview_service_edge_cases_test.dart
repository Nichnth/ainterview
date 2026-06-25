import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:ainterview/models/interview_enums.dart';
import 'package:ainterview/models/interview_message.dart';
import 'package:ainterview/services/open_router_ai_interview_service.dart';

void main() {
  group('OpenRouterAiInterviewService edge cases', () {
    test(
      'falls back to generated recommendation content for non-map entries',
      () async {
        final service = OpenRouterAiInterviewService(
          apiKey: 'test-key',
          client: MockClient((request) async {
            return http.Response(
              jsonEncode({
                'choices': [
                  {
                    'message': {
                      'content': jsonEncode({
                        'summary': 'Good',
                        'communicationFeedback': 'Clear',
                        'technicalFeedback': 'Specific',
                        'improvementAreas': ['Depth'],
                        'recommendations': ['Practice one API retry scenario'],
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
          level: InterviewLevel.junior,
          stage: InterviewStage.technical,
          language: InterviewLanguage.english,
          messages: [
            InterviewMessage(
              sender: InterviewMessageSender.user,
              text: 'I use tests around retry behavior.',
              createdAt: DateTime.utc(2026, 6, 25),
            ),
          ],
        );

        expect(review.recommendations.single.id, 'recommendation_1');
        expect(
          review.recommendations.single.title,
          'Practice one API retry scenario',
        );
        expect(review.recommendations.single.level, InterviewLevel.junior);
        expect(review.recommendations.single.stage, InterviewStage.technical);
      },
    );

    test(
      'normalizes lowercase level and stage labels returned by the model',
      () async {
        final service = OpenRouterAiInterviewService(
          apiKey: 'test-key',
          client: MockClient((request) async {
            return http.Response(
              jsonEncode({
                'choices': [
                  {
                    'message': {
                      'content': jsonEncode({
                        'summary': 'Good',
                        'communicationFeedback': 'Clear',
                        'technicalFeedback': 'Specific',
                        'improvementAreas': ['Depth'],
                        'recommendations': [
                          {
                            'id': 'recommendation_1',
                            'title': 'Retry drill',
                            'description': 'Practice retry states.',
                            'level': 'junior dev',
                            'stage': 'technical',
                          },
                        ],
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
        );

        expect(review.recommendations.single.level, InterviewLevel.junior);
        expect(review.recommendations.single.stage, InterviewStage.technical);
      },
    );

    test('repairs malformed review JSON once before parsing review', () async {
      final requestBodies = <Map<String, dynamic>>[];
      final service = OpenRouterAiInterviewService(
        apiKey: 'test-key',
        modelIds: const ['free-json-model'],
        client: MockClient((request) async {
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          requestBodies.add(body);
          final content = requestBodies.length == 1
              ? '{"summary":"Good","communicationFeedback":"Clear","technicalFeedback":"Specific","improvementAreas":["Depth"'
              : jsonEncode({
                  'summary': 'Good',
                  'communicationFeedback': 'Clear',
                  'technicalFeedback': 'Specific',
                  'improvementAreas': ['Depth'],
                  'recommendations': [],
                });

          return http.Response(
            jsonEncode({
              'choices': [
                {
                  'message': {'content': content},
                },
              ],
            }),
            200,
          );
        }),
      );

      final review = await service.reviewInterview(
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
      );

      expect(review.summary, 'Good');
      expect(review.improvementAreas, ['Depth']);
      expect(requestBodies, hasLength(2));
      final repairMessages = requestBodies.last['messages'] as List<dynamic>;
      expect(repairMessages.last['content'], contains('Repair this'));
      expect(repairMessages.last['content'], contains('valid JSON'));
    });

    test(
      'throws a controlled OpenRouter exception when repaired review JSON is still malformed',
      () async {
        final service = OpenRouterAiInterviewService(
          apiKey: 'test-key',
          modelIds: const ['free-json-model'],
          client: MockClient((request) async {
            return http.Response(
              jsonEncode({
                'choices': [
                  {
                    'message': {
                      'content':
                          '{"summary":"Good","communicationFeedback":"Clear",',
                    },
                  },
                ],
              }),
              200,
            );
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
          throwsA(isA<OpenRouterAiInterviewException>()),
        );
      },
    );
  });
}
