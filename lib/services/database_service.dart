import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../models/budget.dart';
import '../models/category_budget.dart';
import '../models/expense.dart';
import '../models/income.dart';
import '../models/recurring_expense.dart';
import '../models/savings_goal.dart';
import '../utils/formatters.dart';

typedef Json = Map<String, dynamic>;

/// All Cloud Firestore access lives here (Section 12: data persistence).
///
/// Offline support (Section 13): Firestore offline persistence keeps a
/// local copy of the data on the device. Reads come from that cache when
/// there is no internet, and writes are saved locally first, then synced
/// to the cloud when the connection comes back.
///
/// Data layout:  users/{uid}/incomes, expenses, budgets, category_budgets,
///               savings_goals, recurring_expenses
class DatabaseService {
  DatabaseService._();
  static final DatabaseService instance = DatabaseService._();

  static const List<String> collections = [
    'incomes',
    'expenses',
    'budgets',
    'category_budgets',
    'savings_goals',
    'recurring_expenses',
  ];

  FirebaseFirestore get _firestore => FirebaseFirestore.instance;

  bool _settingsApplied = false;
  String? _uid;

  String get uid {
    final value = _uid;
    if (value == null) {
      throw StateError('DatabaseService.init() must be called first.');
    }
    return value;
  }

  /// Turns on offline persistence and signs in anonymously.
  /// The anonymous account is remembered on the device, so only the very
  /// first launch needs an internet connection.
  Future<void> init() async {
    if (!_settingsApplied) {
      _firestore.settings = const Settings(
        persistenceEnabled: true,
        cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
      );
      _settingsApplied = true;
    }
    final auth = FirebaseAuth.instance;
    final user = auth.currentUser ?? (await auth.signInAnonymously()).user;
    if (user == null) throw Exception('Anonymous sign-in failed.');
    _uid = user.uid;
  }

  CollectionReference<Json> collection(String name) =>
      _firestore.collection('users').doc(uid).collection(name);

  WriteBatch newBatch() => _firestore.batch();

  Json withCreated(Json data) =>
      {...data, 'created_at': DateTime.now().millisecondsSinceEpoch};

  /// Writes are NOT awaited on purpose. Offline, the Future only completes
  /// once the server confirms, which would freeze the UI. The local cache
  /// and every listener update immediately either way.
  void commit(Future<void> write, String label) {
    unawaited(write.catchError((Object error) {
      debugPrint('Firestore $label failed: $error');
    }));
  }

  // -------------------------------------------------------------- Streams

  Query<Json> _dateRange(String name, DateTime start, DateTime end) =>
      collection(name)
          .where('date', isGreaterThanOrEqualTo: toDateKey(start))
          .where('date', isLessThanOrEqualTo: toDateKey(end));

  Stream<List<Income>> watchIncomes(DateTime start, DateTime end) =>
      _dateRange('incomes', start, end).snapshots().map((snap) {
        final list =
            snap.docs.map((d) => Income.fromMap(d.id, d.data())).toList();
        list.sort((a, b) {
          final byDate = b.date.compareTo(a.date);
          return byDate != 0 ? byDate : b.createdAt.compareTo(a.createdAt);
        });
        return list;
      });

  Stream<List<Expense>> watchExpenses(DateTime start, DateTime end) =>
      _dateRange('expenses', start, end).snapshots().map((snap) {
        final list =
            snap.docs.map((d) => Expense.fromMap(d.id, d.data())).toList();
        list.sort((a, b) {
          final byDate = b.date.compareTo(a.date);
          return byDate != 0 ? byDate : b.createdAt.compareTo(a.createdAt);
        });
        return list;
      });

  Stream<List<Budget>> watchBudgets() => collection('budgets')
      .snapshots()
      .map((s) => s.docs.map((d) => Budget.fromMap(d.id, d.data())).toList());

  Stream<List<CategoryBudget>> watchCategoryBudgets() =>
      collection('category_budgets').snapshots().map((s) =>
          s.docs.map((d) => CategoryBudget.fromMap(d.id, d.data())).toList());

