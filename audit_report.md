# Deep Audit Report: Interview & Planning Systems

This recheck audits the current repository against `plan.md`, `ai_interview_milestones.md`, and `implementation_plan.md`, focused on unimplemented functionality, bugs, and edge cases in the planning and interview flows.

> **Rescope note:** STT/TTS voice mode is intentionally deferred and is no longer treated as an active implementation gap in this audit.

---

## Executive Summary

The current audit and plan catch several real issues, but they under-cover three important areas:

1. Production persistence is still in-memory for plans and sessions, even after login.
2. Plan-to-interview handoff has edge cases around active/ended sessions and duplicate recommendation insertion.
3. Firestore implementation needs more than adding repositories: model serialization, `Timestamp` parsing, query ordering, user injection, profile loading, and regression tests must land together.

---

## 1. Planning System Audit

### Unimplemented Features

1. **Edit Plan UI is still missing**
   - Requirement: Milestone 2 and Milestone 4 require updating target date, level, and language from the UI.
   - Current code: `InterviewPlanController.updatePlan` exists, but `interview_plan_screen.dart` only has a create form and delete action.
   - Impact: Users must delete/recreate a plan to change target date, level, or language.

2. **Production Firestore plan persistence is not wired**
   - Current code: `MainNavigationWrapper` defaults to `InMemoryInterviewPlanRepository`.
   - Impact: Authenticated users lose plans after app restart. This misses the Firestore requirement for `users/{userId}/plans`.

3. **No plan mutation busy/error state**
   - Current code: `isLoading` is only used by `loadPlans`; `createPlan`, `updatePlan`, `toggleScheduleItem`, `appendReviewRecommendations`, and `deletePlan` do not set busy/error state.
   - Impact: Users can double-tap plan creation or recommendation insertion, and failed saves are not surfaced cleanly.

### Logic Bugs & Edge Cases

1. **Stale generation reference date**
   - File: `lib/providers/interview_plan_controller.dart`
   - Current code: `_today` is captured once in the controller constructor.
   - Impact: If the app remains open across days, newly generated or recalculated plans use the old date.

2. **Plan updates wipe completed state**
   - File: `lib/providers/interview_plan_controller.dart`
   - Current code: `updatePlan` regenerates all schedule items from scratch.
   - Impact: Completed tasks reset to incomplete. The current test suite even expects this behavior in `test/interview_plan_controller_test.dart`, so tests must be updated too.

3. **Date parsing and countdown can drift around timezone/midnight**
   - Files: `lib/models/interview_plan.dart`, `lib/screens/interview_plan_screen.dart`
   - Current code: dates are stored as ISO strings and countdown uses `plan.targetDate.difference(DateTime.now()).inDays`.
   - Impact: A target date stored at midnight can display fewer days than expected, especially later in the day or after timezone conversions.

4. **Firestore `Timestamp` values are not supported by model readers**
   - File: `lib/models/interview_plan.dart`
   - Current code: `_readDate` accepts only `DateTime` or `String`.
   - Impact: A Firestore repository that reads raw `Timestamp` fields will fail unless conversion happens in the repository or the model is made tolerant.

5. **Review recommendations can be duplicated**
   - Files: `lib/providers/interview_plan_controller.dart`, `lib/screens/interview_session_screen.dart`
   - Current code: `appendReviewRecommendations` always appends items; the UI only checks whether the active plan already contains the review after state updates.
   - Impact: Double taps, retries, or concurrent saves can append the same review recommendations more than once.

6. **Plan-to-practice request does not reset an active interview**
   - File: `lib/screens/interview_session_screen.dart`
   - Current code: `_applyPracticeRequest` changes selected preparation context, but `build` keeps showing `_SessionView` if messages already exist.
   - Impact: Pressing `Practice` from a plan while an interview is running or ended can silently change the selected focus without showing setup or starting a new session.

---

## 2. Interview System Audit

### Unimplemented Features

1. **Profile review history is unimplemented**
   - Requirement: Milestone 7 expects completed interview reviews/history.
   - Current code: `ProfileScreen` renders a static placeholder and does not accept a session repository or user ID.

2. **Authenticated session ownership is not wired**
   - File: `lib/screens/interview_session_screen.dart`
   - Current code: `InterviewSessionController` is created without passing the logged-in user ID, so it falls back to `demo_user`.
   - Impact: Saved sessions are not associated with the actual authenticated user.

3. **Production Firestore session persistence is not wired**
   - File: `lib/screens/main_navigation_wrapper.dart`
   - Current code: Defaults to `InMemoryInterviewSessionRepository`.
   - Impact: Completed sessions disappear after app restart and cannot populate profile history.

### Logic Bugs & Edge Cases

