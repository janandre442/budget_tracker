import '../models/budget.dart';
import '../models/category_budget.dart';
import '../models/expense.dart';
import '../models/income.dart';
import '../models/recurring_expense.dart';
import '../models/savings_goal.dart';
import '../utils/formatters.dart';
import 'database_service.dart';

/// Demo data that reproduces the numbers in the activity sheet:
/// budget ₱25,000, income ₱25,000, expenses ₱17,450 this month and
/// ₱15,200 last month. Used from Settings for screenshots and evaluation.
class SampleData {
  SampleData._();

  static Future<void> load(DatabaseService db) async {
    await db.clearAllData();

    final now = DateTime.now();
    final current = DateTime(now.year, now.month);
    final previous = DateTime(now.year, now.month - 1);

    // Keeps sample dates valid and never later than today.
    DateTime day(DateTime month, int d) {
      final lastDay = DateTime(month.year, month.month + 1, 0).day;
      var safe = d > lastDay ? lastDay : d;
      final isCurrent = month.year == now.year && month.month == now.month;
      if (isCurrent && safe > now.day) safe = now.day;
      return DateTime(month.year, month.month, safe);
    }

    final batch = db.newBatch();

    // Recurring expenses
    final recurring = db.collection('recurring_expenses');
    final internetRef = recurring.doc();
    batch.set(
        internetRef,
        RecurringExpense(
          title: 'Internet',
          amount: 1699,
          category: 'Bills',
          paymentMethod: 'Bank Transfer',
          frequency: 'Monthly',
          nextDueDate: DateTime(now.year, now.month + 1, 1),
        ).toMap());
    batch.set(
        recurring.doc(),
        RecurringExpense(
          title: 'Streaming subscription',
          amount: 549,
          category: 'Entertainment',
          paymentMethod: 'Credit Card',
          frequency: 'Monthly',
          nextDueDate: dateOnly(now),
        ).toMap());
    batch.set(
        recurring.doc(),
        RecurringExpense(
          title: 'Phone plan',
          amount: 999,
          category: 'Bills',
          paymentMethod: 'GCash',
          frequency: 'Monthly',
          nextDueDate: DateTime(now.year, now.month, 20),
        ).toMap());

    // Monthly budgets
    for (final m in [previous, current]) {
      final key = toMonthKey(m);
      batch.set(db.collection('budgets').doc(key),
          Budget(month: key, amount: 25000).toMap());
    }

    // Category limits
    const limits = {
      'Food': 3000.0,
      'Transportation': 2000.0,
      'Bills': 7000.0,
      'Entertainment': 1000.0,
      'Shopping': 2000.0,
    };
    for (final entry in limits.entries) {
      batch.set(db.collection('category_budgets').doc(entry.key),
          CategoryBudget(category: entry.key, limit: entry.value).toMap());
    }

    // Savings goals
    final prevKey = toMonthKey(previous);
    final currentKey = toMonthKey(current);
    batch.set(
        db.collection('savings_goals').doc(prevKey),
        SavingsGoal(month: prevKey, target: 5000, currentSavings: 5000)
            .toMap());
    batch.set(
        db.collection('savings_goals').doc(currentKey),
        SavingsGoal(month: currentKey, target: 5000, currentSavings: 3500)
            .toMap());

    // Income
    for (final m in [previous, current]) {
      batch.set(
          db.collection('incomes').doc(),
          db.withCreated(Income(
                  source: 'Salary',
                  amount: 20000,
                  date: day(m, 1),
                  description: 'Monthly salary')
              .toMap()));
      batch.set(
          db.collection('incomes').doc(),
          db.withCreated(Income(
                  source: 'Allowance',
                  amount: 5000,
                  date: day(m, 2),
                  description: 'Allowance from family')
              .toMap()));
    }

    Expense e(String title, double amount, String category, DateTime date,
            String method,
            {String description = '', String? recurringId}) =>
        Expense(
          title: title,
          amount: amount,
          category: category,
          date: date,
          paymentMethod: method,
          description: description,
          recurringId: recurringId,
        );

    // Previous month: total ₱15,200
    final previousExpenses = [
      e('Groceries', 3000, 'Food', day(previous, 3), 'Cash'),
      e('Commute fare', 1500, 'Transportation', day(previous, 5), 'Cash'),
      e('Internet', 1699, 'Bills', day(previous, 1), 'Bank Transfer',
          recurringId: internetRef.id),
      e('Electricity', 2101, 'Bills', day(previous, 8), 'GCash'),
      e('Boarding house rent', 2500, 'Bills', day(previous, 1), 'Cash'),
      e('School supplies', 1600, 'Education', day(previous, 10), 'Cash'),
      e('Clothes', 1200, 'Shopping', day(previous, 14), 'Debit Card'),
      e('Movie night', 700, 'Entertainment', day(previous, 20), 'GCash'),
      e('Medicine', 600, 'Health', day(previous, 18), 'Cash'),
      e('Load and snacks', 300, 'Others', day(previous, 22), 'GCash'),
    ];

    // Current month: total ₱17,450
    final currentExpenses = [
      e('Groceries', 1500, 'Food', day(current, 2), 'Cash',
          description: 'Weekly groceries'),
      e('Lunch with classmates', 650, 'Food', day(current, 4), 'GCash'),
      e('Coffee and snacks', 350, 'Food', day(current, 6), 'GCash'),
      e('Jeepney and tricycle fare', 450, 'Transportation', day(current, 3),
          'Cash'),
      e('Bus fare', 750, 'Transportation', day(current, 5), 'Cash'),
      e('Internet', 1699, 'Bills', day(current, 1), 'Bank Transfer',
          description: 'Monthly recurring payment',
          recurringId: internetRef.id),
      e('Electricity', 2301, 'Bills', day(current, 3), 'GCash'),
      e('Boarding house rent', 2500, 'Bills', day(current, 1), 'Cash'),
      e('Printing and school supplies', 800, 'Education', day(current, 4),
          'Cash'),
      e('Review book', 1200, 'Education', day(current, 5), 'Debit Card'),
      e('Running shoes', 2400, 'Shopping', day(current, 6), 'Credit Card'),
      e('Movie night', 850, 'Entertainment', day(current, 5), 'GCash'),
      e('Vitamins and medicine', 1500, 'Health', day(current, 2), 'Cash'),
      e('Birthday gift', 500, 'Others', day(current, 6), 'Cash'),
    ];

    for (final expense in [...previousExpenses, ...currentExpenses]) {
      batch.set(db.collection('expenses').doc(), db.withCreated(expense.toMap()));
    }

    db.commit(batch.commit(), 'load sample data');
  }
}
