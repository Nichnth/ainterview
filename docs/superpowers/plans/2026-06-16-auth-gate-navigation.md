# Auth Gate Navigation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make Firebase authentication and the tab navigation shell use one source of truth so Plan, Interview, and Profile share the same user context and controller wiring.

**Architecture:** `main.dart` owns Firebase initialization, theme, splash, and auth gate decisions. `lib/screens/main_navigation_wrapper.dart` is the only tab shell and receives a user id plus injectable services/repositories. Login and signup only authenticate; the auth gate decides whether to show login or the main shell.

**Tech Stack:** Flutter, Firebase Auth, ChangeNotifier controllers, existing in-memory repositories, widget tests with injected authenticated user id.

---

### Task 1: Authenticated App Test Entry

**Files:**
- Modify: `test/widget_test.dart`
- Verify: `flutter test test/widget_test.dart -r expanded`

- [ ] **Step 1: Write the failing test-facing app entry**

Update widget tests to pump `MyApp` with an authenticated user override and no splash:

```dart
Future<void> _pumpAuthenticatedApp(
  WidgetTester tester, {
  AiInterviewService? aiService,
}) async {
  await tester.pumpWidget(
    MyApp(
      aiService: aiService ?? MockAiInterviewService(),
      authenticatedUserId: 'test_user',
      showSplash: false,
    ),
  );
  await tester.pumpAndSettle();
}
```

- [ ] **Step 2: Run test to verify RED**

Run: `flutter test test/widget_test.dart -r expanded`

Expected: FAIL because `MyApp` does not yet expose `authenticatedUserId` and `showSplash`.

### Task 2: Single Auth Gate

**Files:**
- Modify: `lib/main.dart`
- Modify: `lib/screens/main_navigation_wrapper.dart`
- Verify: `flutter test test/widget_test.dart -r expanded`

- [ ] **Step 1: Move shell responsibility out of `main.dart`**

`main.dart` keeps `MyApp`, `SplashNavigationWrapper`, and `_AuthGate`. It imports `AuthService`, `LoginScreen`, `SplashScreen`, and `screens/main_navigation_wrapper.dart`.

- [ ] **Step 2: Add injectable auth override**

`MyApp` accepts:

```dart
final AiInterviewService? aiService;
final String? authenticatedUserId;
final bool showSplash;
```

`_AuthGate` returns `MainNavigationWrapper(userId: authenticatedUserId!, aiService: aiService)` when the override is present.

- [ ] **Step 3: Use Firebase auth stream in production**

When no override is present, `_AuthGate` listens to `AuthService.instance.authStateChanges`, uses `AuthService.instance.currentUser` as initial data, returns `LoginScreen` when null, and returns `MainNavigationWrapper(userId: user.uid, aiService: aiService)` when authenticated.

### Task 3: Single Main Navigation Wrapper

**Files:**
- Modify: `lib/screens/main_navigation_wrapper.dart`
- Verify: `flutter test test/widget_test.dart -r expanded`

- [ ] **Step 1: Add app shell dependencies**

`MainNavigationWrapper` accepts:

```dart
required String userId,
AiInterviewService? aiService,
InterviewPlanRepository? planRepository,
InterviewSessionRepository? sessionRepository,
```

- [ ] **Step 2: Wire plan and session consistently**

Initialize `InterviewPlanController` with `widget.planRepository ?? InMemoryInterviewPlanRepository()` and `widget.userId`, call `loadPlans()`, initialize session repository, and pass `planController`, `sessionRepository`, `practiceScheduleItemId`, and `practiceRequestVersion` into `InterviewSessionScreen`.

- [ ] **Step 3: Keep Profile in the same shell**

The Profile tab uses `const ProfileScreen()`.

### Task 4: Login And Signup Use Auth Gate

**Files:**
- Modify: `lib/screens/login_screen.dart`
- Modify: `lib/screens/signup_screen.dart`
- Verify: `flutter analyze`

- [ ] **Step 1: Convert both screens to `StatefulWidget`**

Move `TextEditingController`s into state fields and dispose them.

- [ ] **Step 2: Remove manual navigation to `MainNavigationWrapper` after success**

After sign in, close the loading dialog and let `AuthGate` replace the screen. After sign up, close the dialog and pop back to the root route so the auth gate can show the main shell.

### Task 5: Verification

**Files:**
- All changed Dart files

- [ ] **Step 1: Format**

Run: `dart format lib/main.dart lib/screens/main_navigation_wrapper.dart lib/screens/login_screen.dart lib/screens/signup_screen.dart test/widget_test.dart`

- [ ] **Step 2: Analyze**

Run: `flutter analyze`

Expected: no analyzer errors.

- [ ] **Step 3: Test**

Run: `flutter test -r expanded`

Expected: all tests pass.
