import 'package:flutter/material.dart';

import '../models/recurring_expense.dart';
import '../services/app_state.dart';
import '../services/finance_calculator.dart';
import '../utils/constants.dart';
import '../utils/dialogs.dart';
import '../utils/formatters.dart';
import '../utils/validators.dart';
import '../widgets/amount_field.dart';
import '../widgets/date_form_field.dart';
import '../widgets/empty_state.dart';

/// Section 11: recurring expenses, listed apart from ordinary transactions.
class RecurringExpensesView extends StatelessWidget {
  const RecurringExpensesView({super.key});

  void _openForm(BuildContext context, [RecurringExpense? item]) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => RecurringFormScreen(item: item)),
    );
  }

  Future<void> _markPaid(BuildContext context, RecurringExpense item) async {
    final paidOn = item.paymentDate(DateTime.now());
    final ok = await confirmAction(
      context,
      title: 'Record payment?',
      message:
          'This adds a ${peso(item.amount)} "${item.title}" expense dated ${shortDate(paidOn)} '
          'and moves the next payment to ${longDate(item.followingDueDate())}.',
      confirmLabel: 'Mark as paid',
      destructive: false,
    );
    if (!ok || !context.mounted) return;
    try {
      final usage = await AppState.instance.markRecurringPaid(item);
      if (!context.mounted) return;
      if (usage != null && usage.status == BudgetStatus.exceeded) {
        await showBudgetExceededAlert(context, usage);
        if (!context.mounted) return;
      }
      showMessage(context, '${item.title} payment recorded');
    } on ValidationException catch (e) {
      if (context.mounted) showMessage(context, e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = AppState.instance;
    return ListenableBuilder(
      listenable: state,
      builder: (context, _) {
        final theme = Theme.of(context);
        final items = state.recurringExpenses;
        return Scaffold(
          body: items.isEmpty
              ? EmptyState(
                  icon: Icons.autorenew,
                  title: 'No recurring expenses',
                  message:
                      'Add bills that repeat, like Internet, electricity, rent, streaming or your phone plan.',
                  actionLabel: 'Add recurring expense',
                  onAction: () => _openForm(context),
                )
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                  children: [
                    Card(
                      child: ListTile(
                        leading: Icon(Icons.calendar_month,
                            color: theme.colorScheme.primary),
                        title: const Text('Monthly commitment'),
                        subtitle: Text(
                            '${items.length} recurring expense${items.length == 1 ? '' : 's'}'),
                        trailing: Text(
                          peso(state.recurringMonthlyCommitment),
                          style: theme.textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    for (final item in items)
                      _RecurringCard(
                        item: item,
                        onEdit: () => _openForm(context, item),
                        onMarkPaid: () => _markPaid(context, item),
                      ),
                  ],
                ),
          floatingActionButton: FloatingActionButton.extended(
            heroTag: 'recurring_fab',
            onPressed: () => _openForm(context),
            icon: const Icon(Icons.add),
            label: const Text('Add recurring'),
          ),
        );
      },
    );
  }
}

class _RecurringCard extends StatelessWidget {
  const _RecurringCard({
    required this.item,
    required this.onEdit,
    required this.onMarkPaid,
  });

  final RecurringExpense item;
  final VoidCallback onEdit;
  final VoidCallback onMarkPaid;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final today = DateTime.now();
    final isDue = item.isDue(today);
    final days = item.daysUntilDue(today);
    final color = categoryColor(item.category);

    final String dueText;
    if (isDue && days < 0) {
      dueText = 'Overdue by ${-days} day${days == -1 ? '' : 's'}';
    } else if (isDue) {
      dueText = 'Due today';
    } else {
      dueText = 'Due in $days day${days == 1 ? '' : 's'}';
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: color.withAlpha(38),
                  child: Icon(categoryIcon(item.category), color: color, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.title,
                          style: theme.textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700)),
                      Text('${item.category}, ${item.paymentMethod}',
                          style: theme.textTheme.bodySmall),
                    ],
                  ),
                ),
                Text(peso(item.amount),
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700)),
              ],
            ),
            const SizedBox(height: 12),
            Text('Frequency: ${item.frequency}'),
            Text('Next payment: ${longDate(item.nextDueDate)}'),
            const SizedBox(height: 4),
            Text(
              dueText,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: isDue ? colors.error : colors.primary,
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(onPressed: onEdit, child: const Text('Edit')),
                const SizedBox(width: 4),
                FilledButton.tonal(
                    onPressed: onMarkPaid, child: const Text('Mark as paid')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class RecurringFormScreen extends StatefulWidget {
  const RecurringFormScreen({super.key, this.item});

  final RecurringExpense? item;

  @override
  State<RecurringFormScreen> createState() => _RecurringFormScreenState();
}

class _RecurringFormScreenState extends State<RecurringFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleCtrl;
  late final TextEditingController _amountCtrl;
  String? _category;
  String? _paymentMethod;
  String _frequency = 'Monthly';
  DateTime? _nextDue;
  bool _saving = false;

  bool get _isEditing => widget.item != null;

  @override
  void initState() {
    super.initState();
    final item = widget.item;
    _titleCtrl = TextEditingController(text: item?.title ?? '');
    _amountCtrl = TextEditingController(
        text: item == null ? '' : item.amount.toStringAsFixed(2));
    _category = item?.category;
    _paymentMethod = item?.paymentMethod;
    _frequency = item?.frequency ?? 'Monthly';
    _nextDue = item?.nextDueDate;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final item = RecurringExpense(
      id: widget.item?.id,
      title: _titleCtrl.text.trim(),
      amount: Validators.tryParseAmount(_amountCtrl.text)!,
      category: _category!,
      paymentMethod: _paymentMethod!,
      frequency: _frequency,
      nextDueDate: _nextDue!,
    );
    try {
      if (_isEditing) {
        await AppState.instance.updateRecurring(item);
      } else {
        await AppState.instance.addRecurring(item);
      }
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      Navigator.of(context).pop();
      messenger.showSnackBar(
          const SnackBar(content: Text('Recurring expense saved')));
    } on ValidationException catch (e) {
      if (mounted) showMessage(context, e.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete() async {
    final item = widget.item!;
    final ok = await confirmAction(
      context,
      title: 'Delete recurring expense?',
      message:
          'Stop tracking "${item.title}"? Payments you already recorded stay in your expense history.',
    );
    if (!ok || !mounted) return;
    await AppState.instance.deleteRecurring(item.id!);
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    Navigator.of(context).pop();
    messenger.showSnackBar(
        const SnackBar(content: Text('Recurring expense deleted')));
  }

  @override
  Widget build(BuildContext context) {
    const gap = SizedBox(height: 16);
    return Scaffold(
      appBar: AppBar(
        title:
            Text(_isEditing ? 'Edit recurring expense' : 'Add recurring expense'),
        actions: [
          if (_isEditing)
            IconButton(
              onPressed: _saving ? null : _delete,
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Delete',
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _titleCtrl,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Title',
                hintText: 'e.g. Internet, Rent, Phone plan',
                border: OutlineInputBorder(),
              ),
              validator: (v) => Validators.requiredText(v, 'Title'),
            ),
            gap,
            AmountField(controller: _amountCtrl),
            gap,
            DropdownButtonFormField<String>(
              value: _category,
              isExpanded: true,
              decoration: const InputDecoration(
                  labelText: 'Category', border: OutlineInputBorder()),
              items: [
                for (final c in AppConstants.expenseCategories)
                  DropdownMenuItem(value: c, child: Text(c)),
              ],
              onChanged: (v) => setState(() => _category = v),
              validator: (v) =>
                  Validators.requiredSelection(v, 'Please select a category'),
            ),
            gap,
            DropdownButtonFormField<String>(
              value: _paymentMethod,
              isExpanded: true,
              decoration: const InputDecoration(
                  labelText: 'Payment method', border: OutlineInputBorder()),
              items: [
                for (final m in AppConstants.paymentMethods)
                  DropdownMenuItem(value: m, child: Text(m)),
              ],
              onChanged: (v) => setState(() => _paymentMethod = v),
              validator: (v) => Validators.requiredSelection(
                  v, 'Please select a payment method'),
            ),
            gap,
            DropdownButtonFormField<String>(
              value: _frequency,
              isExpanded: true,
              decoration: const InputDecoration(
                  labelText: 'Frequency', border: OutlineInputBorder()),
              items: [
                for (final f in AppConstants.frequencies)
                  DropdownMenuItem(value: f, child: Text(f)),
              ],
              onChanged: (v) => setState(() => _frequency = v ?? 'Monthly'),
            ),
            gap,
            DateFormField(
              label: 'Next payment date',
              initialDate: _nextDue,
              allowFuture: true,
              onChanged: (d) => _nextDue = d,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _saving ? null : _save,
              icon: const Icon(Icons.save_outlined),
              label: Text(_isEditing ? 'Update' : 'Save recurring expense'),
            ),
          ],
        ),
      ),
    );
  }
}
