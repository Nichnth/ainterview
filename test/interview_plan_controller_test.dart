import 'package:flutter_test/flutter_test.dart';

import 'package:ainterview/models/interview_enums.dart';
import 'package:ainterview/models/review_recommendation.dart';
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

      final completedBeforeUpdate = await controller.toggleScheduleItem(
        created.id,
        itemIndex: 0,
        isCompleted: true,
      );
      expect(completedBeforeUpdate.scheduleItems.first.isCompleted, isTrue);

      final updated = await controller.updatePlan(
        created.id,
        targetDate: DateTime(2026, 6, 1),
        level: InterviewLevel.senior,
        language: InterviewLanguage.english,
      );

      expect(updated.level, InterviewLevel.senior);
      expect(updated.language, InterviewLanguage.english);
      expect(updated.scheduleItems.first.isCompleted, isTrue);
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

    test(
      'appends review recommendations to an active plan with source metadata',
      () async {
        final repository = InMemoryInterviewPlanRepository();
        final controller = InterviewPlanController(
          repository: repository,
          userId: 'user_1',
          today: DateTime(2026, 5, 25),
        );
        final plan = await controller.createPlan(
          targetDate: DateTime(2026, 6, 15),
          level: InterviewLevel.junior,
          language: InterviewLanguage.indonesian,
        );
        final previousLastOffset = plan.scheduleItems.last.dayOffset;

        final updated = await controller.appendReviewRecommendations(
          plan.id,
          reviewId: 'review_1',
          recommendations: const [
            ReviewRecommendation(
              id: 'recommendation_1',
              title: 'State Management Recovery Drill',
              description:
                  'Latih ulang loading, error, retry, dan cache invalidation pada flow API.',
              level: InterviewLevel.junior,
              stage: InterviewStage.technical,
            ),
          ],
        );

        expect(updated.scheduleItems, hasLength(plan.scheduleItems.length + 1));
        expect(
          updated.scheduleItems.last.title,
          'State Management Recovery Drill',
        );
        expect(
          updated.scheduleItems.last.description,
          contains('loading, error, retry'),
        );
        expect(updated.scheduleItems.last.dayOffset, previousLastOffset + 1);
        expect(updated.scheduleItems.last.isCompleted, isFalse);
        expect(updated.scheduleItems.last.sourceReviewId, 'review_1');
        expect(
          updated.scheduleItems.last.sourceRecommendationId,
          'recommendation_1',
        );
      },
    );

    test('selects one plan while keeping schedule updates isolated', () async {
      final repository = InMemoryInterviewPlanRepository();
      final controller = InterviewPlanController(
        repository: repository,
        userId: 'user_1',
        today: DateTime(2026, 5, 25),
      );

      final firstPlan = await controller.createPlan(
        targetDate: DateTime(2026, 6, 15),
        level: InterviewLevel.intern,
        language: InterviewLanguage.indonesian,
      );
      final secondPlan = await controller.createPlan(
        targetDate: DateTime(2026, 6, 20),
        level: InterviewLevel.senior,
        language: InterviewLanguage.english,
      );

      expect(controller.selectedPlanId, secondPlan.id);
      expect(controller.selectedPlan, secondPlan);

      controller.selectPlan(firstPlan.id);
      expect(controller.selectedPlan, firstPlan);

      await controller.toggleScheduleItem(
        secondPlan.id,
        itemIndex: 0,
        isCompleted: true,
      );

      expect(controller.selectedPlanId, firstPlan.id);
      expect(controller.selectedPlan!.scheduleItems.first.isCompleted, isFalse);
      expect(
        controller.plans
            .firstWhere((plan) => plan.id == secondPlan.id)
            .scheduleItems
            .first
            .isCompleted,
        isTrue,
      );
    });

    test('moves selection after deleting the selected plan', () async {
      final repository = InMemoryInterviewPlanRepository();
      final controller = InterviewPlanController(
        repository: repository,
        userId: 'user_1',
        today: DateTime(2026, 5, 25),
      );

      final firstPlan = await controller.createPlan(
        targetDate: DateTime(2026, 6, 15),
        level: InterviewLevel.intern,
        language: InterviewLanguage.indonesian,
      );
      final secondPlan = await controller.createPlan(
        targetDate: DateTime(2026, 6, 20),
        level: InterviewLevel.senior,
        language: InterviewLanguage.english,
      );

      expect(controller.selectedPlanId, secondPlan.id);

      await controller.deletePlan(secondPlan.id);

      expect(controller.plans, hasLength(1));
      expect(controller.selectedPlanId, firstPlan.id);
      expect(controller.selectedPlan, firstPlan);

      await controller.deletePlan(firstPlan.id);

      expect(controller.plans, isEmpty);
      expect(controller.selectedPlanId, isNull);
      expect(controller.selectedPlan, isNull);
    });

    test('uses the current clock when generating each new plan', () async {
      var today = DateTime(2026, 5, 25);
      final repository = InMemoryInterviewPlanRepository();
      final controller = InterviewPlanController(
        repository: repository,
        userId: 'user_1',
        today: () => today,
      );

      final first = await controller.createPlan(
        targetDate: DateTime(2026, 6, 15),
        level: InterviewLevel.junior,
        language: InterviewLanguage.indonesian,
      );
      today = DateTime(2026, 6, 14);
      final second = await controller.createPlan(
        targetDate: DateTime(2026, 6, 15),
        level: InterviewLevel.junior,
        language: InterviewLanguage.indonesian,
      );

      expect(first.scheduleItems.last.dayOffset, greaterThan(1));
      expect(second.scheduleItems.every((item) => item.dayOffset == 1), isTrue);
    });

    test('does not append the same review recommendations twice', () async {
      final repository = InMemoryInterviewPlanRepository();
      final controller = InterviewPlanController(
        repository: repository,
        userId: 'user_1',
        today: DateTime(2026, 5, 25),
      );
      final plan = await controller.createPlan(
        targetDate: DateTime(2026, 6, 15),
        level: InterviewLevel.junior,
        language: InterviewLanguage.indonesian,
      );
      const recommendations = [
        ReviewRecommendation(
          id: 'recommendation_1',
          title: 'Retry drill',
          description: 'Practice retry and failure states.',
          level: InterviewLevel.junior,
          stage: InterviewStage.technical,
        ),
      ];

      await controller.appendReviewRecommendations(
        plan.id,
        reviewId: 'review_1',
        recommendations: recommendations,
      );
      final updatedAgain = await controller.appendReviewRecommendations(
        plan.id,
        reviewId: 'review_1',
        recommendations: recommendations,
      );

      expect(
        updatedAgain.scheduleItems
            .where((item) => item.sourceReviewId == 'review_1')
            .length,
        1,
      );
    });
  });
}