  Stream<SavingsGoal?> watchSavingsGoal(String monthKey) =>
      collection('savings_goals').doc(monthKey).snapshots().map((d) {
        final data = d.data();
        return d.exists && data != null ? SavingsGoal.fromMap(d.id, data) : null;
      });

  Stream<List<RecurringExpense>> watchRecurring() =>
      collection('recurring_expenses').snapshots().map((snap) {
        final list = snap.docs
            .map((d) => RecurringExpense.fromMap(d.id, d.data()))
            .toList()
          ..sort((a, b) {
            final byDate = a.nextDueDate.compareTo(b.nextDueDate);
            return byDate != 0 ? byDate : a.title.compareTo(b.title);
          });
        return list;
      });

  // ---------------------------------------------------------------- Income

  void addIncome(Income income) => commit(
      collection('incomes').doc().set(withCreated(income.toMap())),
      'add income');

  void updateIncome(Income income) => commit(
      collection('incomes')
          .doc(income.id)
          .set(income.toMap(), SetOptions(merge: true)),
      'update income');

  void deleteIncome(String id) =>
      commit(collection('incomes').doc(id).delete(), 'delete income');

  // --------------------------------------------------------------- Expense

  void addExpense(Expense expense) => commit(
      collection('expenses').doc().set(withCreated(expense.toMap())),
      'add expense');

  void updateExpense(Expense expense) => commit(
      collection('expenses')
          .doc(expense.id)
          .set(expense.toMap(), SetOptions(merge: true)),
      'update expense');

  void deleteExpense(String id) =>
      commit(collection('expenses').doc(id).delete(), 'delete expense');

  // -------------------------------------------------- Budgets and savings

  void saveBudget(Budget budget) => commit(
      collection('budgets').doc(budget.month).set(budget.toMap()),
      'save budget');

  void saveCategoryBudget(CategoryBudget budget) => commit(
      collection('category_budgets').doc(budget.category).set(budget.toMap()),
      'save category limit');

  void deleteCategoryBudget(String category) => commit(
      collection('category_budgets').doc(category).delete(),
      'delete category limit');

  void saveSavingsGoal(SavingsGoal goal) => commit(
      collection('savings_goals').doc(goal.month).set(goal.toMap()),
      'save savings goal');

  // ------------------------------------------------------------- Recurring

  void addRecurring(RecurringExpense item) => commit(
      collection('recurring_expenses').doc().set(item.toMap()),
      'add recurring');

  void updateRecurring(RecurringExpense item) => commit(
      collection('recurring_expenses').doc(item.id).set(item.toMap()),
      'update recurring');

  void deleteRecurring(String id) => commit(
      collection('recurring_expenses').doc(id).delete(), 'delete recurring');

  /// Saves the payment as a normal expense and moves the next due date in
  /// one batch, so both changes are applied together. (Firestore
  /// transactions need internet, batches work offline.)
  void recordRecurringPayment(RecurringExpense item, Expense payment) {
    final batch = newBatch()
      ..set(collection('expenses').doc(), withCreated(payment.toMap()))
      ..update(collection('recurring_expenses').doc(item.id),
          {'next_due_date': toDateKey(item.followingDueDate())});
    commit(batch.commit(), 'record recurring payment');
  }

  // ----------------------------------------------------------------- Admin

  /// Deletes every document this device knows about, in batches of 400.
  Future<void> clearAllData() async {
    final refs = <DocumentReference<Json>>[];
    for (final name in collections) {
      final snap =
          await collection(name).get(const GetOptions(source: Source.cache));
      refs.addAll(snap.docs.map((d) => d.reference));
    }
    for (var i = 0; i < refs.length; i += 400) {
      final batch = newBatch();
      for (final ref in refs.skip(i).take(400)) {
        batch.delete(ref);
      }
      commit(batch.commit(), 'clear data');
    }
  }
}
