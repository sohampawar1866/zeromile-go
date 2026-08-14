import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_core/utils/phone_utils.dart';

void main() {
  group('PhoneUtils Tests', () {
    test('extract10Digits handles raw 10 digits and formatted numbers', () {
      expect(PhoneUtils.extract10Digits('9822012345'), equals('9822012345'));
      expect(PhoneUtils.extract10Digits('+91 98220 12345'), equals('9822012345'));
      expect(PhoneUtils.extract10Digits('+919822012345'), equals('9822012345'));
      expect(PhoneUtils.extract10Digits('09822012345'), equals('9822012345'));
    });

    test('formatWithPrefix adds +91 properly', () {
      expect(PhoneUtils.formatWithPrefix('9822012345'), equals('+91 9822012345'));
      expect(PhoneUtils.formatWithPrefix('9822012345', space: false), equals('+919822012345'));
    });

    test('isValid10Digits validates 10 digits accurately', () {
      expect(PhoneUtils.isValid10Digits('9822012345'), isTrue);
      expect(PhoneUtils.isValid10Digits('+91 98220 12345'), isTrue);
      expect(PhoneUtils.isValid10Digits('12345'), isFalse);
      expect(PhoneUtils.isValid10Digits(''), isFalse);
    });
  });
}
