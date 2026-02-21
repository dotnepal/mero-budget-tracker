import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/category.dart';
import '../bloc/category_bloc.dart';
import '../bloc/category_event.dart';
import '../bloc/category_state.dart';

class CategoryChipSelector extends StatefulWidget {
  final String? selectedCategoryId;
  final ValueChanged<String?> onCategorySelected;

  const CategoryChipSelector({
    super.key,
    this.selectedCategoryId,
    required this.onCategorySelected,
  });

  @override
  State<CategoryChipSelector> createState() => _CategoryChipSelectorState();
}

class _CategoryChipSelectorState extends State<CategoryChipSelector> {
  @override
  void initState() {
    super.initState();
    // Load categories when widget is initialized
    context.read<CategoryBloc>().add(const LoadCategories());
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CategoryBloc, CategoryState>(
      builder: (context, state) {
        if (state is CategoryLoading) {
          return const SizedBox(
            height: 50,
            child: Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        }

        if (state is CategoryError) {
          return SizedBox(
            height: 50,
            child: Center(
              child: Text(
                'Failed to load categories',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                  fontSize: 12,
                ),
              ),
            ),
          );
        }

        if (state is CategoryLoaded) {
          final categories = state.categories;

          if (categories.isEmpty) {
            return const SizedBox(
              height: 50,
              child: Center(
                child: Text(
                  'No categories available',
                  style: TextStyle(fontSize: 12),
                ),
              ),
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Category',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 40,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: categories.length,
                  separatorBuilder: (context, index) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final category = categories[index];
                    final isSelected = widget.selectedCategoryId == category.id;

                    return _CategoryChip(
                      category: category,
                      isSelected: isSelected,
                      onTap: () {
                        widget.onCategorySelected(
                          isSelected ? null : category.id,
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          );
        }

        return const SizedBox.shrink();
      },
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final Category category;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.category,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final categoryColor = Color(category.color);
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? categoryColor : categoryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: categoryColor,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                IconData(category.icon, fontFamily: 'MaterialIcons'),
                size: 16,
                color: isSelected
                    ? _getContrastColor(categoryColor)
                    : categoryColor,
              ),
              const SizedBox(width: 6),
              Text(
                category.name,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: isSelected
                      ? _getContrastColor(categoryColor)
                      : theme.colorScheme.onSurface,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getContrastColor(Color color) {
    final luminance = color.computeLuminance();
    return luminance > 0.5 ? Colors.black : Colors.white;
  }
}
