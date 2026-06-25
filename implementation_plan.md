# Implementation Plan - Interview & Planning Completion

This revised plan covers the missing functional work for the **Planning** and **Interview** systems after rescoping: Firestore persistence, authenticated user wiring, profile review history, edit-plan support, text interview robustness, and the bug fixes found in the deeper audit.

## User Review Required

> [!IMPORTANT]
> **Firestore & Text Interview Completion:** This plan adds database storage for plans and sessions, profile review history, and text interview stability.
>
> **Scope Included:** Interview plan CRUD, schedule preservation, interview session ownership, profile review history, OpenRouter robustness, and focused regression tests.
>
> **Scope Excluded:** STT/TTS voice mode, login/signup visual redesign, and unrelated aesthetic changes.

---

## Decisions To Confirm

1. **Network timeout:** Use 15 seconds per OpenRouter model attempt before trying the next model.
2. **Zero-answer reviews:** Disable review until the candidate has sent at least one valid answer.
3. **Practice while session is active:** Tapping a plan `Practice` button should route to interview setup for a new session, not mutate a running session silently.

---

## Component 1: Dependencies

### [MODIFY] `pubspec.yaml`

Add:

```yaml
cloud_firestore: ^4.17.5
```

Then run `flutter pub get`.

---

## Component 2: Models & Serialization

### [MODIFY] `lib/models/interview_message.dart`

- Add `fromMap`.
- Accept `DateTime`, ISO string, and repository-normalized date values.
- Default unknown sender safely or throw a clear `ArgumentError`.

### [MODIFY] `lib/models/interview_session.dart`

- Add `toMap` and `fromMap`.
- Include `id`, `level`, `stage`, `language`, `startedAt`, `endedAt`, `linkedPlanId`, `linkedScheduleItemId`, `preparationFocusTitle`, `messages`, and `review`.
- Use `InterviewReview.fromMap` for nested review data.
- Ensure `copyWith` can intentionally clear nullable fields if needed, or avoid relying on it for clear operations.

### [MODIFY] `lib/models/interview_plan.dart`

- Normalize plan date reads for Firestore repository inputs.
- Prefer date-only target handling for `targetDate` to avoid countdown drift.
- Keep `createdAt` as UTC timestamp.

### [MODIFY] `lib/models/schedule_item.dart`

- Make `dayOffset` parsing tolerant of `int`, numeric strings, and numeric Firestore values.

### [MODIFY] `lib/models/review_recommendation.dart`

Fix `linkedScheduleItemIndex` parsing:

```dart
int? _readNullableInt(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}
```

Use that helper instead of `map['linkedScheduleItemIndex'] as int?`.

---

## Component 3: Firestore Repositories

### [NEW] `lib/services/firestore_repositories.dart`

Implement:

- `FirestoreInterviewPlanRepository implements InterviewPlanRepository`
- `FirestoreInterviewSessionRepository implements InterviewSessionRepository`

Paths:

- Plans: `users/{userId}/plans/{planId}`
- Sessions: `users/{userId}/interview_sessions/{sessionId}`

Repository behavior:

- Generate a new document ID when model `id` is empty.
- Save model maps under the document ID.
- Convert Firestore `Timestamp` values to `DateTime` before calling model factories, or make a shared date reader.
- Fetch plans ordered by `targetDate` ascending.
- Fetch sessions ordered by `startedAt` descending.
- For profile history, fetch only completed sessions when possible: `endedAt != null` or equivalent query strategy.
- Preserve optional level/stage filters in `fetchSessions`.

---

## Component 4: Planning Controller & UI

### [MODIFY] `lib/providers/interview_plan_controller.dart`

- Replace captured `_today` with a `DateTime Function()` clock, defaulting to `DateTime.now`.
- Use the clock at create/update time.
- Add busy/error handling for create, update, toggle, append recommendations, and delete.
- Preserve completed state during update when regenerated items share stable IDs with previous items.
- Make `appendReviewRecommendations` idempotent by skipping recommendations whose `sourceReviewId` and `sourceRecommendationId` already exist.

### [MODIFY] `lib/screens/interview_plan_screen.dart`

