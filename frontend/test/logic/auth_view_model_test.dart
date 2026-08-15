// test/logic/auth_view_model_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_core/flutter_core.dart';

void main() {
  group('AuthViewModel Unit Tests', () {
    test('initial state has null user and unauthenticated status', () {
      final vm = AuthViewModel();
      expect(vm.currentUser, isNull);
      expect(vm.isAuthenticated, isFalse);
      expect(vm.isLoading, isFalse);
      expect(vm.errorMessage, isNull);
    });

    test('sendOtp sets loading state and handles phone formatting gracefully', () async {
      final vm = AuthViewModel();
      final future = vm.sendOtp('9822012345');
      expect(vm.isLoading, isTrue);

      await future;
      expect(vm.isLoading, isFalse);
      expect(vm.errorMessage, isNull);
    });

    test('loginAsDemoPersona verifies and sets currentUser', () async {
      final vm = AuthViewModel();
      await vm.loginAsDemoPersona('+91 98220 11111');
      expect(vm.currentUser, isNotNull);
      expect(vm.isAuthenticated, isTrue);
      expect(vm.currentUser?.phoneNumber, contains('9822011111'));
    });

    test('signOut clears current session and resets state', () async {
      final vm = AuthViewModel();
      await vm.loginAsDemoPersona('+91 98220 11111');
      expect(vm.isAuthenticated, isTrue);

      await vm.signOut();
      expect(vm.currentUser, isNull);
      expect(vm.isAuthenticated, isFalse);
    });
  });
}
