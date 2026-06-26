/// Base route segment for the project settings feature module.
const String projectSettingsBaseRoute = '/project-settings';

final String createProjectChildRoute = '/create-project';
final String createProjectRoute = '$projectSettingsBaseRoute$createProjectChildRoute';

/// Route segment for the [ProjectDetailScreen] within [ProjectSettingsModule].
const String viewProjectRoute = '/view-project';

/// Full routable path to [ProjectDetailScreen].
const String fullViewProjectRoute = '$projectSettingsBaseRoute$viewProjectRoute';

final String editProjectChildRoute = '/edit-project';
final String editProjectRoute = '$projectSettingsBaseRoute$editProjectChildRoute';
