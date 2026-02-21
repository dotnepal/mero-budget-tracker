import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/router/app_router.dart';
import '../bloc/settings_bloc.dart';
import '../bloc/settings_event.dart';
import '../bloc/settings_state.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  void _showCurrencyPicker(BuildContext context, String currentCode) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Select Currency'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              value: 'USD',
              groupValue: currentCode,
              title: const Text('\$ US Dollar'),
              onChanged: (value) {
                if (value != null) {
                  context.read<SettingsBloc>().add(UpdateCurrencyCode(value));
                  Navigator.of(dialogContext).pop();
                }
              },
            ),
            RadioListTile<String>(
              value: 'INR',
              groupValue: currentCode,
              title: const Text('₹ Indian Rupee'),
              onChanged: (value) {
                if (value != null) {
                  context.read<SettingsBloc>().add(UpdateCurrencyCode(value));
                  Navigator.of(dialogContext).pop();
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: BlocBuilder<SettingsBloc, SettingsState>(
        builder: (context, settingsState) {
          final currentCode = settingsState is SettingsLoaded
              ? settingsState.settings.currencyCode
              : 'USD';
          final currencySubtitle =
              currentCode == 'INR' ? '₹ Indian Rupee' : '\$ US Dollar';

          return ListView(
            children: [
              const SizedBox(height: 8),
              _SettingsSection(
                title: 'General',
                children: [
                  _SettingsTile(
                    icon: Icons.currency_rupee,
                    title: 'Currency',
                    subtitle: currencySubtitle,
                    onTap: () => _showCurrencyPicker(context, currentCode),
                  ),
                  _SettingsTile(
                    icon: Icons.category_outlined,
                    title: 'Categories',
                    subtitle: 'Manage income and expense categories',
                    onTap: () {
                      Navigator.pushNamed(context, AppRouter.categorySettings);
                    },
                  ),
                ],
              ),
              _SettingsSection(
                title: 'Data',
                children: [
                  _SettingsTile(
                    icon: Icons.storage_outlined,
                    title: 'Database',
                    subtitle: 'Backup, export, and manage your data',
                    onTap: () {
                      Navigator.pushNamed(context, AppRouter.databaseSettings);
                    },
                  ),
                ],
              ),
              _SettingsSection(
                title: 'About',
                children: [
                  _SettingsTile(
                    icon: Icons.info_outline,
                    title: 'App Info',
                    subtitle: 'Mero Budget Tracker v1.0.0',
                    onTap: () {
                      showAboutDialog(
                        context: context,
                        applicationName: 'Mero Budget Tracker',
                        applicationVersion: '1.0.0',
                        applicationIcon: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.account_balance_wallet,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        children: [
                          const Text(
                            'A simple budget tracking application to help you manage your personal finances.',
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SettingsSection({
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        ...children,
      ],
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: theme.colorScheme.primary,
        ),
      ),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
