import 'package:flutter/material.dart';

import '../models/savings_goal.dart';
import '../services/app_state.dart';
import '../utils/constants.dart';
import '../utils/dialogs.dart';
import '../utils/formatters.dart';
import '../utils/validators.dart';
import '../widgets/amount_field.dart';
import '../widgets/amount_input_dialog.dart';
import '../widgets/budget_progress.dart';
import '../widgets/summary_card.dart';

/// Section 5, 6 and 7: monthly budget, category limits and savings goal.
class BudgetScreen extends StatefulWidget {
  const BudgetScreen({super.key});

  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen> {
  final AppState _state = AppState.instance;
  final _formKey = GlobalKey<FormState>();
  final _budgetCtrl = TextEditingController();
  final _budgetFocus = FocusNode();
  String? _syncedSignature;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _state.addListener(_syncBudgetField);
    _syncBudgetField();
  }

  @override
  void dispose() {
    _state.removeListener(_syncBudgetField);
    _budgetCtrl.dispose();
    _budgetFocus.dispose();
    super.dispose();
  }

  /// Puts the saved budget in the text field when the month changes,
  /// without overwriting what the user is typing.
  void _syncBudgetField() {
    if (_budgetFocus.hasFocus) return;
    final signature = '${_state.selectedMonthKey}|${_state.monthlyBudget}';
    if (signature == _syncedSignature) return;
    _syncedSignature = signature;
    _budgetCtrl.text =
        _state.hasBudget ? _state.monthlyBudget.toStringAsFixed(2) : '';
  }

