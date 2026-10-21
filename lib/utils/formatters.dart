import 'package:intl/intl.dart';

final NumberFormat _pesoFormat =
    NumberFormat.currency(locale: 'en_US', symbol: '₱', decimalDigits: 2);

/// Formats a number as Philippine peso, e.g. ₱25,000.00
String peso(double value) => _pesoFormat.format(value);

/// Adds a + or - sign, e.g. +₱2,250.00
String signedPeso(double value) {
  if (value > 0) return '+${peso(value)}';
  if (value < 0) return '-${peso(value.abs())}';
  return peso(0);
}

String percent(double value) => '${value.toStringAsFixed(1)}%';

String monthLabel(DateTime month) => DateFormat('MMMM yyyy').format(month);
String shortDate(DateTime date) => DateFormat('MMM d, yyyy').format(date);
String longDate(DateTime date) => DateFormat('MMMM d, yyyy').format(date);

/// Dates are stored in Firestore as yyyy-MM-dd text so they sort and compare
/// correctly in range queries (>= and <=).
String toDateKey(DateTime date) => DateFormat('yyyy-MM-dd').format(date);

/// Month key used for monthly budgets and savings goals, e.g. 2026-10
String toMonthKey(DateTime date) => DateFormat('yyyy-MM').format(date);

DateTime monthFromKey(String key) => DateTime.parse('$key-01');

DateTime dateOnly(DateTime date) => DateTime(date.year, date.month, date.day);

/// Adds months while keeping the day valid (Jan 31 + 1 month = Feb 28/29).
DateTime addMonths(DateTime date, int months) {
  assert(months >= 0);
  final totalMonths = date.month - 1 + months;
  final year = date.year + totalMonths ~/ 12;
  final month = totalMonths % 12 + 1;
  final lastDay = DateTime(year, month + 1, 0).day;
  return DateTime(year, month, date.day > lastDay ? lastDay : date.day);
}
