import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/interview_enums.dart';
import '../models/interview_session.dart';
import 'interview_session_repository.dart';

class FirestoreInterviewSessionRepository
    implements InterviewSessionRepository {
  FirebaseFirestore? get _firestoreInstance {
    try {
      return FirebaseFirestore.instance;
    } catch (_) {
      return null;
    }
  }

  CollectionReference _sessionsRef(String userId) {
    final firestore = _firestoreInstance;
    if (firestore == null) {
      throw StateError('Firestore is not initialized');
    }
    return firestore.collection('users').doc(userId).collection('sessions');
  }

  @override
  Future<InterviewSession> saveSession(
      String userId, InterviewSession session) async {
    if (userId.isEmpty) {
      return session;
    }
    final docRef = session.id.isEmpty
        ? _sessionsRef(userId).doc()
        : _sessionsRef(userId).doc(session.id);

    final sessionToSave =
        session.id.isEmpty ? session.copyWith(id: docRef.id) : session;

    // Pastikan menggunakan SetOptions dari package cloud_firestore
    await docRef.set(sessionToSave.toMap(), SetOptions(merge: true));
    return sessionToSave;
  }

  @override
  Future<List<InterviewSession>> fetchSessions(
    String userId, {
    InterviewLevel? level,
    InterviewStage? stage,
  }) async {
    if (userId.isEmpty) {
      return [];
    }
    Query query = _sessionsRef(userId).orderBy('startedAt', descending: true);

    if (level != null) {
      query = query.where('level', isEqualTo: level.label);
    }
    if (stage != null) {
      query = query.where('stage', isEqualTo: stage.label);
    }

    final snapshot = await query.get();
    return snapshot.docs.map((doc) {
      return InterviewSession.fromMap(
          doc.data() as Map<String, dynamic>, doc.id);
    }).toList();
  }

  Future<void> deleteSession(String userId, String sessionId) async {
    if (userId.isEmpty) return;
    await _sessionsRef(userId).doc(sessionId).delete();
  }

  Future<void> toggleFavorite(
      String userId, String sessionId, bool isFavorite) async {
    if (userId.isEmpty) return;
    await _sessionsRef(userId)
        .doc(sessionId)
        .update({'isFavorite': isFavorite});
  }

  Stream<List<InterviewSession>> watchSessions(String userId) {
    if (userId.isEmpty) {
      return Stream.value(<InterviewSession>[]);
    }
    return _sessionsRef(userId)
        .orderBy('startedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => InterviewSession.fromMap(
                doc.data() as Map<String, dynamic>, doc.id))
            .toList());
  }
}
