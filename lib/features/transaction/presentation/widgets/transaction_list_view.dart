import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shimmer/shimmer.dart';
import 'package:grouped_list/grouped_list.dart';
import 'package:intl/intl.dart';

import '../../domain/entities/transaction.dart';
import '../bloc/transaction_bloc.dart';
import 'transaction_tile.dart';
import 'transaction_error_view.dart';
import 'transaction_empty_view.dart';
import 'transaction_loading_view.dart';
import 'delete_confirmation_dialog.dart';

class TransactionListView extends StatefulWidget {
  const TransactionListView({
    super.key,
    required this.transactions,
    required this.onDelete,
    required this.onEdit,
  });

  final List<Transaction> transactions;
  final Function(String) onDelete;
  final Function(Transaction) onEdit;

  @override
  State<TransactionListView> createState() => _TransactionListViewState();
}

class _TransactionListViewState extends State<TransactionListView> {
  static const int _pageSize = 20;
  bool _isLoading = false;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_isLoadingMore) return;

    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;

    if (currentScroll >= maxScroll - 200) {
      _loadMore();
    }
  }

  bool get _isLoadingMore =>
    context.read<TransactionBloc>().state is TransactionLoadingMore;

  void _loadMore() {
    if (!_isLoading) {
      setState(() => _isLoading = true);
      context.read<TransactionBloc>().add(
        LoadMoreTransactions(pageSize: _pageSize),
      );
    }
  }

  Future<void> _onRefresh() async {
    context.read<TransactionBloc>().add(RefreshTransactions());
    // Wait for the refresh to complete
    await Future.delayed(const Duration(milliseconds: 500));
  }

  @override
  Widget build(BuildContext context) {
    if (widget.transactions.isEmpty) {
      return const TransactionEmptyView();
    }

    return RefreshIndicator(
      onRefresh: _onRefresh,
      child: Stack(
        children: [
          GroupedListView<Transaction, DateTime>(
            controller: _scrollController,
            elements: widget.transactions,
            order: GroupedListOrder.DESC,
            groupBy: (transaction) => DateTime(
              transaction.date.year,
              transaction.date.month,
              transaction.date.day,
            ),
            groupSeparatorBuilder: (DateTime date) => Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                DateFormat('MMMM dd, yyyy').format(date),
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            itemBuilder: (context, Transaction transaction) {
              return Dismissible(
                key: Key(transaction.id),
                background: const DismissibleBackground(
                  alignment: Alignment.centerLeft,
                  color: Colors.green,
                  icon: Icons.edit,
                ),
                secondaryBackground: const DismissibleBackground(
                  alignment: Alignment.centerRight,
                  color: Colors.red,
                  icon: Icons.delete,
                ),
                confirmDismiss: (direction) async {
                  if (direction == DismissDirection.endToStart) {
                    return await showDeleteConfirmation(context);
                  } else if (direction == DismissDirection.startToEnd) {
                    // Handle edit action
                    widget.onEdit(transaction);
                    return false; // Don't actually dismiss
                  }
                  return false;
                },
                onDismissed: (direction) {
                  if (direction == DismissDirection.endToStart) {
                    widget.onDelete(transaction.id);
                  }
                },
                child: TransactionTile(
                  transaction: transaction,
                  onEdit: () => widget.onEdit(transaction),
                  onDelete: () => widget.onDelete(transaction.id),
                ),
              );
            },
            separator: const Divider(),
          ),
          if (_isLoadingMore)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                color: Colors.white.withOpacity(0.8),
                child: const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Center(
                    child: CircularProgressIndicator(),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class TransactionLoadingMore extends StatelessWidget {
  const TransactionLoadingMore({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(8.0),
      child: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}

class DismissibleBackground extends StatelessWidget {
  const DismissibleBackground({
    super.key,
    required this.alignment,
    required this.color,
    required this.icon,
  });

  final Alignment alignment;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: color,
      child: Align(
        alignment: alignment,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Icon(
            icon,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
