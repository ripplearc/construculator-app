import 'package:flutter_test/flutter_test.dart';
import 'package:construculator/libraries/auth/data/models/auth_credential.dart';

void main() {
  group('UserCredential Model', () {
    group('constructor', () {
      test('should create UserCredential with all required fields', () {
        // Arrange
        final id = 'cred123';
        final email = 'test@example.com';
        final metadata = <String, dynamic>{'provider': 'email', 'verified': true};
        final createdAt = DateTime.parse('2023-01-01T00:00:00.000Z');

        // Act
        final credential = UserCredential(
          id: id,
          email: email,
          metadata: metadata,
          createdAt: createdAt,
        );

        // Assert
        expect(credential.id, id);
        expect(credential.email, email);
        expect(credential.metadata, metadata);
        expect(credential.createdAt, createdAt);
      });

      test('should create UserCredential with empty metadata', () {
        // Arrange
        final id = 'cred456';
        final email = 'user@example.com';
        final metadata = <String, dynamic>{};
        final createdAt = DateTime.now();

        // Act
        final credential = UserCredential(
          id: id,
          email: email,
          metadata: metadata,
          createdAt: createdAt,
        );

        // Assert
        expect(credential.id, id);
        expect(credential.email, email);
        expect(credential.metadata, isEmpty);
        expect(credential.createdAt, createdAt);
      });

      test('should create UserCredential with complex metadata', () {
        // Arrange
        final id = 'cred789';
        final email = 'complex@example.com';
        final metadata = <String, dynamic>{
          'provider': 'google',
          'verified': true,
          'last_login': '2023-01-01T12:00:00.000Z',
          'login_count': 5,
          'preferences': {
            'theme': 'dark',
            'notifications': false,
          },
          'roles': ['user', 'admin'],
        };
        final createdAt = DateTime.parse('2023-01-01T00:00:00.000Z');

        // Act
        final credential = UserCredential(
          id: id,
          email: email,
          metadata: metadata,
          createdAt: createdAt,
        );

        // Assert
        expect(credential.id, id);
        expect(credential.email, email);
        expect(credential.metadata, metadata);
        expect(credential.metadata['provider'], 'google');
        expect(credential.metadata['verified'], true);
        expect(credential.metadata['login_count'], 5);
        expect(credential.metadata['preferences'], isA<Map>());
        expect(credential.metadata['roles'], isA<List>());
        expect(credential.createdAt, createdAt);
      });
    });

    group('empty factory', () {
      test('should create empty UserCredential with default values', () {
        // Act
        final credential = UserCredential.empty();

        // Assert
        expect(credential.id, '');
        expect(credential.email, '');
        expect(credential.metadata, isEmpty);
        expect(credential.createdAt, isA<DateTime>());
      });

      test('should create empty UserCredential with recent timestamp', () {
        // Arrange
        final beforeCreation = DateTime.now();
        
        // Act
        final credential = UserCredential.empty();
        
        // Arrange
        final afterCreation = DateTime.now();

        // Assert
        expect(credential.createdAt.isAfter(beforeCreation.subtract(Duration(seconds: 1))), true);
        expect(credential.createdAt.isBefore(afterCreation.add(Duration(seconds: 1))), true);
      });

      test('should create multiple empty credentials with different timestamps', () async {
        // Act
        final credential1 = UserCredential.empty();
        
        // Add a small delay to ensure different timestamps
        await Future.delayed(Duration(milliseconds: 1));
        
        final credential2 = UserCredential.empty();

        // Assert
        expect(credential1.id, credential2.id); // Both should be empty strings
        expect(credential1.email, credential2.email); // Both should be empty strings
        expect(credential1.metadata, credential2.metadata); // Both should be empty maps
        expect(credential1.createdAt.isBefore(credential2.createdAt) || 
               credential1.createdAt.isAtSameMomentAs(credential2.createdAt), true);
      });

      test('should create empty credential with mutable metadata', () {
        // Act
        final credential = UserCredential.empty();
        
        // Verify we can modify the metadata (it's not a const/immutable map)
        credential.metadata['test_key'] = 'test_value';

        // Assert
        expect(credential.metadata['test_key'], 'test_value');
        expect(credential.metadata, hasLength(1));
      });
    });

    group('field validation', () {
      test('should handle special characters in email', () {
        // Arrange
        final specialEmails = [
          'user+tag@example.com',
          'user.name@example.com',
          'user_name@example.com',
          'user-name@example.com',
          'user123@example-domain.com',
        ];

        for (final email in specialEmails) {
          // Act
          final credential = UserCredential(
            id: 'test_id',
            email: email,
            metadata: {},
            createdAt: DateTime.now(),
          );

          // Assert
          expect(credential.email, email);
        }
      });

      test('should handle various ID formats', () {
        // Arrange
        final idFormats = [
          'simple_id',
          'uuid-like-id-with-dashes',
          '12345',
          'mixed123ID',
          'ID_WITH_UNDERSCORES',
          'id.with.dots',
        ];

        for (final id in idFormats) {
          // Act
          final credential = UserCredential(
            id: id,
            email: 'test@example.com',
            metadata: {},
            createdAt: DateTime.now(),
          );

          // Assert
          expect(credential.id, id);
        }
      });

      test('should handle edge case timestamps', () {
        // Arrange
        final timestamps = [
          DateTime(1970, 1, 1), // Unix epoch
          DateTime(2000, 1, 1), // Y2K
          DateTime(2023, 12, 31, 23, 59, 59), // End of year
          DateTime.now(), // Current time
          DateTime.now().add(Duration(days: 365)), // Future date
        ];

        for (final timestamp in timestamps) {
          // Act
          final credential = UserCredential(
            id: 'test_id',
            email: 'test@example.com',
            metadata: {},
            createdAt: timestamp,
          );

          // Assert
          expect(credential.createdAt, timestamp);
        }
      });
    });

    group('metadata handling', () {
      test('should preserve metadata reference', () {
        // Arrange
        final metadata = <String, dynamic>{'key': 'value'};
        
        // Act
        final credential = UserCredential(
          id: 'test_id',
          email: 'test@example.com',
          metadata: metadata,
          createdAt: DateTime.now(),
        );
        
        // Modify original metadata
        metadata['new_key'] = 'new_value';

        // Assert - should reflect the change since it's the same reference
        expect(credential.metadata['new_key'], 'new_value');
        expect(credential.metadata, hasLength(2));
      });

      test('should handle null values in metadata', () {
        // Arrange
        final metadata = <String, dynamic>{
          'null_value': null,
          'string_value': 'test',
          'number_value': 42,
          'bool_value': true,
        };

        // Act
        final credential = UserCredential(
          id: 'test_id',
          email: 'test@example.com',
          metadata: metadata,
          createdAt: DateTime.now(),
        );

        // Assert
        expect(credential.metadata['null_value'], isNull);
        expect(credential.metadata['string_value'], 'test');
        expect(credential.metadata['number_value'], 42);
        expect(credential.metadata['bool_value'], true);
      });

      test('should handle nested data structures in metadata', () {
        // Arrange
        final metadata = <String, dynamic>{
          'nested_map': {
            'inner_key': 'inner_value',
            'inner_number': 123,
          },
          'nested_list': [1, 2, 3, 'string', true],
          'mixed_list': [
            {'map_in_list': 'value'},
            [1, 2, 3],
            'simple_string',
          ],
        };

        // Act
        final credential = UserCredential(
          id: 'test_id',
          email: 'test@example.com',
          metadata: metadata,
          createdAt: DateTime.now(),
        );

        // Assert
        expect(credential.metadata['nested_map'], isA<Map>());
        expect(credential.metadata['nested_map']['inner_key'], 'inner_value');
        expect(credential.metadata['nested_list'], isA<List>());
        expect(credential.metadata['nested_list'], hasLength(5));
        expect(credential.metadata['mixed_list'], isA<List>());
        expect(credential.metadata['mixed_list'][0], isA<Map>());
      });
    });
  });
} 