- Add an edit action for the selected plan.
- Reuse the existing form fields for editing or open a small edit form/dialog.
- Pre-fill target date, level, and language from the selected plan.
- Show mutation errors in the plan screen.
- Disable create/update/delete/toggle controls while the relevant mutation is running.
- Normalize countdown by comparing date-only values.

---

## Component 5: Interview Controller & UI

### [MODIFY] `lib/providers/interview_session_controller.dart`

- Require `userId` instead of defaulting to `demo_user`, or make the default test-only and never used by production screens.
- Remove `test` from the low-effort rejection regex.
- Add better English off-topic terms or move relevance checks into a clearer validator.
- Set `_isEnded = true` only after `_saveEndedSession` succeeds.
- Keep review data available after a save failure but allow retry.
- Prevent review before at least one valid candidate answer, unless the UI explicitly confirms ending early.

### [MODIFY] `lib/screens/interview_session_screen.dart`

- Accept required `userId` and pass it into `InterviewSessionController`.
- Make the answer field `readOnly` or disabled while busy/ended.
- Do not clear the answer text until `sendUserAnswer` accepts it.
- When receiving a practice request while a session already has messages, show/reset to setup for a new topic-guided session instead of silently mutating context.

---

## Component 6: Profile Review History

### [MODIFY] `lib/screens/main_navigation_wrapper.dart`

- Instantiate Firestore repositories by default in production mode:
  - `FirestoreInterviewPlanRepository`
  - `FirestoreInterviewSessionRepository`
- Keep constructor injection for tests.
- Pass `widget.userId` to `InterviewSessionScreen`.
- Pass `widget.userId` and `_sessionRepository` to `ProfileScreen`.

### [MODIFY] `lib/screens/profile_screen.dart`

- Accept `userId` and `InterviewSessionRepository`.
- Load completed sessions in `initState`.
- Render loading, empty, error, and populated states.
- Show useful fields: date, level, stage, language, preparation focus, summary, and a short recommendation preview.
- Keep existing profile image/logout behavior intact.

---

## Component 7: OpenRouter Robustness

### [MODIFY] `lib/services/open_router_ai_interview_service.dart`

- Apply a 15-second timeout to each model request:

```dart
await _client.post(...).timeout(const Duration(seconds: 15));
```

- Strengthen review JSON extraction:
  - Strip fenced JSON when present.
  - If surrounding prose exists, parse from first `{` to last `}`.
  - Throw a clear `OpenRouterAiInterviewException` when no JSON object is found.

- Add tests for timeout fallback and prose-wrapped JSON.

---

## Verification Plan

### Automated Tests

Run:

```sh
flutter test
flutter analyze
```

Add/update tests for:

1. Plan update preserves completed schedule items with matching stable IDs.
2. Plan generation uses the current clock, not the controller construction date.
3. Plan mutation failures surface errors without corrupting local state.
4. Recommendation append is idempotent for the same review/recommendation IDs.
5. `InterviewSessionScreen` passes authenticated user ID to saved sessions.
6. Repository save failure during `endAndReview` leaves retry possible.
7. Technical answers containing exact `test` phrases are accepted.
8. English off-topic answers are redirected.
9. Ending with zero candidate answers is disabled or rejected.
10. Firestore repositories round-trip nested plan/session/review/message data.
11. Profile screen shows loading, empty, error, and populated history states.
12. OpenRouter timeout tries the next model.
13. OpenRouter review parser handles fenced JSON and prose-wrapped JSON.

### Manual Verification

1. Create, edit, complete, delete, and reload a plan; verify Firestore data under the authenticated user.
2. Update a plan after completing tasks; verify completed matching tasks remain completed.
3. Start interview from a plan item; verify level/language/stage/focus match the selected item.
4. Try tapping another plan item while a session is running/ended; verify the app starts a clean setup for the new session.
5. Complete an interview; verify session is saved under `users/{userId}/interview_sessions`.
6. Open Profile; verify the completed session appears after app restart.
7. Trigger/retry a session save failure; verify the user is not locked out.
8. Verify `unit test`, `test coverage`, and relevant English technical answers are accepted.
9. Verify unrelated English and Indonesian answers are redirected.