1. **Common testing answers are rejected**
   - File: `lib/providers/interview_session_controller.dart`
   - Current code: the low-effort regex rejects the exact word `test`.
   - Impact: Relevant answers like "I wrote a unit test" or "test coverage caught the regression" can be rejected. The word `testing` itself is not rejected, but exact `test` phrases are common in technical interviews.

2. **Relevance filtering is incomplete across languages**
   - File: `lib/providers/interview_session_controller.dart`
   - Current code: unrelated terms mostly cover Indonesian examples, while English off-topic phrases can pass.
   - Impact: English interviews accept unrelated answers such as vacation/movie chatter unless they hit the low-effort checks.

3. **Save failure locks the session as ended**
   - File: `lib/providers/interview_session_controller.dart`
   - Current code: `_isEnded = true` is set before `_saveEndedSession`.
   - Impact: If persistence fails after review generation, the user sees an error but cannot retry ending/saving the interview. A widget test currently checks button visibility, but it does not verify repository-save failure with `_isEnded`.

4. **User input remains editable while AI is processing**
   - File: `lib/screens/interview_session_screen.dart`
   - Current code: the `TextField` remains editable while send/end actions are disabled.
   - Impact: Users can change or erase the answer field while the AI response is loading, producing confusing UI state.

5. **Interview can be reviewed with zero candidate answers**
   - File: `lib/providers/interview_session_controller.dart`
   - Current code: `endAndReview` only checks that a session started.
   - Impact: User can start then immediately end, producing a low-signal review with no candidate response.

6. **Answer is cleared before controller success is known**
   - File: `lib/screens/interview_session_screen.dart`
   - Current code: `_sendAnswer` clears the text controller before awaiting `sendUserAnswer`.
   - Impact: If the controller throws or rejects due to state, the typed answer is lost.

---

## 3. API, AI, and Database Integration Audit

### Unimplemented Features

1. **No Firestore package or repository implementation**
   - Current code: `cloud_firestore` is absent from `pubspec.yaml`; repositories are in-memory only.

2. **Session serialization is incomplete**
   - Files: `lib/models/interview_session.dart`, `lib/models/interview_message.dart`
   - Current code: `InterviewMessage` has `toMap` only; `InterviewSession` has no `toMap`/`fromMap`.
   - Impact: Firestore-backed session history cannot be loaded without new serialization.

### Logic Bugs & Edge Cases

1. **OpenRouter requests have no timeout**
   - File: `lib/services/open_router_ai_interview_service.dart`
   - Impact: A hanging network request can keep the UI busy indefinitely and block fallback models.

2. **Review JSON extraction is fragile**
   - File: `lib/services/open_router_ai_interview_service.dart`
   - Current code: `_stripCodeFence` only handles responses that start with a code fence.
   - Impact: Responses like `Here is the JSON: {...}` fail parsing.

3. **Recommendation index parsing is fragile**
   - File: `lib/models/review_recommendation.dart`
   - Current code: `linkedScheduleItemIndex` is cast with `as int?`.
   - Impact: AI or Firestore values like `"2"` or `2.0` can crash parsing.

4. **Firestore ordering and profile filters are unspecified**
   - Planned code: `FirestoreInterviewSessionRepository.fetchSessions`.
   - Risk: Profile history needs deterministic descending order, completed-session filtering, optional level/stage filters, and bounded reads.

---

## 4. Test Coverage Gaps

Add or update tests for:

1. `updatePlan` preserves completed schedule state when stable item IDs still match.
2. Dynamic `today` is used for new plan generation after the controller has lived across days.
3. Create/delete/toggle/recommendation save failures surface an error and do not corrupt local state.
4. Review recommendation insertion is idempotent for the same review ID.
5. `InterviewSessionScreen` passes authenticated `userId` into `InterviewSessionController`.
6. Repository save failure during `endAndReview` leaves the user able to retry.
7. Exact `test` phrases in technical answers are accepted when the answer is otherwise relevant.
8. English off-topic answers are redirected.
9. Review cannot be generated with zero candidate answers, or the UI clearly confirms that choice.
10. Firestore repository round-trips plans and sessions, including nested messages, review, recommendations, and date fields.
11. Profile screen renders empty, loading, error, and populated review-history states.

---

## 5. Highest-Priority Fix Order

1. Wire authenticated user ID through `InterviewSessionScreen` and `ProfileScreen`.
2. Implement Firestore repositories plus robust serialization for plans and sessions.
3. Fix `endAndReview` save failure ordering and add regression coverage.
4. Add edit-plan UI and preserve completed schedule items on updates.
5. Fix plan generation date handling and countdown normalization.
6. Harden relevance filtering, timeout behavior, JSON parsing, and recommendation parsing.
7. Add profile history list.
