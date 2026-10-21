import 'package:flutter/material.dart';

import '../models/expense.dart';
import '../utils/constants.dart';
import '../utils/formatters.dart';

class ExpenseTile extends StatelessWidget {
  const ExpenseTile({
    super.key,
    required this.expense,
    this.onTap,
    this.onLongPress,
  });

  final Expense expense;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = categoryColor(expense.category);
    return ListTile(
      onTap: onTap,
      onLongPress: onLongPress,
      leading: CircleAvatar(
        backgroundColor: color.withAlpha(38),
        child: Icon(categoryIcon(expense.category), color: color, size: 20),
      ),
      title: Text(expense.title, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(
        '${expense.category}, ${expense.paymentMethod}\n${shortDate(expense.date)}',
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      isThreeLine: true,
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            peso(expense.amount),
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.error,
            ),
          ),
          if (expense.isRecurring)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.autorenew,
                      size: 14, color: theme.colorScheme.primary),
                  const SizedBox(width: 2),
                  Text('Recurring',
                      style: theme.textTheme.labelSmall
                          ?.copyWith(color: theme.colorScheme.primary)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
