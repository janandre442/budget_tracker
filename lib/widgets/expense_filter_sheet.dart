import 'package:flutter/material.dart';

import '../models/expense_filter.dart';
import '../utils/constants.dart';
import '../utils/formatters.dart';
import '../utils/validators.dart';

/// Bottom sheet for category, payment method, date and amount filters.
class ExpenseFilterSheet extends StatefulWidget {
  const ExpenseFilterSheet({super.key, required this.initial});

  final ExpenseFilter initial;

  @override
  State<ExpenseFilterSheet> createState() => _ExpenseFilterSheetState();
}

class _ExpenseFilterSheetState extends State<ExpenseFilterSheet> {
  final _formKey = GlobalKey<FormState>();
  String? _category;
  String? _paymentMethod;
  DateTimeRange? _range;
  late final TextEditingController _minCtrl;
  late final TextEditingController _maxCtrl;

  @override
  void initState() {
    super.initState();
    final f = widget.initial;
    _category = f.category;
    _paymentMethod = f.paymentMethod;
    _range = f.hasDateRange
        ? DateTimeRange(start: f.startDate!, end: f.endDate!)
        : null;
    _minCtrl = TextEditingController(text: f.minAmount?.toStringAsFixed(2) ?? '');
    _maxCtrl = TextEditingController(text: f.maxAmount?.toStringAsFixed(2) ?? '');
  }

  @override
  void dispose() {
    _minCtrl.dispose();
    _maxCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      initialDateRange: _range,
    );
    if (picked != null) setState(() => _range = picked);
  }

  void _apply() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(
      context,
      ExpenseFilter(
        query: widget.initial.query,
        category: _category,
        paymentMethod: _paymentMethod,
        startDate: _range?.start,
        endDate: _range?.end,
        minAmount: Validators.tryParseAmount(_minCtrl.text),
        maxAmount: Validators.tryParseAmount(_maxCtrl.text),
      ),
    );
  }

  String? _validateMax(String? value) {
    final base = Validators.optionalAmount(value);
    if (base != null) return base;
    final min = Validators.tryParseAmount(_minCtrl.text);
    final max = Validators.tryParseAmount(value);
    if (min != null && max != null && max < min) return 'Must not be below min';
    return null;
  }

  InputDecoration _decoration(String label) =>
      InputDecoration(labelText: label, border: const OutlineInputBorder());

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          20, 0, 20, MediaQuery.viewInsetsOf(context).bottom + 20),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Filter expenses',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              DropdownButtonFormField<String?>(
                value: _category,
                isExpanded: true,
                decoration: _decoration('Category'),
                items: [
                  const DropdownMenuItem<String?>(
                      value: null, child: Text('All categories')),
                  for (final c in AppConstants.expenseCategories)
                    DropdownMenuItem<String?>(value: c, child: Text(c)),
                ],
                onChanged: (v) => setState(() => _category = v),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String?>(
                value: _paymentMethod,
                isExpanded: true,
                decoration: _decoration('Payment method'),
                items: [
                  const DropdownMenuItem<String?>(
                      value: null, child: Text('All payment methods')),
                  for (final m in AppConstants.paymentMethods)
                    DropdownMenuItem<String?>(value: m, child: Text(m)),
                ],
                onChanged: (v) => setState(() => _paymentMethod = v),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _pickRange,
                      icon: const Icon(Icons.date_range),
                      label: Text(_range == null
                          ? 'Any date in selected month'
                          : '${shortDate(_range!.start)} to ${shortDate(_range!.end)}'),
                    ),
                  ),
                  if (_range != null)
                    IconButton(
                      onPressed: () => setState(() => _range = null),
                      icon: const Icon(Icons.close),
                      tooltip: 'Clear date filter',
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _minCtrl,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: _decoration('Min amount')
                          .copyWith(prefixText: '₱ '),
                      validator: Validators.optionalAmount,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _maxCtrl,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: _decoration('Max amount')
                          .copyWith(prefixText: '₱ '),
                      validator: _validateMax,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(
                        context, ExpenseFilter(query: widget.initial.query)),
                    child: const Text('Reset'),
                  ),
                  const Spacer(),
                  FilledButton(
                      onPressed: _apply, child: const Text('Apply filters')),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
