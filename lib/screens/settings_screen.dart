import 'package:flutter/material.dart';

import '../services/app_state.dart';
import '../utils/dialogs.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _loadSample(BuildContext context) async {
    final ok = await confirmAction(
      context,
      title: 'Load sample data?',
      message:
          'This replaces everything in the app with sample income, expenses, budgets and recurring payments for this month and last month.',
      confirmLabel: 'Load sample data',
    );
    if (!ok || !context.mounted) return;
    await AppState.instance.loadSampleData();
    if (context.mounted) showMessage(context, 'Sample data loaded');
  }

  Future<void> _clearAll(BuildContext context) async {
    final ok = await confirmAction(
      context,
      title: 'Clear all data?',
      message:
          'All income, expenses, budgets, savings goals and recurring expenses will be deleted.',
      confirmLabel: 'Clear all data',
    );
    if (!ok || !context.mounted) return;
    await AppState.instance.clearAllData();
    if (context.mounted) showMessage(context, 'All data cleared');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          const ListTile(
            leading: Icon(Icons.storage_outlined),
            title: Text('Storage'),
            subtitle: Text(
                'Cloud Firestore with offline persistence. Changes save on this device first and sync when online.'),
          ),
          const ListTile(
            leading: Icon(Icons.currency_exchange),
            title: Text('Currency'),
            subtitle: Text('Philippine peso (₱)'),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.science_outlined),
            title: const Text('Load sample data'),
            subtitle: const Text('Fill the app with demo data for testing'),
            onTap: () => _loadSample(context),
          ),
          ListTile(
            leading: Icon(Icons.delete_forever_outlined, color: colors.error),
            title: Text('Clear all data', style: TextStyle(color: colors.error)),
            subtitle: const Text('Delete all your budget data'),
            onTap: () => _clearAll(context),
          ),
          const Divider(),
          const ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('Personal Budget Tracker'),
            subtitle: Text('Version 1.0.0, MP101 Intermediate Laboratory Activity'),
          ),
        ],
      ),
    );
  }
}
