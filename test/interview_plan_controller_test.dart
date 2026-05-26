import 'package:flutter_test/flutter_test.dart';

import 'package:ainterview/models/interview_enums.dart';
import 'package:ainterview/providers/interview_plan_controller.dart';
import 'package:ainterview/services/interview_plan_repository.dart';

void main() {
  group('InterviewPlanController', () {
    test('creates, updates, completes, and deletes a plan', () async {
      final repository = InMemoryInterviewPlanRepository();
      final controller = InterviewPlanController(
        repository: repository,
        userId: 'user_1',
        today: DateTime(2026, 5, 25),
      );

      await controller.loadPlans();
      expect(controller.plans, isEmpty);

      final created = await controller.createPlan(
        targetDate: DateTime(2026, 6, 15),
        level: InterviewLevel.junior,
        language: InterviewLanguage.indonesian,
      );

      expect(controller.plans, hasLength(1));
      expect(created.id, isNotEmpty);
      expect(created.scheduleItems, isNotEmpty);
      expect(
        created.scheduleItems.any(
          (item) => item.title.contains('State Management'),
        ),
        isTrue,
      );

      final updated = await controller.updatePlan(
        created.id,
        targetDate: DateTime(2026, 6, 1),
        level: InterviewLevel.senior,
        language: InterviewLanguage.english,
      );

      expect(updated.level, InterviewLevel.senior);
      expect(updated.language, InterviewLanguage.english);
      expect(updated.scheduleItems.every((item) => !item.isCompleted), isTrue);
      expect(
        updated.scheduleItems.any(
          (item) => item.title.contains('Architecture'),
        ),
        isTrue,
      );

      final completed = await controller.toggleScheduleItem(
        updated.id,
        itemIndex: 0,
        isCompleted: true,
      );

      expect(completed.scheduleItems.first.isCompleted, isTrue);
      expect(controller.plans.single.progress, greaterThan(0));

      await controller.deletePlan(updated.id);

      expect(controller.plans, isEmpty);
    });

    test('keeps plans isolated by user id', () async {
      final repository = InMemoryInterviewPlanRepository();
      final userOne = InterviewPlanController(
        repository: repository,
        userId: 'user_1',
        today: DateTime(2026, 5, 25),
      );
      final userTwo = InterviewPlanController(
        repository: repository,
        userId: 'user_2',
        today: DateTime(2026, 5, 25),
      );

      await userOne.createPlan(
        targetDate: DateTime(2026, 6, 15),
        level: InterviewLevel.intern,
        language: InterviewLanguage.indonesian,
      );
      await userTwo.loadPlans();

      expect(userOne.plans, hasLength(1));
      expect(userTwo.plans, isEmpty);
    });
  });
}
