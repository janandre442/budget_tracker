import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/budget.dart';
import '../models/category_budget.dart';
import '../models/expense.dart';
import '../models/income.dart';
import '../models/recurring_expense.dart';
import '../models/savings_goal.dart';
import '../utils/constants.dart';
import '../utils/formatters.dart';
import 'database_service.dart';
import 'finance_calculator.dart';
import 'sample_data.dart';

class ValidationException implements Exception {
  final String message;
  const ValidationException(this.message);

  @override
  String toString() => message;
}

/// Listens to Firestore for the selected month and recalculates every total
/// from the latest data. Firestore pushes changes through snapshot streams,
/// so adding, editing or deleting anything updates every screen right away.
class AppState extends ChangeNotifier {
  AppState._();
  static final AppState instance = AppState._();

  final DatabaseService _db = DatabaseService.instance;
  final List<StreamSubscription<Object?>> _subscriptions = [];

  static DateTime _currentMonth() {
    final now = DateTime.now();
    return DateTime(now.year, now.month);
  }

  DateTime _selectedMonth = _currentMonth();
  String? _loadError;

  List<Income> _incomes = const [];
  List<Expense> _expenses = const [];
  Budget? _budget;
  Map<String, double> _categoryLimits = const {};
  SavingsGoal? _savingsGoal;
  List<RecurringExpense> _recurring = const [];
  double _previousMonthExpenses = 0;

  // --------------------------------------------------------------- Raw data

  DateTime get selectedMonth => _selectedMonth;
  String? get loadError => _loadError;
  List<Income> get incomes => _incomes;
  List<Expense> get expenses => _expenses;
  Budget? get budget => _budget;
  Map<String, double> get categoryLimits => _categoryLimits;
  SavingsGoal? get savingsGoal => _savingsGoal;
  List<RecurringExpense> get recurringExpenses => _recurring;
  double get previousMonthExpenses => _previousMonthExpenses;

