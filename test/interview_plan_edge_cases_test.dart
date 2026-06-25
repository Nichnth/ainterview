import 'package:flutter_test/flutter_test.dart';

import 'package:ainterview/models/interview_enums.dart';
import 'package:ainterview/models/interview_plan.dart';
import 'package:ainterview/models/review_recommendation.dart';
import 'package:ainterview/providers/interview_plan_controller.dart';
import 'package:ainterview/services/interview_plan_repository.dart';

void main() {
  group('InterviewPlanController edge cases', () {
    test(
      'keeps local schedule state unchanged when toggle persistence fails',
      () async {
        final repository = _SwitchablePlanRepository();
        final controller = InterviewPlanController(
          repository: repository,
          userId: 'user_1',
          today: DateTime(2026, 6, 25),
        );
        final plan = await controller.createPlan(
          targetDate: DateTime(2026, 7, 10),
          level: InterviewLevel.junior,
          language: InterviewLanguage.indonesian,
        );

        repository.failSaves = true;

        await expectLater(
          controller.toggleScheduleItem(
            plan.id,
            itemIndex: 0,
            isCompleted: true,
          ),
          throwsException,
        );

        expect(
          controller.plans.single.scheduleItems.first.isCompleted,
          isFalse,
        );
        expect(controller.errorMessage, contains('save failed'));
        expect(controller.isLoading, isFalse);
      },
    );

    test(
      'preserves appended review recommendations when plan settings are updated',
      () async {
        final repository = InMemoryInterviewPlanRepository();
        final controller = InterviewPlanController(
          repository: repository,
          userId: 'user_1',
          today: DateTime(2026, 6, 25),
        );
        final plan = await controller.createPlan(
          targetDate: DateTime(2026, 7, 10),
          level: InterviewLevel.junior,
          language: InterviewLanguage.indonesian,
        );
        await controller.appendReviewRecommendations(
          plan.id,
          reviewId: 'review_1',
          recommendations: const [
            ReviewRecommendation(
              id: 'recommendation_1',
              title: 'Review Follow-up: Retry Drill',
              description: 'Practice loading, error, retry, and cache states.',
              level: InterviewLevel.junior,
              stage: InterviewStage.technical,
            ),
          ],
        );

        final updated = await controller.updatePlan(
          plan.id,
          targetDate: DateTime(2026, 7, 20),
          level: InterviewLevel.senior,
          language: InterviewLanguage.english,
        );

        expect(
          updated.scheduleItems.map((item) => item.title),
          contains('Review Follow-up: Retry Drill'),
        );
      },
    );

    test(
      'does not add duplicate review items when duplicate recommendation ids arrive in one batch',
      () async {
        final repository = InMemoryInterviewPlanRepository();
        final controller = InterviewPlanController(
          repository: repository,
          userId: 'user_1',
          today: DateTime(2026, 6, 25),
        );
        final plan = await controller.createPlan(
          targetDate: DateTime(2026, 7, 10),
          level: InterviewLevel.junior,
          language: InterviewLanguage.english,
        );

        final updated = await controller.appendReviewRecommendations(
          plan.id,
          reviewId: 'review_1',
          recommendations: const [
            ReviewRecommendation(
              id: 'same_id',
              title: 'Retry Drill',
              description: 'Practice retry behavior.',
              level: InterviewLevel.junior,
              stage: InterviewStage.technical,
            ),
            ReviewRecommendation(
              id: 'same_id',
              title: 'Retry Drill',
              description: 'Practice retry behavior.',
              level: InterviewLevel.junior,
              stage: InterviewStage.technical,
            ),
          ],
        );

        expect(
          updated.scheduleItems.where(
            (item) => item.sourceRecommendationId == 'same_id',
          ),
          hasLength(1),
        );
      },
    );
  });
}

class _SwitchablePlanRepository implements InterviewPlanRepository {
  final InMemoryInterviewPlanRepository _inner =
      InMemoryInterviewPlanRepository();
  bool failSaves = false;
  bool failDeletes = false;
  bool failFetches = false;

  @override
  Future<List<InterviewPlan>> fetchPlans(String userId) {
    if (failFetches) {
      throw Exception('fetch failed');
    }

    return _inner.fetchPlans(userId);
  }

  @override
  Future<InterviewPlan> savePlan(String userId, InterviewPlan plan) {
    if (failSaves) {
      throw Exception('save failed');
    }

    return _inner.savePlan(userId, plan);
  }

  @override
  Future<void> deletePlan(String userId, String planId) {
    if (failDeletes) {
      throw Exception('delete failed');
    }

    return _inner.deletePlan(userId, planId);
  }
}
