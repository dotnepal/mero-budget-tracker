import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../domain/entities/transaction.dart';

class TransactionTile extends StatelessWidget {
  const TransactionTile({
    super.key,
    required this.transaction,
    required this.onEdit,
    required this.onDelete,
  });

  final Transaction transaction;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isIncome = transaction.type == TransactionType.income;
    final currencyFormat = NumberFormat.currency(symbol: '\$');
    
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: (isIncome ? Colors.green : Colors.red).withOpacity(0.2),
        child: Icon(
          isIncome ? Icons.arrow_downward : Icons.arrow_upward,
          color: isIncome ? Colors.green : Colors.red,
        ),
      ),
      title: Text(
        transaction.description,
        style: theme.textTheme.titleMedium,
      ),
      subtitle: Text(
        DateFormat('MMM dd, yyyy').format(transaction.date),
        style: theme.textTheme.bodySmall,
      ),
      trailing: Text(
        currencyFormat.format(transaction.amount),
        style: theme.textTheme.titleMedium?.copyWith(
          color: isIncome ? Colors.green : Colors.red,
          fontWeight: FontWeight.bold,
        ),
      ),
      onTap: () {
        // Show transaction details in a bottom sheet
        showModalBottomSheet(
          context: context,
          builder: (context) => TransactionDetailsSheet(
            transaction: transaction,
            onEdit: onEdit,
            onDelete: onDelete,
          ),
        );
      },
    );
  }
}

class TransactionDetailsSheet extends StatelessWidget {
  const TransactionDetailsSheet({
    super.key,
    required this.transaction,
    required this.onEdit,
    required this.onDelete,
  });

  final Transaction transaction;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isIncome = transaction.type == TransactionType.income;
    final currencyFormat = NumberFormat.currency(symbol: '\$');

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Transaction Details',
                style: theme.textTheme.titleLarge,
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () {
                  Navigator.of(context).pop();
                  onEdit();
                },
              ),
              IconButton(
                icon: const Icon(Icons.delete),
                color: theme.colorScheme.error,
                onPressed: () async {
                  final shouldDelete = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Delete Transaction'),
                      content: const Text(
                        'Are you sure you want to delete this transaction?',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          child: const Text('Delete'),
                        ),
                      ],
                    ),
                  );
                  if (shouldDelete == true) {
                    Navigator.of(context).pop();
                    onDelete();
                  }
                },
              ),
            ],
          ),
          const Divider(),
          const SizedBox(height: 16),
          Row(
            children: [
              CircleAvatar(
                backgroundColor: (isIncome ? Colors.green : Colors.red)
                    .withOpacity(0.2),
                child: Icon(
                  isIncome ? Icons.arrow_downward : Icons.arrow_upward,
                  color: isIncome ? Colors.green : Colors.red,
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    transaction.description,
                    style: theme.textTheme.titleMedium,
                  ),
                  Text(
                    DateFormat('MMMM dd, yyyy').format(transaction.date),
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
              const Spacer(),
              Text(
                currencyFormat.format(transaction.amount),
                style: theme.textTheme.titleLarge?.copyWith(
                  color: isIncome ? Colors.green : Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          if (transaction.category != null) ...[
            const SizedBox(height: 16),
            Text(
              'Category',
              style: theme.textTheme.titleSmall,
            ),
            const SizedBox(height: 4),
            Text(
              transaction.category!,
              style: theme.textTheme.bodyMedium,
            ),
          ],
          if (transaction.note != null) ...[
            const SizedBox(height: 16),
            Text(
              'Note',
              style: theme.textTheme.titleSmall,
            ),
            const SizedBox(height: 4),
            Text(
              transaction.note!,
              style: theme.textTheme.bodyMedium,
            ),
          ],
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}