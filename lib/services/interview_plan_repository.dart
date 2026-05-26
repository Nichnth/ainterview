import '../models/interview_plan.dart';

abstract class InterviewPlanRepository {
  Future<List<InterviewPlan>> fetchPlans(String userId);

  Future<InterviewPlan> savePlan(String userId, InterviewPlan plan);

  Future<void> deletePlan(String userId, String planId);
}

class InMemoryInterviewPlanRepository implements InterviewPlanRepository {
  final Map<String, List<InterviewPlan>> _plansByUser = {};
  int _nextId = 1;

  @override
  Future<List<InterviewPlan>> fetchPlans(String userId) async {
    final plans = [...?_plansByUser[userId]]
      ..sort((first, second) => first.targetDate.compareTo(second.targetDate));
    return List.unmodifiable(plans);
  }

  @override
  Future<InterviewPlan> savePlan(String userId, InterviewPlan plan) async {
    final plans = _plansByUser.putIfAbsent(userId, () => []);
    final savedPlan = plan.id.isEmpty
        ? plan.copyWith(id: 'plan_${_nextId++}')
        : plan;
    final index = plans.indexWhere((existing) => existing.id == savedPlan.id);

    if (index == -1) {
      plans.add(savedPlan);
    } else {
      plans[index] = savedPlan;
    }

    return savedPlan;
  }

  @override
  Future<void> deletePlan(String userId, String planId) async {
    _plansByUser[userId]?.removeWhere((plan) => plan.id == planId);
  }
}
