/// Shared form validators (Section 17: Validation Requirements).
class Validators {
  Validators._();

  /// Accepts "1,699" or "1699.50". Returns null if it is not a number.
  static double? tryParseAmount(String? raw) {
    if (raw == null) return null;
    final cleaned = raw.replaceAll(',', '').trim();
    if (cleaned.isEmpty) return null;
    return double.tryParse(cleaned);
  }

  /// Amount = 0 -> error, Amount = -500 -> error, empty -> error.
  static String? amount(String? raw) {
    if (raw == null || raw.trim().isEmpty) return 'Amount is required';
    final value = tryParseAmount(raw);
    if (value == null) return 'Enter a valid number';
    if (value <= 0) return 'Amount must be greater than zero';
    if (value > 100000000) return 'Amount is too large';
    return null;
  }

  /// Optional amount (filters, current savings). Empty is allowed, negative is not.
  static String? optionalAmount(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    final value = tryParseAmount(raw);
    if (value == null) return 'Enter a valid number';
    if (value < 0) return 'Cannot be negative';
    return null;
  }

  static String? requiredText(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName must not be empty';
    }
    return null;
  }

  static String? requiredSelection(Object? value, String message) =>
      value == null ? message : null;
}
