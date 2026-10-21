import '../utils/constants.dart';
import '../utils/formatters.dart';

class Income {
  final String? id; // Firestore document id
  final String source;
  final double amount;
  final DateTime date;
  final String description;
  final int createdAt; // used to keep a stable order for same-day records

  const Income({
    this.id,
    required this.source,
    required this.amount,
    required this.date,
    this.description = '',
    this.createdAt = 0,
  });

  /// Returns an error message, or null if the record is valid.
  String? validate() {
    if (!AppConstants.incomeSources.contains(source)) {
      return 'Please select an income source.';
    }
    if (amount <= 0) return 'Amount must be greater than zero.';
    return null;
  }

  Map<String, dynamic> toMap() => {
        'source': source,
        'amount': amount,
        'date': toDateKey(date),
        'description': description,
      };

  factory Income.fromMap(String id, Map<String, dynamic> map) => Income(
        id: id,
        source: map['source'] as String? ?? 'Other',
        amount: (map['amount'] as num?)?.toDouble() ?? 0,
        date: DateTime.parse(map['date'] as String),
        description: map['description'] as String? ?? '',
        createdAt: (map['created_at'] as num?)?.toInt() ?? 0,
      );
}
