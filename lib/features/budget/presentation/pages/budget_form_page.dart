import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../settings/domain/app_currency.dart';
import '../../../settings/presentation/bloc/settings_bloc.dart';
import '../../../settings/presentation/bloc/settings_state.dart';
import '../../domain/services/budget_rule_engine.dart';
import '../bloc/budget_bloc.dart';

class BudgetFormPage extends StatefulWidget {
  final int? initialMonth;
  final int? initialYear;
  // Pre-fill with existing plan's income when editing (in cents)
  final int? initialIncomeCents;

  const BudgetFormPage({
    super.key,
    this.initialMonth,
    this.initialYear,
    this.initialIncomeCents,
  });

  @override
  State<BudgetFormPage> createState() => _BudgetFormPageState();
}

class _BudgetFormPageState extends State<BudgetFormPage> {
  late int _month;
  late int _year;
  String _ruleType = '50-30-20';
  final _incomeController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _submitted = false;

  static const _months = [
    '', 'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _month = widget.initialMonth ?? now.month;
    _year = widget.initialYear ?? now.year;
    if (widget.initialIncomeCents != null) {
      final dollars = widget.initialIncomeCents! / 100;
      _incomeController.text = dollars == dollars.truncateToDouble()
          ? dollars.toStringAsFixed(0)
          : dollars.toStringAsFixed(2);
    }
  }

  @override
  void dispose() {
    _incomeController.dispose();
    super.dispose();
  }

  int? get _incomeCents {
    final text = _incomeController.text.replaceAll(',', '');
    final value = double.tryParse(text);
    if (value == null || value <= 0) return null;
    return (value * 100).round();
  }

  Map<String, int> _preview(int incomeCents) {
    final rule = budgetRuleForType(_ruleType);
    return rule.allocate(incomeCents);
  }

  String _fmt(int cents, String symbol) => '$symbol${(cents / 100).toStringAsFixed(2)}';

  String _periodLabel() => '${_months[_month]} $_year';

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final cents = _incomeCents;
    if (cents == null) return;

    setState(() => _submitted = true);
    context.read<BudgetBloc>().add(CreateBudgetPlan(
      totalIncomeCents: cents,
      month: _month,
      year: _year,
      ruleType: _ruleType,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<BudgetBloc, BudgetState>(
      listener: (context, state) {
        if (!_submitted) return;
        if (state is BudgetLoaded) {
          Navigator.pop(context);
        } else if (state is BudgetError) {
          setState(() => _submitted = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      },
      child: Builder(
        builder: (context) {
          final symbol = context.select<SettingsBloc, String>(
            (b) => b.state is SettingsLoaded
                ? (b.state as SettingsLoaded).currency.symbol
                : AppCurrency.usd.symbol,
          );
          return _buildScaffold(context, symbol);
        },
      ),
    );
  }

  Widget _buildScaffold(BuildContext context, String symbol) {
    return Scaffold(
        appBar: AppBar(title: const Text('New Budget')),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Period selector
              _SectionLabel(text: 'Period'),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: DropdownButtonFormField<int>(
                      value: _month,
                      decoration: const InputDecoration(
                        labelText: 'Month',
                        border: OutlineInputBorder(),
                      ),
                      items: List.generate(
                        12,
                        (i) => DropdownMenuItem(
                          value: i + 1,
                          child: Text(_months[i + 1]),
                        ),
                      ),
                      onChanged: (v) => setState(() => _month = v!),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      value: _year,
                      decoration: const InputDecoration(
                        labelText: 'Year',
                        border: OutlineInputBorder(),
                      ),
                      items: List.generate(
                        5,
                        (i) {
                          final y = DateTime.now().year - 1 + i;
                          return DropdownMenuItem(value: y, child: Text('$y'));
                        },
                      ),
                      onChanged: (v) => setState(() => _year = v!),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Income field
              _SectionLabel(text: 'Total Income'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _incomeController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[\d.,]')),
                ],
                decoration: InputDecoration(
                  labelText: 'Amount',
                  prefixText: '$symbol ',
                  border: const OutlineInputBorder(),
                  hintText: '0.00',
                ),
                onChanged: (_) => setState(() {}),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Enter your income';
                  final parsed = double.tryParse(v.replaceAll(',', ''));
                  if (parsed == null || parsed <= 0) return 'Enter a valid amount';
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Rule selector
              _SectionLabel(text: 'Budget Rule'),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _ruleType,
                decoration: const InputDecoration(
                  labelText: 'Rule',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(
                    value: '50-30-20',
                    child: Text('50-30-20  (Needs / Wants / Savings)'),
                  ),
                ],
                onChanged: (v) => setState(() => _ruleType = v!),
              ),
              const SizedBox(height: 24),

              // Allocation preview
              if (_incomeCents != null) ...[
                _SectionLabel(text: 'Allocation Preview'),
                const SizedBox(height: 8),
                _AllocationPreview(
                  allocations: _preview(_incomeCents!),
                  pcts: {'NEEDS': 50, 'WANTS': 30, 'SAVINGS': 20},
                  fmt: (cents) => _fmt(cents, symbol),
                ),
                const SizedBox(height: 24),
              ],

              // Save button
              SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: _submitted ? null : _submit,
                  child: _submitted
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text('Save Budget for ${_periodLabel()}'),
                ),
              ),
            ],
          ),
        ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel({required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: Theme.of(context).colorScheme.primary,
          ),
    );
  }
}

class _AllocationPreview extends StatelessWidget {
  final Map<String, int> allocations;
  final Map<String, int> pcts;
  final String Function(int) fmt;

  const _AllocationPreview({
    required this.allocations,
    required this.pcts,
    required this.fmt,
  });

  @override
  Widget build(BuildContext context) {
    const buckets = ['NEEDS', 'WANTS', 'SAVINGS'];
    const colors = {
      'NEEDS': Color(0xFF0984E3),
      'WANTS': Color(0xFF6C5CE7),
      'SAVINGS': Color(0xFF00B894),
    };

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: buckets.map((bucket) {
            final amount = allocations[bucket] ?? 0;
            final pct = pcts[bucket] ?? 0;
            final color = colors[bucket]!;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '$bucket ($pct%)',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: color,
                      ),
                    ),
                  ),
                  Text(
                    fmt(amount),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}