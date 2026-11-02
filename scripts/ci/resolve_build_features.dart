// Resolve Build Features
//
// `config/flavors/<flavor>.json` is a human-edited list of enabled feature
// names, e.g. {"features": ["calculator"]}. `flutter build` cannot consume
// that shape directly: `--dart-define-from-file` needs one `ENABLE_X: bool`
// entry per feature in the `Feature` enum in
// lib/libraries/config/feature_availability.dart. This tool writes that file
// to build/generated/flavors/<flavor>.json ahead of the build. Doing it before
// `flutter build` runs (rather than inside the app) keeps BuildFeatures'
// compile-time guarantee intact.
//
// The feature names come from the `Feature` enum itself, so Dart holds the
// only list. Each enum value `fooBar` is listed in manifests as `foo_bar` and
// becomes the key `ENABLE_FOO_BAR`.
//
// Imports no Flutter package, so it runs with plain Dart. The enum and
// BuildFeatures are read as text for the same reason, so `enum Feature` must
// stay a plain enum with no `implements`, `with` or value arguments.
//
// Usage (from the repository root):
//   fvm dart run scripts/ci/resolve_build_features.dart <flavor>
//
// Exits 0 and writes the resolved file on success; exits 1 with a specific
// message when an input is missing or inconsistent.

import 'dart:convert';
import 'dart:io';

/// Raised for every input problem this tool reports; [message] is printed as is.
class ResolveException implements Exception {
  /// Creates an exception that carries the message shown to the developer.
  const ResolveException(this.message);

  /// What is wrong and which file it is in.
  final String message;

  @override
  String toString() => message;
}

/// Flavors from the one with the fewest features to the one with the most.
///
/// Prod must be inside dogfood, and dogfood inside fishfood, so nothing ships
/// to prod that dogfood QA did not test.
const List<String> flavorsFewestFeaturesFirst = <String>[
  'prod',
  'dogfood',
  'fishfood',
];

const String _featureEnumPath =
    'lib/libraries/config/feature_availability.dart';
const String _buildFeaturesPath = 'lib/libraries/config/build_features.dart';
const String _outputDirectoryPath = 'build/generated/flavors';

/// Writes `build/generated/flavors/<flavor>.json` under [projectRoot].
///
/// Returns the written file. Throws [ResolveException], before writing
/// anything, when the manifest is missing or has no `features` list, lists a
/// name that is not in the `Feature` enum, when an enum value has no
/// `BuildFeatures` constant, or when the three manifests are not nested.
File resolveBuildFeatures(String flavor, Directory projectRoot) {
  final List<String> enumNames = readFeatureEnumNames(
    File('${projectRoot.path}/$_featureEnumPath'),
  );
  checkBuildFeaturesCoverEnum(
    enumNames,
    File('${projectRoot.path}/$_buildFeaturesPath'),
  );
  final Set<String> enabled = readManifestFeatures(
    _manifestFile(projectRoot, flavor),
    enumNames,
  );
  checkManifestsNest(projectRoot, enumNames);

  final File output = File(
    '${projectRoot.path}/$_outputDirectoryPath/$flavor.json',
  );
  output.createSync(recursive: true);
  output.writeAsStringSync(_renderDefines(enumNames, enabled));
  return output;
}

/// Returns the values of `enum Feature` in [source], in declaration order.
///
/// Throws [ResolveException] when the file or the enum is missing, or when a
/// value is not a plain identifier (this reader does not handle enum
/// arguments).
List<String> readFeatureEnumNames(File source) {
  final String withoutComments = _withoutComments(
    _readRequired(source, 'Feature enum source'),
  );
  final RegExpMatch? body = RegExp(
    r'enum\s+Feature\s*\{([^}]*)\}',
  ).firstMatch(withoutComments);
  if (body == null) {
    throw ResolveException('${source.path} has no "enum Feature"');
  }
  final List<String> names = (body.group(1) ?? '')
      .split(RegExp(r'[,;]'))
      .map((String value) => value.trim())
      .where((String value) => value.isNotEmpty)
      .toList();
  for (final String name in names) {
    if (!RegExp(r'^[a-z][A-Za-z0-9]*$').hasMatch(name)) {
      throw ResolveException(
        '${source.path}: cannot read enum value "$name"; '
        'Feature values must be plain lowerCamelCase names',
      );
    }
  }
  if (names.isEmpty) {
    throw ResolveException('${source.path}: "enum Feature" has no values');
  }
  return names;
}

/// Maps an enum value such as `globalSearch` to its manifest name `global_search`.
String manifestNameOf(String enumName) => enumName.replaceAllMapped(
  RegExp(r'[A-Z]'),
  (Match match) => '_${(match.group(0) ?? '').toLowerCase()}',
);

/// Maps an enum value such as `globalSearch` to its key `ENABLE_GLOBAL_SEARCH`.
String envKeyOf(String enumName) =>
    'ENABLE_${manifestNameOf(enumName).toUpperCase()}';

