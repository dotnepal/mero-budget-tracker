import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/category.dart';
import '../bloc/category_bloc.dart';
import '../bloc/category_event.dart';
import '../bloc/category_state.dart';
import '../widgets/category_form_dialog.dart';

class CategorySettingsPage extends StatefulWidget {
  const CategorySettingsPage({super.key});

  @override
  State<CategorySettingsPage> createState() => _CategorySettingsPageState();
}

class _CategorySettingsPageState extends State<CategorySettingsPage> {
  @override
  void initState() {
    super.initState();
    context.read<CategoryBloc>().add(const LoadCategories());
  }

  Future<void> _addCategory() async {
    final category = await showCategoryFormDialog(context);
    if (category != null && mounted) {
      context.read<CategoryBloc>().add(AddCategory(category));
    }
  }

  Future<void> _editCategory(Category category) async {
    final updatedCategory = await showCategoryFormDialog(
      context,
      category: category,
    );
    if (updatedCategory != null && mounted) {
      context.read<CategoryBloc>().add(UpdateCategory(updatedCategory));
    }
  }

  Future<void> _deleteCategory(Category category) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Category'),
        content: Text(
          'Are you sure you want to delete "${category.name}"? '
          'Transactions using this category will have their category removed.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      context.read<CategoryBloc>().add(DeleteCategory(category.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Categories'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addCategory,
        child: const Icon(Icons.add),
      ),
      body: BlocBuilder<CategoryBloc, CategoryState>(
        builder: (context, state) {
          if (state is CategoryLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is CategoryError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 48,
                    color: theme.colorScheme.error,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    state.message,
                    style: theme.textTheme.bodyLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () {
                      context.read<CategoryBloc>().add(const LoadCategories());
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (state is CategoryLoaded) {
            final categories = state.categories;

            if (categories.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.category_outlined,
                      size: 64,
                      color: theme.colorScheme.outline,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No categories yet',
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tap + to add a category',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.outline,
                      ),
                    ),
                  ],
                ),
              );
            }

            // Group categories by type
            final expenseCategories = categories
                .where((c) => c.type == CategoryType.expense)
                .toList();
            final incomeCategories = categories
                .where((c) => c.type == CategoryType.income)
                .toList();

            return ListView(
              padding: const EdgeInsets.only(bottom: 80),
              children: [
                if (expenseCategories.isNotEmpty) ...[
                  _SectionHeader(
                    title: 'Expense Categories',
                    count: expenseCategories.length,
                  ),
                  ...expenseCategories.map(
                    (category) => _CategoryTile(
                      category: category,
                      onEdit: () => _editCategory(category),
                      onDelete: () => _deleteCategory(category),
                    ),
                  ),
                ],
                if (incomeCategories.isNotEmpty) ...[
                  _SectionHeader(
                    title: 'Income Categories',
                    count: incomeCategories.length,
                  ),
                  ...incomeCategories.map(
                    (category) => _CategoryTile(
                      category: category,
                      onEdit: () => _editCategory(category),
                      onDelete: () => _deleteCategory(category),
                    ),
                  ),
                ],
              ],
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final int count;

  const _SectionHeader({
    required this.title,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              count.toString(),
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  final Category category;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _CategoryTile({
    required this.category,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final categoryColor = Color(category.color);

    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: categoryColor.withValues(alpha: 0.2),
          shape: BoxShape.circle,
        ),
        child: Icon(
          IconData(category.icon, fontFamily: 'MaterialIcons'),
          color: categoryColor,
          size: 20,
        ),
      ),
      title: Text(category.name),
      subtitle: category.isSystem
          ? Text(
              'System category',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.outline,
              ),
            )
          : null,
      trailing: category.isSystem
          ? Icon(
              Icons.lock_outline,
              size: 20,
              color: theme.colorScheme.outline,
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: onEdit,
                  tooltip: 'Edit',
                ),
                IconButton(
                  icon: Icon(
                    Icons.delete_outline,
                    color: theme.colorScheme.error,
                  ),
                  onPressed: onDelete,
                  tooltip: 'Delete',
                ),
              ],
            ),
    );
  }
}
