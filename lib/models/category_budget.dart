/// Spending limit for one category. Stored as
/// users/{uid}/category_budgets/{category}. Limits apply to every month.
class CategoryBudget {
  final String category;
  final double limit;

  const CategoryBudget({required this.category, required this.limit});

  Map<String, dynamic> toMap() => {'category': category, 'limit_amount': limit};

  factory CategoryBudget.fromMap(String category, Map<String, dynamic> map) =>
      CategoryBudget(
        category: category,
        limit: (map['limit_amount'] as num?)?.toDouble() ?? 0,
      );
}
