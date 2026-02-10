# Prashant

Prashant is a Student Productivity + Social Study Community mobile app built with Flutter and Firebase.

## What I created
- Flutter app scaffold (Material3)
- Screens: Login / Signup / Dashboard / Group Chat / Friends / Notes / Reports
- Auth service using Firebase Auth + Firestore user document
- Friend system, group & private chat (Firestore-based), notes feed
- Push notifications via FCM + Cloud Functions
- Firestore security rules and Cloud Functions stubs
- GitHub Actions workflow to build APK and publish artifact

## Firebase setup
1. Create a Firebase project in the Firebase console.
2. Add an Android app and follow the steps. Use package name `com.example.studentify` or your own.
3. Download `google-services.json` and place it in `android/app/`.
4. Enable Firebase Authentication (Email/Password).
5. Enable Firestore in native mode.
6. Enable Cloud Functions and deploy `functions/` using `firebase deploy --only functions`.
7. In Firestore, set rules from `firestore.rules`.

## Firestore schema
- `Users/{uid}`
	- name, username, email, photoUrl, fcmToken, createdAt, lastSeen, online
- `FriendRequests/{requestId}`
	- from, to, status (pending/accepted/rejected), createdAt
- `Friends/{id}`
	- userA, userB, createdAt
- `Messages/{chatId}/Threads/{messageId}`
	- from, fromName, to, text, createdAt, delivered, seen
- `GroupMessages/{messageId}`
	- from, fromName, text, createdAt
- `Notes/{noteId}`
	- authorId, authorName, text, createdAt
- `DailyActivity/{doc}`
	- userId, date (timestamp), studyHours (map subject->hours), sleepHours, mood, notes
- `Goals/{doc}`
	- userId, period (weekly/monthly), targetStudyHours, createdAt

## Run locally
- Install Flutter and Android SDK.
- Place `google-services.json` in `android/app/`.
- Run `flutter pub get`.
- Start emulator or connect device.
- `flutter run` for debug or `flutter build apk` to produce APK.

## CI / GitHub Actions
- The workflow at `.github/workflows/build_apk.yml` builds an APK on pushes to `main` and uploads the `app-release.apk` as an artifact.

## Notes & Next tasks
- Complete UI polish (gradients, animations, dark mode toggles).
- Add AI feedback Cloud Function to generate personalized tips (stub present in functions).
- Improve typing indicators and message delivery receipts logic for production.

