import 'package:flutter_test/flutter_test.dart';
import 'package:construculator_app_architecture/core/config/constants.dart';

void main() {
  group('Constants', () {
    group('Environment String Constants', () {
      test('should have correct environment string values', () {
        expect(devEnv, equals('dev'));
        expect(qaEnv, equals('qa'));
        expect(prodEnv, equals('prod'));
      });

      test('environment strings should be non-empty', () {
        expect(devEnv.isNotEmpty, isTrue);
        expect(qaEnv.isNotEmpty, isTrue);
        expect(prodEnv.isNotEmpty, isTrue);
      });

      test('environment strings should be unique', () {
        final envs = {devEnv, qaEnv, prodEnv};
        expect(envs.length, equals(3)); // All should be unique
      });
    });

    group('Environment Readable Names', () {
      test('should have correct readable names', () {
        expect(devReadableName, equals('Development'));
        expect(qaReadableName, equals('QA'));
        expect(prodReadableName, equals('Production'));
      });

      test('readable names should be non-empty', () {
        expect(devReadableName.isNotEmpty, isTrue);
        expect(qaReadableName.isNotEmpty, isTrue);
        expect(prodReadableName.isNotEmpty, isTrue);
      });

      test('readable names should be properly formatted', () {
        // Should start with capital letter
        expect(devReadableName[0], equals(devReadableName[0].toUpperCase()));
        expect(qaReadableName[0], equals(qaReadableName[0].toUpperCase()));
        expect(prodReadableName[0], equals(prodReadableName[0].toUpperCase()));
      });

      test('readable names should be unique', () {
        final names = {devReadableName, qaReadableName, prodReadableName};
        expect(names.length, equals(3)); // All should be unique
      });
    });

    group('Environment Enum', () {
      test('should have all expected enum values', () {
        final values = Environment.values;
        expect(values.length, equals(3));
        expect(values.contains(Environment.dev), isTrue);
        expect(values.contains(Environment.qa), isTrue);
        expect(values.contains(Environment.prod), isTrue);
      });

      test('enum values should have correct names', () {
        expect(Environment.dev.name, equals('dev'));
        expect(Environment.qa.name, equals('qa'));
        expect(Environment.prod.name, equals('prod'));
      });

      test('enum values should have correct indices', () {
        expect(Environment.dev.index, equals(0));
        expect(Environment.qa.index, equals(1));
        expect(Environment.prod.index, equals(2));
      });

      test('should be able to convert from string to enum', () {
        // Test string to enum conversion (if needed in the app)
        expect(Environment.values.firstWhere((e) => e.name == 'dev'), equals(Environment.dev));
        expect(Environment.values.firstWhere((e) => e.name == 'qa'), equals(Environment.qa));
        expect(Environment.values.firstWhere((e) => e.name == 'prod'), equals(Environment.prod));
      });

      test('should support switch statements', () {
        String getDescription(Environment env) {
          switch (env) {
            case Environment.dev:
              return 'Development environment';
            case Environment.qa:
              return 'Quality assurance environment';
            case Environment.prod:
              return 'Production environment';
          }
        }

        expect(getDescription(Environment.dev), equals('Development environment'));
        expect(getDescription(Environment.qa), equals('Quality assurance environment'));
        expect(getDescription(Environment.prod), equals('Production environment'));
      });

      test('should support comparison operations', () {
        expect(Environment.dev == Environment.dev, isTrue);
        expect(Environment.dev == Environment.qa, isFalse);
        expect(Environment.dev != Environment.prod, isTrue);
      });
    });

    group('Consistency Between Constants and Enum', () {
      test('string constants should match enum names', () {
        expect(devEnv, equals(Environment.dev.name));
        expect(qaEnv, equals(Environment.qa.name));
        expect(prodEnv, equals(Environment.prod.name));
      });

      test('should have matching count of constants and enum values', () {
        final stringConstants = [devEnv, qaEnv, prodEnv];
        final readableNames = [devReadableName, qaReadableName, prodReadableName];
        final enumValues = Environment.values;

        expect(stringConstants.length, equals(enumValues.length));
        expect(readableNames.length, equals(enumValues.length));
      });
    });

    group('Type Safety', () {
      test('constants should have correct types', () {
        expect(devEnv, isA<String>());
        expect(qaEnv, isA<String>());
        expect(prodEnv, isA<String>());
        expect(devReadableName, isA<String>());
        expect(qaReadableName, isA<String>());
        expect(prodReadableName, isA<String>());
      });

      test('enum should have correct type', () {
        expect(Environment.dev, isA<Environment>());
        expect(Environment.qa, isA<Environment>());
        expect(Environment.prod, isA<Environment>());
      });
    });

    group('Immutability', () {
      test('constants should be compile-time constants', () {
        // These should be compile-time constants (const)
        const testDevEnv = devEnv;
        const testQaEnv = qaEnv;
        const testProdEnv = prodEnv;
        const testDevReadableName = devReadableName;
        const testQaReadableName = qaReadableName;
        const testProdReadableName = prodReadableName;

        expect(testDevEnv, equals(devEnv));
        expect(testQaEnv, equals(qaEnv));
        expect(testProdEnv, equals(prodEnv));
        expect(testDevReadableName, equals(devReadableName));
        expect(testQaReadableName, equals(qaReadableName));
        expect(testProdReadableName, equals(prodReadableName));
      });
    });
  });
} 