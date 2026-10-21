import 'package:flutter/material.dart';

import '../services/app_state.dart';
import '../services/finance_calculator.dart';
import '../utils/formatters.dart';
import '../widgets/budget_progress.dart';
import '../widgets/empty_state.dart';
import '../widgets/expense_tile.dart';
import '../widgets/summary_card.dart';
import 'expense_form_screen.dart';
import 'income_form_screen.dart';

/// Section 1: financial summary for the selected month. Every value is
/// calculated by AppState from the database, nothing is hard-coded.
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key, required this.onNavigate});

  final ValueChanged<int> onNavigate;

  @override
  Widget build(BuildContext context) {
    final state = AppState.instance;
    return ListenableBuilder(
      listenable: state,
      builder: (context, _) {
        final theme = Theme.of(context);
        final colors = theme.colorScheme;
        final recent = state.expenses.take(5).toList();
        final alerts = state.alertCategories;
        final due = state.dueRecurring;

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            if (state.loadError != null)
              Card(
                color: colors.errorContainer,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(state.loadError!,
                      style: TextStyle(color: colors.onErrorContainer)),
                ),
              ),
            _BudgetHeader(state: state, onSetBudget: () => onNavigate(3)),
            const SizedBox(height: 12),
            SummaryCardRow(
              left: SummaryCard(
                label: 'Monthly Budget',
                value: peso(state.monthlyBudget),
                icon: Icons.account_balance_wallet_outlined,
              ),
              right: SummaryCard(
                label: 'Total Income',
                value: peso(state.totalIncome),
                icon: Icons.trending_up,
                color: Colors.green.shade700,
              ),
            ),
            const SizedBox(height: 10),
            SummaryCardRow(
              left: SummaryCard(
                label: 'Total Expenses',
                value: peso(state.totalExpenses),
                icon: Icons.trending_down,
                color: colors.error,
              ),
              right: SummaryCard(
                label: 'Remaining',
                value: peso(state.remainingBudget),
                icon: Icons.savings_outlined,
                color: state.remainingBudget < 0 ? colors.error : null,
                caption: 'Budget minus expenses',
              ),
            ),
            const SizedBox(height: 10),
            SummaryCardRow(
              left: SummaryCard(
                label: 'Savings',
                value: peso(state.currentSavings),
                icon: Icons.flag_outlined,
                caption: state.savingsTarget > 0
                    ? '${percent(state.savingsProgress)} of ${peso(state.savingsTarget)}'
                    : 'No goal set',
              ),
              right: SummaryCard(
                label: 'Budget Used',
                value: percent(state.budgetUsedPercent),
                icon: Icons.pie_chart_outline,
                color: statusColor(state.overallStatus, colors),
              ),
            ),
            if (alerts.isNotEmpty) ...[
              const SizedBox(height: 16),
              _AlertsCard(alerts: alerts, onTap: () => onNavigate(3)),
            ],
            if (due.isNotEmpty) ...[
              const SizedBox(height: 12),
              Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: Icon(Icons.event_note, color: colors.primary),
                      title: Text(
                          '${due.length} recurring payment${due.length == 1 ? '' : 's'} due'),
                      subtitle: Text(due.map((r) => r.title).join(', ')),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => onNavigate(2),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (_) => const ExpenseFormScreen())),
                    icon: const Icon(Icons.remove_circle_outline),
                    label: const Text('Add expense'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (_) => const IncomeFormScreen())),
                    icon: const Icon(Icons.add_circle_outline),
                    label: const Text('Add income'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: Text('Recent expenses',
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700)),
                ),
                TextButton(
                    onPressed: () => onNavigate(2),
                    child: const Text('See all')),
              ],
            ),
            if (recent.isEmpty)
              const EmptyState(
                compact: true,
                icon: Icons.receipt_long_outlined,
                title: 'No expenses yet',
                message: 'Expenses you add for this month will show up here.',
              )
            else
              Card(
                child: Column(
                  children: [
                    for (final e in recent)
                      ExpenseTile(
                        expense: e,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (_) => ExpenseFormScreen(expense: e)),
                        ),
                      ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}

class _BudgetHeader extends StatelessWidget {
  const _BudgetHeader({required this.state, required this.onSetBudget});

  final AppState state;
  final VoidCallback onSetBudget;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final color = statusColor(state.overallStatus, colors);

    return Card(
      color: colors.primaryContainer,
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Budget used in ${monthLabel(state.selectedMonth)}',
                style: theme.textTheme.titleSmall
                    ?.copyWith(color: colors.onPrimaryContainer)),
            const SizedBox(height: 8),
            if (!state.hasBudget) ...[
              Text('No monthly budget set yet.',
                  style: theme.textTheme.bodyLarge
                      ?.copyWith(color: colors.onPrimaryContainer)),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: onSetBudget,
                icon: const Icon(Icons.add),
                label: const Text('Set monthly budget'),
              ),
            ] else ...[
              Text(
                percent(state.budgetUsedPercent),
                style: theme.textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: state.overallStatus == BudgetStatus.normal
                      ? colors.onPrimaryContainer
                      : color,
                ),
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: (state.budgetUsedPercent / 100)
                      .clamp(0.0, 1.0)
                      .toDouble(),
                  minHeight: 10,
                  color: color,
                  backgroundColor: colors.surface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${peso(state.totalExpenses)} spent of ${peso(state.monthlyBudget)}',
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: colors.onPrimaryContainer),
              ),
              if (state.isBudgetCarriedOver)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    'Using the budget from ${monthLabel(monthFromKey(state.budget!.month))}',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: colors.onPrimaryContainer),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _AlertsCard extends StatelessWidget {
  const _AlertsCard({required this.alerts, required this.onTap});

  final List<CategoryUsage> alerts;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      child: Column(
        children: [
          for (final u in alerts)
            ListTile(
              onTap: onTap,
              leading: Icon(
                u.status == BudgetStatus.exceeded
                    ? Icons.error_outline
                    : Icons.warning_amber_rounded,
                color: statusColor(u.status, colors),
              ),
              title: Text(u.status == BudgetStatus.exceeded
                  ? '${u.category} budget exceeded'
                  : '${u.category} is close to its limit'),
              subtitle: Text(
                  '${peso(u.spent)} of ${peso(u.limit)} (${percent(u.percent)})'),
            ),
        ],
      ),
    );
  }
}
