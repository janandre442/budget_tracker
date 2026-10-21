// Unit tests for the formulas in the activity sheet.
// Run with: flutter test
import 'package:flutter_test/flutter_test.dart';
import 'package:personal_budget_tracker/services/finance_calculator.dart';
import 'package:personal_budget_tracker/utils/validators.dart';

void main() {
  group('FinanceCalculator', () {
    test('Remaining = Monthly Budget - Total Expenses', () {
      expect(FinanceCalculator.remainingBudget(25000, 17450), 7550);
    });

    test('Budget used is 69.8%', () {
      expect(FinanceCalculator.percentUsed(17450, 25000), closeTo(69.8, 0.001));
    });

    test('Category status thresholds', () {
      expect(FinanceCalculator.statusFor(79.9), BudgetStatus.normal);
      expect(FinanceCalculator.statusFor(80), BudgetStatus.warning);
      expect(FinanceCalculator.statusFor(99.9), BudgetStatus.warning);
      expect(FinanceCalculator.statusFor(100), BudgetStatus.exceeded);
      expect(FinanceCalculator.statusFor(120), BudgetStatus.exceeded);
    });

    test('Savings progress 3,500 / 5,000 = 70%', () {
      expect(FinanceCalculator.savingsProgress(3500, 5000), 70);
    });

    test('Savings rate 5,000 / 25,000 = 20%', () {
      expect(FinanceCalculator.savingsRate(5000, 25000), 20);
    });

    test('No division by zero', () {
      expect(FinanceCalculator.percentUsed(500, 0), 0);
      expect(FinanceCalculator.savingsRate(500, 0), 0);
      expect(FinanceCalculator.averageDailySpending(500, 0), 0);
    });

    test('Monthly comparison 15,200 to 17,450', () {
      expect(17450 - 15200, 2250);
      expect(FinanceCalculator.percentChange(15200, 17450), closeTo(14.80, 0.01));
    });
  });

  group('Validators', () {
    test('Rejects 0, -500 and empty amounts', () {
      expect(Validators.amount('0'), isNotNull);
      expect(Validators.amount('-500'), isNotNull);
      expect(Validators.amount(''), isNotNull);
      expect(Validators.amount('abc'), isNotNull);
      expect(Validators.amount('1,699'), isNull);
    });

    test('Rejects empty title', () {
      expect(Validators.requiredText('   ', 'Expense title'), isNotNull);
      expect(Validators.requiredText('Lunch', 'Expense title'), isNull);
    });
  });
}
