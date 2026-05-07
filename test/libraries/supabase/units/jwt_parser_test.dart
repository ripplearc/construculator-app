import 'dart:convert';

import 'package:construculator/libraries/supabase/utils/jwt_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('JwtParser', () {
    group('parsePayload', () {
      test('successfully parses valid JWT token', () {
        final payload = {
          'user_id': '123',
          'email': 'test@example.com',
          'app_metadata': {
            'projects': {
              'project-1': ['read', 'write']
            }
          }
        };
        final encodedPayload = base64Url.encode(utf8.encode(json.encode(payload)));
        final token = 'header.$encodedPayload.signature';

        final result = JwtParser.parsePayload(token);

        expect(result, isNotNull);
        expect(result!['user_id'], equals('123'));
        expect(result['email'], equals('test@example.com'));
        expect(result['app_metadata'], isA<Map>());
      });

      test('successfully parses JWT token with base64 padding', () {
        final payload = {'sub': '1234567890', 'name': 'John Doe', 'iat': 1516239022};
        final encodedPayload = base64Url.encode(utf8.encode(json.encode(payload)));
        final token = 'header.$encodedPayload.signature';

        final result = JwtParser.parsePayload(token);

        expect(result, isNotNull);
        expect(result!['sub'], equals('1234567890'));
        expect(result['name'], equals('John Doe'));
        expect(result['iat'], equals(1516239022));
      });

      test('successfully parses JWT token without base64 padding', () {
        final payload = {'test': 'value'};
        var encodedPayload = base64Url.encode(utf8.encode(json.encode(payload)));

        encodedPayload = encodedPayload.replaceAll('=', '');
        final token = 'header.$encodedPayload.signature';

        final result = JwtParser.parsePayload(token);

        expect(result, isNotNull);
        expect(result!['test'], equals('value'));
      });

      test('parses JWT token with complex nested structure', () {
        final payload = {
          'app_metadata': {
            'projects': {
              'project-1': ['read', 'write', 'delete'],
              'project-2': ['read']
            },
            'internal_user_id': 'user-123'
          },
          'user_metadata': {
            'name': 'Test User',
            'preferences': {'theme': 'dark', 'language': 'en'}
          }
        };
        final encodedPayload = base64Url.encode(utf8.encode(json.encode(payload)));
        final token = 'header.$encodedPayload.signature';

        final result = JwtParser.parsePayload(token);

        expect(result, isNotNull);
        expect(result!['app_metadata']['projects']['project-1'], hasLength(3));
        expect(result['app_metadata']['internal_user_id'], equals('user-123'));
        expect(result['user_metadata']['preferences']['theme'], equals('dark'));
      });

      test('parses JWT token with special characters in payload', () {
        final payload = {
          'email': 'user+test@example.com',
          'name': 'Test User™',
          'description': 'Line 1\nLine 2\tTabbed'
        };
        final encodedPayload = base64Url.encode(utf8.encode(json.encode(payload)));
        final token = 'header.$encodedPayload.signature';

        final result = JwtParser.parsePayload(token);

        expect(result, isNotNull);
        expect(result!['email'], equals('user+test@example.com'));
        expect(result['name'], equals('Test User™'));
        expect(result['description'], equals('Line 1\nLine 2\tTabbed'));
      });

      test('returns null for empty string', () {
        final result = JwtParser.parsePayload('');

        expect(result, isNull);
      });

      test('returns null for token with only 1 part', () {
        const token = 'onlyonepart';

        final result = JwtParser.parsePayload(token);

        expect(result, isNull);
      });

      test('returns null for token with only 2 parts', () {
        const token = 'header.payload';

        final result = JwtParser.parsePayload(token);

        expect(result, isNull);
      });

      test('returns null for token with 4 parts', () {
        const token = 'header.payload.signature.extra';

        final result = JwtParser.parsePayload(token);

        expect(result, isNull);
      });

      test('returns null for token with invalid base64 encoding', () {
        const token = 'header.invalid@#\$%base64!.signature';

        final result = JwtParser.parsePayload(token);

        expect(result, isNull);
      });

      test('returns null for token with valid base64 but invalid JSON', () {
        final invalidJson = 'not-valid-json{]';
        final encodedPayload = base64Url.encode(utf8.encode(invalidJson));
        final token = 'header.$encodedPayload.signature';

        final result = JwtParser.parsePayload(token);

        expect(result, isNull);
      });

      test('returns null for token with valid base64 but non-object JSON', () {
        final jsonArray = ['item1', 'item2'];
        final encodedPayload = base64Url.encode(utf8.encode(json.encode(jsonArray)));
        final token = 'header.$encodedPayload.signature';

        final result = JwtParser.parsePayload(token);

        expect(result, isNull);
      });

      test('returns null for token with valid base64 but primitive JSON value', () {
        const primitiveValue = '"just a string"';
        final encodedPayload = base64Url.encode(utf8.encode(primitiveValue));
        final token = 'header.$encodedPayload.signature';

        final result = JwtParser.parsePayload(token);

        expect(result, isNull);
      });

      test('returns null for token with empty payload section', () {
        const token = 'header..signature';

        final result = JwtParser.parsePayload(token);

        expect(result, isNull);
      });

      test('parses JWT token with empty object payload', () {
        final payload = <String, dynamic>{};
        final encodedPayload = base64Url.encode(utf8.encode(json.encode(payload)));
        final token = 'header.$encodedPayload.signature';

        final result = JwtParser.parsePayload(token);

        expect(result, isNotNull);
        expect(result, isEmpty);
      });

      test('parses JWT token with null values in payload', () {
        final payload = {'key1': null, 'key2': 'value', 'key3': null};
        final encodedPayload = base64Url.encode(utf8.encode(json.encode(payload)));
        final token = 'header.$encodedPayload.signature';

        final result = JwtParser.parsePayload(token);

        expect(result, isNotNull);
        expect(result!['key1'], isNull);
        expect(result['key2'], equals('value'));
        expect(result['key3'], isNull);
      });

      test('parses JWT token with numeric values', () {
        final payload = {
          'int_value': 42,
          'double_value': 3.14,
          'negative': -100,
          'exp_notation': 1.5e10
        };
        final encodedPayload = base64Url.encode(utf8.encode(json.encode(payload)));
        final token = 'header.$encodedPayload.signature';

        final result = JwtParser.parsePayload(token);

        expect(result, isNotNull);
        expect(result!['int_value'], equals(42));
        expect(result['double_value'], equals(3.14));
        expect(result['negative'], equals(-100));
        expect(result['exp_notation'], equals(1.5e10));
      });

      test('parses JWT token with boolean values', () {
        final payload = {'is_admin': true, 'is_active': false, 'verified': true};
        final encodedPayload = base64Url.encode(utf8.encode(json.encode(payload)));
        final token = 'header.$encodedPayload.signature';

        final result = JwtParser.parsePayload(token);

        expect(result, isNotNull);
        expect(result!['is_admin'], isTrue);
        expect(result['is_active'], isFalse);
        expect(result['verified'], isTrue);
      });

      test('parses JWT token with array values', () {
        final payload = {
          'roles': ['admin', 'user', 'moderator'],
          'numbers': [1, 2, 3, 4, 5],
          'mixed': ['string', 123, true, null]
        };
        final encodedPayload = base64Url.encode(utf8.encode(json.encode(payload)));
        final token = 'header.$encodedPayload.signature';

        final result = JwtParser.parsePayload(token);

        expect(result, isNotNull);
        expect(result!['roles'], hasLength(3));
        expect(result['roles'][0], equals('admin'));
        expect(result['numbers'], equals([1, 2, 3, 4, 5]));
        expect(result['mixed'], equals(['string', 123, true, null]));
      });
    });
  });
}
