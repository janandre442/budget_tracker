import 'package:flutter/material.dart';

import '../services/finance_calculator.dart';
import 'formatters.dart';

Future<bool> confirmAction(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = 'Delete',
  bool destructive = true,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          style: destructive
              ? FilledButton.styleFrom(
                  backgroundColor: Theme.of(ctx).colorScheme.error,
                  foregroundColor: Theme.of(ctx).colorScheme.onError,
                )
              : null,
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return result ?? false;
}

void showMessage(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}

/// Section 18: notify the user that a category limit has been exceeded.
Future<void> showBudgetExceededAlert(BuildContext context, CategoryUsage usage) {
  final colors = Theme.of(context).colorScheme;
  return showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      icon: Icon(Icons.warning_amber_rounded, color: colors.error, size: 40),
      title: Text('${usage.category} budget exceeded'),
      content: Text(
        'You have spent ${peso(usage.spent)} of your ${peso(usage.limit)} '
        '${usage.category} limit (${percent(usage.percent)}). '
        'That is ${peso(usage.spent - usage.limit)} over the limit.',
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('OK'),
        ),
      ],
    ),
  );
}

String expenseSavedMessage(CategoryUsage? usage) {
  if (usage == null) return 'Expense saved';
  return switch (usage.status) {
    BudgetStatus.exceeded =>
      'Expense saved. ${usage.category} is over its limit.',
    BudgetStatus.warning =>
      'Expense saved. ${usage.category} is at ${percent(usage.percent)} of its limit.',
    BudgetStatus.normal => 'Expense saved',
  };
}
