# AI Plan Risk Hardening Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Reduce coupling risks in AI interview and plan flows by using stable enum keys, preserving legacy reads, and treating plan-derived prompt text as untrusted context.

**Architecture:** Keep UI labels separate from persistence/API keys. Dart models serialize stable keys while parsers accept both old labels and new keys. The Firebase proxy normalizes incoming payloads and includes plan context as quoted data with explicit instruction boundaries.

**Tech Stack:** Flutter/Dart tests, Firebase Functions Node tests, existing repository/service/controller architecture.

---

### Task 1: Stable Enum Keys

**Files:**
- Modify: `lib/models/interview_enums.dart`
- Modify: `lib/models/interview_plan.dart`
- Modify: `lib/models/interview_review.dart`
- Modify: `lib/models/review_recommendation.dart`
- Modify: `lib/models/schedule_item.dart`
- Test: `test/interview_model_serialization_test.dart`

- [ ] Add failing tests that serialized model maps use keys like `junior`, `technical`, and `indonesian`, while legacy labels like `Junior Dev` still parse.
- [ ] Run `flutter test test/interview_model_serialization_test.dart` and verify the new test fails.
- [ ] Add `key` fields to enums and update `toMap()` methods to serialize keys.
- [ ] Run the test again and verify it passes.

### Task 2: Backend API Contract Uses Keys

**Files:**
- Modify: `lib/services/backend_ai_interview_service.dart`
- Modify: `functions/src/openrouterProxy.js`
- Test: `test/backend_ai_interview_service_test.dart`
- Test: `functions/test/openrouterProxy.edge.test.js`

- [ ] Add failing tests that Flutter sends enum keys to the backend and the proxy accepts both keys and legacy labels.
- [ ] Run targeted Dart and Node tests and verify failures.
- [ ] Update Flutter backend payloads to use keys.
- [ ] Normalize proxy payload values to display labels internally, while returning keys in review JSON.
- [ ] Run targeted tests and verify they pass.

### Task 3: Prompt Context Is Untrusted Data

**Files:**
- Modify: `lib/models/interview_preparation_context.dart`
- Modify: `lib/services/open_router_ai_interview_service.dart`
- Modify: `functions/src/openrouterProxy.js`
- Test: `test/interview_plan_generator_test.dart`
- Test: `test/open_router_ai_interview_service_test.dart`
- Test: `functions/test/openrouterProxy.edge.test.js`

- [ ] Add failing tests with a malicious-looking plan title and assert prompts instruct the model to treat it as untrusted data.
- [ ] Run targeted tests and verify failures.
- [ ] Add explicit untrusted-context wording and JSON-quote plan values in direct and proxy prompts.
- [ ] Run targeted tests and verify they pass.

### Task 4: Full Verification

**Files:**
- Test: all Flutter tests
- Test: all Firebase Functions tests

- [ ] Run `dart format` on touched Dart files.
- [ ] Run `flutter test`.
- [ ] Run `npm test` in `functions`.
- [ ] Report pass/fail counts and remaining risks.
