// lib/utils/phone_utils.dart

/// Standardized utility for Indian Mobile Phone Number (+91) formatting and validation.
class PhoneUtils {
  /// Strips all non-digit characters and returns the normalized 10 digits.
  static String extract10Digits(String input) {
    final digits = input.replaceAll(RegExp(r'\D'), '');
    if (digits.length > 10) {
      return digits.substring(digits.length - 10);
    }
    return digits;
  }

  /// Formats raw digits into standard E.164 string: `+91 9822012345` or `+919822012345`
  static String formatWithPrefix(String input, {bool space = true}) {
    final digits = extract10Digits(input);
    if (digits.isEmpty) return '';
    return space ? '+91 $digits' : '+91$digits';
  }

  /// Formats for display: `+91 98220 12345`
  static String formatDisplay(String input) {
    final digits = extract10Digits(input);
    if (digits.length == 10) {
      return '+91 ${digits.substring(0, 5)} ${digits.substring(5)}';
    }
    return formatWithPrefix(input);
  }

  /// Extracts exactly 10 digits for clean database storage (no +91, no spaces).
  static String toDbFormat(String input) {
    return extract10Digits(input);
  }

  /// Validates that input contains exactly 10 digits.
  static bool isValid10Digits(String input) {
    final digits = extract10Digits(input);
    return digits.length == 10;
  }
}
