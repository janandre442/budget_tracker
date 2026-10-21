/// Monthly budget. Stored as users/{uid}/budgets/{yyyy-MM}.
class Budget {
  final String month;
  final double amount;

  const Budget({required this.month, required this.amount});

  Map<String, dynamic> toMap() => {'month': month, 'amount': amount};

  factory Budget.fromMap(String month, Map<String, dynamic> map) => Budget(
        month: month,
        amount: (map['amount'] as num?)?.toDouble() ?? 0,
      );
}
