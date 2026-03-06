import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/router/app_router.dart';
import '../../../settings/domain/app_currency.dart';
import '../../../settings/presentation/bloc/settings_bloc.dart';
import '../../../settings/presentation/bloc/settings_state.dart';
import '../bloc/budget_bloc.dart';
import '../widgets/bucket_card.dart';

class BudgetStatusPage extends StatefulWidget {
  const BudgetStatusPage({super.key});

  @override
  State<BudgetStatusPage> createState() => _BudgetStatusPageState();
}

class _BudgetStatusPageState extends State<BudgetStatusPage> {
  late int _month;
  late int _year;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _month = now.month;
    _year = now.year;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BudgetBloc>().add(
            LoadBudgetForPeriod(month: _month, year: _year),
          );
    });
  }

  void _loadPeriod(int month, int year) {
    setState(() {
      _month = month;
      _year = year;
    });
    context.read<BudgetBloc>().add(
          LoadBudgetForPeriod(month: month, year: year),
        );
  }

  String _periodLabel(int month, int year) {
    const months = [
      '', 'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    return '${months[month]} $year';
  }

  String _formatIncome(int cents, String symbol) {
    final dollars = cents / 100;
    return '$symbol${dollars.toStringAsFixed(2)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Budget'),
        actions: [
          BlocBuilder<BudgetBloc, BudgetState>(
            builder: (context, state) {
              final isLoaded = state is BudgetLoaded;
              final incomeCents = isLoaded ? state.plan.totalIncome : null;
              return IconButton(
                icon: Icon(isLoaded ? Icons.edit_outlined : Icons.add),
                tooltip: isLoaded ? 'Edit Budget' : 'New Budget',
                onPressed: () {
                  Navigator.pushNamed(
                    context,
                    AppRouter.budgetNew,
                    arguments: {
                      'month': _month,
                      'year': _year,
                      if (incomeCents != null) 'incomeCents': incomeCents,
                    },
                  ).then((_) {
                    if (mounted) {
                      context.read<BudgetBloc>().add(
                            LoadBudgetForPeriod(month: _month, year: _year),
                          );
                    }
                  });
                },
              );
            },
          ),
        ],
      ),
      body: BlocBuilder<BudgetBloc, BudgetState>(
        builder: (context, state) {
          if (state is BudgetLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is BudgetError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(state.message),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => context.read<BudgetBloc>().add(
                          LoadBudgetForPeriod(month: _month, year: _year),
                        ),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (state is BudgetNoPlan) {
            return _NoPlanView(
              month: state.month,
              year: state.year,
              periodLabel: _periodLabel(state.month, state.year),
              onPrev: () {
                final dt = DateTime(state.year, state.month - 1);
                _loadPeriod(dt.month, dt.year);
              },
              onNext: () {
                final dt = DateTime(state.year, state.month + 1);
                _loadPeriod(dt.month, dt.year);
              },
            );
          }

          if (state is BudgetLoaded) {
            final status = state.status;
            final symbol = context.select<SettingsBloc, String>(
              (b) => b.state is SettingsLoaded
                  ? (b.state as SettingsLoaded).currency.symbol
                  : AppCurrency.usd.symbol,
            );
            return ListView(
              children: [
                // Period header
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.chevron_left),
                        onPressed: () {
                          final dt = DateTime(state.plan.periodYear, state.plan.periodMonth - 1);
                          _loadPeriod(dt.month, dt.year);
                        },
                      ),
                      Column(
                        children: [
                          Text(
                            _periodLabel(state.plan.periodMonth, state.plan.periodYear),
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          Text(
                            'Income: ${_formatIncome(state.plan.totalIncome, symbol)}',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withOpacity(0.6),
                                ),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.chevron_right),
                        onPressed: () {
                          final dt = DateTime(state.plan.periodYear, state.plan.periodMonth + 1);
                          _loadPeriod(dt.month, dt.year);
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                ...status.buckets.map((b) => BucketCard(bucket: b)),
                const SizedBox(height: 16),
              ],
            );
          }

          // BudgetInitial — loading in progress via initState
          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }
}

class _NoPlanView extends StatelessWidget {
  final int month;
  final int year;
  final String periodLabel;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  const _NoPlanView({
    required this.month,
    required this.year,
    required this.periodLabel,
    required this.onPrev,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(icon: const Icon(Icons.chevron_left), onPressed: onPrev),
              Text(
                periodLabel,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              IconButton(icon: const Icon(Icons.chevron_right), onPressed: onNext),
            ],
          ),
        ),
        const Spacer(),
        const Icon(Icons.account_balance_wallet_outlined, size: 64, color: Colors.grey),
        const SizedBox(height: 16),
        Text(
          'No budget for $periodLabel',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        const Text(
          'Create a budget plan to track spending\nagainst your income.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey),
        ),
        const SizedBox(height: 24),
        ElevatedButton.icon(
          icon: const Icon(Icons.add),
          label: const Text('Create Budget'),
          onPressed: () async {
            await Navigator.pushNamed(
              context,
              AppRouter.budgetNew,
              arguments: {'month': month, 'year': year},
            );
            if (context.mounted) {
              context.read<BudgetBloc>().add(
                    LoadBudgetForPeriod(month: month, year: year),
                  );
            }
          },
        ),
        const Spacer(),
      ],
    );
  }
}