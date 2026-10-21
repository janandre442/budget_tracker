import '../utils/constants.dart';
import '../utils/formatters.dart';

class Expense {
  final String? id; // Firestore document id
  final String title;
  final double amount;
  final String category;
  final DateTime date;
  final String paymentMethod;
  final String description;

  /// Set when this expense was recorded from a recurring payment.
  final String? recurringId;
  final int createdAt;

  const Expense({
    this.id,
    required this.title,
    required this.amount,
    required this.category,
    required this.date,
    required this.paymentMethod,
    this.description = '',
    this.recurringId,
    this.createdAt = 0,
  });

  bool get isRecurring => recurringId != null;

  /// Returns an error message, or null if the record is valid.
  String? validate() {
    if (title.trim().isEmpty) return 'Expense title must not be empty.';
    if (amount <= 0) return 'Amount must be greater than zero.';
    if (!AppConstants.expenseCategories.contains(category)) {
      return 'Please select a category.';
    }
    if (!AppConstants.paymentMethods.contains(paymentMethod)) {
      return 'Please select a payment method.';
    }
    return null;
  }

  Map<String, dynamic> toMap() => {
        'title': title,
        'amount': amount,
        'category': category,
        'date': toDateKey(date),
        'payment_method': paymentMethod,
        'description': description,
        'recurring_id': recurringId,
      };

  factory Expense.fromMap(String id, Map<String, dynamic> map) => Expense(
        id: id,
        title: map['title'] as String? ?? '',
        amount: (map['amount'] as num?)?.toDouble() ?? 0,
        category: map['category'] as String? ?? 'Others',
        date: DateTime.parse(map['date'] as String),
        paymentMethod: map['payment_method'] as String? ?? 'Other',
        description: map['description'] as String? ?? '',
        recurringId: map['recurring_id'] as String?,
        createdAt: (map['created_at'] as num?)?.toInt() ?? 0,
      );
}
