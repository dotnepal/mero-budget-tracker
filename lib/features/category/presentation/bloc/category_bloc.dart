import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/repositories/category_repository.dart';
import 'category_event.dart';
import 'category_state.dart';

class CategoryBloc extends Bloc<CategoryEvent, CategoryState> {
  final CategoryRepository repository;

  CategoryBloc({
    required this.repository,
  }) : super(const CategoryInitial()) {
    on<LoadCategories>(_onLoadCategories);
    on<AddCategory>(_onAddCategory);
    on<UpdateCategory>(_onUpdateCategory);
    on<DeleteCategory>(_onDeleteCategory);
  }

  Future<void> _onLoadCategories(
    LoadCategories event,
    Emitter<CategoryState> emit,
  ) async {
    emit(const CategoryLoading());
    try {
      final categories = await repository.getCategories();
      emit(CategoryLoaded(categories));
    } catch (e) {
      debugPrint('Error loading categories: $e');
      emit(CategoryError('Failed to load categories: ${e.toString()}'));
    }
  }

  Future<void> _onAddCategory(
    AddCategory event,
    Emitter<CategoryState> emit,
  ) async {
    try {
      await repository.addCategory(event.category);
      add(const LoadCategories());
    } catch (e) {
      debugPrint('Error adding category: $e');
      emit(CategoryError('Failed to add category: ${e.toString()}'));
    }
  }

  Future<void> _onUpdateCategory(
    UpdateCategory event,
    Emitter<CategoryState> emit,
  ) async {
    try {
      await repository.updateCategory(event.category);
      add(const LoadCategories());
    } catch (e) {
      debugPrint('Error updating category: $e');
      emit(CategoryError('Failed to update category: ${e.toString()}'));
    }
  }

  Future<void> _onDeleteCategory(
    DeleteCategory event,
    Emitter<CategoryState> emit,
  ) async {
    try {
      await repository.deleteCategory(event.id);
      add(const LoadCategories());
    } catch (e) {
      debugPrint('Error deleting category: $e');
      emit(CategoryError('Failed to delete category: ${e.toString()}'));
    }
  }
}
