import 'package:construculator/libraries/router/routes/project_settings_routes.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('project_settings_routes', () {
    test('createProjectRoute is base + child', () {
      expect(
        createProjectRoute,
        equals('$projectSettingsBaseRoute$createProjectChildRoute'),
      );
    });

    test('createProjectRoute resolves to expected path', () {
      expect(createProjectRoute, equals('/project-settings/create-project'));
    });
  });
}
