import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../../../scripts/ci/resolve_build_features.dart';

void main() {
  late Directory root;

  setUp(() {
    root = Directory.systemTemp.createTempSync('resolve_build_features_test');
  });

  tearDown(() {
    root.deleteSync(recursive: true);
  });

  void writeFile(String relativePath, String content) {
    File('${root.path}/$relativePath')
      ..createSync(recursive: true)
      ..writeAsStringSync(content);
  }

  void writeFeatureEnum(List<String> names) {
    writeFile(
      'lib/libraries/config/feature_availability.dart',
      'enum Feature {\n${names.map((String n) => '  /// $n\n  $n,\n').join()}}\n',
    );
  }

  void writeBuildFeatures(List<String> keys) {
    final String constants = keys
        .map(
          (String key) =>
              '''
  static const bool x$key = bool.fromEnvironment(
    '$key',
    defaultValue: true,
  );
''',
        )
        .join();
    writeFile(
      'lib/libraries/config/build_features.dart',
      'abstract final class BuildFeatures {\n$constants}\n',
    );
  }

  void writeManifest(String flavor, List<String> features) {
    final String quoted = features.map((String f) => '"$f"').join(', ');
    writeFile('config/flavors/$flavor.json', '{"features": [$quoted]}');
  }

  void writeCodeFor(List<String> enumNames) {
    writeFeatureEnum(enumNames);
    writeBuildFeatures(enumNames.map(envKeyOf).toList());
  }

  void writeNestedManifests({
    List<String> prod = const <String>[],
    List<String> dogfood = const <String>[],
    List<String> fishfood = const <String>[],
  }) {
    writeManifest('prod', prod);
    writeManifest('dogfood', dogfood);
    writeManifest('fishfood', fishfood);
  }

  String resolvedFile(String flavor) => File(
    '${root.path}/build/generated/flavors/$flavor.json',
  ).readAsStringSync();

  bool resolvedFileExists(String flavor) =>
      File('${root.path}/build/generated/flavors/$flavor.json').existsSync();

  Matcher failsWith(Matcher message) => throwsA(
    isA<ResolveException>().having(
      (ResolveException e) => e.message,
      'message',
      message,
    ),
  );

  group('the three real manifests', () {
    setUp(() {
      for (final String path in <String>[
        'lib/libraries/config/feature_availability.dart',
        'lib/libraries/config/build_features.dart',
        'config/flavors/prod.json',
        'config/flavors/dogfood.json',
        'config/flavors/fishfood.json',
      ]) {
        writeFile(path, File(path).readAsStringSync());
      }
    });

    test('fishfood turns the calculator on', () {
      resolveBuildFeatures('fishfood', root);

      expect(resolvedFile('fishfood'), '{\n  "ENABLE_CALCULATOR": true\n}\n');
    });

    test('dogfood turns the calculator on', () {
      resolveBuildFeatures('dogfood', root);

      expect(resolvedFile('dogfood'), '{\n  "ENABLE_CALCULATOR": true\n}\n');
    });

    test('prod turns the calculator off', () {
      resolveBuildFeatures('prod', root);

      expect(resolvedFile('prod'), '{\n  "ENABLE_CALCULATOR": false\n}\n');
    });
  });

  group('resolving a flavor', () {
    test(
      'writes one key per enum value, in enum order, true only when listed',
      () {
        writeCodeFor(<String>['calculator', 'globalSearch', 'estimation']);
        writeNestedManifests(
          prod: <String>['estimation'],
          dogfood: <String>['estimation', 'global_search'],
          fishfood: <String>['calculator', 'estimation', 'global_search'],
        );

        resolveBuildFeatures('dogfood', root);

        expect(
          resolvedFile('dogfood'),
          '{\n'
          '  "ENABLE_CALCULATOR": false,\n'
          '  "ENABLE_GLOBAL_SEARCH": true,\n'
          '  "ENABLE_ESTIMATION": true\n'
          '}\n',
        );
      },
    );

    test('an empty features list turns every feature off', () {
      writeCodeFor(<String>['calculator', 'globalSearch']);
      writeNestedManifests();

      resolveBuildFeatures('prod', root);

      expect(
        resolvedFile('prod'),
        '{\n  "ENABLE_CALCULATOR": false,\n  "ENABLE_GLOBAL_SEARCH": false\n}\n',
      );
    });

    test('replaces a file left by an earlier run', () {
      writeCodeFor(<String>['calculator']);
      writeNestedManifests(
        prod: <String>['calculator'],
        dogfood: <String>['calculator'],
        fishfood: <String>['calculator'],
      );
      resolveBuildFeatures('prod', root);
      writeNestedManifests();

      resolveBuildFeatures('prod', root);

      expect(resolvedFile('prod'), '{\n  "ENABLE_CALCULATOR": false\n}\n');
    });

    test('reads enum values written with trailing semicolons and comments', () {
      writeFile(
        'lib/libraries/config/feature_availability.dart',
        'enum Feature {\n'
            '  // not a doc comment, with a { brace\n'
            '  calculator,\n'
            '  /// the second one\n'
            '  globalSearch;\n'
            '}\n',
      );
      writeBuildFeatures(<String>['ENABLE_CALCULATOR', 'ENABLE_GLOBAL_SEARCH']);
      writeNestedManifests();

      resolveBuildFeatures('prod', root);

      expect(
        resolvedFile('prod'),
        '{\n  "ENABLE_CALCULATOR": false,\n  "ENABLE_GLOBAL_SEARCH": false\n}\n',
      );
    });

    test(
      'a comment with a glob path does not hide the enum values around it',
      () {
        writeFile(
          'lib/libraries/config/feature_availability.dart',
          'enum Feature {\n'
              '  /// Screens under lib/features/calculator/*.dart\n'
              '  calculator,\n'
              '  /// New one. Tests under test/features/**/search_test.dart\n'
              '  globalSearch,\n'
              '}\n',
        );
        writeBuildFeatures(<String>[
          'ENABLE_CALCULATOR',
          'ENABLE_GLOBAL_SEARCH',
        ]);
        writeNestedManifests();

        resolveBuildFeatures('prod', root);

        expect(
          resolvedFile('prod'),
          '{\n  "ENABLE_CALCULATOR": false,\n  "ENABLE_GLOBAL_SEARCH": false\n}\n',
        );
      },
    );
  });

  group('a missing or broken manifest', () {
    setUp(() {
      writeCodeFor(<String>['calculator']);
    });

    test('fails naming the missing manifest file', () {
      writeManifest('prod', <String>[]);
      writeManifest('dogfood', <String>[]);

      expect(
        () => resolveBuildFeatures('fishfood', root),
        failsWith(
          equals(
            'No flavor manifest found at ${root.path}/config/flavors/fishfood.json',
          ),
        ),
      );
      expect(resolvedFileExists('fishfood'), isFalse);
    });

    test('fails when the file has no features key', () {
      writeFile('config/flavors/prod.json', '{}');

      expect(
        () => resolveBuildFeatures('prod', root),
        failsWith(
          equals(
            '${root.path}/config/flavors/prod.json has no "features" list',
          ),
        ),
      );
      expect(resolvedFileExists('prod'), isFalse);
    });

    test('fails when features is not a list', () {
      writeFile('config/flavors/prod.json', '{"features": "calculator"}');

      expect(
        () => resolveBuildFeatures('prod', root),
        failsWith(contains('has no "features" list')),
      );
    });

    test('fails when the top level is not an object', () {
      writeFile('config/flavors/prod.json', '["calculator"]');

      expect(
        () => resolveBuildFeatures('prod', root),
        failsWith(contains('has no "features" list')),
      );
    });

    test('fails naming a feature listed twice', () {
      writeManifest('prod', <String>['calculator', 'calculator']);

      expect(
        () => resolveBuildFeatures('prod', root),
        failsWith(
          equals(
            'Feature "calculator" is listed twice in '
            '${root.path}/config/flavors/prod.json',
          ),
        ),
      );
      expect(resolvedFileExists('prod'), isFalse);
    });

    test('fails when the file is empty', () {
      writeFile('config/flavors/prod.json', '');

      expect(
        () => resolveBuildFeatures('prod', root),
        failsWith(contains('config/flavors/prod.json is not valid JSON')),
      );
      expect(resolvedFileExists('prod'), isFalse);
    });

    test('fails naming the unknown feature, the manifest and the known ones', () {
      writeManifest('prod', <String>['calculater']);

      expect(
        () => resolveBuildFeatures('prod', root),
        failsWith(
          equals(
            'Unknown feature "calculater" in ${root.path}/config/flavors/prod.json. '
            'Known features: calculator',
          ),
        ),
      );
      expect(resolvedFileExists('prod'), isFalse);
    });

    test('fails when a listed feature is not a string', () {
      writeFile('config/flavors/prod.json', '{"features": [7]}');

      expect(
        () => resolveBuildFeatures('prod', root),
        failsWith(contains('Unknown feature 7')),
      );
    });

    test(
      'fails on the camelCase enum spelling, since manifests use snake_case',
      () {
        writeCodeFor(<String>['calculator', 'globalSearch']);
        writeManifest('prod', <String>['globalSearch']);

        expect(
          () => resolveBuildFeatures('prod', root),
          failsWith(contains('Unknown feature "globalSearch"')),
        );
      },
    );
  });

  group('the feature enum and BuildFeatures', () {
    test('an enum value with no BuildFeatures constant fails the script', () {
      writeFeatureEnum(<String>['calculator', 'globalSearch']);
      writeBuildFeatures(<String>['ENABLE_CALCULATOR']);
      writeNestedManifests();

      expect(
        () => resolveBuildFeatures('prod', root),
        failsWith(
          equals(
            'Feature.globalSearch has no BuildFeatures constant: add one that '
            "reads 'ENABLE_GLOBAL_SEARCH' in "
            '${root.path}/lib/libraries/config/build_features.dart',
          ),
        ),
      );
      expect(resolvedFileExists('prod'), isFalse);
    });

    test('a constant that reads a different key does not count', () {
      writeFeatureEnum(<String>['calculator']);
      writeBuildFeatures(<String>['ENABLE_CALCULATOR_V2']);
      writeNestedManifests();

      expect(
        () => resolveBuildFeatures('prod', root),
        failsWith(contains("reads 'ENABLE_CALCULATOR'")),
      );
    });

    test('accepts a constant declared with double quotes', () {
      writeFeatureEnum(<String>['calculator']);
      writeFile(
        'lib/libraries/config/build_features.dart',
        'const bool c = bool.fromEnvironment("ENABLE_CALCULATOR");\n',
      );
      writeNestedManifests();

      resolveBuildFeatures('prod', root);

      expect(resolvedFile('prod'), '{\n  "ENABLE_CALCULATOR": false\n}\n');
    });

    test('fails when the enum source file is missing', () {
      writeBuildFeatures(<String>['ENABLE_CALCULATOR']);
      writeNestedManifests();

      expect(
        () => resolveBuildFeatures('prod', root),
        failsWith(
          equals(
            'No Feature enum source found at '
            '${root.path}/lib/libraries/config/feature_availability.dart',
          ),
        ),
      );
    });

    test('fails when the file has no Feature enum', () {
      writeFile('lib/libraries/config/feature_availability.dart', 'class A {}');
      writeBuildFeatures(<String>['ENABLE_CALCULATOR']);

      expect(
        () => resolveBuildFeatures('prod', root),
        failsWith(contains('has no "enum Feature"')),
      );
    });

    test('fails when the enum has no values', () {
      writeFile(
        'lib/libraries/config/feature_availability.dart',
        'enum Feature {}',
      );

      expect(
        () => resolveBuildFeatures('prod', root),
        failsWith(contains('"enum Feature" has no values')),
      );
    });

    test('fails on an enum value this reader cannot parse', () {
      writeFile(
        'lib/libraries/config/feature_availability.dart',
        'enum Feature { calculator("x") }',
      );

      expect(
        () => resolveBuildFeatures('prod', root),
        failsWith(contains('cannot read enum value "calculator("x")"')),
      );
    });

    test('a constant that appears only in a comment does not count', () {
      writeFeatureEnum(<String>['calculator']);
      writeFile(
        'lib/libraries/config/build_features.dart',
        "// static const bool a = bool.fromEnvironment('ENABLE_CALCULATOR');\n"
            "/// bool.fromEnvironment('ENABLE_CALCULATOR')\n"
            "/* bool.fromEnvironment('ENABLE_CALCULATOR') */\n",
      );
      writeNestedManifests();

      expect(
        () => resolveBuildFeatures('prod', root),
        failsWith(contains("reads 'ENABLE_CALCULATOR'")),
      );
    });

    test('a block comment with a brace inside the enum is ignored', () {
      writeFile(
        'lib/libraries/config/feature_availability.dart',
        'enum Feature {\n'
            '  /* legacy } value */\n'
            '  calculator,\n'
            '}\n',
      );
      writeBuildFeatures(<String>['ENABLE_CALCULATOR']);
      writeNestedManifests();

      resolveBuildFeatures('prod', root);

      expect(resolvedFile('prod'), '{\n  "ENABLE_CALCULATOR": false\n}\n');
    });

    test('fails when the BuildFeatures source file is missing', () {
      writeFeatureEnum(<String>['calculator']);
      writeNestedManifests();

      expect(
        () => resolveBuildFeatures('prod', root),
        failsWith(
          equals(
            'No BuildFeatures source found at '
            '${root.path}/lib/libraries/config/build_features.dart',
          ),
        ),
      );
    });
  });

  group('prod inside dogfood inside fishfood', () {
    setUp(() {
      writeCodeFor(<String>['calculator', 'globalSearch']);
    });

    test('passes when each flavor lists exactly the same features', () {
      writeNestedManifests(
        prod: <String>['calculator'],
        dogfood: <String>['calculator'],
        fishfood: <String>['calculator'],
      );

      resolveBuildFeatures('prod', root);

      expect(resolvedFileExists('prod'), isTrue);
    });

    test('passes when an outer flavor lists more than the inner one', () {
      writeNestedManifests(
        prod: <String>[],
        dogfood: <String>['calculator'],
        fishfood: <String>['calculator', 'global_search'],
      );

      resolveBuildFeatures('fishfood', root);

      expect(resolvedFileExists('fishfood'), isTrue);
    });

    test('names the feature that is in prod but not in dogfood', () {
      writeNestedManifests(
        prod: <String>['calculator', 'global_search'],
        dogfood: <String>['calculator'],
        fishfood: <String>['calculator', 'global_search'],
      );

      expect(
        () => resolveBuildFeatures('prod', root),
        failsWith(
          equals(
            'Feature "global_search" is in the prod manifest but not in the '
            'dogfood manifest: prod must be inside dogfood',
          ),
        ),
      );
      expect(resolvedFileExists('prod'), isFalse);
    });

    test('names the feature that is in dogfood but not in fishfood', () {
      writeNestedManifests(
        prod: <String>[],
        dogfood: <String>['calculator'],
        fishfood: <String>[],
      );

      expect(
        () => resolveBuildFeatures('dogfood', root),
        failsWith(
          equals(
            'Feature "calculator" is in the dogfood manifest but not in the '
            'fishfood manifest: dogfood must be inside fishfood',
          ),
        ),
      );
    });

    test('fails for every flavor, not only the one that breaks the rule', () {
      writeNestedManifests(
        prod: <String>['calculator'],
        dogfood: <String>[],
        fishfood: <String>[],
      );

      expect(
        () => resolveBuildFeatures('fishfood', root),
        failsWith(contains('Feature "calculator" is in the prod manifest')),
      );
    });

    test('fails when another flavor manifest is missing', () {
      writeManifest('prod', <String>[]);
      writeManifest('fishfood', <String>[]);

      expect(
        () => resolveBuildFeatures('prod', root),
        failsWith(contains('config/flavors/dogfood.json')),
      );
    });
  });

  group('names', () {
    test('a single word maps to its upper-case key', () {
      expect(manifestNameOf('calculator'), 'calculator');
      expect(envKeyOf('calculator'), 'ENABLE_CALCULATOR');
    });

    test('a camelCase value maps to snake_case and a snake-case key', () {
      expect(manifestNameOf('globalSearch'), 'global_search');
      expect(envKeyOf('globalSearch'), 'ENABLE_GLOBAL_SEARCH');
    });
  });

  group('the command line', () {
    late StringBuffer out;
    late StringBuffer err;

    setUp(() {
      out = StringBuffer();
      err = StringBuffer();
      writeCodeFor(<String>['calculator']);
      writeNestedManifests(
        prod: <String>[],
        dogfood: <String>['calculator'],
        fishfood: <String>['calculator'],
      );
    });

    test('exits 0, writes the file and says where', () {
      final int code = runResolver(<String>['dogfood'], root, out, err);

      expect(code, 0);
      expect(
        out.toString(),
        "✅ Resolved build features for flavor 'dogfood' -> "
        '${root.path}/build/generated/flavors/dogfood.json\n',
      );
      expect(err.toString(), isEmpty);
      expect(resolvedFile('dogfood'), '{\n  "ENABLE_CALCULATOR": true\n}\n');
    });

    test('exits 1 with usage when no flavor is given', () {
      final int code = runResolver(<String>[], root, out, err);

      expect(code, 1);
      expect(
        err.toString(),
        '❌ ERROR: Usage: resolve_build_features.dart <flavor>\n',
      );
      expect(out.toString(), isEmpty);
    });

    test('exits 1 with usage when the flavor is an empty string', () {
      final int code = runResolver(<String>[''], root, out, err);

      expect(code, 1);
      expect(err.toString(), contains('Usage:'));
    });

    test('exits 1 with usage when more than one flavor is given', () {
      final int code = runResolver(<String>['prod', 'dogfood'], root, out, err);

      expect(code, 1);
      expect(err.toString(), contains('Usage:'));
      expect(resolvedFileExists('prod'), isFalse);
    });

    test('exits 1 and names the path when the output cannot be written', () {
      writeFile('build', 'a file where the build directory should be');

      final int code = runResolver(<String>['prod'], root, out, err);

      expect(code, 1);
      expect(err.toString(), startsWith('❌ ERROR: '));
      expect(err.toString(), contains('${root.path}/build'));
      expect(out.toString(), isEmpty);
    });

    test('exits 1 and prints the reason when an input is wrong', () {
      writeManifest('prod', <String>['nope']);

      final int code = runResolver(<String>['prod'], root, out, err);

      expect(code, 1);
      expect(
        err.toString(),
        '❌ ERROR: Unknown feature "nope" in ${root.path}/config/flavors/prod.json. '
        'Known features: calculator\n',
      );
      expect(out.toString(), isEmpty);
    });
  });
}
