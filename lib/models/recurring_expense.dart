import '../utils/constants.dart';
import '../utils/formatters.dart';

/// A bill that repeats (Internet, rent, subscriptions). Stored separately
/// from ordinary transactions. Marking it as paid creates a normal Expense.
class RecurringExpense {
  final String? id;
  final String title;
  final double amount;
  final String category;
  final String paymentMethod;
  final String frequency;
  final DateTime nextDueDate;

  const RecurringExpense({
    this.id,
    required this.title,
    required this.amount,
    required this.category,
    required this.paymentMethod,
    required this.frequency,
    required this.nextDueDate,
  });

  String? validate() {
    if (title.trim().isEmpty) return 'Title must not be empty.';
    if (amount <= 0) return 'Amount must be greater than zero.';
    if (!AppConstants.expenseCategories.contains(category)) {
      return 'Please select a category.';
    }
    if (!AppConstants.paymentMethods.contains(paymentMethod)) {
      return 'Please select a payment method.';
    }
    if (!AppConstants.frequencies.contains(frequency)) {
      return 'Please select a frequency.';
    }
    return null;
  }

  /// The due date after the current one, based on frequency.
  DateTime followingDueDate() => switch (frequency) {
        'Weekly' => DateTime(
            nextDueDate.year, nextDueDate.month, nextDueDate.day + 7),
        'Quarterly' => addMonths(nextDueDate, 3),
        'Yearly' => addMonths(nextDueDate, 12),
        _ => addMonths(nextDueDate, 1),
      };

  /// Cost converted to a monthly amount, for the "monthly commitment" total.
  double get monthlyEquivalent => switch (frequency) {
        'Weekly' => amount * 52 / 12,
        'Quarterly' => amount / 3,
        'Yearly' => amount / 12,
        _ => amount,
      };

  bool isDue(DateTime today) => !nextDueDate.isAfter(dateOnly(today));

  int daysUntilDue(DateTime today) =>
      nextDueDate.difference(dateOnly(today)).inDays;

  /// Paying early records the expense today. Paying late uses the due date.
  DateTime paymentDate(DateTime today) {
    final t = dateOnly(today);
    return nextDueDate.isAfter(t) ? t : nextDueDate;
  }

  Map<String, dynamic> toMap() => {
        'title': title,
        'amount': amount,
        'category': category,
        'payment_method': paymentMethod,
        'frequency': frequency,
        'next_due_date': toDateKey(nextDueDate),
      };

  factory RecurringExpense.fromMap(String id, Map<String, dynamic> map) =>
      RecurringExpense(
        id: id,
        title: map['title'] as String? ?? '',
        amount: (map['amount'] as num?)?.toDouble() ?? 0,
        category: map['category'] as String? ?? 'Others',
        paymentMethod: map['payment_method'] as String? ?? 'Other',
        frequency: map['frequency'] as String? ?? 'Monthly',
        nextDueDate: DateTime.parse(map['next_due_date'] as String),
      );
}
