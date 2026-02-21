import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/database/database_service.dart';
import '../../../transaction/presentation/bloc/transaction_bloc.dart';

class DatabaseSettingsPage extends StatefulWidget {
  const DatabaseSettingsPage({super.key});

  @override
  State<DatabaseSettingsPage> createState() => _DatabaseSettingsPageState();
}

class _DatabaseSettingsPageState extends State<DatabaseSettingsPage> {
  final DatabaseService _databaseService = DatabaseService();
  bool _isLoading = false;
  Map<String, dynamic>? _dbStats;

  @override
  void initState() {
    super.initState();
    _loadDatabaseStats();
  }

  Future<void> _loadDatabaseStats() async {
    try {
      final stats = await _databaseService.getDatabaseStats();
      setState(() {
        _dbStats = stats;
      });
    } catch (e) {
      _showErrorSnackBar('Failed to load database statistics');
    }
  }

  Future<void> _backupDatabase() async {
    setState(() => _isLoading = true);

    try {
      // Create backup
      final backupPath = await _databaseService.backupDatabase();

      // Share the backup file
      await Share.shareXFiles(
        [XFile(backupPath)],
        subject: 'Mero Budget Tracker Backup',
        text: 'Database backup from ${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())}',
      );

      if (mounted) {
        _showSuccessSnackBar('Database backed up successfully');
      }
    } catch (e) {
      _showErrorSnackBar('Failed to backup database: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _exportData() async {
    setState(() => _isLoading = true);

    try {
      // Export data as JSON
      final data = await _databaseService.exportData();
      final jsonString = const JsonEncoder.withIndent('  ').convert(data);

      // Save to file
      final directory = await getApplicationDocumentsDirectory();
      final file = File(
        '${directory.path}/mero_budget_export_${DateTime.now().millisecondsSinceEpoch}.json',
      );
      await file.writeAsString(jsonString);

      // Share the file
      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'Mero Budget Tracker Data Export',
        text: 'Data export from ${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())}',
      );

      if (mounted) {
        _showSuccessSnackBar('Data exported successfully');
      }
    } catch (e) {
      _showErrorSnackBar('Failed to export data: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _clearAllData() async {
    final confirmed = await _showConfirmationDialog(
      'Clear All Data',
      'This will permanently delete all your transactions. This action cannot be undone. Are you sure?',
    );

    if (!confirmed) return;

    setState(() => _isLoading = true);

    try {
      await _databaseService.clearTransactions();

      if (mounted) {
        // Reload transactions in the bloc
        context.read<TransactionBloc>().add(const LoadTransactions());
        _showSuccessSnackBar('All transactions cleared successfully');
        await _loadDatabaseStats();
      }
    } catch (e) {
      _showErrorSnackBar('Failed to clear data: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _resetDatabase() async {
    final confirmed = await _showConfirmationDialog(
      'Reset Database',
      'This will delete all data and reset the database to its initial state. This action cannot be undone. Are you sure?',
    );

    if (!confirmed) return;

    setState(() => _isLoading = true);

    try {
      await _databaseService.resetDatabase();

      if (mounted) {
        // Reload transactions in the bloc
        context.read<TransactionBloc>().add(const LoadTransactions());
        _showSuccessSnackBar('Database reset successfully');
        await _loadDatabaseStats();
      }
    } catch (e) {
      _showErrorSnackBar('Failed to reset database: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _insertSampleData() async {
    final confirmed = await _showConfirmationDialog(
      'Insert Sample Data',
      'This will add sample transactions for testing purposes. Continue?',
    );

    if (!confirmed) return;

    setState(() => _isLoading = true);

    try {
      await _databaseService.insertSampleData();

      if (mounted) {
        // Reload transactions in the bloc
        context.read<TransactionBloc>().add(const LoadTransactions());
        _showSuccessSnackBar('Sample data inserted successfully');
        await _loadDatabaseStats();
      }
    } catch (e) {
      _showErrorSnackBar('Failed to insert sample data: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _performMaintenance() async {
    setState(() => _isLoading = true);

    try {
      await _databaseService.performMaintenance();

      final isHealthy = await _databaseService.checkIntegrity();

      if (mounted) {
        _showSuccessSnackBar(
          isHealthy
              ? 'Database maintenance completed. Database is healthy.'
              : 'Database maintenance completed. Some issues were found.',
        );
        await _loadDatabaseStats();
      }
    } catch (e) {
      _showErrorSnackBar('Failed to perform maintenance: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<bool> _showConfirmationDialog(String title, String message) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(title),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: TextButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.error,
                ),
                child: const Text('Confirm'),
              ),
            ],
          ),
        ) ??
        false;
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Database Settings'),
      ),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Database Statistics Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Database Statistics',
                        style: theme.textTheme.titleLarge,
                      ),
                      const SizedBox(height: 16),
                      if (_dbStats != null) ...[
                        _buildStatRow(
                          'Total Transactions',
                          '${_dbStats!['transactionCount']}',
                        ),
                        _buildStatRow(
                          'Categories',
                          '${_dbStats!['categoryCount']}',
                        ),
                        _buildStatRow(
                          'Budget Rules',
                          '${_dbStats!['budgetCount']}',
                        ),
                        _buildStatRow(
                          'Database Status',
                          _dbStats!['isInitialized'] ? 'Active' : 'Inactive',
                        ),
                      ] else
                        const Center(child: CircularProgressIndicator()),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Backup & Restore Section
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Backup & Restore',
                        style: theme.textTheme.titleLarge,
                      ),
                      const SizedBox(height: 16),
                      ListTile(
                        leading: const Icon(Icons.backup),
                        title: const Text('Backup Database'),
                        subtitle: const Text('Create a backup of your entire database'),
                        onTap: _isLoading ? null : _backupDatabase,
                      ),
                      ListTile(
                        leading: const Icon(Icons.file_download),
                        title: const Text('Export Data'),
                        subtitle: const Text('Export all data as JSON'),
                        onTap: _isLoading ? null : _exportData,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Maintenance Section
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Maintenance',
                        style: theme.textTheme.titleLarge,
                      ),
                      const SizedBox(height: 16),
                      ListTile(
                        leading: const Icon(Icons.build),
                        title: const Text('Optimize Database'),
                        subtitle: const Text('Perform maintenance and check integrity'),
                        onTap: _isLoading ? null : _performMaintenance,
                      ),
                      ListTile(
                        leading: const Icon(Icons.science),
                        title: const Text('Insert Sample Data'),
                        subtitle: const Text('Add sample transactions for testing'),
                        onTap: _isLoading ? null : _insertSampleData,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Danger Zone
              Card(
                color: theme.colorScheme.errorContainer.withValues(alpha: 0.3),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Danger Zone',
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: theme.colorScheme.error,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ListTile(
                        leading: Icon(
                          Icons.delete_outline,
                          color: theme.colorScheme.error,
                        ),
                        title: Text(
                          'Clear All Transactions',
                          style: TextStyle(color: theme.colorScheme.error),
                        ),
                        subtitle: const Text('Delete all transactions but keep settings'),
                        onTap: _isLoading ? null : _clearAllData,
                      ),
                      ListTile(
                        leading: Icon(
                          Icons.warning,
                          color: theme.colorScheme.error,
                        ),
                        title: Text(
                          'Reset Database',
                          style: TextStyle(color: theme.colorScheme.error),
                        ),
                        subtitle: const Text('Delete everything and start fresh'),
                        onTap: _isLoading ? null : _resetDatabase,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (_isLoading)
            Container(
              color: Colors.black54,
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      ),
    );
  }
}
