import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../bloc/statistics_bloc.dart';
import '../bloc/statistics_event.dart';
import '../bloc/statistics_state.dart';
import '../widgets/expense_income_chart.dart';
import '../widgets/financial_summary_cards.dart';
import '../widgets/date_range_selector.dart';
import '../widgets/statistics_empty_view.dart';
import '../../../transaction/presentation/widgets/show_add_transaction_sheet.dart';

class StatisticsPage extends StatefulWidget {
  const StatisticsPage({super.key});

  @override
  State<StatisticsPage> createState() => _StatisticsPageState();
}

class _StatisticsPageState extends State<StatisticsPage> {
  @override
  void initState() {
    super.initState();
    // Load current month statistics by default
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);
      final endOfMonth = DateTime(now.year, now.month + 1, 0);

      context.read<StatisticsBloc>().add(LoadStatistics(
        startDate: startOfMonth,
        endDate: endOfMonth,
      ));
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Statistics'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<StatisticsBloc>()
                .add(const RefreshStatistics()),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: BlocBuilder<StatisticsBloc, StatisticsState>(
        builder: (context, state) {
          if (state is StatisticsLoading) {
            return _buildLoadingView();
          }

          if (state is StatisticsError) {
            return _buildErrorView(theme, state.message);
          }

          if (state is StatisticsLoaded) {
            if (!state.summary.hasData) {
              return StatisticsEmptyView(
                onAddTransaction: () => _showAddTransaction(context),
              );
            }
            return _buildLoadedView(context, state);
          }

          return _buildInitialView();
        },
      ),
    );
  }

  Widget _buildLoadingView() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Loading statistics...'),
        ],
      ),
    );
  }

  Widget _buildErrorView(ThemeData theme, String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Error Loading Statistics',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => context.read<StatisticsBloc>()
                  .add(const RefreshStatistics()),
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInitialView() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Preparing statistics...'),
        ],
      ),
    );
  }

  Widget _buildLoadedView(BuildContext context, StatisticsLoaded state) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date Range Selector
          DateRangeSelector(
            selectedRange: DateTimeRange(
              start: state.summary.startDate,
              end: state.summary.endDate,
            ),
            onRangeChanged: (range) {
              context.read<StatisticsBloc>().add(LoadStatistics(
                startDate: range.start,
                endDate: range.end,
              ));
            },
          ),
          const SizedBox(height: 24),

          // Summary Cards
          FinancialSummaryCards(summary: state.summary),
          const SizedBox(height: 32),

          // Chart Section
          _buildChartSection(context, state),
          const SizedBox(height: 32),

          // Additional Information
          _buildAdditionalInfo(context, state),
        ],
      ),
    );
  }

  Widget _buildChartSection(BuildContext context, StatisticsLoaded state) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Income vs Expenses',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: ExpenseIncomeChart(summary: state.summary),
          ),
        ),
      ],
    );
  }

  Widget _buildAdditionalInfo(BuildContext context, StatisticsLoaded state) {
    final theme = Theme.of(context);
    final currencyFormat = NumberFormat.currency(symbol: '\$');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Summary',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                _buildInfoRow(
                  'Total Transactions',
                  '${state.transactions.length}',
                  Icons.receipt_long,
                  theme,
                ),
                const Divider(height: 24),
                _buildInfoRow(
                  'Average Transaction',
                  state.transactions.isNotEmpty
                      ? currencyFormat.format(
                          state.transactions.fold<double>(
                              0, (sum, t) => sum + t.amount) /
                              state.transactions.length)
                      : currencyFormat.format(0),
                  Icons.analytics,
                  theme,
                ),
                const Divider(height: 24),
                _buildInfoRow(
                  'Period',
                  _formatDateRange(state.summary.startDate, state.summary.endDate),
                  Icons.date_range,
                  theme,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(
    String label,
    String value,
    IconData icon,
    ThemeData theme,
  ) {
    return Row(
      children: [
        Icon(
          icon,
          color: theme.colorScheme.primary,
          size: 20,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  String _formatDateRange(DateTime start, DateTime end) {
    final formatter = DateFormat('MMM dd, yyyy');
    return '${formatter.format(start)} - ${formatter.format(end)}';
  }

  void _showAddTransaction(BuildContext context) {
    showAddTransactionSheet(context);
  }
}
