# SQLite Removal Specification

## Overview

This document provides a detailed specification for removing the SQLite database integration from the Mero Budget Tracker Flutter application. The removal will transition the app from persistent storage to in-memory storage using the existing `InMemoryTransactionRepository`.

## Current SQLite Integration

The application currently has a fully functional SQLite database implementation with the following components:

### Core Database Layer
- **DatabaseHelper** (`lib/core/database/database_helper.dart`) - Low-level SQLite operations, schema management, and database lifecycle
- **DatabaseService** (`lib/core/database/database_service.dart`) - High-level business logic operations including export/import, statistics, and maintenance
- **MigrationManager** (`lib/core/database/migration_manager.dart`) - Database schema version management and migrations

### Data Layer
- **SqliteTransactionRepository** (`lib/features/transaction/data/repositories/sqlite_transaction_repository.dart`) - SQLite implementation of the transaction repository with CRUD operations, pagination, filtering, and statistics

### UI Layer
- **DatabaseSettingsPage** (`lib/features/settings/presentation/pages/database_settings_page.dart`) - Settings page providing database backup, export, maintenance, and reset functionality

### Dependencies
- `sqflite: ^2.3.0` - SQLite database engine for Flutter
- `path: ^1.9.0` - Path manipulation utilities
- `path_provider: ^2.1.1` - File system access for database location

### Documentation
- `docs/sqlite-database.md` - Comprehensive SQLite implementation documentation

## Removal Strategy

### Phase 1: Core Database Files

**Action**: Delete all SQLite-specific database infrastructure files.

**Files to Remove**:
1. `lib/core/database/database_helper.dart`
2. `lib/core/database/database_service.dart`
3. `lib/core/database/migration_manager.dart`

**Note**: The `lib/core/database/` directory will be preserved (empty) for potential future database implementations.

**Impact**:
- Loss of all SQLite database operations
- Loss of database initialization, schema management, and migrations
- Loss of backup/restore, export/import, and maintenance capabilities

### Phase 2: Repository Layer

**Action**: Remove SQLite repository implementation and switch to in-memory repository.

**Files to Remove**:
1. `lib/features/transaction/data/repositories/sqlite_transaction_repository.dart`

**Files to Modify**:
1. `lib/main.dart`
   - Remove import: `import 'core/database/database_service.dart';`
   - Remove import: `import 'features/transaction/data/repositories/sqlite_transaction_repository.dart';`
   - Add import: `import 'features/transaction/data/repositories/in_memory_transaction_repository.dart';`
   - Remove database initialization from `main()` function:
     ```dart
     // DELETE THESE LINES:
     final databaseService = DatabaseService();
     await databaseService.initialize();
     ```
   - Change repository instantiation in `MyApp.build()`:
     ```dart
     // BEFORE:
     final transactionRepository = SqliteTransactionRepository();
     
     // AFTER:
     final transactionRepository = InMemoryTransactionRepository();
     ```

**Impact**:
- All transactions will be stored in memory only
- Data will be lost when the app is closed or restarted
- No persistence between app sessions

### Phase 3: UI Layer

**Action**: Remove database settings page and associated routing.

**Files to Remove**:
1. `lib/features/settings/presentation/pages/database_settings_page.dart`

**Files to Modify**:
1. `lib/core/router/app_router.dart`
   - Remove import: `import '../../features/settings/presentation/pages/database_settings_page.dart';`
   - Remove route constant: `static const String databaseSettings = '/database-settings';`
   - Remove route case from `onGenerateRoute()`:
     ```dart
     // DELETE THIS CASE:
     case databaseSettings:
       return MaterialPageRoute(
         builder: (_) => const DatabaseSettingsPage(),
       );
     ```

**Impact**:
- Loss of database settings UI
- Loss of backup/restore functionality
- Loss of data export/import as JSON
- Loss of database statistics display
- Loss of sample data insertion
- Loss of database maintenance tools
- Loss of clear/reset database operations

**Additional Considerations**:
- Check if any other UI components navigate to `/database-settings` route
- Check if settings menu has links to database settings page
- Remove or update any documentation/help text referencing database features

### Phase 4: Dependencies

**Action**: Remove SQLite and file system dependencies from `pubspec.yaml`.

**Dependencies to Remove**:
```yaml
# DELETE THESE LINES:
sqflite: ^2.3.0
path: ^1.9.0
path_provider: ^2.1.1
```

**Verification**:
- `sqflite` - Only used for SQLite operations, safe to remove
- `path` - Only used with SQLite database paths, safe to remove
- `path_provider` - Only used in `database_settings_page.dart` for export directory, safe to remove

**Post-Removal Actions**:
```bash
flutter pub get
```

### Phase 5: Documentation

**Action**: Remove or archive SQLite-specific documentation.

**Files to Remove**:
1. `docs/sqlite-database.md`

**Alternative**: Instead of deleting, consider:
- Moving to `docs/archive/sqlite-database.md` for historical reference
- Adding a note at the top indicating the feature was removed
- Keeping for reference if SQLite is re-implemented in the future

## Fallback Implementation

### InMemoryTransactionRepository

The app already has a working in-memory repository implementation at:
`lib/features/transaction/data/repositories/in_memory_transaction_repository.dart`

**Features**:
- ✅ Full CRUD operations (Create, Read, Update, Delete)
- ✅ Pagination support (limit and offset)
- ✅ Date range filtering
- ✅ Sorting by date (newest first)
- ✅ Implements the same `TransactionRepository` interface

