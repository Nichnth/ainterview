import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ainterview/main.dart';

void main() {
  testWidgets('creates a practice plan from the main screen', (tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('AI Interview'), findsOneWidget);
    expect(find.text('Interview Plan'), findsWidgets);
    expect(find.text('Generate Practice Plan'), findsOneWidget);

    await tester.tap(find.text('Generate Practice Plan'));
    await tester.pumpAndSettle();

    expect(find.text('Junior Dev Preparation'), findsOneWidget);
    expect(find.textContaining('State Management'), findsOneWidget);
  });

  testWidgets('runs a text interview session and shows review', (tester) async {
    await tester.pumpWidget(const MyApp());

    await tester.tap(find.text('Interview'));
    await tester.pumpAndSettle();

    expect(find.text('Interview Setup'), findsOneWidget);

    await tester.tap(find.text('Start Mock Interview'));
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
}
