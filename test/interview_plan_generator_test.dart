import 'package:flutter_test/flutter_test.dart';

import 'package:ainterview/models/interview_enums.dart';
import 'package:ainterview/models/interview_preparation_context.dart';
import 'package:ainterview/models/interview_plan.dart';
import 'package:ainterview/models/schedule_item.dart';
import 'package:ainterview/services/interview_plan_generator.dart';

void main() {
  group('InterviewPlan', () {
    test('serializes and deserializes a Firestore-compatible map', () {
      final createdAt = DateTime.utc(2026, 5, 25, 15, 45);
      final targetDate = DateTime.utc(2026, 6, 15, 9);
      final plan = InterviewPlan(
        id: 'plan_1',
        targetDate: targetDate,
        level: InterviewLevel.junior,
        language: InterviewLanguage.indonesian,
        createdAt: createdAt,
        scheduleItems: const [
          ScheduleItem(
            id: 'hr_mock_interview',
            dayOffset: 1,
            title: 'HR Mock Interview',
            description: 'Practice behavioral questions.',
            suggestedStage: InterviewStage.hr,
          ),
        ],
      );

      final map = plan.toMap();

      expect(map['targetDate'], targetDate.toIso8601String());
      expect(map['level'], 'Junior Dev');
      expect(map['language'], 'Indonesian');
      expect(map['createdAt'], createdAt.toIso8601String());
      expect(map['scheduleItems'], isA<List<Map<String, Object?>>>());

      final parsed = InterviewPlan.fromMap('plan_1', map);

      expect(parsed.id, 'plan_1');
      expect(parsed.targetDate, targetDate);
      expect(parsed.level, InterviewLevel.junior);
      expect(parsed.language, InterviewLanguage.indonesian);
      expect(parsed.createdAt, createdAt);
      expect(parsed.scheduleItems.single.id, 'hr_mock_interview');
      expect(parsed.scheduleItems.single.title, 'HR Mock Interview');
      expect(parsed.scheduleItems.single.suggestedStage, InterviewStage.hr);
    });

    test('deserializes legacy schedule items with stable ids', () {
      final plan = InterviewPlan.fromMap('plan_legacy', {
        'targetDate': '2026-06-15T09:00:00.000Z',
        'level': 'Junior Dev',
        'language': 'Indonesian',
        'createdAt': '2026-05-25T15:45:00.000Z',
        'scheduleItems': [
          {
            'dayOffset': 3,
            'title': 'Technical Focus: State Management',
            'description': 'Practice Provider and BLoC.',
            'isCompleted': false,
          },
        ],
      });

      expect(plan.scheduleItems.single.id, 'technical_focus_state_management');
      expect(plan.scheduleItems.single.suggestedStage, isNull);
    });
  });

  group('InterviewPlanGenerator', () {
    test(
      'generates a Junior Indonesian schedule with HR and technical topics',
      () {
        final items = InterviewPlanGenerator.generate(
          today: DateTime(2026, 5, 25),
          targetDate: DateTime(2026, 6, 15),
          level: InterviewLevel.junior,
          language: InterviewLanguage.indonesian,
        );

        expect(items.length, greaterThanOrEqualTo(6));
        final offsets = items.map((item) => item.dayOffset).toList();
        expect(offsets, orderedEquals([...offsets]..sort()));
        expect(items.every((item) => item.dayOffset >= 1), isTrue);
        expect(items.every((item) => item.dayOffset <= 21), isTrue);
        expect(items.any((item) => item.title.contains('HR')), isTrue);
        expect(items.every((item) => item.id.isNotEmpty), isTrue);
        expect(items.first.suggestedStage, InterviewStage.hr);
        expect(
          items
              .firstWhere((item) => item.title.contains('State Management'))
              .suggestedStage,
          InterviewStage.technical,
        );
        expect(
          items.any((item) => item.title.contains('State Management')),
          isTrue,
        );
        expect(
          items.any((item) => item.description.contains('Latihan')),
          isTrue,
        );
      },
    );

    test('keeps Senior English short timelines within available days', () {
      final items = InterviewPlanGenerator.generate(
        today: DateTime(2026, 5, 25),
        targetDate: DateTime(2026, 5, 28),
        level: InterviewLevel.senior,
        language: InterviewLanguage.english,
      );

      expect(items, isNotEmpty);
      expect(items.every((item) => item.dayOffset >= 1), isTrue);
      expect(items.every((item) => item.dayOffset <= 3), isTrue);
      expect(
        items.any(
          (item) =>
              item.title.contains('Architecture') ||
              item.title.contains('System Design'),
        ),
        isTrue,
      );
    });

    test('builds preparation context for a selected schedule item', () {
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

      expect(context.selectedScheduleItemId, focusItem.id);
      expect(context.selectedTopic?.title, focusItem.title);
      expect(context.primaryFocusTitle, focusItem.title);
      expect(context.suggestedStage, InterviewStage.technical);
      expect(
        context.promptSummary(InterviewLanguage.indonesian),
        contains(focusItem.title),
      );
    });
  });
}
