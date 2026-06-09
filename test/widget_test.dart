import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ainterview/models/interview_enums.dart';
import 'package:ainterview/models/interview_message.dart';
import 'package:ainterview/models/interview_preparation_context.dart';
import 'package:ainterview/models/interview_review.dart';
import 'package:ainterview/main.dart';
import 'package:ainterview/screens/interview_session_screen.dart';
import 'package:ainterview/services/ai_interview_service.dart';

void main() {
  testWidgets('creates a practice plan from the main screen', (tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle(const Duration(seconds: 1));

    expect(find.text('AI Interview'), findsOneWidget);
    expect(find.text('Interview Plan'), findsWidgets);
    expect(find.text('Generate Practice Plan'), findsOneWidget);

    await tester.tap(find.text('Generate Practice Plan'));
    await tester.pumpAndSettle();

    expect(find.text('Junior Dev Preparation'), findsOneWidget);
    expect(find.textContaining('State Management'), findsOneWidget);
  });

  testWidgets('runs a text interview session and shows review', (tester) async {
    await tester.pumpWidget(MyApp(aiService: MockAiInterviewService()));
    await tester.pumpAndSettle(const Duration(seconds: 1));

    await tester.tap(find.text('Interview'));
    await tester.pumpAndSettle();

    expect(find.text('Interview Setup'), findsOneWidget);

    await tester.ensureVisible(find.text('Start AI Interview'));
    await tester.tap(find.text('Start AI Interview'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Junior Dev'), findsWidgets);
    expect(find.byType(TextField), findsOneWidget);

    await tester.enterText(
      find.byType(TextField),
      'Saya pernah membangun aplikasi Flutter dengan REST API.',
    );
    await tester.tap(find.byIcon(Icons.send));
    await tester.pumpAndSettle();

    expect(find.textContaining('Terima kasih'), findsOneWidget);

    await tester.tap(find.text('End Interview & Get Review'));
    await tester.pumpAndSettle();

    expect(find.text('Interview Review'), findsOneWidget);
    expect(find.textContaining('Sesi Junior Dev HR selesai'), findsOneWidget);
  });

  testWidgets('active preparation progress influences the interview opening', (
    tester,
  ) async {
    await tester.pumpWidget(MyApp(aiService: MockAiInterviewService()));
    await tester.pumpAndSettle(const Duration(seconds: 1));

    await tester.tap(find.text('Generate Practice Plan'));
    await tester.pumpAndSettle();
    final firstPreparationItem = find.text('HR Mock Interview: Introduction');
    await tester.ensureVisible(firstPreparationItem);
    await tester.tap(firstPreparationItem);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Interview'));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Start AI Interview'));
    await tester.tap(find.text('Start AI Interview'));
    await tester.pumpAndSettle();

    expect(
      find.textContaining('HR Mock Interview: Introduction'),
      findsOneWidget,
    );
  });

  testWidgets('starts a technical interview from a selected plan topic', (
    tester,
  ) async {
    await tester.pumpWidget(MyApp(aiService: MockAiInterviewService()));
    await tester.pumpAndSettle(const Duration(seconds: 1));

    await tester.tap(find.text('Generate Practice Plan'));
    await tester.pumpAndSettle();

    final practiceButton = find.byKey(
      const ValueKey('practice_technical_focus_state_management'),
    );
    await tester.ensureVisible(practiceButton);
    await tester.tap(practiceButton);
    await tester.pumpAndSettle();

    expect(find.text('Interview Setup'), findsOneWidget);
    expect(
      find.textContaining('Fokus: Technical Focus: State Management'),
      findsOneWidget,
    );

    await tester.ensureVisible(find.text('Start AI Interview'));
    await tester.tap(find.text('Start AI Interview'));
    await tester.pumpAndSettle();

    expect(find.text('Junior Dev Technical'), findsOneWidget);
    expect(
      find.textContaining('Technical Focus: State Management'),
      findsWidgets,
    );
  });

  testWidgets('review errors stay visible and leave the end button usable', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: InterviewSessionScreen(aiService: _ReviewFailureAiService()),
      ),
    );

    await tester.tap(find.text('Start AI Interview'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('End Interview & Get Review'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Review service unavailable'), findsOneWidget);
    expect(find.text('End Interview & Get Review'), findsOneWidget);
  });

  testWidgets('adds review recommendations to the active interview plan', (
    tester,
  ) async {
    await tester.pumpWidget(MyApp(aiService: MockAiInterviewService()));
    await tester.pumpAndSettle(const Duration(seconds: 1));

    await tester.tap(find.text('Generate Practice Plan'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Interview'));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Start AI Interview'));
    await tester.tap(find.text('Start AI Interview'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byType(TextField),
      'Saya ingin melatih jawaban behavioral dengan struktur yang jelas.',
    );
    await tester.tap(find.byIcon(Icons.send));
    await tester.pumpAndSettle();
    await tester.tap(find.text('End Interview & Get Review'));
    await tester.pumpAndSettle();

    expect(find.text('Add to Active Plan'), findsOneWidget);

    await tester.ensureVisible(find.text('Add to Active Plan'));
    await tester.tap(find.text('Add to Active Plan'));
    await tester.pumpAndSettle();

    expect(find.text('Added to active plan'), findsOneWidget);

    await tester.tap(find.text('Plan'));
    await tester.pumpAndSettle();

    expect(
      find.text('Review Recommendation: HR Storytelling Drill'),
      findsOneWidget,
    );
  });
}

class _ReviewFailureAiService implements AiInterviewService {
  @override
  Future<String> startInterview({
    required InterviewLevel level,
    required InterviewStage stage,
    required InterviewLanguage language,
    InterviewPreparationContext? preparationContext,
  }) async {
    return 'Opening question';
  }

  @override
  Future<String> sendMessage({
    required InterviewLevel level,
    required InterviewStage stage,
    required InterviewLanguage language,
    required List<InterviewMessage> messages,
    InterviewPreparationContext? preparationContext,
  }) async {
    return 'Follow-up question';
  }

  @override
  Future<InterviewReview> reviewInterview({
    required InterviewLevel level,
    required InterviewStage stage,
    required InterviewLanguage language,
    required List<InterviewMessage> messages,
    InterviewPreparationContext? preparationContext,
  }) {
    throw Exception('Review service unavailable');
  }
}