  Future<void> _saveBudget() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await _state
          .saveMonthlyBudget(Validators.tryParseAmount(_budgetCtrl.text)!);
      _budgetFocus.unfocus();
      _syncedSignature = null;
      _syncBudgetField();
      if (mounted) {
        showMessage(context,
            'Monthly budget saved for ${monthLabel(_state.selectedMonth)}');
      }
    } on ValidationException catch (e) {
      if (mounted) showMessage(context, e.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _editCategoryLimit(String category) async {
    final current = _state.categoryLimits[category];
    final result = await showDialog<AmountDialogResult>(
      context: context,
      builder: (_) => AmountInputDialog(
        title: '$category limit',
        label: 'Spending limit',
        initialValue: current,
        message:
            'Spent in ${monthLabel(_state.selectedMonth)}: ${peso(_state.categoryTotals[category] ?? 0)}',
        allowRemove: current != null,
      ),
    );
    if (result == null) return;
    try {
      if (result.remove) {
        await _state.removeCategoryLimit(category);
      } else {
        await _state.setCategoryLimit(category, result.amount!);
      }
      if (mounted) {
        showMessage(context,
            result.remove ? '$category limit removed' : '$category limit saved');
      }
    } on ValidationException catch (e) {
      if (mounted) showMessage(context, e.message);
    }
  }

  Future<void> _editSavingsGoal() async {
    final result = await showDialog<({double target, double current})>(
      context: context,
      builder: (_) => _SavingsGoalDialog(goal: _state.savingsGoal),
    );
    if (result == null) return;
    try {
      await _state.saveSavingsGoal(
          target: result.target, currentSavings: result.current);
      if (mounted) showMessage(context, 'Savings goal saved');
    } on ValidationException catch (e) {
      if (mounted) showMessage(context, e.message);
    }
  }

  Future<void> _addSavings() async {
    final result = await showDialog<AmountDialogResult>(
      context: context,
      builder: (_) => const AmountInputDialog(
        title: 'Add to savings',
        label: 'Amount saved',
        saveLabel: 'Add',
      ),
    );
    if (result == null || result.amount == null) return;
    try {
      await _state.addToSavings(result.amount!);
      if (mounted) showMessage(context, '${peso(result.amount!)} added to savings');
    } on ValidationException catch (e) {
      if (mounted) showMessage(context, e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _state,
      builder: (context, _) => ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          _monthlyBudgetCard(context),
          const SizedBox(height: 12),
          _categoryLimitsCard(context),
          const SizedBox(height: 12),
          _savingsCard(context),
        ],
      ),
    );
  }

  Widget _sectionTitle(BuildContext context, String title, String subtitle) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w700)),
        Text(subtitle, style: theme.textTheme.bodySmall),
      ],
    );
  }

  Widget _monthlyBudgetCard(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final remaining = _state.remainingBudget;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _sectionTitle(context, 'Monthly budget',
                  'For ${monthLabel(_state.selectedMonth)}'),
              if (_state.isBudgetCarriedOver)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    'Using the budget from ${monthLabel(monthFromKey(_state.budget!.month))}. Save to set one for this month.',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: colors.primary),
                  ),
                ),
              const SizedBox(height: 12),
              AmountField(
                controller: _budgetCtrl,
                focusNode: _budgetFocus,
                label: 'Monthly budget',
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: _saving ? null : _saveBudget,
                icon: const Icon(Icons.save_outlined),
                label: const Text('Save budget'),
              ),
              const SizedBox(height: 16),
              LabelValueRow(
                  label: 'Total expenses', value: peso(_state.totalExpenses)),
              LabelValueRow(
                label: 'Remaining budget',
                value: peso(remaining),
                valueColor:
                    remaining < 0 ? colors.error : Colors.green.shade700,
              ),
              Text('Remaining Budget = Monthly Budget - Total Expenses',
                  style: theme.textTheme.bodySmall),
              if (_state.hasBudget) ...[
                const SizedBox(height: 14),
                BudgetProgress(
                  label: 'Overall budget used',
                  spent: _state.totalExpenses,
                  limit: _state.monthlyBudget,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _categoryLimitsCard(BuildContext context) {
    final theme = Theme.of(context);
    final totals = _state.categoryTotals;
    final limits = _state.categoryLimits;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionTitle(context, 'Category budget limits',
                'Limits apply every month. Spending is for ${monthLabel(_state.selectedMonth)}.'),
            const SizedBox(height: 4),
            Text('Percentage Used = Category Expenses / Category Budget × 100',
                style: theme.textTheme.bodySmall),
            const SizedBox(height: 8),
            for (final c in AppConstants.expenseCategories)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: limits.containsKey(c)
                    ? BudgetProgress(
                        label: c,
                        icon: categoryIcon(c),
                        iconColor: categoryColor(c),
                        spent: totals[c] ?? 0,
                        limit: limits[c]!,
                        onEdit: () => _editCategoryLimit(c),
                      )
                    : Row(
                        children: [
                          Icon(categoryIcon(c),
                              size: 20, color: categoryColor(c)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(c, style: theme.textTheme.titleSmall),
                                Text(
                                    'No limit set. Spent ${peso(totals[c] ?? 0)}',
                                    style: theme.textTheme.bodySmall),
                              ],
                            ),
                          ),
                          TextButton(
                            onPressed: () => _editCategoryLimit(c),
                            child: const Text('Set limit'),
                          ),
                        ],
                      ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _savingsCard(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final goal = _state.savingsGoal;
    final progress = _state.savingsProgress;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _sectionTitle(
                context, 'Savings goal', 'For ${monthLabel(_state.selectedMonth)}'),
            const SizedBox(height: 12),
            if (goal == null) ...[
              const Text('No savings goal for this month yet.'),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: _editSavingsGoal,
                icon: const Icon(Icons.flag_outlined),
                label: const Text('Set savings goal'),
              ),
            ] else ...[
              LabelValueRow(label: 'Target', value: peso(goal.target)),
              LabelValueRow(
                  label: 'Current savings', value: peso(goal.currentSavings)),
              LabelValueRow(label: 'Progress', value: percent(progress)),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: (progress / 100).clamp(0.0, 1.0).toDouble(),
                  minHeight: 10,
                  color: progress >= 100 ? Colors.green.shade600 : colors.primary,
                  backgroundColor: colors.surfaceContainerHighest,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                progress >= 100
                    ? 'Goal reached.'
                    : '${peso(goal.target - goal.currentSavings)} more to reach your goal',
                style: theme.textTheme.bodySmall,
              ),
              Text('Savings Progress = Current Savings / Savings Target × 100',
                  style: theme.textTheme.bodySmall),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _editSavingsGoal,
                      icon: const Icon(Icons.edit_outlined),
                      label: const Text('Edit goal'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _addSavings,
                      icon: const Icon(Icons.add),
                      label: const Text('Add savings'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SavingsGoalDialog extends StatefulWidget {
  const _SavingsGoalDialog({this.goal});

  final SavingsGoal? goal;

  @override
  State<_SavingsGoalDialog> createState() => _SavingsGoalDialogState();
}

class _SavingsGoalDialogState extends State<_SavingsGoalDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _targetCtrl = TextEditingController(
      text: widget.goal?.target.toStringAsFixed(2) ?? '');
  late final TextEditingController _currentCtrl = TextEditingController(
      text: widget.goal?.currentSavings.toStringAsFixed(2) ?? '');

  @override
  void dispose() {
    _targetCtrl.dispose();
    _currentCtrl.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(context, (
      target: Validators.tryParseAmount(_targetCtrl.text)!,
      current: Validators.tryParseAmount(_currentCtrl.text) ?? 0.0,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Savings goal'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AmountField(
                controller: _targetCtrl, label: 'Savings target', autofocus: true),
            const SizedBox(height: 12),
            AmountField(
              controller: _currentCtrl,
              label: 'Current savings',
              validator: Validators.optionalAmount,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(onPressed: _save, child: const Text('Save')),
      ],
    );
  }
}
