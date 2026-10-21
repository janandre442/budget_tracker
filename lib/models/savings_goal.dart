/// Monthly savings goal. Stored as users/{uid}/savings_goals/{yyyy-MM}.
class SavingsGoal {
  final String month;
  final double target;
  final double currentSavings;

  const SavingsGoal({
    required this.month,
    required this.target,
    required this.currentSavings,
  });

  SavingsGoal copyWith({double? target, double? currentSavings}) => SavingsGoal(
        month: month,
        target: target ?? this.target,
        currentSavings: currentSavings ?? this.currentSavings,
      );

  Map<String, dynamic> toMap() => {
        'month': month,
        'target': target,
        'current_savings': currentSavings,
      };

  factory SavingsGoal.fromMap(String month, Map<String, dynamic> map) =>
      SavingsGoal(
        month: month,
        target: (map['target'] as num?)?.toDouble() ?? 0,
        currentSavings: (map['current_savings'] as num?)?.toDouble() ?? 0,
      );
}
