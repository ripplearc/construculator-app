import 'package:flutter_test/flutter_test.dart';
import 'package:construculator/libraries/auth/data/models/auth_credential.dart';

void main() {
  group('UserCredential Model', () {
    group('empty factory', () {
      test('should create empty UserCredential with default values', () {
        final credential = UserCredential.empty();

        expect(credential.id, '');
        expect(credential.email, '');
        expect(credential.metadata, isEmpty);
        expect(credential.createdAt, isA<DateTime>());
      });

      test('should create empty UserCredential with recent timestamp', () {

        final beforeCreation = DateTime.now();

        final credential = UserCredential.empty();

        final afterCreation = DateTime.now();

        expect(
          credential.createdAt.isAfter(
            beforeCreation.subtract(Duration(seconds: 1)),
          ),
          true,
        );
        expect(
          credential.createdAt.isBefore(
            afterCreation.add(Duration(seconds: 1)),
          ),
          true,
        );
      });

      test(
        'should create multiple empty credentials with different timestamps',
        () async {
          final credential1 = UserCredential.empty();
          final credential2 = UserCredential.empty();

          expect(
            credential1.id,
            credential2.id,
          );
          expect(
            credential1.email,
            credential2.email,
          ); 
          expect(
            credential1.metadata,
            credential2.metadata,
          );
          expect(
            credential1.createdAt.isBefore(credential2.createdAt) ||
                credential1.createdAt.isAtSameMomentAs(credential2.createdAt),
            true,
          );
        },
      );

      test('should create empty credential with mutable metadata', () {
        final credential = UserCredential.empty();

        credential.metadata['test_key'] = 'test_value';

        expect(credential.metadata['test_key'], 'test_value');
        expect(credential.metadata, hasLength(1));
      });
    });
  });
}
