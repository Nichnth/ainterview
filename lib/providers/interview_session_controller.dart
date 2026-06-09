import 'package:flutter/foundation.dart';

import '../models/interview_enums.dart';
import '../models/interview_message.dart';
import '../models/interview_preparation_context.dart';
import '../models/interview_review.dart';
import '../models/interview_session.dart';
import '../services/ai_interview_service.dart';
import '../services/interview_session_repository.dart';

class InterviewSessionController extends ChangeNotifier {
  InterviewSessionController({
    required AiInterviewService aiService,
    InterviewSessionRepository? sessionRepository,
    String userId = 'demo_user',
    DateTime Function()? now,
  }) : _aiService = aiService,
       _sessionRepository = sessionRepository,
       _userId = userId,
       _now = now ?? DateTime.now;

  final AiInterviewService _aiService;
  final InterviewSessionRepository? _sessionRepository;
  final String _userId;
  final DateTime Function() _now;

  final List<InterviewMessage> _messages = [];
  InterviewLevel? _level;
  InterviewStage? _stage;
  InterviewLanguage? _language;
  DateTime? _startedAt;
  String? _linkedPlanId;
  String? _linkedScheduleItemId;
  String? _preparationFocusTitle;
  InterviewPreparationContext? _preparationContext;
  InterviewSession? _currentSession;
  InterviewReview? _review;
  String? _errorMessage;
  bool _isBusy = false;
  bool _isEnded = false;

  List<InterviewMessage> get messages => List.unmodifiable(_messages);

  InterviewLevel? get level => _level;

  InterviewStage? get stage => _stage;

  InterviewLanguage? get language => _language;

  InterviewReview? get review => _review;

  InterviewSession? get currentSession => _currentSession;

  String? get errorMessage => _errorMessage;

  bool get isBusy => _isBusy;

  bool get isEnded => _isEnded;

  Future<void> start({
    required InterviewLevel level,
    required InterviewStage stage,
    required InterviewLanguage language,
    String? linkedPlanId,
    String? linkedScheduleItemId,
    InterviewPreparationContext? preparationContext,
  }) async {
    _level = level;
    _stage = stage;
    _language = language;
    _startedAt = _now().toUtc();
    _linkedPlanId = linkedPlanId;
    _linkedScheduleItemId = linkedScheduleItemId;
    _preparationFocusTitle = preparationContext?.primaryFocusTitle;
    _preparationContext = preparationContext;
    _currentSession = InterviewSession(
      id: '',
      level: level,
      stage: stage,
      language: language,
      startedAt: _startedAt!,
      linkedPlanId: linkedPlanId,
      linkedScheduleItemId: linkedScheduleItemId,
      preparationFocusTitle: _preparationFocusTitle,
      messages: const [],
    );
    _review = null;
    _errorMessage = null;
    _isEnded = false;
    _messages.clear();
    _setBusy(true);

    try {
      final openingQuestion = await _aiService.startInterview(
        level: level,
        stage: stage,
        language: language,
        preparationContext: preparationContext,
      );
      _messages.add(
        InterviewMessage(
          sender: InterviewMessageSender.ai,
          text: openingQuestion,
          createdAt: _now().toUtc(),
        ),
      );
      _refreshCurrentSession();
    } catch (error) {
      _errorMessage = _messageFromError(error);
      _currentSession = null;
      notifyListeners();
    } finally {
      _setBusy(false);
    }
  }

  Future<void> sendUserAnswer(String answer) {
    _ensureActiveSession();
    return _sendUserAnswer(answer);
  }

  Future<InterviewReview> endAndReview() async {
    _ensureStarted();
    _errorMessage = null;
    _setBusy(true);

    try {
      final generatedReview = await _aiService.reviewInterview(
        level: _level!,
        stage: _stage!,
        language: _language!,
        messages: messages,
        preparationContext: _preparationContext,
      );
      _review = generatedReview;
      _isEnded = true;
      await _saveEndedSession(generatedReview);
      notifyListeners();
      return generatedReview;
    } catch (error) {
      _errorMessage = _messageFromError(error);
      notifyListeners();
      rethrow;
    } finally {
      _setBusy(false);
    }
  }

