import 'package:construculator/libraries/config/env_constants.dart';
import 'package:construculator/libraries/config/interfaces/env_loader.dart';

/// Whether this build ships the offline-first local consent store.
///
/// False while `InMemoryLocalConsentDataSource` is the bound implementation:
/// every record is lost on restart, so a user would be re-prompted on every
/// cold start. CA-971 replaces the binding in
/// `ConsentLibraryModule._registerDependencies`.
const bool durableLocalConsentStoreLanded = false;

/// Whether a consent write reaches the server.
///
/// False because there is nothing to reach: `RemoteConsentDataSource` exposes
/// only `fetchPublishedVersions()`, so `ConsentRecorder` has no write method
/// to route to. Flipping this needs all three of a write method on the
/// interface, a `SupabaseConsentDataSource` implementation of it, and a
/// backend RPC behind that -- CA-971's scope is wider than the local-store
/// swap it is usually described as.
const bool remoteConsentWritePathLanded = false;

/// Whether this build can durably record an attributable acceptance.
///
/// The block standing between `CONSENT_GATE_ENABLED` and a live consent gate.
/// A gate that cannot produce a record is worse than no gate -- it collects an
/// acceptance the user believes was kept and keeps nothing -- so the flag
/// alone must not be able to turn it on.
///
/// It is a runtime check reading a source-level constant, not a const-folded
/// one: the two write paths (`CreateAccountBloc._onSubmitted` and
/// `ConsentGateBloc._onAccepted`, the latter reached only through the route
/// `ConsentModule` declines to register) stay in the compiled snapshot. What
/// it guarantees is narrower and is the property that matters: no `.env`
/// value, deployment config, or unread doc comment can lift it. Only editing
/// Dart source under review can -- either this file, or a `persistenceReady`
/// override at one of the three call sites, which `app_module_test` and
/// `auth_module_test` assert the app does not do.
///
/// Both halves, not one: a durable local store still produces no attributable
/// record without the remote path, and the remote path alone still re-prompts
/// on every cold start.
const bool consentPersistenceReady =
    durableLocalConsentStoreLanded && remoteConsentWritePathLanded;

/// Whether the consent gate is live in this build.
///
/// The single place [consentGateEnabledKey] is interpreted: `ShellModule`
/// registers `ConsentGuard` on this, `ConsentModule` registers the gate route
/// on it, and `CreateAccountBloc` records the signup acceptance on it. All
/// three read the same answer by construction rather than by three call sites
/// agreeing to compare the same string the same way.
///
/// [persistenceReady] is a seam so the flag wiring itself stays testable
/// while [consentPersistenceReady] is false. It is not annotated
/// `@visibleForTesting` because the two production call sites forward it,
/// but nothing production passes a value: overriding it means editing Dart
/// source under review, not flipping a config value.
bool consentGateEnabled(
  EnvLoader envLoader, {
  bool persistenceReady = consentPersistenceReady,
}) =>
    persistenceReady && envLoader.get(consentGateEnabledKey) == 'true';
