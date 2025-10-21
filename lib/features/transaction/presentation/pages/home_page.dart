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

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
    context.read<TransactionBloc>().add(const LoadTransactions());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mero Budget Tracker'),
        actions: [
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
      body: BlocBuilder<TransactionBloc, TransactionState>(
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
