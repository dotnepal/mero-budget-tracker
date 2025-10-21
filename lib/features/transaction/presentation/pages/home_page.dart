import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/transaction.dart';
import '../bloc/transaction_bloc.dart';
import '../widgets/transaction_list_view.dart';
import '../widgets/transaction_loading_view.dart';
import '../widgets/transaction_error_view.dart';
import '../widgets/transaction_empty_view.dart';
import '../widgets/add_transaction_sheet.dart';
import '../widgets/edit_transaction_sheet.dart';
import '../../../../core/router/app_router.dart';
import '../../../home/presentation/bloc/summary_bloc.dart';
import '../../../home/presentation/bloc/summary_event.dart';
import '../../../home/presentation/bloc/summary_state.dart';
import '../../../home/presentation/widgets/summary_cards.dart';
import '../../../home/presentation/widgets/summary_cards_loading.dart';
import '../../../home/presentation/widgets/summary_cards_error.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
    // Use WidgetsBinding to ensure context is ready
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TransactionBloc>().add(const LoadTransactions());

      // Load current month summary
      final now = DateTime.now();
      context.read<SummaryBloc>().add(LoadMonthlySummary(
        year: now.year,
        month: now.month,
      ));
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<TransactionBloc, TransactionState>(
      listener: (context, state) {
        // Auto-refresh summary when transactions change
        if (state is TransactionLoaded) {
          context.read<SummaryBloc>().add(const RefreshMonthlySummary());
        }

        if (state is TransactionError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Mero Budget Tracker'),
          actions: [
            IconButton(
              icon: const Icon(Icons.analytics_outlined),
              onPressed: () => Navigator.pushNamed(context, AppRouter.statistics),
              tooltip: 'View Statistics',
            ),
            IconButton(
              icon: const Icon(Icons.filter_list),
              onPressed: () {
                // TODO: Show filter options
              },
            ),
            IconButton(
              icon: const Icon(Icons.sort),
              onPressed: () {
                // TODO: Show sort options
              },
            ),
          ],
        ),
        body: Column(
          children: [
            // Existing transaction list
            Expanded(
              child: BlocBuilder<TransactionBloc, TransactionState>(
                builder: (context, state) {
                  if (state is TransactionLoading) {
                    return const TransactionLoadingView();
                  }

                  if (state is TransactionError) {
                    return TransactionErrorView(
                      message: state.message,
                      onRetry: () => context.read<TransactionBloc>()
                        .add(const LoadTransactions()),
                    );
                  }

                  if (state is TransactionLoaded) {
                    return TransactionListView(
                      transactions: state.transactions,
                      onDelete: (id) => context.read<TransactionBloc>()
                        .add(DeleteTransaction(id)),
                      onEdit: (transaction) => _showEditSheet(context, transaction),
                    );
                  }

                  return const TransactionEmptyView();
                },
              ),
            ),

            // Summary cards section
            BlocBuilder<SummaryBloc, SummaryState>(
              builder: (context, state) {
                if (state is SummaryLoading) {
                  return const SummaryCardsLoading();
                }
                if (state is SummaryLoaded) {
                  return SummaryCards(
                    summary: state.summary,
                    onMonthChanged: (month) {
                      context.read<SummaryBloc>().add(LoadMonthlySummary(
                        year: month.year,
                        month: month.month,
                      ));
                    },
                  );
                }
                if (state is SummaryError) {
                  return SummaryCardsError(
                    error: state.message,
                    onRetry: () {
                      final now = DateTime.now();
                      context.read<SummaryBloc>().add(LoadMonthlySummary(
                        year: now.year,
                        month: now.month,
                      ));
                    },
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              builder: (context) => const AddTransactionSheet(),
            );
          },
          child: const Icon(Icons.add),
        ),
      ),
    );
  }

  void _showEditSheet(BuildContext context, Transaction transaction) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => EditTransactionSheet(transaction: transaction),
    );
  }
}
