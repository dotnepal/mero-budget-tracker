import '../entities/category.dart';

abstract class CategoryRepository {
  Future<List<Category>> getCategories();

  Future<List<Category>> getCategoriesByType(CategoryType type);

  Future<Category?> getCategoryById(String id);

  Future<Category> addCategory(Category category);

  Future<Category> updateCategory(Category category);

  Future<void> deleteCategory(String id);
}
