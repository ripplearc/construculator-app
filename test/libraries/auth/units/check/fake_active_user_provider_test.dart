import 'package:construculator/libraries/auth/check/testing/fake_active_user_provider.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FakeActiveUserProvider', () {
    test(
      'reports the user the function returns at the time of the call',
      () async {
        String? signedIn;
        final provider = FakeActiveUserProvider(userIdOf: () => signedIn);
        expect(provider.activeUserId, isNull);

        signedIn = 'user-a';

        expect(provider.activeUserId, 'user-a');
        expect(await provider.whenFinished(), 'user-a');
      },
    );

    test('is finished for the signed-in user only', () async {
      final provider = FakeActiveUserProvider(userIdOf: () => 'user-a');

      expect(await provider.whenFinishedFor('user-a'), isTrue);
      expect(await provider.whenFinishedFor('user-b'), isFalse);
    });
  });
}
