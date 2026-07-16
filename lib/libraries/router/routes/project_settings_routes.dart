/// Base route segment for the project settings feature module.
const String projectSettingsBaseRoute = '/project-settings';

const String createProjectChildRoute = '/create-project';
const String createProjectRoute = '$projectSettingsBaseRoute$createProjectChildRoute';

/// Route segment for the [ProjectDetailScreen] within [ProjectSettingsRoutesModule].
const String viewProjectRoute = '/view-project';

/// Full routable path to [ProjectDetailScreen].
const String fullViewProjectRoute = '$projectSettingsBaseRoute$viewProjectRoute';

const String editProjectChildRoute = '/edit-project';
const String editProjectRoute = '$projectSettingsBaseRoute$editProjectChildRoute';
