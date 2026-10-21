import 'package:flutter/material.dart';

import '../services/app_state.dart';
import '../services/finance_calculator.dart';
import '../utils/constants.dart';
import '../utils/formatters.dart';
import '../widgets/summary_card.dart';

/// Section 8 and 19: analytics and the monthly comparison challenge.
class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppState.instance;
    return ListenableBuilder(
      listenable: state,
      builder: (context, _) {
        final theme = Theme.of(context);
        final colors = theme.colorScheme;
        final byCategory = state.categoryTotals.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));
        final byMethod = FinanceCalculator.totalsByPaymentMethod(state.expenses)
            .entries
            .toList()
          ..sort((a, b) => b.value.compareTo(a.value));
        final highest = state.highestExpenseCategory;

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            SummaryCardRow(
              left: SummaryCard(
                label: 'Total Income',
                value: peso(state.totalIncome),
                icon: Icons.trending_up,
                color: Colors.green.shade700,
              ),
              right: SummaryCard(
                label: 'Total Expenses',
                value: peso(state.totalExpenses),
                icon: Icons.trending_down,
                color: colors.error,
              ),
            ),
            const SizedBox(height: 10),
            SummaryCardRow(
              left: SummaryCard(
                label: 'Remaining Balance',
                value: peso(state.remainingBalance),
                icon: Icons.account_balance,
                color: state.remainingBalance < 0 ? colors.error : null,
                caption: 'Income - Expenses',
              ),
              right: SummaryCard(
                label: 'Savings Rate',
                value: percent(state.savingsRate),
                icon: Icons.savings_outlined,
                caption: 'Savings / Income × 100',
              ),
            ),
            const SizedBox(height: 10),
            SummaryCardRow(
              left: SummaryCard(
                label: 'Highest Category',
                value: highest?.key ?? 'None',
                icon: highest == null
                    ? Icons.category_outlined
                    : categoryIcon(highest.key),
                color: highest == null ? null : categoryColor(highest.key),
                caption:
                    highest == null ? 'No expenses yet' : peso(highest.value),
              ),
              right: SummaryCard(
                label: 'Avg Daily Spending',
                value: peso(state.averageDailySpending),
                icon: Icons.today_outlined,
                caption:
                    'Expenses / ${state.daysCounted} day${state.daysCounted == 1 ? '' : 's'}',
              ),
            ),
            const SizedBox(height: 16),
            _BreakdownCard(
              title: 'Spending by category',
              entries: byCategory,
              total: state.totalExpenses,
              iconFor: categoryIcon,
              colorFor: categoryColor,
            ),
            const SizedBox(height: 12),
            _BreakdownCard(
              title: 'Spending by payment method',
              entries: byMethod,
              total: state.totalExpenses,
              iconFor: paymentIcon,
              colorFor: (_) => colors.primary,
            ),
            const SizedBox(height: 12),
            _ComparisonCard(state: state),
          ],
        );
      },
    );
  }
}

class _BreakdownCard extends StatelessWidget {
  const _BreakdownCard({
    required this.title,
    required this.entries,
    required this.total,
    required this.iconFor,
    required this.colorFor,
  });

  final String title;
  final List<MapEntry<String, double>> entries;
  final double total;
  final IconData Function(String) iconFor;
  final Color Function(String) colorFor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            if (entries.isEmpty)
              const Text('No expenses recorded for this month.')
            else
              for (final e in entries)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Icon(iconFor(e.key), size: 18, color: colorFor(e.key)),
                          const SizedBox(width: 8),
                          Expanded(child: Text(e.key)),
                          Text(peso(e.value),
                              style:
                                  const TextStyle(fontWeight: FontWeight.w700)),
                          SizedBox(
                            width: 56,
                            child: Text(
                              percent(FinanceCalculator.percentUsed(e.value, total)),
                              textAlign: TextAlign.end,
                              style: theme.textTheme.bodySmall,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: total <= 0 ? 0 : e.value / total,
                          minHeight: 6,
                          color: colorFor(e.key),
                          backgroundColor:
                              theme.colorScheme.surfaceContainerHighest,
                        ),
                      ),
                    ],
                  ),
                ),
          ],
        ),
      ),
    );
  }
}

class _ComparisonCard extends StatelessWidget {
  const _ComparisonCard({required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final previous = state.previousMonthExpenses;
    final current = state.totalExpenses;
    final diff = state.monthOverMonthDifference;
    final prevLabel = monthLabel(state.previousMonth);
    final change = FinanceCalculator.percentChange(previous, current);

    final String verdict;
    final Color verdictColor;
    final IconData verdictIcon;
    if (previous == 0 && current == 0) {
      verdict = 'No expenses recorded in either month yet.';
      verdictColor = colors.onSurfaceVariant;
      verdictIcon = Icons.trending_flat;
    } else if (diff > 0) {
      verdict = previous > 0
          ? 'Spending increased by ${percent(change)} compared to $prevLabel.'
          : 'Spending increased. There were no expenses in $prevLabel.';
      verdictColor = colors.error;
      verdictIcon = Icons.trending_up;
    } else if (diff < 0) {
      verdict =
          'Spending decreased by ${percent(change.abs())} compared to $prevLabel.';
      verdictColor = Colors.green.shade700;
      verdictIcon = Icons.trending_down;
    } else {
      verdict = 'Spending is the same as $prevLabel.';
      verdictColor = colors.onSurfaceVariant;
      verdictIcon = Icons.trending_flat;
    }

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Monthly comparison',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            LabelValueRow(label: '$prevLabel expenses', value: peso(previous)),
            LabelValueRow(
                label: '${monthLabel(state.selectedMonth)} expenses',
                value: peso(current)),
            const Divider(),
            LabelValueRow(
                label: 'Difference',
                value: signedPeso(diff),
                valueColor: verdictColor),
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(verdictIcon, color: verdictColor),
                const SizedBox(width: 8),
                Expanded(
                    child: Text(verdict, style: TextStyle(color: verdictColor))),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
