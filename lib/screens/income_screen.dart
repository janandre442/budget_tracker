import 'package:flutter/material.dart';

import '../models/income.dart';
import '../services/app_state.dart';
import '../utils/constants.dart';
import '../utils/dialogs.dart';
import '../utils/formatters.dart';
import '../widgets/empty_state.dart';
import 'income_form_screen.dart';

/// Section 2: add, edit, delete and view income history.
class IncomeScreen extends StatelessWidget {
  const IncomeScreen({super.key});

  void _open(BuildContext context, [Income? income]) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => IncomeFormScreen(income: income)),
    );
  }

  Future<void> _delete(BuildContext context, Income income) async {
    final ok = await confirmAction(
      context,
      title: 'Delete income?',
      message:
          'Remove ${income.source} income of ${peso(income.amount)}? This cannot be undone.',
    );
    if (!ok || !context.mounted) return;
    await AppState.instance.deleteIncome(income.id!);
    if (context.mounted) showMessage(context, 'Income deleted');
  }

  @override
  Widget build(BuildContext context) {
    final state = AppState.instance;
    return ListenableBuilder(
      listenable: state,
      builder: (context, _) {
        final theme = Theme.of(context);
        final incomes = state.incomes;
        return Scaffold(
          body: incomes.isEmpty
              ? EmptyState(
                  icon: Icons.savings_outlined,
                  title: 'No income recorded',
                  message:
                      'Add your salary, allowance or other income for ${monthLabel(state.selectedMonth)}.',
                  actionLabel: 'Add income',
                  onAction: () => _open(context),
                )
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                  children: [
                    Card(
                      child: ListTile(
                        leading: Icon(Icons.trending_up,
                            color: Colors.green.shade700),
                        title: const Text('Total income'),
                        subtitle: Text(
                            '${incomes.length} record${incomes.length == 1 ? '' : 's'} in ${monthLabel(state.selectedMonth)}'),
                        trailing: Text(
                          peso(state.totalIncome),
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: Colors.green.shade700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text('Income history',
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700)),
                    Text('Tap to edit. Long press to delete.',
                        style: theme.textTheme.bodySmall),
                    const SizedBox(height: 8),
                    Card(
                      child: Column(
                        children: [
                          for (final income in incomes)
                            ListTile(
                              onTap: () => _open(context, income),
                              onLongPress: () => _delete(context, income),
                              leading: CircleAvatar(
                                backgroundColor: Colors.green.withAlpha(38),
                                child: Icon(incomeIcon(income.source),
                                    color: Colors.green.shade700, size: 20),
                              ),
                              title: Text(income.source),
                              subtitle: Text(
                                income.description.isEmpty
                                    ? shortDate(income.date)
                                    : '${shortDate(income.date)}\n${income.description}',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              trailing: Text(
                                '+${peso(income.amount)}',
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: Colors.green.shade700,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
          floatingActionButton: FloatingActionButton.extended(
            heroTag: 'income_fab',
            onPressed: () => _open(context),
            icon: const Icon(Icons.add),
            label: const Text('Add income'),
          ),
        );
      },
    );
  }
}
