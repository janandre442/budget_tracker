import '../models/expense.dart';
import '../utils/constants.dart';

enum BudgetStatus { normal, warning, exceeded }

/// Spending vs limit for one category.
class CategoryUsage {
  final String category;
  final double spent;
  final double limit;

  const CategoryUsage({
    required this.category,
    required this.spent,
    required this.limit,
  });

  double get percent => FinanceCalculator.percentUsed(spent, limit);
  BudgetStatus get status => FinanceCalculator.statusFor(percent);
  double get remaining => limit - spent;
}

/// Every formula in the activity lives here so it is easy to explain
/// and to unit test. Nothing on screen is hard-coded.
class FinanceCalculator {
  FinanceCalculator._();

  static double sum(Iterable<double> values) =>
      values.fold(0.0, (total, value) => total + value);

  /// Remaining Budget = Monthly Budget - Total Expenses
  static double remainingBudget(double monthlyBudget, double totalExpenses) =>
      monthlyBudget - totalExpenses;

  /// Percentage Used = Used / Total x 100 (safe when total is zero)
  static double percentUsed(double used, double total) =>
      total <= 0 ? 0 : used / total * 100;

  /// Below 80% normal, 80% to 99% warning, 100% or higher exceeded.
  static BudgetStatus statusFor(double percent) {
    if (percent >= AppConstants.exceededPercent) return BudgetStatus.exceeded;
    if (percent >= AppConstants.warningPercent) return BudgetStatus.warning;
    return BudgetStatus.normal;
  }

  /// Savings Progress = Current Savings / Savings Target x 100
  static double savingsProgress(double currentSavings, double target) =>
      percentUsed(currentSavings, target);

  /// Savings Rate = Savings / Total Income x 100
  static double savingsRate(double savings, double totalIncome) =>
      totalIncome <= 0 ? 0 : savings / totalIncome * 100;

  static Map<String, double> totalsByCategory(List<Expense> expenses) {
    final totals = <String, double>{};
    for (final e in expenses) {
      totals[e.category] = (totals[e.category] ?? 0) + e.amount;
    }
    return totals;
  }

  static Map<String, double> totalsByPaymentMethod(List<Expense> expenses) {
    final totals = <String, double>{};
    for (final e in expenses) {
      totals[e.paymentMethod] = (totals[e.paymentMethod] ?? 0) + e.amount;
    }
    return totals;
  }

  static MapEntry<String, double>? highestCategory(Map<String, double> totals) {
    if (totals.isEmpty) return null;
    return totals.entries.reduce((a, b) => b.value > a.value ? b : a);
  }

  /// Current month: divide by days elapsed so far (today's day of month).
  /// Past months: divide by the number of days in that month.
  static int daysToAverage(DateTime month, DateTime today) {
    final isCurrentMonth =
        month.year == today.year && month.month == today.month;
    if (isCurrentMonth) return today.day;
    return DateTime(month.year, month.month + 1, 0).day;
  }

  /// Average Daily Spending = Total Expenses / Days
  static double averageDailySpending(double totalExpenses, int days) =>
      days <= 0 ? 0 : totalExpenses / days;

  /// Percent change from previous to current (Advanced Challenge).
  static double percentChange(double previous, double current) =>
      previous <= 0 ? 0 : (current - previous) / previous * 100;
}
