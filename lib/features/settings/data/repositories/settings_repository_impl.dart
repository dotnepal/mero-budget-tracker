import 'package:sqflite/sqflite.dart';

import '../../../../core/database/database_helper.dart';
import '../../domain/entities/app_settings.dart';
import '../../domain/repositories/settings_repository.dart';

class SettingsRepositoryImpl implements SettingsRepository {
  final DatabaseHelper _db;
  static const _currencyKey = 'currency_code';

  SettingsRepositoryImpl(this._db);

  @override
  Future<AppSettings> loadSettings() async {
    final db = await _db.database;
    final rows = await db.query(
      DatabaseHelper.tablePreferences,
      where: 'key = ?',
      whereArgs: [_currencyKey],
    );
    final code = rows.isNotEmpty ? rows.first['value'] as String : 'USD';
    return AppSettings(currencyCode: code);
  }

  @override
  Future<void> saveCurrencyCode(String code) async {
    final db = await _db.database;
    await db.insert(
      DatabaseHelper.tablePreferences,
      {
        'key': _currencyKey,
        'value': code,
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}
