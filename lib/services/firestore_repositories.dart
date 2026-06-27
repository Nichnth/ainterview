import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/interview_enums.dart';
import '../models/interview_plan.dart';
import '../models/interview_session.dart';
import 'interview_plan_repository.dart';
import 'interview_session_repository.dart';

class FirestoreInterviewPlanRepository implements InterviewPlanRepository {
  FirestoreInterviewPlanRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  @override
  Future<List<InterviewPlan>> fetchPlans(String userId) async {
    final snapshot = await _plans(userId).orderBy('targetDate').get();
    return [
      for (final document in snapshot.docs)
        InterviewPlan.fromMap(document.id, _normalizeMap(document.data())),
    ];
  }

  @override
  Future<InterviewPlan> savePlan(String userId, InterviewPlan plan) async {
    final collection = _plans(userId);
    final document =
        plan.id.isEmpty ? collection.doc() : collection.doc(plan.id);
    final savedPlan = plan.id.isEmpty ? plan.copyWith(id: document.id) : plan;
    await document.set(savedPlan.toMap());
    return savedPlan;
  }

  @override
  Future<void> deletePlan(String userId, String planId) {
    return _plans(userId).doc(planId).delete();
  }

  CollectionReference<Map<String, dynamic>> _plans(String userId) {
    return _firestore.collection('users').doc(userId).collection('plans');
  }
}

Map<String, dynamic> _normalizeMap(Map<String, dynamic> map) {
  return {
    for (final entry in map.entries) entry.key: _normalizeValue(entry.value),
  };
}

Object? _normalizeValue(Object? value) {
  if (value is Timestamp) {
    return value.toDate();
  }

  if (value is Map) {
    return {
      for (final entry in value.entries)
        entry.key.toString(): _normalizeValue(entry.value),
    };
  }

  if (value is List) {
    return [for (final item in value) _normalizeValue(item)];
  }

  return value;
}