**Limitations**:
- ❌ No data persistence (all data lost on app restart)
- ❌ No backup/restore capabilities
- ❌ No export/import functionality
- ❌ No database statistics
- ❌ No advanced filtering (by type, category, search)
- ❌ No transaction statistics calculation

**Implementation Details**:
- Uses a simple `List<Transaction>` for storage
- Simulates network delay with 500ms delays
- Automatically sorts transactions by date
- Handles pagination with sublist operations

## Impact Analysis

### Data Persistence
- **Before**: All transactions persisted in SQLite database across app sessions
- **After**: All transactions stored in memory, lost when app closes
- **User Impact**: HIGH - Users will lose all transaction history on app restart

### Features Lost
1. **Database Backup/Restore** - Users cannot create or restore database backups
2. **Data Export/Import** - Users cannot export data as JSON or import from backups
3. **Database Statistics** - No visibility into database size, transaction counts, etc.
4. **Sample Data** - Cannot insert sample transactions for testing
5. **Database Maintenance** - No VACUUM, ANALYZE, or integrity checks
6. **Clear/Reset Operations** - No way to clear all data or reset database

### Features Retained
1. **Transaction Management** - Add, edit, delete transactions (in memory)
2. **Transaction List** - View all transactions sorted by date
3. **Pagination** - Load transactions in pages
4. **Date Filtering** - Filter transactions by date range
5. **BLoC State Management** - All state management remains functional

### Performance Impact
- **Positive**: Faster operations (no disk I/O)
- **Positive**: No database initialization delay on app startup
- **Negative**: All data loaded in memory (potential memory issues with large datasets)
- **Negative**: No indexes for optimized queries

### Code Complexity
- **Positive**: Simpler codebase without database layer
- **Positive**: Fewer dependencies to manage
- **Positive**: Easier testing with in-memory data
- **Negative**: Loss of advanced features may require reimplementation later

## Migration Path

### For Existing Users

If the app has existing users with SQLite data:

1. **Data Export** (before removal):
   - Provide a way for users to export their data before updating
   - Use the existing export functionality to save data as JSON
   - Store exported data in a user-accessible location

2. **Migration Notice**:
   - Display a warning to users about data loss
   - Provide instructions for data export
   - Consider a grace period before removing SQLite

3. **Data Import** (after removal):
   - If needed, implement a one-time JSON import feature
   - Allow users to manually re-enter critical transactions
   - Consider a cloud sync solution for future persistence

### For New Installations

- No migration needed
- App starts with empty in-memory repository
- Users understand data is not persisted (document in app description)

## Verification Steps

### 1. Dependency Verification
```bash
cd /Users/samundra/personal/flutter_playground/mero_budget_tracker
flutter pub get
```
Expected: No errors, all dependencies resolved

### 2. Static Analysis
```bash
flutter analyze
```
Expected: No errors, no import issues, no undefined references

### 3. Build Verification
```bash
# Android
flutter build apk --debug

# iOS (on macOS)
flutter build ios --debug --no-codesign

# macOS
flutter build macos --debug
```
Expected: Successful build on all platforms

### 4. Runtime Testing

**App Launch**:
- App launches without database initialization errors
- No error logs related to database

**Transaction Operations**:
- Add new transaction → Success
- Edit existing transaction → Success
- Delete transaction → Success
- View transaction list → Success
- Filter by date range → Success
- Pagination → Success

**Data Persistence**:
- Add transactions
- Close app
- Reopen app
- Verify transactions are GONE (expected behavior)

**Navigation**:
- Verify no broken links to `/database-settings`
- Verify settings page doesn't reference database features
- Verify no navigation errors

**Error Handling**:
- No crashes or exceptions
- No undefined method calls
- No import errors

## Rollback Plan

If issues arise after removal:

1. **Git Revert**:
   ```bash
   git revert <commit-hash>
   ```

2. **Manual Restoration**:
   - Restore deleted files from git history
   - Restore dependencies in `pubspec.yaml`
   - Run `flutter pub get`
   - Restore imports in `main.dart` and `app_router.dart`

3. **Database Reinitialization**:
   - Database will be recreated on first launch
   - Default categories will be inserted
   - Users start with empty database

## Future Considerations

### Alternative Persistence Solutions

If persistence is needed in the future:

1. **Shared Preferences** - For simple key-value storage
2. **Hive** - Fast, lightweight NoSQL database
3. **Isar** - High-performance NoSQL database for Flutter
4. **Cloud Firestore** - Cloud-based database with sync
5. **SQLite (re-implementation)** - Return to SQLite if needed

### Feature Additions

Consider implementing:
- Local JSON file storage for simple persistence
- Cloud backup/sync for cross-device access
- Export/import functionality without full database
- Settings persistence using shared preferences

## Summary

Removing SQLite integration involves:
- **Deleting 6 files** (3 core database, 1 repository, 1 UI page, 1 documentation)
- **Modifying 3 files** (main.dart, app_router.dart, pubspec.yaml)
- **Removing 3 dependencies** (sqflite, path, path_provider)
- **Preserving** the database directory structure

**Trade-offs**:
- ✅ Simpler codebase
- ✅ Faster operations
- ✅ Fewer dependencies
- ❌ No data persistence
- ❌ Loss of backup/export features
- ❌ Loss of database management tools

**Recommendation**: Only proceed with removal if:
1. Data persistence is not required for your use case
2. Users understand data will be lost on app restart
3. Advanced database features (backup, export, statistics) are not needed
4. You have a plan for future persistence if requirements change
