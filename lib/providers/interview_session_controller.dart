import 'package:flutter/foundation.dart';

import '../models/interview_enums.dart';
import '../models/interview_message.dart';
import '../models/interview_review.dart';
import '../services/ai_interview_service.dart';

class InterviewSessionController extends ChangeNotifier {
  InterviewSessionController({required AiInterviewService aiService})
    : _aiService = aiService;

  final AiInterviewService _aiService;

  final List<InterviewMessage> _messages = [];
  InterviewLevel? _level;
  InterviewStage? _stage;
  InterviewLanguage? _language;
  InterviewReview? _review;
  bool _isBusy = false;
  bool _isEnded = false;

  List<InterviewMessage> get messages => List.unmodifiable(_messages);

  InterviewLevel? get level => _level;

  InterviewStage? get stage => _stage;

  InterviewLanguage? get language => _language;

  InterviewReview? get review => _review;

  bool get isBusy => _isBusy;

  bool get isEnded => _isEnded;

  Future<void> start({
    required InterviewLevel level,
    required InterviewStage stage,
    required InterviewLanguage language,
  }) async {
    _level = level;
    _stage = stage;
    _language = language;
    _review = null;
    _isEnded = false;
    _messages.clear();
    _setBusy(true);

    try {
      final openingQuestion = await _aiService.startInterview(
        level: level,
        stage: stage,
        language: language,
      );
      _messages.add(
        InterviewMessage(
          sender: InterviewMessageSender.ai,
          text: openingQuestion,
          createdAt: DateTime.now().toUtc(),
        ),
      );
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
    _setBusy(true);

    try {
      final generatedReview = await _aiService.reviewInterview(
        level: _level!,
        stage: _stage!,
        language: _language!,
        messages: messages,
      );
      _review = generatedReview;
      _isEnded = true;
      notifyListeners();
      return generatedReview;
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
        createdAt: DateTime.now().toUtc(),
      ),
    );
    _setBusy(true);

    try {
      final response = await _aiService.sendMessage(
        level: _level!,
        stage: _stage!,
        language: _language!,
        messages: messages,
      );
      _messages.add(
        InterviewMessage(
          sender: InterviewMessageSender.ai,
          text: response,
          createdAt: DateTime.now().toUtc(),
        ),
      );
    } finally {
      _setBusy(false);
    }
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
}
