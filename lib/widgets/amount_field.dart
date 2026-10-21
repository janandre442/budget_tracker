import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../utils/validators.dart';

/// Peso amount input. The minus sign is allowed on purpose so the
/// validator can show "Amount must be greater than zero" for -500.
class AmountField extends StatelessWidget {
  const AmountField({
    super.key,
    required this.controller,
    this.label = 'Amount',
    this.focusNode,
    this.autofocus = false,
    this.validator = Validators.amount,
  });

  final TextEditingController controller;
  final String label;
  final FocusNode? focusNode;
  final bool autofocus;
  final FormFieldValidator<String> validator;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      autofocus: autofocus,
      keyboardType:
          const TextInputType.numberWithOptions(decimal: true, signed: true),
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,\-]'))],
      decoration: InputDecoration(
        labelText: label,
        prefixText: '₱ ',
        border: const OutlineInputBorder(),
      ),
      validator: validator,
    );
  }
}
