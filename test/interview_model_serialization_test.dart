import 'package:flutter_test/flutter_test.dart';

import 'package:ainterview/models/interview_enums.dart';
import 'package:ainterview/models/interview_message.dart';
import 'package:ainterview/models/interview_plan.dart';
import 'package:ainterview/models/interview_review.dart';
import 'package:ainterview/models/interview_session.dart';
import 'package:ainterview/models/review_recommendation.dart';
import 'package:ainterview/models/schedule_item.dart';

void main() {
  group('Interview enum persistence contract', () {
    test('serializes stable enum keys while reading legacy labels', () {
      final plan = InterviewPlan(
        id: 'plan_1',
        targetDate: DateTime.utc(2026, 7, 10),
        level: InterviewLevel.junior,
        language: InterviewLanguage.indonesian,
        createdAt: DateTime.utc(2026, 6, 25),
        scheduleItems: const [
          ScheduleItem(
            id: 'technical_focus_state_management',
            dayOffset: 1,
            title: 'Technical Focus: State Management',
            description: 'Practice state flows.',
            suggestedStage: InterviewStage.technical,
          ),
        ],
      );
      final review = InterviewReview(
        id: 'review_1',
        level: InterviewLevel.senior,
        stage: InterviewStage.technical,
        language: InterviewLanguage.english,
        createdAt: DateTime.utc(2026, 6, 25),
        summary: 'Summary',
        communicationFeedback: 'Clear',
        technicalFeedback: 'Specific',
        improvementAreas: const ['Depth'],
        recommendations: const [
          ReviewRecommendation(
            id: 'recommendation_1',
            title: 'Retry drill',
            description: 'Practice retry states.',
            level: InterviewLevel.senior,
            stage: InterviewStage.technical,
          ),
        ],
      );

      expect(plan.toMap()['level'], 'junior');
      expect(plan.toMap()['language'], 'indonesian');
      expect(
        (plan.toMap()['scheduleItems'] as List).single['suggestedStage'],
        'technical',
      );
      expect(review.toMap()['level'], 'senior');
      expect(review.toMap()['stage'], 'technical');
      expect(review.toMap()['language'], 'english');
      expect(
        (review.toMap()['recommendations'] as List).single['level'],
        'senior',
      );

      final legacyPlan = InterviewPlan.fromMap('plan_legacy', {
        'targetDate': '2026-07-10T00:00:00.000Z',
        'level': 'Junior Dev',
        'language': 'Indonesian',
        'createdAt': '2026-06-25T00:00:00.000Z',
        'scheduleItems': [
          {
            'id': 'technical_focus_state_management',
            'dayOffset': 1,
            'title': 'Technical Focus: State Management',
            'description': 'Practice state flows.',
            'suggestedStage': 'Technical',
          },
        ],
      });

      expect(legacyPlan.level, InterviewLevel.junior);
      expect(legacyPlan.language, InterviewLanguage.indonesian);
      expect(
        legacyPlan.scheduleItems.single.suggestedStage,
        InterviewStage.technical,
      );
      expect(InterviewLevel.fromLabel('junior'), InterviewLevel.junior);
      expect(InterviewStage.fromLabel('technical'), InterviewStage.technical);
      expect(InterviewLanguage.fromLabel('english'), InterviewLanguage.english);
    });
  });

  group('InterviewMessage', () {
    test('deserializes from a saved map', () {
      final message = InterviewMessage.fromMap({
        'sender': 'user',
        'text': 'I wrote a unit test for the API failure path.',
        'createdAt': '2026-06-23T10:15:00.000Z',
      });

      expect(message.sender, InterviewMessageSender.user);
      expect(message.text, contains('unit test'));
      expect(message.createdAt, DateTime.utc(2026, 6, 23, 10, 15));
    });
  });

  group('InterviewSession', () {
    test('round-trips saved sessions with nested messages and review', () {
      final session = InterviewSession(
        id: 'session_1',
        level: InterviewLevel.senior,
        stage: InterviewStage.technical,
        language: InterviewLanguage.english,
        startedAt: DateTime.utc(2026, 6, 23, 10),
        endedAt: DateTime.utc(2026, 6, 23, 10, 20),
        linkedPlanId: 'plan_1',
        linkedScheduleItemId: 'technical_focus_architecture',
        preparationFocusTitle: 'Technical Focus: Architecture',
        messages: [
          InterviewMessage(
            sender: InterviewMessageSender.ai,
            text: 'How do you design a scalable app?',
            createdAt: DateTime.utc(2026, 6, 23, 10),
          ),
          InterviewMessage(
            sender: InterviewMessageSender.user,
            text: 'I separate presentation, domain, and data layers.',
            createdAt: DateTime.utc(2026, 6, 23, 10, 1),
          ),
        ],
        review: InterviewReview(
          id: 'review_1',
          level: InterviewLevel.senior,
          stage: InterviewStage.technical,
          language: InterviewLanguage.english,
          createdAt: DateTime.utc(2026, 6, 23, 10, 21),
          summary: 'Strong architecture baseline.',
          communicationFeedback: 'Clear.',
          technicalFeedback: 'Add trade-offs.',
          improvementAreas: const ['Testing strategy'],
          recommendations: const [
            ReviewRecommendation(
              id: 'recommendation_1',
              title: 'Practice trade-offs',
              description: 'Explain offline-first sync trade-offs.',
              level: InterviewLevel.senior,
              stage: InterviewStage.technical,
              linkedPlanId: 'plan_1',
              linkedScheduleItemIndex: 2,
            ),
          ],
        ),
      );

      final parsed = InterviewSession.fromMap('session_1', session.toMap());

      expect(session.toMap()['level'], 'senior');
      expect(session.toMap()['stage'], 'technical');
      expect(session.toMap()['language'], 'english');
      expect(parsed.id, 'session_1');
      expect(parsed.level, InterviewLevel.senior);
      expect(parsed.stage, InterviewStage.technical);
      expect(parsed.language, InterviewLanguage.english);
      expect(parsed.startedAt, DateTime.utc(2026, 6, 23, 10));
      expect(parsed.endedAt, DateTime.utc(2026, 6, 23, 10, 20));
      expect(parsed.linkedPlanId, 'plan_1');
      expect(parsed.linkedScheduleItemId, 'technical_focus_architecture');
      expect(parsed.preparationFocusTitle, 'Technical Focus: Architecture');
      expect(parsed.messages, hasLength(2));
      expect(parsed.messages.last.sender, InterviewMessageSender.user);
      expect(parsed.review?.id, 'review_1');
      expect(parsed.review?.recommendations.single.linkedScheduleItemIndex, 2);
    });
  });

  group('Saved numeric fields', () {
    test('parse flexible numeric values from AI and database maps', () {
      final recommendation = ReviewRecommendation.fromMap({
        'id': 'recommendation_1',
        'title': 'Testing drill',
        'description': 'Practice test coverage explanation.',
        'level': 'Junior Dev',
        'stage': 'Technical',
        'linkedScheduleItemIndex': '3',
      });
      final scheduleItem = ScheduleItem.fromMap({
        'dayOffset': '4',
        'title': 'Technical Focus: Testing',
        'description': 'Practice testing strategy.',
      });

      expect(recommendation.linkedScheduleItemIndex, 3);
      expect(scheduleItem.dayOffset, 4);
    });
  });
}
