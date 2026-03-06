import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../features/settings/domain/app_currency.dart';
import '../../../../features/settings/presentation/bloc/settings_bloc.dart';
import '../../../../features/settings/presentation/bloc/settings_state.dart';
import '../../domain/entities/budget_status.dart';

class HealthBadge extends StatelessWidget {
  final BudgetHealth health;

  const HealthBadge({super.key, required this.health});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (health) {
      BudgetHealth.underBudget => ('Under Budget', Colors.green),
      BudgetHealth.onTrack => ('On Track', Colors.orange),
      BudgetHealth.overBudget => ('Over Budget', Colors.red),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class BucketCard extends StatelessWidget {
  final BucketStatus bucket;

  const BucketCard({
    super.key,
    required this.bucket,
  });

  String _fmt(int cents, String symbol) {
    final dollars = cents / 100;
    if (dollars == dollars.truncateToDouble()) {
      return '$symbol${dollars.toStringAsFixed(0)}';
    }
    return '$symbol${dollars.toStringAsFixed(2)}';
  }

  Color _bucketColor(String bucket) {
    return switch (bucket) {
      'NEEDS' => const Color(0xFF0984E3),
      'WANTS' => const Color(0xFF6C5CE7),
      'SAVINGS' => const Color(0xFF00B894),
      _ => Colors.grey,
    };
  }

  @override
  Widget build(BuildContext context) {
    final symbol = context.select<SettingsBloc, String>(
      (b) => b.state is SettingsLoaded
          ? (b.state as SettingsLoaded).currency.symbol
          : AppCurrency.usd.symbol,
    );
    final theme = Theme.of(context);
    final color = _bucketColor(bucket.bucket);
    final pct = bucket.percentUsed.clamp(0.0, 1.0);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${bucket.bucket} (${bucket.pct}%)',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                HealthBadge(health: bucket.health),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: pct,
                minHeight: 8,
                backgroundColor: color.withOpacity(0.15),
                valueColor: AlwaysStoppedAnimation<Color>(
                  bucket.health == BudgetHealth.overBudget
                      ? Colors.red
                      : color,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${_fmt(bucket.spent, symbol)} spent',
                  style: theme.textTheme.bodyMedium,
                ),
                Text(
                  '${_fmt(bucket.allocated, symbol)} allocated',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              bucket.remaining >= 0
                  ? '${_fmt(bucket.remaining, symbol)} remaining'
                  : '${_fmt(-bucket.remaining, symbol)} over budget',
              style: theme.textTheme.bodySmall?.copyWith(
                color: bucket.remaining >= 0
                    ? theme.colorScheme.onSurface.withOpacity(0.5)
                    : Colors.red,
              ),
            ),
          ],
        ),
      ),
    );
  }
}