  DateTime get monthStart => _selectedMonth;
  DateTime get monthEnd =>
      DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0);
  DateTime get previousMonth =>
      DateTime(_selectedMonth.year, _selectedMonth.month - 1);
  String get selectedMonthKey => toMonthKey(_selectedMonth);

  bool get isCurrentMonth {
    final now = DateTime.now();
    return now.year == _selectedMonth.year && now.month == _selectedMonth.month;
  }

  // ---------------------------------------------------- Calculated values

  bool get hasBudget => _budget != null;
  bool get isBudgetCarriedOver =>
      _budget != null && _budget!.month != selectedMonthKey;
  double get monthlyBudget => _budget?.amount ?? 0;

  double get totalIncome => FinanceCalculator.sum(_incomes.map((i) => i.amount));
  double get totalExpenses =>
      FinanceCalculator.sum(_expenses.map((e) => e.amount));

  double get remainingBudget =>
      FinanceCalculator.remainingBudget(monthlyBudget, totalExpenses);
  double get budgetUsedPercent =>
      FinanceCalculator.percentUsed(totalExpenses, monthlyBudget);
  BudgetStatus get overallStatus =>
      FinanceCalculator.statusFor(budgetUsedPercent);

  /// Analytics: Remaining Balance = Total Income - Total Expenses
  double get remainingBalance => totalIncome - totalExpenses;

  double get currentSavings => _savingsGoal?.currentSavings ?? 0;
  double get savingsTarget => _savingsGoal?.target ?? 0;
  double get savingsProgress =>
      FinanceCalculator.savingsProgress(currentSavings, savingsTarget);
  double get savingsRate =>
      FinanceCalculator.savingsRate(currentSavings, totalIncome);

  Map<String, double> get categoryTotals =>
      FinanceCalculator.totalsByCategory(_expenses);
  MapEntry<String, double>? get highestExpenseCategory =>
      FinanceCalculator.highestCategory(categoryTotals);

  int get daysCounted =>
      FinanceCalculator.daysToAverage(_selectedMonth, DateTime.now());
  double get averageDailySpending =>
      FinanceCalculator.averageDailySpending(totalExpenses, daysCounted);

  double get monthOverMonthDifference => totalExpenses - _previousMonthExpenses;

  List<CategoryUsage> get categoryUsages {
    final totals = categoryTotals;
    return [
      for (final c in AppConstants.expenseCategories)
        if (_categoryLimits.containsKey(c))
          CategoryUsage(
              category: c, spent: totals[c] ?? 0, limit: _categoryLimits[c]!),
    ];
  }

  /// Categories at 80% or more, worst first.
  List<CategoryUsage> get alertCategories {
    final list = categoryUsages
        .where((u) => u.status != BudgetStatus.normal)
        .toList()
      ..sort((a, b) => b.percent.compareTo(a.percent));
    return list;
  }

  List<RecurringExpense> get dueRecurring =>
      _recurring.where((r) => r.isDue(DateTime.now())).toList();

  double get recurringMonthlyCommitment =>
      FinanceCalculator.sum(_recurring.map((r) => r.monthlyEquivalent));

  // ------------------------------------------------- Listening to Firestore

  /// Called once after sign-in.
  void start() => _subscribe();

  void changeMonth(int offset) {
    _selectedMonth =
        DateTime(_selectedMonth.year, _selectedMonth.month + offset);
    _subscribe();
  }

  void goToCurrentMonth() {
    if (isCurrentMonth) return;
    _selectedMonth = _currentMonth();
    _subscribe();
  }

  Stream<List<Expense>> watchExpenses(DateTime start, DateTime end) =>
      _db.watchExpenses(start, end);

  void _subscribe() {
    for (final s in _subscriptions) {
      s.cancel();
    }
    _subscriptions.clear();

    // Clear month data so numbers from the old month never mix in.
    _incomes = const [];
    _expenses = const [];
    _budget = null;
    _savingsGoal = null;
    _previousMonthExpenses = 0;
    notifyListeners();

    final month = _selectedMonth;
    final key = toMonthKey(month);
    final end = DateTime(month.year, month.month + 1, 0);
    final prevStart = DateTime(month.year, month.month - 1);
    final prevEnd = DateTime(month.year, month.month, 0);

    void update(VoidCallback apply) {
      apply();
      _loadError = null;
      notifyListeners();
    }

    void onError(Object error) {
      _loadError = 'Could not load your data: $error';
      notifyListeners();
    }

    _subscriptions
      ..add(_db.watchIncomes(month, end).listen(
          (v) => update(() => _incomes = v),
          onError: onError))
      ..add(_db.watchExpenses(month, end).listen(
          (v) => update(() => _expenses = v),
          onError: onError))
      ..add(_db.watchBudgets().listen(
          (all) => update(() => _budget = _latestBudget(all, key)),
          onError: onError))
      ..add(_db.watchCategoryBudgets().listen(
          (v) => update(() =>
              _categoryLimits = {for (final l in v) l.category: l.limit}),
          onError: onError))
      ..add(_db.watchSavingsGoal(key).listen(
          (v) => update(() => _savingsGoal = v),
          onError: onError))
      ..add(_db.watchRecurring().listen(
          (v) => update(() => _recurring = v),
          onError: onError))
      ..add(_db.watchExpenses(prevStart, prevEnd).listen(
          (v) => update(() => _previousMonthExpenses =
              FinanceCalculator.sum(v.map((e) => e.amount))),
          onError: onError));
  }

  /// This month's budget, or the latest earlier one (carried over).
  Budget? _latestBudget(List<Budget> all, String monthKey) {
    Budget? best;
    for (final b in all) {
      if (b.month.compareTo(monthKey) <= 0 &&
          (best == null || b.month.compareTo(best.month) > 0)) {
        best = b;
      }
    }
    return best;
  }

  void _check(String? error) {
    if (error != null) throw ValidationException(error);
  }

  /// Category usage after a save, calculated before the write so the
  /// screen can warn immediately even while offline.
  CategoryUsage? _projectedUsage(Expense saved, {Expense? replaced}) {
    if (toMonthKey(saved.date) != selectedMonthKey) return null;
    final limit = _categoryLimits[saved.category];
    if (limit == null) return null;
    var spent = categoryTotals[saved.category] ?? 0;
    if (replaced != null &&
        replaced.category == saved.category &&
        toMonthKey(replaced.date) == selectedMonthKey) {
      spent -= replaced.amount;
    }
    spent += saved.amount;
    return CategoryUsage(category: saved.category, spent: spent, limit: limit);
  }

  Expense? _findExpense(String? id) {
    for (final e in _expenses) {
      if (e.id == id) return e;
    }
    return null;
  }

  // ---------------------------------------------------------------- Income

  Future<void> addIncome(Income income) async {
    _check(income.validate());
    _db.addIncome(income);
  }

  Future<void> updateIncome(Income income) async {
    _check(income.validate());
    if (income.id == null) throw const ValidationException('Missing income id.');
    _db.updateIncome(income);
  }

  Future<void> deleteIncome(String id) async {
    _db.deleteIncome(id);
  }

  // --------------------------------------------------------------- Expense

  /// Returns the category usage so the screen can warn about limits.
  Future<CategoryUsage?> addExpense(Expense expense) async {
    _check(expense.validate());
    final usage = _projectedUsage(expense);
    _db.addExpense(expense);
    return usage;
  }

  Future<CategoryUsage?> updateExpense(Expense expense) async {
    _check(expense.validate());
    if (expense.id == null) {
      throw const ValidationException('Missing expense id.');
    }
    final usage =
        _projectedUsage(expense, replaced: _findExpense(expense.id));
    _db.updateExpense(expense);
    return usage;
  }

  Future<void> deleteExpense(String id) async {
    _db.deleteExpense(id);
  }

  // ---------------------------------------------------------------- Budget

  Future<void> saveMonthlyBudget(double amount) async {
    if (amount <= 0) {
      throw const ValidationException('Budget must be greater than zero.');
    }
    _db.saveBudget(Budget(month: selectedMonthKey, amount: amount));
  }

  Future<void> setCategoryLimit(String category, double limit) async {
    if (!AppConstants.expenseCategories.contains(category)) {
      throw const ValidationException('Unknown category.');
    }
    if (limit <= 0) {
      throw const ValidationException('Limit must be greater than zero.');
    }
    _db.saveCategoryBudget(CategoryBudget(category: category, limit: limit));
  }

  Future<void> removeCategoryLimit(String category) async {
    _db.deleteCategoryBudget(category);
  }

  // --------------------------------------------------------------- Savings

  Future<void> saveSavingsGoal({
    required double target,
    required double currentSavings,
  }) async {
    if (target <= 0) {
      throw const ValidationException('Target must be greater than zero.');
    }
    if (currentSavings < 0) {
      throw const ValidationException('Current savings cannot be negative.');
    }
    _db.saveSavingsGoal(SavingsGoal(
        month: selectedMonthKey, target: target, currentSavings: currentSavings));
  }

  Future<void> addToSavings(double amount) async {
    if (amount <= 0) {
      throw const ValidationException('Amount must be greater than zero.');
    }
    final goal = _savingsGoal;
    if (goal == null) {
      throw const ValidationException('Set a savings goal first.');
    }
    _db.saveSavingsGoal(
        goal.copyWith(currentSavings: goal.currentSavings + amount));
  }

  // ------------------------------------------------------------- Recurring

  Future<void> addRecurring(RecurringExpense item) async {
    _check(item.validate());
    _db.addRecurring(item);
  }

  Future<void> updateRecurring(RecurringExpense item) async {
    _check(item.validate());
    if (item.id == null) throw const ValidationException('Missing id.');
    _db.updateRecurring(item);
  }

  Future<void> deleteRecurring(String id) async {
    _db.deleteRecurring(id);
  }

  /// Records the payment as an expense and moves to the next due date.
  Future<CategoryUsage?> markRecurringPaid(RecurringExpense item) async {
    final payment = Expense(
      title: item.title,
      amount: item.amount,
      category: item.category,
      date: item.paymentDate(DateTime.now()),
      paymentMethod: item.paymentMethod,
      description: '${item.frequency} recurring payment',
      recurringId: item.id,
    );
    _check(payment.validate());
    final usage = _projectedUsage(payment);
    _db.recordRecurringPayment(item, payment);
    return usage;
  }

  // -------------------------------------------------------------- Settings

  Future<void> clearAllData() => _db.clearAllData();

  Future<void> loadSampleData() async {
    await SampleData.load(_db);
    _selectedMonth = _currentMonth();
    _subscribe();
  }
}
