import 'package:flutter_test/flutter_test.dart';
import 'package:construculator/libraries/auth/testing/fake_auth_repository.dart';


void main() {
  late FakeAuthRepository fakeRepository;

  setUp(() {
    fakeRepository = FakeAuthRepository();
  });

  // No tearDown here as the test itself calls dispose and checks behavior.

  group('Resource Management', () {
    test('dispose should close all streams without error', () {
      // Arrange - add listeners to streams to check they are handled by dispose
      final authStateSubscription = fakeRepository.authStateChanges.listen((_) {});
      final userChangesSubscription = fakeRepository.userChanges.listen((_) {});

      // Act & Assert - should not throw
      expect(() => fakeRepository.dispose(), returnsNormally);

      // Optionally, try to add more listeners after dispose - this might throw if closed correctly,
      // or just do nothing. Behavior depends on StreamController implementation.
      // For now, just checking dispose() runs without error is the primary goal from original test.
      
      // It's good practice to cancel subscriptions, though dispose should handle controllers.
      authStateSubscription.cancel();
      userChangesSubscription.cancel();
    });
  });
} 