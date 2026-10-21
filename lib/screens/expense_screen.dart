import 'dart:async';

import 'package:flutter/material.dart';

import '../models/expense.dart';
import '../models/expense_filter.dart';
import '../services/app_state.dart';
import '../services/finance_calculator.dart';
import '../utils/dialogs.dart';
import '../utils/formatters.dart';
import '../widgets/empty_state.dart';
import '../widgets/expense_filter_sheet.dart';
import '../widgets/expense_tile.dart';
import 'expense_form_screen.dart';
import 'recurring_screen.dart';

/// Section 3 and 11: ordinary transactions and recurring expenses are
/// kept in separate tabs.
class ExpenseScreen extends StatelessWidget {
  const ExpenseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const DefaultTabController(
      length: 2,
      child: Column(
        children: [
          TabBar(
            tabs: [
              Tab(text: 'Transactions'),
              Tab(text: 'Recurring'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                ExpenseHistoryView(),
                RecurringExpensesView(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Section 9: search by title or description, filter by category, date,
/// payment method and amount range.
class ExpenseHistoryView extends StatefulWidget {
  const ExpenseHistoryView({super.key});

  @override
  State<ExpenseHistoryView> createState() => _ExpenseHistoryViewState();
}

class _ExpenseHistoryViewState extends State<ExpenseHistoryView> {
  final AppState _state = AppState.instance;
  final TextEditingController _searchCtrl = TextEditingController();
  ExpenseFilter _filter = const ExpenseFilter();
  StreamSubscription<List<Expense>>? _subscription;
  String? _rangeKey;
  List<Expense> _source = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _state.addListener(_onStateChanged);
    _subscribeIfNeeded();
  }

  @override
  void dispose() {
    _state.removeListener(_onStateChanged);
    _subscription?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  bool get _isFiltering =>
      _searchCtrl.text.trim().isNotEmpty || _filter.activeCount > 0;

  /// Custom date range from the filter, otherwise the selected month.
  (DateTime, DateTime) get _range => _filter.hasDateRange
      ? (_filter.startDate!, _filter.endDate!)
      : (_state.monthStart, _state.monthEnd);

  void _onStateChanged() {
    if (mounted) setState(_subscribeIfNeeded);
  }

  /// Firestore query for the date range. The other filters are applied in
  /// memory by ExpenseFilter.matches().
  void _subscribeIfNeeded() {
    final (start, end) = _range;
    final key = '${toDateKey(start)}|${toDateKey(end)}';
    if (key == _rangeKey) return;
    _rangeKey = key;
    _loading = true;
    _subscription?.cancel();
    _subscription = _state.watchExpenses(start, end).listen((list) {
      if (!mounted) return;
      setState(() {
        _source = list;
        _loading = false;
      });
    });
  }

  List<Expense> get _results {
    final filter = _filter.copyWith(query: _searchCtrl.text);
    return _source.where(filter.matches).toList();
  }

  void _setFilter(ExpenseFilter filter) {
    setState(() {
      _filter = filter;
      _subscribeIfNeeded();
    });
  }

  void _clearAll() {
    _searchCtrl.clear();
    _setFilter(const ExpenseFilter());
  }

  Future<void> _openFilters() async {
    final result = await showModalBottomSheet<ExpenseFilter>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => ExpenseFilterSheet(initial: _filter),
    );
    if (result != null) _setFilter(result);
  }

  void _openForm([Expense? expense]) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ExpenseFormScreen(expense: expense)),
    );
  }

  Future<void> _delete(Expense expense) async {
    final ok = await confirmAction(
      context,
      title: 'Delete expense?',
      message:
          'Remove "${expense.title}" (${peso(expense.amount)})? This cannot be undone.',
    );
    if (!ok) return;
    await _state.deleteExpense(expense.id!);
    if (mounted) showMessage(context, 'Expense deleted');
  }

  String _amountLabel(ExpenseFilter f) {
    if (f.minAmount != null && f.maxAmount != null) {
      return '${peso(f.minAmount!)} to ${peso(f.maxAmount!)}';
    }
    if (f.minAmount != null) return 'At least ${peso(f.minAmount!)}';
    return 'Up to ${peso(f.maxAmount!)}';
  }

  List<Widget> _activeChips() {
    final f = _filter;
    Widget chip(String label, VoidCallback onDeleted) => Padding(
          padding: const EdgeInsets.only(right: 8),
          child: InputChip(label: Text(label), onDeleted: onDeleted),
        );
    return [
      if (f.category != null)
        chip(f.category!, () => _setFilter(f.copyWith(category: null))),
      if (f.paymentMethod != null)
        chip(f.paymentMethod!,
            () => _setFilter(f.copyWith(paymentMethod: null))),
      if (f.hasDateRange)
        chip('${shortDate(f.startDate!)} to ${shortDate(f.endDate!)}',
            () => _setFilter(f.copyWith(startDate: null, endDate: null))),
      if (f.minAmount != null || f.maxAmount != null)
        chip(_amountLabel(f),
            () => _setFilter(f.copyWith(minAmount: null, maxAmount: null))),
    ];
  }

  Widget _buildList(List<Expense> results) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (results.isEmpty) {
      if (_isFiltering) {
        return EmptyState(
          icon: Icons.search_off,
          title: 'No matching expenses',
          message: 'Try another keyword or remove some filters.',
          actionLabel: 'Clear search and filters',
          onAction: _clearAll,
        );
      }
      return EmptyState(
        icon: Icons.receipt_long_outlined,
        title: 'No expenses yet',
        message:
            'You have no expenses for ${monthLabel(_state.selectedMonth)}. Tap "Add expense" to record one.',
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.only(bottom: 96),
      itemCount: results.length,
      separatorBuilder: (_, __) => const Divider(height: 1, indent: 72),
      itemBuilder: (context, i) {
        final e = results[i];
        return ExpenseTile(
          expense: e,
          onTap: () => _openForm(e),
          onLongPress: () => _delete(e),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final results = _results;
    final total = FinanceCalculator.sum(results.map((e) => e.amount));
    final chips = _activeChips();

    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchCtrl,
                    textInputAction: TextInputAction.search,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: 'Search title or description',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchCtrl.text.isEmpty
                          ? null
                          : IconButton(
                              icon: const Icon(Icons.clear),
                              tooltip: 'Clear search',
                              onPressed: () {
                                _searchCtrl.clear();
                                setState(() {});
                              },
                            ),
                      isDense: true,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Badge(
                  isLabelVisible: _filter.activeCount > 0,
                  label: Text('${_filter.activeCount}'),
                  child: IconButton.filledTonal(
                    onPressed: _openFilters,
                    icon: const Icon(Icons.tune),
                    tooltip: 'Filters',
                  ),
                ),
              ],
            ),
          ),
          if (chips.isNotEmpty)
            SizedBox(
              height: 48,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                children: [
                  ...chips,
                  ActionChip(
                      label: const Text('Clear all'), onPressed: _clearAll),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _filter.hasDateRange
                        ? 'Custom date range'
                        : monthLabel(_state.selectedMonth),
                    style: theme.textTheme.bodySmall,
                  ),
                ),
                Text(
                  '${results.length} result${results.length == 1 ? '' : 's'}, ${peso(total)}',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
          Expanded(child: _buildList(results)),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'expense_fab',
        onPressed: () => _openForm(),
        icon: const Icon(Icons.add),
        label: const Text('Add expense'),
      ),
    );
  }
}
