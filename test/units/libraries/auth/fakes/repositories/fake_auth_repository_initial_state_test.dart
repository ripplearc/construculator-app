import 'package:flutter_test/flutter_test.dart';
import 'package:construculator/libraries/auth/testing/fake_auth_repository.dart';

void main() {
  group('Initial State Configuration', () {
    test('should start unauthenticated by default', () {
      final repo = FakeAuthRepository();
      expect(repo.isAuthenticated(), false);
      expect(repo.getCurrentCredentials(), isNull);
      repo.dispose(); // Dispose instance created in test
    });

    test('should start authenticated when startAuthenticated is true', () {
      final repo = FakeAuthRepository(startAuthenticated: true);
      expect(repo.isAuthenticated(), true);
      expect(repo.getCurrentCredentials(), isNotNull);
      // Default authenticated user in FakeAuthRepository is test@example.com
      expect(repo.getCurrentCredentials()!.email, 'test@example.com');
      repo.dispose(); // Dispose instance created in test
    });
  });
} 