import '../models/interview_enums.dart';
import '../models/interview_session.dart';

abstract class InterviewSessionRepository {
  Future<InterviewSession> saveSession(String userId, InterviewSession session);

  Future<List<InterviewSession>> fetchSessions(
    String userId, {
    InterviewLevel? level,
    InterviewStage? stage,
    bool completedOnly = false,
    int? limit,
  });
}

class InMemoryInterviewSessionRepository implements InterviewSessionRepository {
  final Map<String, List<InterviewSession>> _sessionsByUser = {};
  int _nextId = 1;

  @override
  Future<InterviewSession> saveSession(
    String userId,
    InterviewSession session,
  ) async {
    final sessions = _sessionsByUser.putIfAbsent(userId, () => []);
    final savedSession = session.id.isEmpty
        ? session.copyWith(id: 'session_${_nextId++}')
        : session;
    final index = sessions.indexWhere(
      (existing) => existing.id == savedSession.id,
    );

    if (index == -1) {
      sessions.add(savedSession);
    } else {
      sessions[index] = savedSession;
    }

    return savedSession;
  }

  @override
  Future<List<InterviewSession>> fetchSessions(
    String userId, {
    InterviewLevel? level,
    InterviewStage? stage,
    bool completedOnly = false,
    int? limit,
  }) async {
    final sessions = [...?_sessionsByUser[userId]];
    final filteredSessions =
        sessions.where((session) {
          final matchesLevel = level == null || session.level == level;
          final matchesStage = stage == null || session.stage == stage;
          final matchesCompletion = !completedOnly || session.endedAt != null;
          return matchesLevel && matchesStage && matchesCompletion;
        }).toList()..sort((first, second) {
          final firstSortDate = first.endedAt ?? first.startedAt;
          final secondSortDate = second.endedAt ?? second.startedAt;
          return secondSortDate.compareTo(firstSortDate);
        });

    final boundedSessions = limit == null
        ? filteredSessions
        : filteredSessions.take(limit).toList();
    return List.unmodifiable(boundedSessions);
  }

}
