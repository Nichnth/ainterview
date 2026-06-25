import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/interview_enums.dart';
import '../models/interview_message.dart';
import '../models/interview_preparation_context.dart';
import '../models/interview_review.dart';
import 'ai_interview_service.dart';

class BackendAiInterviewService implements AiInterviewService {
  BackendAiInterviewService({
    required Uri baseUrl,
    required Future<String?> Function() idTokenProvider,
    http.Client? client,
    Duration? requestTimeout,
  }) : _baseUrl = baseUrl,
       _idTokenProvider = idTokenProvider,
       _client = client ?? http.Client(),
       _requestTimeout = requestTimeout ?? const Duration(seconds: 20);

  final Uri _baseUrl;
  final Future<String?> Function() _idTokenProvider;
  final http.Client _client;
  final Duration _requestTimeout;

  @override
  Future<String> startInterview({
    required InterviewLevel level,
    required InterviewStage stage,
    required InterviewLanguage language,
    InterviewPreparationContext? preparationContext,
  }) async {
    final response = await _post('start', {
      'level': level.key,
      'stage': stage.key,
      'language': language.key,
      if (preparationContext != null)
        'preparationContext': _preparationContextToMap(preparationContext),
    });

    final text = response['text'] as String? ?? '';
    if (text.trim().isEmpty) {
      throw const BackendAiInterviewException(
        code: 'AI_EMPTY_RESPONSE',
        message: 'AI interview service returned an empty response.',
      );
    }

    return text;
  }

  @override
  Future<String> sendMessage({
    required InterviewLevel level,
    required InterviewStage stage,
    required InterviewLanguage language,
    required List<InterviewMessage> messages,
    InterviewPreparationContext? preparationContext,
  }) async {
    final response = await _post('reply', {
      'level': level.key,
      'stage': stage.key,
      'language': language.key,
      'messages': messages.map((message) => message.toMap()).toList(),
      if (preparationContext != null)
        'preparationContext': _preparationContextToMap(preparationContext),
    });

    final text = response['text'] as String? ?? '';
    if (text.trim().isEmpty) {
      throw const BackendAiInterviewException(
        code: 'AI_EMPTY_RESPONSE',
        message: 'AI interview service returned an empty response.',
      );
    }

    return text;
  }

  @override
  Future<InterviewReview> reviewInterview({
    required InterviewLevel level,
    required InterviewStage stage,
    required InterviewLanguage language,
    required List<InterviewMessage> messages,
    InterviewPreparationContext? preparationContext,
  }) async {
    final response = await _post('review', {
      'level': level.key,
      'stage': stage.key,
      'language': language.key,
      'messages': messages.map((message) => message.toMap()).toList(),
      if (preparationContext != null)
        'preparationContext': _preparationContextToMap(preparationContext),
    });

    final rawReview = response['review'];
    if (rawReview is! Map) {
      throw const BackendAiInterviewException(
        code: 'AI_INVALID_REVIEW',
        message: 'AI interview service returned an invalid review.',
      );
    }

    final review = InterviewReview.fromMap(
      Map<String, dynamic>.from(rawReview),
    );
    return review;
  }

  Future<Map<String, dynamic>> _post(
    String action,
    Map<String, Object?> body,
  ) async {
    final token = (await _idTokenProvider())?.trim();
    if (token == null || token.isEmpty) {
      throw const BackendAiInterviewException(
        code: 'AUTH_REQUIRED',
        message: 'Please sign in again before using AI interview practice.',
      );
    }

    final response = await _client
        .post(
          _endpoint(action),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          body: jsonEncode(body),
        )
        .timeout(_requestTimeout);

    final data = _decodeResponse(
      response.body,
      isError: response.statusCode < 200 || response.statusCode >= 300,
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw BackendAiInterviewException(
        code: data['code'] as String? ?? 'AI_PROXY_ERROR',
        message:
            data['message'] as String? ??
            'AI interview service is temporarily unavailable.',
      );
    }

    return data;
  }

  Uri _endpoint(String action) {
    final basePath = _baseUrl.path;
    final normalizedBase = basePath.endsWith('/')
        ? basePath.substring(0, basePath.length - 1)
        : basePath;
    final path = normalizedBase.isEmpty
        ? '/$action'
        : '$normalizedBase/$action';

    return _baseUrl.replace(path: path, query: null, fragment: null);
  }

  Map<String, dynamic> _decodeResponse(String body, {required bool isError}) {
    if (body.trim().isEmpty) {
      return const {};
    }

    try {
      final decoded = jsonDecode(body);
      if (decoded is Map) {
        return Map<String, dynamic>.from(decoded);
      }
    } on FormatException {
      if (isError) {
        return const {};
      }

      throw const BackendAiInterviewException(
        code: 'AI_PROXY_ERROR',
        message: 'AI interview service returned an invalid response.',
      );
    }

    throw const BackendAiInterviewException(
      code: 'AI_PROXY_ERROR',
      message: 'AI interview service returned an invalid response.',
    );
  }

  Map<String, Object?> _preparationContextToMap(
    InterviewPreparationContext context,
  ) {
    return {
      'planId': context.planId,
      'targetDate': context.targetDate.toIso8601String(),
      'targetLevel': context.targetLevel.key,
      'targetLanguage': context.targetLanguage.key,
      'totalItemCount': context.totalItemCount,
      'completedItemCount': context.completedItemCount,
      'selectedScheduleItemId': context.selectedScheduleItemId,
      'primaryFocusTitle': context.primaryFocusTitle,
      'completedTopics': context.completedTopics.map(_topicToMap).toList(),
      'pendingTopics': context.pendingTopics.map(_topicToMap).toList(),
      'selectedTopic': context.selectedTopic == null
          ? null
          : _topicToMap(context.selectedTopic!),
    };
  }

  Map<String, Object?> _topicToMap(InterviewPreparationTopic topic) {
    return {
      'id': topic.id,
      'title': topic.title,
      'description': topic.description,
      'suggestedStage': topic.suggestedStage?.key,
    };
  }
}

class BackendAiInterviewException implements Exception {
  const BackendAiInterviewException({
    required this.code,
    required this.message,
  });

  final String code;
  final String message;

  @override
  String toString() => message;
}
