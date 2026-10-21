import 'package:flutter/material.dart';

import '../utils/validators.dart';
import 'amount_field.dart';

class AmountDialogResult {
  final double? amount;
  final bool remove;

  const AmountDialogResult.save(this.amount) : remove = false;
  const AmountDialogResult.remove()
      : amount = null,
        remove = true;
}

class AmountInputDialog extends StatefulWidget {
  const AmountInputDialog({
    super.key,
    required this.title,
    required this.label,
    this.initialValue,
    this.message,
    this.allowRemove = false,
    this.saveLabel = 'Save',
  });

  final String title;
  final String label;
  final double? initialValue;
  final String? message;
  final bool allowRemove;
  final String saveLabel;

  @override
  State<AmountInputDialog> createState() => _AmountInputDialogState();
}

class _AmountInputDialogState extends State<AmountInputDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _controller = TextEditingController(
      text: widget.initialValue?.toStringAsFixed(2) ?? '');

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(context,
        AmountDialogResult.save(Validators.tryParseAmount(_controller.text)));
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return AlertDialog(
      title: Text(widget.title),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.message != null) ...[
              Text(widget.message!),
              const SizedBox(height: 12),
            ],
            AmountField(
                controller: _controller, label: widget.label, autofocus: true),
          ],
        ),
      ),
      actions: [
        if (widget.allowRemove)
          TextButton(
            style: TextButton.styleFrom(foregroundColor: colors.error),
            onPressed: () =>
                Navigator.pop(context, const AmountDialogResult.remove()),
            child: const Text('Remove'),
          ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _save, child: Text(widget.saveLabel)),
      ],
    );
  }
}
