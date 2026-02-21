import 'package:flutter/material.dart';

import '../../domain/entities/category.dart';

class CategoryFormDialog extends StatefulWidget {
  final Category? category;

  const CategoryFormDialog({
    super.key,
    this.category,
  });

  @override
  State<CategoryFormDialog> createState() => _CategoryFormDialogState();
}

class _CategoryFormDialogState extends State<CategoryFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late CategoryType _type;
  late int _selectedColor;

  static const List<int> _availableColors = [
    0xFFFF6B6B, // Red
    0xFFFF8E72, // Coral
    0xFFFFD93D, // Yellow
    0xFF95E77E, // Light Green
    0xFF4ECDC4, // Teal
    0xFF45B7D1, // Sky Blue
    0xFF3498DB, // Blue
    0xFF6C5CE7, // Purple
    0xFF9B59B6, // Violet
    0xFFFF6B9D, // Pink
    0xFFE74C3C, // Dark Red
    0xFFF39C12, // Orange
    0xFF27AE60, // Green
    0xFF16A085, // Dark Teal
    0xFF2980B9, // Dark Blue
    0xFF8E44AD, // Dark Purple
    0xFF95A5A6, // Gray
    0xFF34495E, // Dark Gray
  ];

  bool get _isEditing => widget.category != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.category?.name ?? '');
    _type = widget.category?.type ?? CategoryType.expense;
    _selectedColor = widget.category?.color ?? _availableColors.first;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      final category = Category(
        id: widget.category?.id ?? '',
        name: _nameController.text.trim(),
        icon: 0xe468, // Default icon (category)
        color: _selectedColor,
        type: _type,
        isSystem: false,
      );
      Navigator.of(context).pop(category);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: Text(_isEditing ? 'Edit Category' : 'Add Category'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Category Name',
                  hintText: 'Enter category name',
                  border: OutlineInputBorder(),
                ),
                textCapitalization: TextCapitalization.words,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a category name';
                  }
                  if (value.trim().length > 30) {
                    return 'Name must be less than 30 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Text(
                'Type',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              SegmentedButton<CategoryType>(
                segments: const [
                  ButtonSegment(
                    value: CategoryType.expense,
                    label: Text('Expense'),
                  ),
                  ButtonSegment(
                    value: CategoryType.income,
                    label: Text('Income'),
                  ),
                ],
                selected: {_type},
                onSelectionChanged: (Set<CategoryType> selection) {
                  setState(() {
                    _type = selection.first;
                  });
                },
              ),
              const SizedBox(height: 16),
              Text(
                'Color',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              _ColorPicker(
                selectedColor: _selectedColor,
                colors: _availableColors,
                onColorSelected: (color) {
                  setState(() {
                    _selectedColor = color;
                  });
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _submit,
          child: Text(_isEditing ? 'Update' : 'Add'),
        ),
      ],
    );
  }
}

class _ColorPicker extends StatelessWidget {
  final int selectedColor;
  final List<int> colors;
  final ValueChanged<int> onColorSelected;

  const _ColorPicker({
    required this.selectedColor,
    required this.colors,
    required this.onColorSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: colors.map((color) {
        final isSelected = color == selectedColor;
        return GestureDetector(
          onTap: () => onColorSelected(color),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Color(color),
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Colors.transparent,
                width: 3,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: Color(color).withValues(alpha: 0.4),
                        blurRadius: 8,
                        spreadRadius: 2,
                      ),
                    ]
                  : null,
            ),
            child: isSelected
                ? Icon(
                    Icons.check,
                    size: 18,
                    color: _getContrastColor(Color(color)),
                  )
                : null,
          ),
        );
      }).toList(),
    );
  }

  Color _getContrastColor(Color color) {
    final luminance = color.computeLuminance();
    return luminance > 0.5 ? Colors.black : Colors.white;
  }
}

Future<Category?> showCategoryFormDialog(
  BuildContext context, {
  Category? category,
}) {
  return showDialog<Category>(
    context: context,
    builder: (context) => CategoryFormDialog(category: category),
  );
}