  Future<void> _sendUserAnswer(String answer) async {
    final trimmedAnswer = answer.trim();
    if (trimmedAnswer.isEmpty) {
      return;
    }

    _messages.add(
      InterviewMessage(
        sender: InterviewMessageSender.user,
        text: trimmedAnswer,
        createdAt: _now().toUtc(),
      ),
    );

    _errorMessage = null;
    final redirectMessage = _redirectMessageForAnswer(trimmedAnswer);
    if (redirectMessage != null) {
      _messages.add(
        InterviewMessage(
          sender: InterviewMessageSender.ai,
          text: redirectMessage,
          createdAt: _now().toUtc(),
        ),
      );
      _refreshCurrentSession();
      notifyListeners();
      return;
    }

    _setBusy(true);

    try {
      final response = await _aiService.sendMessage(
        level: _level!,
        stage: _stage!,
        language: _language!,
        messages: messages,
        preparationContext: _preparationContext,
      );
      _messages.add(
        InterviewMessage(
          sender: InterviewMessageSender.ai,
          text: response,
          createdAt: _now().toUtc(),
        ),
      );
      _refreshCurrentSession();
    } catch (error) {
      _errorMessage = _messageFromError(error);
      notifyListeners();
    } finally {
      _setBusy(false);
    }
  }

  Future<void> _saveEndedSession(InterviewReview review) async {
    final session = InterviewSession(
      id: _currentSession?.id ?? '',
      level: _level!,
      stage: _stage!,
      language: _language!,
      startedAt: _startedAt ?? _now().toUtc(),
      endedAt: _now().toUtc(),
      linkedPlanId: _linkedPlanId,
      linkedScheduleItemId: _linkedScheduleItemId,
      preparationFocusTitle: _preparationFocusTitle,
      messages: messages,
      review: review,
    );

    _currentSession = _sessionRepository == null
        ? session
        : await _sessionRepository.saveSession(_userId, session);
  }

  void _refreshCurrentSession() {
    if (_level == null || _stage == null || _language == null) {
      return;
    }

    final session =
        _currentSession ??
        InterviewSession(
          id: '',
          level: _level!,
          stage: _stage!,
          language: _language!,
          startedAt: _startedAt ?? _now().toUtc(),
          linkedPlanId: _linkedPlanId,
          linkedScheduleItemId: _linkedScheduleItemId,
          preparationFocusTitle: _preparationFocusTitle,
          messages: const [],
        );
    _currentSession = session.copyWith(messages: messages);
  }

  void _ensureStarted() {
    if (_level == null || _stage == null || _language == null) {
      throw StateError('Interview session has not started.');
    }
  }

  void _ensureActiveSession() {
    _ensureStarted();
    if (_isEnded) {
      throw StateError('Interview session has already ended.');
    }
  }

  void _setBusy(bool value) {
    _isBusy = value;
    notifyListeners();
  }

  String? _redirectMessageForAnswer(String answer) {
    if (_isRelevantAnswer(answer)) {
      return null;
    }

    final title = '${_level!.label} ${_stage!.label}';
    if (_language == InterviewLanguage.indonesian) {
      return 'Jawabanmu belum sesuai konteks $title. Tolong jawab pertanyaan interview dengan contoh pengalaman, keputusan teknis, atau pembelajaran yang relevan.';
    }

    return 'Your answer is not yet aligned with the $title interview context. Please answer with relevant experience, technical decisions, or learning evidence.';
  }

  bool _isRelevantAnswer(String answer) {
    final normalized = answer.toLowerCase().trim();
    final letterMatches = RegExp(r'[a-zA-Z]').allMatches(normalized).length;
    final words = RegExp(r'[a-zA-Z]{2,}').allMatches(normalized).length;

    if (letterMatches < 12 || words < 3) {
      return false;
    }

    if (RegExp(r'\b(asdf|qwer|zzzz|lorem|ipsum|test)\b').hasMatch(normalized)) {
      return false;
    }

    final uniqueLetters = normalized
        .replaceAll(RegExp(r'[^a-zA-Z]'), '')
        .split('')
        .toSet()
        .length;
    if (uniqueLetters < 5) {
      return false;
    }

    const unrelatedTerms = [
      'makan',
      'pizza',
      'musik',
      'lagu',
      'film',
      'liburan',
      'cuaca',
      'shopping',
    ];
    const interviewTerms = [
      'flutter',
      'dart',
      'mobile',
      'project',
      'proyek',
      'api',
      'team',
      'tim',
      'user',
      'debug',
      'state',
      'architecture',
      'arsitektur',
      'database',
      'testing',
      'deadline',
      'feedback',
      'pengalaman',
      'belajar',
      'problem',
      'solusi',
      'challenge',
      'tantangan',
    ];

    final hasUnrelatedTerm = unrelatedTerms.any(normalized.contains);
    final hasInterviewTerm = interviewTerms.any(normalized.contains);
    return !hasUnrelatedTerm || hasInterviewTerm;
  }

  String _messageFromError(Object error) {
    final rawMessage = error.toString();
    return rawMessage.replaceFirst(RegExp(r'^(Exception|StateError):\s*'), '');
  }
}
