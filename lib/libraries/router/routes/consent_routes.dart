// coverage:ignore-file
// Top-level constants only, so the VM emits no coverable statements and the
// file never appears in lcov.info -- matching calculator_routes.dart and
// project_search_routes.dart. The values themselves are asserted in
// consent_module_test.dart against the routes actually registered.

/// Base route segment for the consent feature module.
const String consentBaseRoute = '/consent';

/// Route segment for the consent gate within the consent module.
const String consentGateRoute = '/gate';

/// Full routable path to the consent gate page.
///
/// This is where [ConsentGuard] redirects a user whose consent is stale. The
/// page sits behind [AuthGuard] only — it must stay reachable while the shell
/// itself is blocked, or the redirect would have nowhere to land.
const String fullConsentGateRoute = '$consentBaseRoute$consentGateRoute';
