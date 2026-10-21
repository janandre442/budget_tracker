import 'package:flutter/material.dart';

import '../services/finance_calculator.dart';
import '../utils/formatters.dart';

Color statusColor(BudgetStatus status, ColorScheme colors) => switch (status) {
      BudgetStatus.normal => Colors.green.shade600,
      BudgetStatus.warning => Colors.orange.shade700,
      BudgetStatus.exceeded => colors.error,
    };

String statusLabel(BudgetStatus status) => switch (status) {
      BudgetStatus.normal => 'Within normal spending range',
      BudgetStatus.warning => 'Approaching the limit',
      BudgetStatus.exceeded => 'Budget exceeded',
    };

/// Shows "₱2,500.00 / ₱3,000.00" with a colored bar and status text.
class BudgetProgress extends StatelessWidget {
  const BudgetProgress({
    super.key,
    required this.label,
    required this.spent,
    required this.limit,
    this.icon,
    this.iconColor,
    this.onEdit,
  });

  final String label;
  final double spent;
  final double limit;
  final IconData? icon;
  final Color? iconColor;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final percentUsed = FinanceCalculator.percentUsed(spent, limit);
    final status = FinanceCalculator.statusFor(percentUsed);
    final color = statusColor(status, theme.colorScheme);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (icon != null) ...[
              Icon(icon, size: 20, color: iconColor),
              const SizedBox(width: 8),
            ],
            Expanded(
              child: Text(label,
                  style: theme.textTheme.titleSmall,
                  overflow: TextOverflow.ellipsis),
            ),
            Text('${peso(spent)} / ${peso(limit)}',
                style: theme.textTheme.bodyMedium
                    ?.copyWith(fontWeight: FontWeight.w600)),
            if (onEdit != null)
              IconButton(
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined, size: 20),
                tooltip: 'Edit limit',
                visualDensity: VisualDensity.compact,
              ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: (percentUsed / 100).clamp(0.0, 1.0).toDouble(),
            minHeight: 8,
            color: color,
            backgroundColor: theme.colorScheme.surfaceContainerHighest,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Icon(
              status == BudgetStatus.normal
                  ? Icons.check_circle_outline
                  : Icons.warning_amber_rounded,
              size: 16,
              color: color,
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Text(statusLabel(status),
                  style: theme.textTheme.bodySmall?.copyWith(color: color)),
            ),
            Text(percent(percentUsed),
                style: theme.textTheme.bodySmall
                    ?.copyWith(fontWeight: FontWeight.w600, color: color)),
          ],
        ),
      ],
    );
  }
}
