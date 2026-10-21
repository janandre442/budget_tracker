import 'package:flutter/material.dart';

class AppConstants {
  AppConstants._();

  static const List<String> expenseCategories = [
    'Food',
    'Transportation',
    'Bills',
    'Education',
    'Shopping',
    'Entertainment',
    'Health',
    'Others',
  ];

  static const List<String> incomeSources = [
    'Salary',
    'Allowance',
    'Freelance',
    'Business',
    'Gift',
    'Other',
  ];

  static const List<String> paymentMethods = [
    'Cash',
    'GCash',
    'Debit Card',
    'Credit Card',
    'Bank Transfer',
    'Other',
  ];

  static const List<String> frequencies = [
    'Weekly',
    'Monthly',
    'Quarterly',
    'Yearly',
  ];

  /// Category budget thresholds (Section 6 of the activity).
  static const double warningPercent = 80;
  static const double exceededPercent = 100;
}

IconData categoryIcon(String category) => switch (category) {
      'Food' => Icons.restaurant,
      'Transportation' => Icons.directions_bus,
      'Bills' => Icons.receipt_long,
      'Education' => Icons.school,
      'Shopping' => Icons.shopping_bag,
      'Entertainment' => Icons.movie,
      'Health' => Icons.favorite,
      _ => Icons.category,
    };

Color categoryColor(String category) => switch (category) {
      'Food' => const Color(0xFFE67E22),
      'Transportation' => const Color(0xFF2980B9),
      'Bills' => const Color(0xFF546E7A),
      'Education' => const Color(0xFF16A085),
      'Shopping' => const Color(0xFFC2185B),
      'Entertainment' => const Color(0xFF8E44AD),
      'Health' => const Color(0xFFE53935),
      _ => const Color(0xFF757575),
    };

IconData incomeIcon(String source) => switch (source) {
      'Salary' => Icons.work,
      'Allowance' => Icons.account_balance_wallet,
      'Freelance' => Icons.laptop,
      'Business' => Icons.storefront,
      'Gift' => Icons.card_giftcard,
      _ => Icons.attach_money,
    };

IconData paymentIcon(String method) => switch (method) {
      'Cash' => Icons.payments,
      'GCash' => Icons.phone_android,
      'Debit Card' => Icons.credit_card,
      'Credit Card' => Icons.credit_score,
      'Bank Transfer' => Icons.account_balance,
      _ => Icons.more_horiz,
    };
