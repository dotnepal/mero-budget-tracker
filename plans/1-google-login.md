# Plan: Google Login + Per-User Transactions

## Context
The app currently has no authentication — all transactions are stored in a shared SQLite database visible to anyone using the device. The goal is to add Google Sign-In via Firebase Auth, scope all transactions to the signed-in user's UID, and discard any pre-login data on first sign-in. One user at a time; no account switching.

---

## Decisions
- **Auth**: Firebase Auth + `google_sign_in` package
- **Storage**: Existing SQLite, extended with a `user_id` column on the `transactions` table
- **Existing data**: Wiped on first login (`DatabaseService.clearTransactions()` already exists)
- **Multi-user**: Not supported — one active session at a time

---

## Step 0 — Manual Firebase Setup (YOU must do this)
These steps cannot be automated and must be done before any code runs:

1. Create a Firebase project at https://console.firebase.google.com
2. Enable **Google Sign-In** under Authentication → Sign-in methods
3. Register the **iOS app** (bundle ID: `com.example.mero_budget_tracker`)
   - Download `GoogleService-Info.plist` → place at `ios/Runner/GoogleService-Info.plist`
   - Copy the `REVERSED_CLIENT_ID` value from that file
   - Add it as a URL scheme in `ios/Runner/Info.plist`:
     ```xml
     <key>CFBundleURLTypes</key>
     <array>
       <dict>
         <key>CFBundleTypeRole</key><string>Editor</string>
         <key>CFBundleURLSchemes</key>
         <array><string>YOUR_REVERSED_CLIENT_ID</string></array>
       </dict>
     </array>
     ```
4. Register the **Android app** (package: `com.example.mero_budget_tracker`)
   - Download `google-services.json` → place at `android/app/google-services.json`
   - Add to `android/build.gradle.kts`: `id("com.google.gms.google-services") version "4.4.0" apply false`
   - Add to `android/app/build.gradle.kts`: `id("com.google.gms.google-services")`

---

## Step 1 — Add Dependencies (`pubspec.yaml`)
```yaml
firebase_core: ^3.6.0
firebase_auth: ^5.3.1
google_sign_in: ^6.2.1
```

---

## Step 2 — New `auth` Feature (Clean Architecture)

### `lib/features/auth/domain/entities/app_user.dart`
```dart
class AppUser extends Equatable {
  final String uid;
  final String email;
  final String? displayName;
  final String? photoUrl;
}
```

### `lib/features/auth/domain/repositories/auth_repository.dart`
```dart
abstract class AuthRepository {
  Stream<AppUser?> get authStateChanges;
  Future<AppUser> signInWithGoogle();
  Future<void> signOut();
  AppUser? get currentUser;
}
```

### `lib/features/auth/data/repositories/firebase_auth_repository.dart`
Implements `AuthRepository` using `FirebaseAuth` + `GoogleSignIn`.

### `lib/features/auth/presentation/bloc/`
- `AuthEvent`: `AuthStarted`, `AuthSignInWithGoogle`, `AuthSignedOut`
- `AuthState`: `AuthInitial`, `AuthLoading`, `AuthAuthenticated(AppUser)`, `AuthUnauthenticated`, `AuthError(message)`
- `AuthBloc`: listens to `authStateChanges` stream; handles sign-in and sign-out events

### `lib/features/auth/presentation/pages/login_page.dart`
Simple screen with app logo, "Sign in with Google" button, and error display.

---

## Step 3 — Database Migration (`database_helper.dart`)

- Bump `_databaseVersion` from `1` → `2`
- Add `user_id TEXT NOT NULL DEFAULT ''` to `transactions` table CREATE statement
- Add `onUpgrade` handler:
  ```dart
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE transactions ADD COLUMN user_id TEXT NOT NULL DEFAULT ""');
    }
  }
  ```
- Pass `onUpgrade: _onUpgrade` to `openDatabase()`
- Add index: `CREATE INDEX idx_transactions_user_id ON transactions(user_id)`

---

## Step 4 — Scope Transactions by User (`sqlite_transaction_repository.dart`)

