# ainterview

AI Interview Coach is a Flutter app for generating interview preparation plans, running text interview practice, and saving review history per authenticated Firebase user.

## Requirements

- Flutter SDK
- Node.js 22 for Firebase Functions
- Firebase CLI
- A Firebase project configured for Auth and Firestore
- An OpenRouter API key

## Free Firebase Setup

The Spark/free plan can deploy Firestore rules and indexes. It cannot deploy the Firebase Functions proxy because Functions secrets require Secret Manager on the Blaze plan.

Deploy Firestore rules and indexes:

```bash
firebase deploy --only firestore --project ai-interview-7333f
```

This repository also includes `.firebaserc`, so local Firebase CLI commands can omit `--project` after the default project is loaded.

The Firestore rules in `firestore.rules` restrict `users/{userId}/plans` and `users/{userId}/interview_sessions` so only the signed-in owner can read or write their own data.

## Run The App

For Spark/free demo mode, run Flutter with the OpenRouter key passed to the client app:

```bash
flutter run --dart-define=OPENROUTER_API_KEY=your_openrouter_key
```

For web builds:

```bash
flutter build web --dart-define=OPENROUTER_API_KEY=your_openrouter_key
```

This is suitable for local demos or trusted portfolio review. For production, do not expose the OpenRouter API key in the client; use the backend proxy below.

## Optional Production Proxy

The backend proxy in `functions/` keeps the OpenRouter key server-side, but it requires the Firebase Blaze plan.

```bash
cd functions
npm ci
firebase functions:secrets:set OPENROUTER_API_KEY --project ai-interview-7333f
firebase deploy --only functions --project ai-interview-7333f
```

Then run the app with:

```bash
flutter run --dart-define=AI_PROXY_BASE_URL=https://your-region-your-project.cloudfunctions.net/interview
```

## Verification

```bash
flutter analyze
flutter test

cd functions
npm test
npm run lint
```
