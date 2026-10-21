import 'package:flutter/material.dart';

import '../services/app_state.dart';
import '../utils/formatters.dart';

/// Switches the month that every screen calculates from.
class MonthSelector extends StatelessWidget {
  const MonthSelector({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppState.instance;
    final theme = Theme.of(context);
    return ListenableBuilder(
      listenable: state,
      builder: (context, _) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          children: [
            IconButton(
              onPressed: () => state.changeMonth(-1),
              icon: const Icon(Icons.chevron_left),
              tooltip: 'Previous month',
            ),
            Expanded(
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: state.isCurrentMonth ? null : state.goToCurrentMonth,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(monthLabel(state.selectedMonth),
                          style: theme.textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700)),
                      if (!state.isCurrentMonth)
                        Text('Tap to go back to this month',
                            style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.primary)),
                    ],
                  ),
                ),
              ),
            ),
            IconButton(
              onPressed: () => state.changeMonth(1),
              icon: const Icon(Icons.chevron_right),
              tooltip: 'Next month',
            ),
          ],
        ),
      ),
    );
  }
}