All queries gain a `userId` parameter:

| Method | Change |
|--------|--------|
| `getTransactions(userId)` | Add `WHERE user_id = ?` |
| `addTransaction(userId, tx)` | Store `user_id` in insert map |
| `updateTransaction(userId, tx)` | Add `AND user_id = ?` to WHERE |
| `deleteTransaction(userId, id)` | Add `AND user_id = ?` to WHERE |
| `getTransactionsInRange(userId, ...)` | Add `AND user_id = ?` |
| `getTransactionsByDateRange(userId, ...)` | Add `AND user_id = ?` |
| `searchTransactions(userId, ...)` | Add `AND user_id = ?` |
| `getTransactionStats(userId)` | Add `WHERE user_id = ?` |

The abstract interface `transaction_repository.dart` gains `userId` on all method signatures.

---

## Step 5 — Wire Auth into App (`main.dart`)

- Add `await Firebase.initializeApp()` before `runApp()`
- Add `AuthBloc` to `MultiBlocProvider`
- Replace `initialRoute` with a top-level `BlocBuilder<AuthBloc, AuthState>` auth gate:
  - `AuthAuthenticated` → show `MaterialApp` routing to `HomePage`, userId passed via BLoC events
  - `AuthUnauthenticated` / `AuthInitial` → show `LoginPage`
  - `AuthLoading` → show splash/loading indicator
- On sign-out: call `DatabaseService.clearTransactions()` then `AuthRepository.signOut()`

---

## Step 6 — Router Update (`app_router.dart`)
Add `login = '/login'` route constant and `LoginPage` mapping.

---

## Step 7 — Pass `userId` Through BLoC Events

`TransactionBloc` events updated:
- `LoadTransactions(userId)`
- `AddTransaction(userId, ...)`
- `EditTransaction(userId, ...)`
- `DeleteTransaction(userId, id)`

`SummaryBloc` and `StatisticsBloc` similarly receive `userId` so repository calls are scoped.

---

## Files Modified / Created

| Action | File |
|--------|------|
| CREATE | `lib/features/auth/domain/entities/app_user.dart` |
| CREATE | `lib/features/auth/domain/repositories/auth_repository.dart` |
| CREATE | `lib/features/auth/data/repositories/firebase_auth_repository.dart` |
| CREATE | `lib/features/auth/presentation/bloc/auth_bloc.dart` |
| CREATE | `lib/features/auth/presentation/bloc/auth_event.dart` |
| CREATE | `lib/features/auth/presentation/bloc/auth_state.dart` |
| CREATE | `lib/features/auth/presentation/pages/login_page.dart` |
| MODIFY | `pubspec.yaml` |
| MODIFY | `lib/core/database/database_helper.dart` |
| MODIFY | `lib/features/transaction/domain/repositories/transaction_repository.dart` |
| MODIFY | `lib/features/transaction/data/repositories/sqlite_transaction_repository.dart` |
| MODIFY | `lib/features/transaction/presentation/bloc/transaction_bloc.dart` |
| MODIFY | `lib/features/transaction/presentation/bloc/transaction_event.dart` |
| MODIFY | `lib/features/home/presentation/bloc/summary_bloc.dart` |
| MODIFY | `lib/features/statistics/presentation/bloc/statistics_bloc.dart` |
| MODIFY | `lib/core/router/app_router.dart` |
| MODIFY | `lib/main.dart` |
| MANUAL | `ios/Runner/Info.plist` (REVERSED_CLIENT_ID URL scheme) |
| MANUAL | `ios/Runner/GoogleService-Info.plist` (download from Firebase console) |
| MANUAL | `android/app/google-services.json` (download from Firebase console) |

---

## Verification
1. Complete Step 0 (Firebase console setup) first — no code will work without it
2. `flutter pub get`
3. `flutter run --flavor staging` (iOS) — Google sign-in sheet appears
4. Sign in → redirected to `HomePage`
5. Add a transaction → stored in SQLite with signed-in user's UID
6. Sign out → local transactions cleared, `LoginPage` shown
7. Sign in with a different Google account → empty transaction list (correctly isolated)
