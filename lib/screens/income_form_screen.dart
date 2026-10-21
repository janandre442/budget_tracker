import 'package:flutter/material.dart';

import '../models/income.dart';
import '../services/app_state.dart';
import '../utils/constants.dart';
import '../utils/dialogs.dart';
import '../utils/formatters.dart';
import '../utils/validators.dart';
import '../widgets/amount_field.dart';
import '../widgets/date_form_field.dart';

class IncomeFormScreen extends StatefulWidget {
  const IncomeFormScreen({super.key, this.income});

  final Income? income;

  @override
  State<IncomeFormScreen> createState() => _IncomeFormScreenState();
}

class _IncomeFormScreenState extends State<IncomeFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _amountCtrl;
  late final TextEditingController _descriptionCtrl;
  String? _source;
  DateTime? _date;
  bool _saving = false;

  bool get _isEditing => widget.income != null;

  @override
  void initState() {
    super.initState();
    final income = widget.income;
    _amountCtrl = TextEditingController(
        text: income == null ? '' : income.amount.toStringAsFixed(2));
    _descriptionCtrl = TextEditingController(text: income?.description ?? '');
    _source = income?.source;
    _date = income?.date ?? dateOnly(DateTime.now());
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _descriptionCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final income = Income(
      id: widget.income?.id,
      source: _source!,
      amount: Validators.tryParseAmount(_amountCtrl.text)!,
      date: _date!,
      description: _descriptionCtrl.text.trim(),
    );
    try {
      if (_isEditing) {
        await AppState.instance.updateIncome(income);
      } else {
        await AppState.instance.addIncome(income);
      }
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      Navigator.of(context).pop();
      messenger.showSnackBar(
          SnackBar(content: Text(_isEditing ? 'Income updated' : 'Income saved')));
    } on ValidationException catch (e) {
      if (mounted) showMessage(context, e.message);
    } catch (e) {
      if (mounted) showMessage(context, 'Could not save income: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete() async {
    final income = widget.income!;
    final ok = await confirmAction(
      context,
      title: 'Delete income?',
      message:
          'Remove ${income.source} income of ${peso(income.amount)}? This cannot be undone.',
    );
    if (!ok || !mounted) return;
    await AppState.instance.deleteIncome(income.id!);
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    Navigator.of(context).pop();
    messenger.showSnackBar(const SnackBar(content: Text('Income deleted')));
  }

  @override
  Widget build(BuildContext context) {
    const gap = SizedBox(height: 16);
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit income' : 'Add income'),
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
            DropdownButtonFormField<String>(
              value: _source,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Source',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.work_outline),
              ),
              items: [
                for (final s in AppConstants.incomeSources)
                  DropdownMenuItem(value: s, child: Text(s)),
              ],
              onChanged: (v) => setState(() => _source = v),
              validator: (v) =>
                  Validators.requiredSelection(v, 'Please select a source'),
            ),
            gap,
            AmountField(controller: _amountCtrl),
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
              label: Text(_isEditing ? 'Update income' : 'Save income'),
            ),
          ],
        ),
      ),
    );
  }
}
