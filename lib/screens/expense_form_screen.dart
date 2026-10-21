import 'package:flutter/material.dart';

import '../models/expense.dart';
import '../services/app_state.dart';
import '../services/finance_calculator.dart';
import '../utils/constants.dart';
import '../utils/dialogs.dart';
import '../utils/formatters.dart';
import '../utils/validators.dart';
import '../widgets/amount_field.dart';
import '../widgets/date_form_field.dart';

class ExpenseFormScreen extends StatefulWidget {
  const ExpenseFormScreen({super.key, this.expense});

  final Expense? expense;

  @override
  State<ExpenseFormScreen> createState() => _ExpenseFormScreenState();
}

class _ExpenseFormScreenState extends State<ExpenseFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleCtrl;
  late final TextEditingController _amountCtrl;
  late final TextEditingController _descriptionCtrl;
  String? _category;
  String? _paymentMethod;
  DateTime? _date;
  bool _saving = false;

  bool get _isEditing => widget.expense != null;

  @override
  void initState() {
    super.initState();
    final e = widget.expense;
    _titleCtrl = TextEditingController(text: e?.title ?? '');
    _amountCtrl =
        TextEditingController(text: e == null ? '' : e.amount.toStringAsFixed(2));
    _descriptionCtrl = TextEditingController(text: e?.description ?? '');
    _category = e?.category;
    _paymentMethod = e?.paymentMethod;
    _date = e?.date ?? dateOnly(DateTime.now());
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _amountCtrl.dispose();
    _descriptionCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    // Invalid data never reaches the database: the form stops here first.
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final expense = Expense(
      id: widget.expense?.id,
      title: _titleCtrl.text.trim(),
      amount: Validators.tryParseAmount(_amountCtrl.text)!,
      category: _category!,
      date: _date!,
      paymentMethod: _paymentMethod!,
      description: _descriptionCtrl.text.trim(),
      recurringId: widget.expense?.recurringId,
    );

    try {
      final state = AppState.instance;
      final usage = _isEditing
          ? await state.updateExpense(expense)
          : await state.addExpense(expense);
      if (!mounted) return;

      if (usage != null && usage.status == BudgetStatus.exceeded) {
        await showBudgetExceededAlert(context, usage);
        if (!mounted) return;
      }

      final messenger = ScaffoldMessenger.of(context);
      Navigator.of(context).pop();
      messenger.showSnackBar(SnackBar(content: Text(expenseSavedMessage(usage))));
    } on ValidationException catch (e) {
      if (mounted) showMessage(context, e.message);
    } catch (e) {
      if (mounted) showMessage(context, 'Could not save expense: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete() async {
    final e = widget.expense!;
    final ok = await confirmAction(
      context,
      title: 'Delete expense?',
      message: 'Remove "${e.title}" (${peso(e.amount)})? This cannot be undone.',
    );
    if (!ok || !mounted) return;
    await AppState.instance.deleteExpense(e.id!);
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    Navigator.of(context).pop();
    messenger.showSnackBar(const SnackBar(content: Text('Expense deleted')));
  }

  @override
  Widget build(BuildContext context) {
    const gap = SizedBox(height: 16);
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit expense' : 'Add expense'),
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
            if (widget.expense?.isRecurring ?? false) ...[
              Card(
                color: colors.secondaryContainer,
                child: ListTile(
                  leading: const Icon(Icons.autorenew),
                  title: const Text('Recorded from a recurring payment'),
                  textColor: colors.onSecondaryContainer,
                  iconColor: colors.onSecondaryContainer,
                ),
              ),
              gap,
            ],
            TextFormField(
              controller: _titleCtrl,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Title',
                hintText: 'e.g. Lunch, Jeepney fare',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.edit_outlined),
              ),
              validator: (v) => Validators.requiredText(v, 'Expense title'),
            ),
            gap,
            AmountField(controller: _amountCtrl),
            gap,
            DropdownButtonFormField<String>(
              value: _category,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Category',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.category_outlined),
              ),
              items: [
                for (final c in AppConstants.expenseCategories)
                  DropdownMenuItem(
                    value: c,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(categoryIcon(c), size: 20, color: categoryColor(c)),
                        const SizedBox(width: 10),
                        Text(c),
                      ],
                    ),
                  ),
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
                labelText: 'Payment method',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.payment),
              ),
              items: [
                for (final m in AppConstants.paymentMethods)
                  DropdownMenuItem(value: m, child: Text(m)),
              ],
              onChanged: (v) => setState(() => _paymentMethod = v),
              validator: (v) => Validators.requiredSelection(
                  v, 'Please select a payment method'),
            ),
            gap,
            DateFormField(
              label: 'Date',
              initialDate: _date,
              onChanged: (d) => _date = d,
            ),
            gap,
            TextFormField(
              controller: _descriptionCtrl,
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Description (optional)',
                alignLabelWithHint: true,
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _saving ? null : _save,
              icon: const Icon(Icons.save_outlined),
              label: Text(_isEditing ? 'Update expense' : 'Save expense'),
            ),
          ],
        ),
      ),
    );
  }
}
