import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/models/transaction.dart';
import '../bloc/transaction_bloc.dart';
import '../bloc/transaction_state.dart';
import '../widgets/add_transaction_form.dart';

/// The main home screen of the application
class HomeScreen extends StatelessWidget {
  /// Creates a [HomeScreen] widget
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mero Budget Tracker'),
      ),
      body: BlocBuilder<TransactionBloc, TransactionState>(
        builder: (context, state) {
          if (state is TransactionLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
          
          if (state is TransactionError) {
            return Center(
              child: Text(
                'Error: ${state.message}',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            );
          }
          
          if (state is TransactionLoaded) {
            if (state.transactions.isEmpty) {
              return const Center(
                child: Text('No transactions yet. Add one to get started!'),
              );
            }
            
            return ListView.builder(
              itemCount: state.transactions.length,
              itemBuilder: (context, index) {
                final transaction = state.transactions[index];
                return ListTile(
                  leading: Icon(
                    transaction.type == TransactionType.income
                        ? Icons.arrow_downward
                        : Icons.arrow_upward,
                    color: transaction.type == TransactionType.income
                        ? Colors.green
                        : Colors.red,
                  ),
                  title: Text(transaction.description),
                  subtitle: Text(
                    transaction.date.toString().split(' ')[0],
                  ),
                  trailing: Text(
                    '\$${transaction.amount.toStringAsFixed(2)}',
                    style: TextStyle(
                      color: transaction.type == TransactionType.income
                          ? Colors.green
                          : Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                );
              },
            );
          }
          
          return const Center(
            child: Text('Start adding your transactions!'),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showModalBottomSheet<void>(
            context: context,
            isScrollControlled: true,
            builder: (BuildContext context) {
              return const AddTransactionForm();
            },
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}