/// Fails when an enum value in [enumNames] has no matching constant in [buildFeatures].
///
/// Without this check a feature whose BuildFeatures constant reads a different
/// key ignores the manifest, falls back to `defaultValue: true` and ships in
/// every flavor.
void checkBuildFeaturesCoverEnum(List<String> enumNames, File buildFeatures) {
  final String code = _withoutComments(
    _readRequired(buildFeatures, 'BuildFeatures source'),
  );
  final Set<String> declaredKeys = RegExp(
    r'''bool\.fromEnvironment\(\s*['"](ENABLE_[A-Z0-9_]+)['"]''',
  ).allMatches(code).map((RegExpMatch match) => match.group(1) ?? '').toSet();
  for (final String name in enumNames) {
    final String key = envKeyOf(name);
    if (!declaredKeys.contains(key)) {
      throw ResolveException(
        'Feature.$name has no BuildFeatures constant: add one that reads '
        "'$key' in ${buildFeatures.path}",
      );
    }
  }
}

/// Returns the enum values that [manifest] lists, validated against [enumNames].
///
/// Throws [ResolveException] when the file is missing or is not JSON, has no
/// `features` list, lists anything that is not the manifest name of an enum
/// value, or lists the same feature twice.
Set<String> readManifestFeatures(File manifest, List<String> enumNames) {
  final String text = _readRequired(manifest, 'flavor manifest');
  final Object? decoded;
  try {
    decoded = jsonDecode(text);
  } on FormatException catch (error) {
    throw ResolveException(
      '${manifest.path} is not valid JSON: ${error.message}',
    );
  }
  final Object? features = decoded is Map<String, Object?>
      ? decoded['features']
      : null;
  if (features is! List<Object?>) {
    throw ResolveException('${manifest.path} has no "features" list');
  }
  final Map<String, String> enumNameByManifestName = <String, String>{
    for (final String name in enumNames) manifestNameOf(name): name,
  };
  final Set<String> enabled = <String>{};
  for (final Object? listed in features) {
    final String? enumName = enumNameByManifestName[listed];
    if (enumName == null) {
      throw ResolveException(
        'Unknown feature ${jsonEncode(listed)} in ${manifest.path}. '
        'Known features: ${enumNameByManifestName.keys.join(', ')}',
      );
    }
    if (!enabled.add(enumName)) {
      throw ResolveException(
        'Feature ${jsonEncode(listed)} is listed twice in ${manifest.path}',
      );
    }
  }
  return enabled;
}

/// Fails with the name of the first feature that breaks prod inside dogfood
/// inside fishfood, reading every manifest under [projectRoot].
void checkManifestsNest(Directory projectRoot, List<String> enumNames) {
  for (int i = 0; i + 1 < flavorsFewestFeaturesFirst.length; i++) {
    final String inner = flavorsFewestFeaturesFirst[i];
    final String outer = flavorsFewestFeaturesFirst[i + 1];
    final Set<String> innerFeatures = readManifestFeatures(
      _manifestFile(projectRoot, inner),
      enumNames,
    );
    final Set<String> outerFeatures = readManifestFeatures(
      _manifestFile(projectRoot, outer),
      enumNames,
    );
    for (final String name in enumNames) {
      if (innerFeatures.contains(name) && !outerFeatures.contains(name)) {
        throw ResolveException(
          'Feature "${manifestNameOf(name)}" is in the $inner manifest but not '
          'in the $outer manifest: $inner must be inside $outer',
        );
      }
    }
  }
}

/// Runs the tool for [args] and returns the process exit code.
///
/// [out] gets the success line and [err] gets the usage text or the error. A
/// file system error, such as an output path that cannot be written, is
/// reported the same way as any other input problem.
int runResolver(
  List<String> args,
  Directory projectRoot,
  StringSink out,
  StringSink err,
) {
  if (args.length != 1 || args.single.isEmpty) {
    err.writeln('❌ ERROR: Usage: resolve_build_features.dart <flavor>');
    return 1;
  }
  final String flavor = args.single;
  try {
    final File written = resolveBuildFeatures(flavor, projectRoot);
    out.writeln(
      "✅ Resolved build features for flavor '$flavor' -> ${written.path}",
    );
    return 0;
  } on ResolveException catch (error) {
    err.writeln('❌ ERROR: ${error.message}');
    return 1;
  } on FileSystemException catch (error) {
    err.writeln('❌ ERROR: ${error.message}: ${error.path}');
    return 1;
  }
}

/// Entry point: resolves the flavor named in [args] against the current directory.
void main(List<String> args) {
  exitCode = runResolver(args, Directory.current, stdout, stderr);
}

File _manifestFile(Directory projectRoot, String flavor) =>
    File('${projectRoot.path}/config/flavors/$flavor.json');

String _withoutComments(String code) => code
    .replaceAll(RegExp(r'/\*.*?\*/', dotAll: true), '')
    .replaceAll(RegExp(r'//[^\n]*'), '');

String _readRequired(File file, String description) {
  if (!file.existsSync()) {
    throw ResolveException('No $description found at ${file.path}');
  }
  return file.readAsStringSync();
}

String _renderDefines(List<String> enumNames, Set<String> enabled) {
  final String entries = enumNames
      .map((String name) => '  "${envKeyOf(name)}": ${enabled.contains(name)}')
      .join(',\n');
  return '{\n$entries\n}\n';
}
