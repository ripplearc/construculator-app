import 'package:construculator/libraries/either/interfaces/either.dart';
import 'package:construculator/libraries/errors/failures.dart';

/// Resolves the logged-in user's own company id for company-scoped reads
/// and writes (e.g. "Your rates").
///
/// Multi-company membership does not exist yet (Decision 56 of the
/// Estimation v2 design doc), so this always resolves a single id, never a
/// list. Every screen or repository that needs company scoping should call
/// this instead of reading `Project.owningCompanyId`, which stays
/// unpopulated on every project by design.
abstract class CurrentCompanyResolver {
  /// Resolves the caller's own company id.
  ///
  /// Returns `Right(null)` — not a [Failure] — when the caller has no
  /// `company_users` row yet (e.g. the signup trigger hasn't run, or
  /// failed). Callers must treat that identically to "a user with zero
  /// saved rates," never as an error state.
  ///
  /// Only a non-null id is cached, for the rest of the login session: every
  /// later call, online or offline, returns it without hitting the network
  /// again. A `Right(null)` answer is not cached, so the next call asks the
  /// backend again and can pick up a company that was created in the
  /// meantime. A call that fails returns a [Failure] and caches nothing, so
  /// the next call retries.
  ///
  /// A non-null id is also kept on the device. When the backend cannot be
  /// reached (no signal or a timeout), the id kept for the signed-in user is
  /// returned instead of a [Failure]. That answer is not cached, so the next
  /// call asks the backend again. An id kept for another user is never
  /// returned, and a failure that is not "backend unreachable" never falls
  /// back. A `Right(null)` answer clears what was kept, so a user with no
  /// company is asked again next time.
  Future<Either<Failure, String?>> resolve();

  /// Resolves the caller's company id at sign-in, creating the company first
  /// if the caller has none.
  ///
  /// Same result, caching and device-kept id as [resolve], and a [resolve]
  /// that starts while this runs joins it. If the creating call fails (no
  /// signal, server error) it falls back to the plain lookup, so signing in
  /// is never blocked and the no-company state still applies. Until the server
  /// has answered the creating call once, every later [resolve] tries it
  /// again. Does nothing extra once an id is cached for the signed-in user.
  Future<Either<Failure, String?>> resolveAfterSignIn();

  /// Clears the cached result and the id kept on the device, so the next
  /// [resolve] call hits the network again.
  ///
  /// Callers that hold this resolver across a sign-out/sign-in must call
  /// this on sign-out — otherwise a different signed-in user could see the
  /// previous user's company id.
  Future<void> clearCache();
}
