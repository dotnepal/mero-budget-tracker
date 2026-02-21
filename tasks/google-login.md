# Tasks: Google Login + Per-User Transactions

> Full plan: `plans/1-google-login.md`

---

## Pre-requisite (Manual — must be done by you before any code task)

- [ ] **0. Firebase project setup**
  - Create Firebase project, enable Google Sign-In
  - Download `GoogleService-Info.plist` → `ios/Runner/GoogleService-Info.plist`
  - Add `REVERSED_CLIENT_ID` URL scheme to `ios/Runner/Info.plist`
  - Download `google-services.json` → `android/app/google-services.json`
  - Add `google-services` Gradle plugin to `android/build.gradle.kts` and `android/app/build.gradle.kts`

---

## Implementation Tasks

- [x] **1. Add Firebase dependencies to `pubspec.yaml`**
  - Add `firebase_core`, `firebase_auth`, `google_sign_in`
  - Run `flutter pub get`

- [x] **2. Create `auth` feature — domain layer**
  - CREATE `lib/features/auth/domain/entities/app_user.dart`
  - CREATE `lib/features/auth/domain/repositories/auth_repository.dart`

- [x] **3. Create `auth` feature — data layer**
  - CREATE `lib/features/auth/data/repositories/firebase_auth_repository.dart`
  - Implements `AuthRepository` using `FirebaseAuth` + `GoogleSignIn`

- [x] **4. Create `auth` feature — BLoC**
  - CREATE `lib/features/auth/presentation/bloc/auth_bloc.dart`
    - Events: `AuthStarted`, `AuthSignInWithGoogle`, `AuthSignedOut`
    - States: `AuthInitial`, `AuthLoading`, `AuthAuthenticated(AppUser)`, `AuthUnauthenticated`, `AuthError(message)`
    - Listens to `authStateChanges` stream; handles sign-in/sign-out

- [x] **5. Create Login page**
  - CREATE `lib/features/auth/presentation/pages/login_page.dart`
  - App logo, "Sign in with Google" button, error display

- [x] **6. Database migration**
  - MODIFY `lib/core/database/database_helper.dart`
  - Bump version `1` → `2`
  - Add `user_id TEXT NOT NULL DEFAULT ''` column to `transactions` table
  - Add `onUpgrade` handler with `ALTER TABLE` migration
  - Add `idx_transactions_user_id` index

- [x] **7. Update transaction repository interface**
  - MODIFY `lib/features/transaction/domain/repositories/transaction_repository.dart`
  - Add `userId` parameter to all method signatures

- [x] **8. Scope SQLite queries by `user_id`**
  - MODIFY `lib/features/transaction/data/repositories/sqlite_transaction_repository.dart`
  - All 8 methods: add `WHERE user_id = ?` / store `user_id` on insert

- [x] **9. Update `TransactionBloc` events**
  - MODIFY `lib/features/transaction/presentation/bloc/transaction_event.dart`
  - Add `userId` to: `LoadTransactions`, `AddTransaction`, `EditTransaction`, `DeleteTransaction`, `LoadMoreTransactions`
  - MODIFY `lib/features/transaction/presentation/bloc/transaction_bloc.dart`
  - Pass `userId` through to all repository calls

- [x] **10. Update `SummaryBloc` and `StatisticsBloc`**
  - MODIFY `lib/features/home/presentation/bloc/summary_bloc.dart`
  - MODIFY `lib/features/statistics/presentation/bloc/statistics_bloc.dart`
  - Pass `userId` to repository calls

- [x] **11. Update router**
  - MODIFY `lib/core/router/app_router.dart`
  - Add `login = '/login'` route and `LoginPage` mapping

- [x] **12. Wire everything in `main.dart`**
  - MODIFY `lib/main.dart`
  - Add `await Firebase.initializeApp()`
  - Add `AuthBloc` to `MultiBlocProvider`
  - Replace static `initialRoute` with `BlocBuilder<AuthBloc, AuthState>` auth gate
  - On `AuthAuthenticated`: dispatch `LoadTransactions(userId)` etc.
  - On sign-out: call `clearTransactions()` then `AuthSignedOut`

---

## Verification

- [ ] **13. End-to-end test**
  - `flutter pub get` succeeds
  - App launches → `LoginPage` shown
  - Google sign-in completes → `HomePage` shown
  - Add a transaction → visible in list
  - Sign out → transactions cleared, `LoginPage` shown
  - Sign in with different account → empty list
