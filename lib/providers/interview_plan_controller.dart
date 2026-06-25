import 'package:flutter/foundation.dart';

import '../models/interview_enums.dart';
import '../models/interview_plan.dart';
import '../models/review_recommendation.dart';
import '../models/schedule_item.dart';
import '../services/interview_plan_generator.dart';
import '../services/interview_plan_repository.dart';

class InterviewPlanController extends ChangeNotifier {
  InterviewPlanController({
    required InterviewPlanRepository repository,
    required String userId,
    Object? today,
  }) : _repository = repository,
       _userId = userId,
       _today = _clockFromValue(today);

  final InterviewPlanRepository _repository;
  final String _userId;
  final DateTime Function() _today;

  List<InterviewPlan> _plans = [];
  bool _isLoading = false;
  String? _errorMessage;
  String? _selectedPlanId;

  List<InterviewPlan> get plans => List.unmodifiable(_plans);

  InterviewPlan? get activePlan => selectedPlan;

  String? get selectedPlanId => _selectedPlanId;

  InterviewPlan? get selectedPlan {
    final selectedId = _selectedPlanId;
    if (selectedId == null) {
      return _plans.isEmpty ? null : _plans.first;
    }

    for (final plan in _plans) {
      if (plan.id == selectedId) {
        return plan;
      }
    }

    return _plans.isEmpty ? null : _plans.first;
  }

  bool get isLoading => _isLoading;

  String? get errorMessage => _errorMessage;

  Future<void> loadPlans() async {
    _setLoading(true);
    try {
      _plans = await _repository.fetchPlans(_userId);
      _syncSelectedPlan();
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
    return _runMutation(() async {
      final plan = InterviewPlan(
        id: '',
        targetDate: targetDate,
        level: level,
        language: language,
        createdAt: DateTime.now().toUtc(),
        scheduleItems: InterviewPlanGenerator.generate(
          today: _today(),
          targetDate: targetDate,
          level: level,
          language: language,
        ),
      );

      final savedPlan = await _repository.savePlan(_userId, plan);
      _upsertPlan(savedPlan);
      _selectedPlanId = savedPlan.id;
      notifyListeners();
      return savedPlan;
    });
  }

  Future<InterviewPlan> updatePlan(
    String planId, {
    required DateTime targetDate,
    required InterviewLevel level,
    required InterviewLanguage language,
  }) async {
    return _runMutation(() async {
      final currentPlan = _findPlan(planId);
      final generatedItems = InterviewPlanGenerator.generate(
        today: _today(),
        targetDate: targetDate,
        level: level,
        language: language,
      );
      final previousItemsById = {
        for (final item in currentPlan.scheduleItems) item.id: item,
      };
      final updatedItems = [
        for (final item in generatedItems)
          item.copyWith(isCompleted: previousItemsById[item.id]?.isCompleted),
        for (final item in currentPlan.scheduleItems)
          if (item.sourceReviewId != null ||
              item.sourceRecommendationId != null)
            item,
      ];
      final updatedPlan = currentPlan.copyWith(
        targetDate: targetDate,
        level: level,
        language: language,
        scheduleItems: updatedItems,
      );

      final savedPlan = await _repository.savePlan(_userId, updatedPlan);
      _upsertPlan(savedPlan);
      return savedPlan;
    });
  }

  void selectPlan(String planId) {
    _findPlan(planId);
    _selectedPlanId = planId;
    notifyListeners();
  }

  Future<InterviewPlan> toggleScheduleItem(
    String planId, {
    required int itemIndex,
    required bool isCompleted,
  }) async {
    return _runMutation(() async {
      final currentPlan = _findPlan(planId);
      if (itemIndex < 0 || itemIndex >= currentPlan.scheduleItems.length) {
        throw RangeError.index(
          itemIndex,
          currentPlan.scheduleItems,
          'itemIndex',
        );
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
    });
  }

  Future<InterviewPlan> appendReviewRecommendations(
    String planId, {
    required String reviewId,
    required List<ReviewRecommendation> recommendations,
  }) async {
    return _runMutation(() async {
      final currentPlan = _findPlan(planId);
      if (recommendations.isEmpty) {
        return currentPlan;
      }

      final lastDayOffset = currentPlan.scheduleItems.isEmpty
          ? 0
          : currentPlan.scheduleItems
                .map((item) => item.dayOffset)
                .reduce((first, second) => first > second ? first : second);
      final existingRecommendationKeys = currentPlan.scheduleItems
          .map(
            (item) => '${item.sourceReviewId}:${item.sourceRecommendationId}',
          )
          .toSet();
      final recommendationItems = <ScheduleItem>[];
      final seenRecommendationKeys = {...existingRecommendationKeys};
      for (final recommendation in recommendations) {
        final key = '$reviewId:${recommendation.id}';
        if (!seenRecommendationKeys.add(key)) {
          continue;
        }

        recommendationItems.add(
          ScheduleItem(
            id: 'review_${reviewId}_${recommendation.id}',
            dayOffset: lastDayOffset + recommendationItems.length + 1,
            title: recommendation.title,
            description: recommendation.description,
            suggestedStage: recommendation.stage,
            sourceReviewId: reviewId,
            sourceRecommendationId: recommendation.id,
          ),
        );
      }
      if (recommendationItems.isEmpty) {
        return currentPlan;
      }

      final savedPlan = await _repository.savePlan(
        _userId,
        currentPlan.copyWith(
          scheduleItems: [...currentPlan.scheduleItems, ...recommendationItems],
        ),
      );
      _upsertPlan(savedPlan);
      return savedPlan;
    });
  }

  Future<void> deletePlan(String planId) async {
    await _runMutation(() async {
      await _repository.deletePlan(_userId, planId);
      _plans = _plans.where((plan) => plan.id != planId).toList();
      if (_selectedPlanId == planId) {
        _selectedPlanId = _plans.isEmpty ? null : _plans.first.id;
      } else {
        _syncSelectedPlan();
      }
      notifyListeners();
    });
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
    _syncSelectedPlan();
    notifyListeners();
  }

  void _syncSelectedPlan() {
    if (_plans.isEmpty) {
      _selectedPlanId = null;
      return;
    }

    final selectedId = _selectedPlanId;
    final hasSelection =
        selectedId != null && _plans.any((plan) => plan.id == selectedId);
    if (!hasSelection) {
      _selectedPlanId = _plans.first.id;
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  Future<T> _runMutation<T>(Future<T> Function() mutation) async {
    _setLoading(true);
    try {
      final result = await mutation();
      _errorMessage = null;
      return result;
    } catch (error) {
      _errorMessage = error.toString();
      notifyListeners();
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  static DateTime Function() _clockFromValue(Object? today) {
    if (today is DateTime Function()) {
      return today;
    }

    if (today is DateTime) {
      return () => today;
    }

    return DateTime.now;
  }
}
