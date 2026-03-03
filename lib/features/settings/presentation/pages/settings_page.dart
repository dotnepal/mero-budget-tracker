import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/router/app_router.dart';
import '../../domain/app_currency.dart';
import '../bloc/settings_bloc.dart';
import '../bloc/settings_event.dart';
import '../bloc/settings_state.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          const SizedBox(height: 8),
          _SettingsSection(
            title: 'General',
            children: [
              _SettingsTile(
                icon: Icons.category_outlined,
                title: 'Categories',
                subtitle: 'Manage income and expense categories',
                onTap: () {
                  Navigator.pushNamed(context, AppRouter.categorySettings);
                },
              ),
              BlocBuilder<SettingsBloc, SettingsState>(
                builder: (context, state) {
                  final current = state is SettingsLoaded
                      ? state.currency
                      : AppCurrency.usd;
                  return _SettingsTile(
                    icon: Icons.attach_money,
                    title: 'Currency',
                    subtitle: '${current.code} (${current.symbol})',
                    onTap: () => _showCurrencyPicker(context, current),
                  );
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
      ),
    );
  }
}

void _showCurrencyPicker(BuildContext context, AppCurrency current) {
  showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Select Currency'),
      content: RadioGroup<AppCurrency>(
        groupValue: current,
        onChanged: (selected) {
          if (selected != null) {
            context.read<SettingsBloc>().add(UpdateCurrency(selected));
            Navigator.of(dialogContext).pop();
          }
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: AppCurrency.values.map((currency) {
            return RadioListTile<AppCurrency>(
              value: currency,
              title: Text('${currency.code} — ${currency.symbol}'),
            );
          }).toList(),
        ),
      ),
    ),
  );
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
