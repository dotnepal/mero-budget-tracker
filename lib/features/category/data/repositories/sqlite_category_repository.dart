import 'package:sqflite/sqflite.dart';

import '../../../../core/database/database_helper.dart';
import '../../domain/entities/category.dart';
import '../../domain/repositories/category_repository.dart';

class SqliteCategoryRepository implements CategoryRepository {
  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;

  @override
  Future<List<Category>> getCategories() async {
    final db = await _databaseHelper.database;

    final List<Map<String, dynamic>> maps = await db.query(
      DatabaseHelper.tableCategories,
      orderBy: '${DatabaseHelper.columnCategoryIsSystem} DESC, ${DatabaseHelper.columnCategoryName} ASC',
    );

    return List.generate(maps.length, (i) {
      return _mapToCategory(maps[i]);
    });
  }

  @override
  Future<List<Category>> getCategoriesByType(CategoryType type) async {
    final db = await _databaseHelper.database;

    final typeString = type == CategoryType.income ? 'income' : 'expense';

    final List<Map<String, dynamic>> maps = await db.query(
      DatabaseHelper.tableCategories,
      where: '${DatabaseHelper.columnCategoryType} = ?',
      whereArgs: [typeString],
      orderBy: '${DatabaseHelper.columnCategoryIsSystem} DESC, ${DatabaseHelper.columnCategoryName} ASC',
    );

    return List.generate(maps.length, (i) {
      return _mapToCategory(maps[i]);
    });
  }

  @override
  Future<Category?> getCategoryById(String id) async {
    final db = await _databaseHelper.database;

    final List<Map<String, dynamic>> maps = await db.query(
      DatabaseHelper.tableCategories,
      where: '${DatabaseHelper.columnId} = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (maps.isEmpty) {
      return null;
    }

    return _mapToCategory(maps.first);
  }

  @override
  Future<Category> addCategory(Category category) async {
    final db = await _databaseHelper.database;
    final now = DateTime.now().millisecondsSinceEpoch;

    final id = 'cat_custom_${DateTime.now().millisecondsSinceEpoch}_${_generateRandomString(4)}';

    final categoryWithId = category.copyWith(id: id, isSystem: false);

    await db.insert(
      DatabaseHelper.tableCategories,
      {
        DatabaseHelper.columnId: categoryWithId.id,
        DatabaseHelper.columnCategoryName: categoryWithId.name,
        DatabaseHelper.columnCategoryIcon: categoryWithId.icon,
        DatabaseHelper.columnCategoryColor: categoryWithId.color,
        DatabaseHelper.columnCategoryType: categoryWithId.type == CategoryType.income ? 'income' : 'expense',
        DatabaseHelper.columnCategoryIsSystem: 0,
        DatabaseHelper.columnBudgetBucket: categoryWithId.budgetBucket,
        DatabaseHelper.columnCreatedAt: now,
        DatabaseHelper.columnUpdatedAt: now,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    return categoryWithId;
  }

  @override
  Future<Category> updateCategory(Category category) async {
    final db = await _databaseHelper.database;

    // Check if it's a system category
    final existing = await getCategoryById(category.id);
    if (existing != null && existing.isSystem) {
      throw Exception('Cannot modify system categories');
    }

    final now = DateTime.now().millisecondsSinceEpoch;

    await db.update(
      DatabaseHelper.tableCategories,
      {
        DatabaseHelper.columnCategoryName: category.name,
        DatabaseHelper.columnCategoryIcon: category.icon,
        DatabaseHelper.columnCategoryColor: category.color,
        DatabaseHelper.columnCategoryType: category.type == CategoryType.income ? 'income' : 'expense',
        DatabaseHelper.columnBudgetBucket: category.budgetBucket,
        DatabaseHelper.columnUpdatedAt: now,
      },
      where: '${DatabaseHelper.columnId} = ? AND ${DatabaseHelper.columnCategoryIsSystem} = 0',
      whereArgs: [category.id],
    );

    return category;
  }

  @override
  Future<void> deleteCategory(String id) async {
    final db = await _databaseHelper.database;

    // Check if it's a system category
    final existing = await getCategoryById(id);
    if (existing != null && existing.isSystem) {
      throw Exception('Cannot delete system categories');
    }

    await db.delete(
      DatabaseHelper.tableCategories,
      where: '${DatabaseHelper.columnId} = ? AND ${DatabaseHelper.columnCategoryIsSystem} = 0',
      whereArgs: [id],
    );
  }

  Category _mapToCategory(Map<String, dynamic> map) {
    return Category(
      id: map[DatabaseHelper.columnId],
      name: map[DatabaseHelper.columnCategoryName],
      icon: map[DatabaseHelper.columnCategoryIcon] ?? 0xe468, // default icon
      color: map[DatabaseHelper.columnCategoryColor] ?? 0xFFA8A8A8, // default color
      type: map[DatabaseHelper.columnCategoryType] == 'income'
          ? CategoryType.income
          : CategoryType.expense,
      isSystem: map[DatabaseHelper.columnCategoryIsSystem] == 1,
      budgetBucket: map[DatabaseHelper.columnBudgetBucket] as String?,
    );
  }

  String _generateRandomString(int length) {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final now = DateTime.now();
    int seed = now.millisecondsSinceEpoch;

    String result = '';
    for (int i = 0; i < length; i++) {
      seed = (seed * 1103515245 + 12345) % (1 << 32);
      result += chars[seed % chars.length];
    }
    return result;
  }
}
