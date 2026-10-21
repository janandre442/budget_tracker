import '../utils/formatters.dart';
import 'expense.dart';

/// Search and filter options for the expense history (Section 9).
class ExpenseFilter {
  final String query;
  final String? category;
  final String? paymentMethod;
  final DateTime? startDate;
  final DateTime? endDate;
  final double? minAmount;
  final double? maxAmount;

  const ExpenseFilter({
    this.query = '',
    this.category,
    this.paymentMethod,
    this.startDate,
    this.endDate,
    this.minAmount,
    this.maxAmount,
  });

  bool get hasDateRange => startDate != null && endDate != null;

  int get activeCount => [
        category,
        paymentMethod,
        hasDateRange ? startDate : null,
        (minAmount != null || maxAmount != null) ? true : null,
      ].where((v) => v != null).length;

  /// Firestore cannot do "contains" text search, so the date range is
  /// queried from Firestore and the rest of the filters run here.
  bool matches(Expense e) {
    final q = query.trim().toLowerCase();
    if (q.isNotEmpty &&
        !e.title.toLowerCase().contains(q) &&
        !e.description.toLowerCase().contains(q)) {
      return false;
    }
    if (category != null && e.category != category) return false;
    if (paymentMethod != null && e.paymentMethod != paymentMethod) return false;
    if (startDate != null && e.date.isBefore(dateOnly(startDate!))) return false;
    if (endDate != null && e.date.isAfter(dateOnly(endDate!))) return false;
    if (minAmount != null && e.amount < minAmount!) return false;
    if (maxAmount != null && e.amount > maxAmount!) return false;
    return true;
  }

  static const Object _keep = Object();

  /// Pass null explicitly to clear a field.
  ExpenseFilter copyWith({
    String? query,
    Object? category = _keep,
    Object? paymentMethod = _keep,
    Object? startDate = _keep,
    Object? endDate = _keep,
    Object? minAmount = _keep,
    Object? maxAmount = _keep,
  }) {
    return ExpenseFilter(
      query: query ?? this.query,
      category: identical(category, _keep) ? this.category : category as String?,
      paymentMethod: identical(paymentMethod, _keep)
          ? this.paymentMethod
          : paymentMethod as String?,
      startDate:
          identical(startDate, _keep) ? this.startDate : startDate as DateTime?,
      endDate: identical(endDate, _keep) ? this.endDate : endDate as DateTime?,
      minAmount:
          identical(minAmount, _keep) ? this.minAmount : minAmount as double?,
      maxAmount:
          identical(maxAmount, _keep) ? this.maxAmount : maxAmount as double?,
    );
  }
}
