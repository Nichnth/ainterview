import 'package:flutter/foundation.dart';

import '../models/interview_enums.dart';
import '../models/interview_plan.dart';
import '../models/schedule_item.dart';
import '../services/interview_plan_generator.dart';
import '../services/interview_plan_repository.dart';

class InterviewPlanController extends ChangeNotifier {
  InterviewPlanController({
    required InterviewPlanRepository repository,
    required String userId,
    DateTime? today,
  }) : _repository = repository,
       _userId = userId,
       _today = today ?? DateTime.now();

  final InterviewPlanRepository _repository;
  final String _userId;
  final DateTime _today;

  List<InterviewPlan> _plans = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<InterviewPlan> get plans => List.unmodifiable(_plans);

  bool get isLoading => _isLoading;

  String? get errorMessage => _errorMessage;

  Future<void> loadPlans() async {
    _setLoading(true);
    try {
      _plans = await _repository.fetchPlans(_userId);
      _errorMessage = null;
    } catch (error) {
      _errorMessage = error.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<InterviewPlan> createPlan({
    required DateTime targetDate,
    required InterviewLevel level,
    required InterviewLanguage language,
  }) async {
    final plan = InterviewPlan(
      id: '',
      targetDate: targetDate,
      level: level,
      language: language,
      createdAt: DateTime.now().toUtc(),
      scheduleItems: InterviewPlanGenerator.generate(
        today: _today,
        targetDate: targetDate,
        level: level,
        language: language,
      ),
    );

    final savedPlan = await _repository.savePlan(_userId, plan);
    _upsertPlan(savedPlan);
    return savedPlan;
  }

  Future<InterviewPlan> updatePlan(
    String planId, {
    required DateTime targetDate,
    required InterviewLevel level,
    required InterviewLanguage language,
  }) async {
    final currentPlan = _findPlan(planId);
    final updatedPlan = currentPlan.copyWith(
      targetDate: targetDate,
      level: level,
      language: language,
      scheduleItems: InterviewPlanGenerator.generate(
        today: _today,
        targetDate: targetDate,
        level: level,
        language: language,
      ),
    );

    final savedPlan = await _repository.savePlan(_userId, updatedPlan);
    _upsertPlan(savedPlan);
    return savedPlan;
  }

  Future<InterviewPlan> toggleScheduleItem(
    String planId, {
    required int itemIndex,
    required bool isCompleted,
  }) async {
    final currentPlan = _findPlan(planId);
    if (itemIndex < 0 || itemIndex >= currentPlan.scheduleItems.length) {
      throw RangeError.index(itemIndex, currentPlan.scheduleItems, 'itemIndex');
    }

    final updatedItems = <ScheduleItem>[
      for (var index = 0; index < currentPlan.scheduleItems.length; index++)
        index == itemIndex
            ? currentPlan.scheduleItems[index].copyWith(
                isCompleted: isCompleted,
              )
            : currentPlan.scheduleItems[index],
    ];

    final savedPlan = await _repository.savePlan(
      _userId,
      currentPlan.copyWith(scheduleItems: updatedItems),
    );
    _upsertPlan(savedPlan);
    return savedPlan;
  }

  Future<void> deletePlan(String planId) async {
    await _repository.deletePlan(_userId, planId);
    _plans = _plans.where((plan) => plan.id != planId).toList();
    notifyListeners();
  }

  InterviewPlan _findPlan(String planId) {
    return _plans.firstWhere(
      (plan) => plan.id == planId,
      orElse: () => throw StateError('Interview plan not found: $planId'),
    );
  }

  void _upsertPlan(InterviewPlan plan) {
    final index = _plans.indexWhere((existing) => existing.id == plan.id);

    if (index == -1) {
      _plans = [..._plans, plan];
    } else {
      _plans = [
        for (var currentIndex = 0; currentIndex < _plans.length; currentIndex++)
          currentIndex == index ? plan : _plans[currentIndex],
      ];
    }

    _plans.sort(
      (first, second) => first.targetDate.compareTo(second.targetDate),
    );
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
