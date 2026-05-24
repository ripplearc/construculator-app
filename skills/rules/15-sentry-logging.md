# RULE 15: Judicious Sentry Error Reporting

## Rule ID
RULE_15

## Category
Error Handling & Monitoring

## Severity Levels
- **Critical:** Expected errors (validation, auth failures) logged to Sentry, wasting quota
- **Major:** Duplicate error logging across multiple layers
- **Minor:** Using `error()` when `warning()` or `info()` would suffice
- **Suggestion:** Consider using breadcrumbs instead of full error events

## Description

`AppLogger.error()` and `AppLogger.omg()` send events to Sentry and consume quota. Reserve them for genuinely unexpected failures only. Expected errors, validation failures, and normal business flow errors should use lower severity levels.

**Core Principle:** Sentry is for bugs and unexpected system failures, not expected business logic errors.

## Applicability

Applies to all code that uses `AppLogger` in `lib/` directory, particularly in:
- Data layer: `lib/features/**/data/`
- Repository implementations
- DataSources
- Error handling boundaries

---

## For Coding Agents (Prescriptive)

### Core Principle

**Log errors at ONE layer only.** Typically at the Repository or DataSource where the error originates. Upper layers (BLoC, UseCase) handle `Either<Failure, T>` without logging.

### Decision Tree: Which Log Level?

```
Is this error expected in normal operation?

├─ YES (Expected Business Error)
│  ├─ User input validation failed?
│  │  └─ Use: debug() or warning()  // ✅ Not Sentry
│  │
│  ├─ Expected API error (404, 409 conflict)?
│  │  └─ Use: warning() or info()  // ✅ Breadcrumb only
│  │
│  └─ Duplicate entry (unique constraint)?
│     └─ Use: warning()  // ✅ Breadcrumb only
│
└─ NO (Unexpected System Failure)
   ├─ Parsing failed unexpectedly?
   │  └─ Use: error()  // ✅ Sentry event
   │
   ├─ Auth token invalid/expired?
   │  └─ Use: error()  // ✅ Sentry event
   │
   ├─ Critical storage failure?
   │  └─ Use: omg()  // ✅ Critical Sentry event
   │
   └─ Invariant violation?
      └─ Use: omg()  // ✅ Critical Sentry event
```

### AppLogger Levels

| Level | Sentry Impact | When to Use | Example |
|-------|---------------|-------------|---------|
| `debug()` | None | Development debugging | `AppLogger.debug('Fetching user data')` |
| `info()` | Breadcrumb only | Normal operations | `AppLogger.info('User logged in successfully')` |
| `warning()` | Breadcrumb only | Expected errors | `AppLogger.warning('Invalid email format')` |
| `error()` | **Sentry event** ⚠️ | Unexpected failures | `AppLogger.error('Failed to parse response', error)` |
| `omg()` | **Critical Sentry event** 🚨 | Critical failures | `AppLogger.omg('Database corruption detected', error)` |

### When to Use error() / omg()

#### ✅ Genuinely Unexpected Failures

```dart
// ✅ Good: Unexpected parsing failure
Future<Either<Failure, User>> getUser(String id) async {
  try {
    final json = await _api.fetchUser(id);
    return Right(User.fromJson(json));
  } on FormatException catch (e, stack) {
    // ✅ Unexpected: API should return valid JSON
    AppLogger.error('Failed to parse user JSON', e, stack);
    return Left(ParsingFailure(message: 'Invalid user data'));
  }
}
```

```dart
// ✅ Good: Critical storage failure
Future<void> saveAuthToken(String token) async {
  try {
    await _secureStorage.write(key: 'auth_token', value: token);
  } catch (e, stack) {
    // ✅ Critical: Can't save auth token = can't use app
    AppLogger.omg('Failed to save auth token to secure storage', e, stack);
    rethrow;
  }
}
```

```dart
// ✅ Good: Invariant violation
if (userId == null && isAuthenticated) {
  // ✅ Should never happen: authenticated but no userId
  AppLogger.omg('Invariant violated: authenticated with null userId');
  throw StateError('Invalid authentication state');
}
```

#### ❌ Expected Business Errors

```dart
// ❌ Bad: Expected validation error
Future<Either<Failure, void>> createAccount(String email) async {
  if (!_isValidEmail(email)) {
    // ❌ Don't send to Sentry: expected validation failure
    AppLogger.error('Invalid email format: $email');  // ❌
    return Left(ValidationFailure(message: 'Invalid email'));
  }
}

// ✅ Good: Use warning for expected errors
Future<Either<Failure, void>> createAccount(String email) async {
  if (!_isValidEmail(email)) {
    // ✅ Breadcrumb only, no Sentry event
    AppLogger.warning('Validation failed: invalid email format');
    return Left(ValidationFailure(message: 'Invalid email'));
  }
}
```

```dart
// ❌ Bad: Expected Supabase error
Future<Either<Failure, User>> login(String email, String password) async {
  try {
    final response = await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
    return Right(User.from(response.user));
  } on AuthException catch (e, stack) {
    if (e.message.contains('Invalid login credentials')) {
      // ❌ Expected: wrong password
      AppLogger.error('Login failed: invalid credentials', e, stack);  // ❌
      return Left(AuthFailure(message: 'Invalid credentials'));
    }
  }
}

// ✅ Good: Distinguish expected from unexpected
Future<Either<Failure, User>> login(String email, String password) async {
  try {
    final response = await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
    return Right(User.from(response.user));
  } on AuthException catch (e, stack) {
    if (e.message.contains('Invalid login credentials')) {
      // ✅ Expected error: just a breadcrumb
      AppLogger.warning('Login attempt with invalid credentials');
      return Left(AuthFailure(message: 'Invalid credentials'));
    } else {
      // ✅ Unexpected auth error: send to Sentry
      AppLogger.error('Unexpected auth error during login', e, stack);
      return Left(AuthFailure(message: 'Login failed'));
    }
  }
}
```

### No Duplicate Logging

**Log once, at the boundary where the error occurs:**

```dart
// ❌ Bad: Logging at multiple layers
class RemoteUserDataSource {
  Future<UserDto> fetchUser(String id) async {
    try {
      return await _api.get('/users/$id');
    } catch (e, stack) {
      AppLogger.error('DataSource: Failed to fetch user', e, stack);  // ❌ Log #1
      rethrow;
    }
  }
}

class UserRepositoryImpl {
  Future<Either<Failure, User>> getUser(String id) async {
    try {
      final dto = await _dataSource.fetchUser(id);
      return Right(User.fromDto(dto));
    } catch (e, stack) {
      AppLogger.error('Repository: Failed to get user', e, stack);  // ❌ Log #2 (duplicate!)
      return Left(NetworkFailure(message: 'Failed to fetch user'));
    }
  }
}

// ✅ Good: Log once at the boundary
class RemoteUserDataSource {
  Future<UserDto> fetchUser(String id) async {
    try {
      return await _api.get('/users/$id);
    } catch (e, stack) {
      // ✅ Log once, at the source
      AppLogger.error('Failed to fetch user from API', e, stack);
      rethrow;
    }
  }
}

class UserRepositoryImpl {
  Future<Either<Failure, User>> getUser(String id) async {
    try {
      final dto = await _dataSource.fetchUser(id);
      return Right(User.fromDto(dto));
    } catch (e, stack) {
      // ✅ No logging: error already logged in DataSource
      return Left(NetworkFailure(message: 'Failed to fetch user'));
    }
  }
}
```

### Where to Log

**Recommended logging location:**

```
DataSource (boundary)
  └─ ✅ Log unexpected errors here
       └─ Throw/return error

Repository (transforms errors)
  └─ ❌ Don't log again
       └─ Return Either<Failure, T>

UseCase (business logic)
  └─ ❌ Don't log
       └─ Handle Either<Failure, T>

BLoC (state management)
  └─ ❌ Don't log
       └─ Emit error state
```

**Example:**

```dart
// DataSource: Log at boundary
class RemoteEstimationDataSource {
  Future<List<EstimationDto>> fetch(String projectId) async {
    try {
      final response = await _supabase
          .from('estimations')
          .select()
          .eq('project_id', projectId);

      return response.map((json) => EstimationDto.fromJson(json)).toList();
    } on PostgrestException catch (e, stack) {
      // ✅ Log unexpected database error
      AppLogger.error('Supabase query failed for project $projectId', e, stack);
      rethrow;
    }
  }
}

// Repository: Don't log, transform error
class EstimationRepositoryImpl {
  Future<Either<Failure, List<Estimation>>> getEstimations(String projectId) async {
    try {
      final dtos = await _dataSource.fetch(projectId);
      return Right(dtos.map((dto) => Estimation.fromDto(dto)).toList());
    } catch (e) {
      // ✅ Don't log again, just transform to domain Failure
      return Left(DatabaseFailure(message: 'Failed to load estimations'));
    }
  }
}

// UseCase: Don't log, pass through
class GetEstimationsUseCase {
  Future<Either<Failure, List<Estimation>>> execute(String projectId) {
    // ✅ Don't log, just delegate
    return repository.getEstimations(projectId);
  }
}

// BLoC: Don't log, emit state
class EstimationBloc {
  Future<void> _onLoad(LoadEstimations event, Emitter emit) async {
    final result = await useCase.execute(event.projectId);

    result.fold(
      (failure) {
        // ✅ Don't log, emit error state
        emit(EstimationError(message: failure.message));
      },
      (estimations) => emit(EstimationsLoaded(estimations)),
    );
  }
}
```

### Common Scenarios

#### Scenario 1: Supabase Errors

```dart
// Distinguish expected from unexpected
try {
  await _supabase.from('users').insert(userData);
} on PostgrestException catch (e, stack) {
  if (e.code == '23505') {  // Unique constraint violation
    // ✅ Expected: duplicate entry
    AppLogger.warning('Duplicate user entry attempt: ${userData.email}');
    return Left(DuplicateFailure(message: 'User already exists'));
  } else {
    // ✅ Unexpected: other database error
    AppLogger.error('Unexpected database error', e, stack);
    return Left(DatabaseFailure(message: 'Failed to create user'));
  }
}
```

#### Scenario 2: Network Errors

```dart
try {
  final response = await _http.get(url);
  return response.data;
} on DioError catch (e, stack) {
  if (e.response?.statusCode == 404) {
    // ✅ Expected: resource not found
    AppLogger.info('Resource not found: $url');
    return Left(NotFoundFailure());
  } else if (e.response?.statusCode == 401) {
    // ✅ Important: auth token expired
    AppLogger.error('Auth token expired or invalid', e, stack);
    return Left(AuthFailure(message: 'Unauthorized'));
  } else {
    // ✅ Unexpected: other network error
    AppLogger.error('Network request failed: $url', e, stack);
    return Left(NetworkFailure());
  }
}
```

#### Scenario 3: Validation

```dart
// ❌ Bad: Logging validation errors
Future<Either<Failure, void>> updateEmail(String email) async {
  if (!_isValidEmail(email)) {
    AppLogger.error('Invalid email: $email');  // ❌ Wastes Sentry quota
    return Left(ValidationFailure());
  }
}

// ✅ Good: Validation errors are debug-level
Future<Either<Failure, void>> updateEmail(String email) async {
  if (!_isValidEmail(email)) {
    AppLogger.debug('Email validation failed: $email');  // ✅ Debug only
    return Left(ValidationFailure());
  }
}
```

---

## For Review Agents (Detective)

### Detection Patterns

**Pattern 1: Expected Errors Logged with error()**

Look for validation, 404, duplicate errors logged with `error()`:

```bash
grep -rn "AppLogger.error\|AppLogger.omg" lib/
```

Check context:
- Is it validation? → Should be `warning()` or `debug()`
- Is it 404/409? → Should be `info()` or `warning()`
- Is it duplicate entry? → Should be `warning()`

**Pattern 2: Duplicate Logging**

Same error logged at DataSource AND Repository:

```bash
# Find files with both error logs and rethrow/return Left
grep -A 5 "AppLogger.error" lib/ | grep -E "(rethrow|return Left)"
```

**Severity:** Major

**Pattern 3: Logging in Upper Layers**

`AppLogger.error()` in BLoC or UseCase (should only be in DataSource/Repository):

```bash
grep -rn "AppLogger.error" lib/features/**/domain/
grep -rn "AppLogger.error" lib/features/**/presentation/
```

**Severity:** Major

### Common Violations

| ❌ Violation | ✅ Fix | Severity |
|-------------|--------|----------|
| `error('Invalid email')` | Use `debug()` or `warning()` | Critical |
| `error('404 not found')` | Use `info()` or `warning()` | Critical |
| `error('Duplicate entry')` | Use `warning()` | Critical |
| Error logged in DataSource AND Repository | Remove duplicate, log once | Major |
| `error()` in BLoC/UseCase | Move to DataSource/Repository | Major |
| `error()` without checking if expected | Add conditional logic | Major |

### Review Questions

1. **Is this error expected in normal operation?**
   - If YES → Should not use `error()` or `omg()`

2. **Is the error logged at multiple layers?**
   - If YES → Remove duplicate logging

3. **Is this a validation or user input error?**
   - If YES → Should use `debug()` or `warning()`

4. **Does the error come from a known Supabase/API error code?**
   - Check if it's documented/expected → Use `warning()`

---

## Summary: Suggested Fixes

1. **Reserve `error()` for unexpected failures:** Parsing errors, system failures, invariant violations
2. **Use `warning()` for expected errors:** Validation failures, 404s, duplicate entries, invalid credentials
3. **Log once at the boundary:** Typically DataSource, not Repository/UseCase/BLoC
4. **Distinguish expected from unexpected:** Check error codes/types before logging
5. **Use breadcrumbs for context:** `info()` and `warning()` create breadcrumbs without consuming quota

## References

- [Sentry Best Practices](https://docs.sentry.io/platforms/flutter/best-practices/)
- [Sentry Pricing](https://sentry.io/pricing/) - Understand quota costs
- Review Script Lines: 519-539 in `scripts/review_pr.sh`

## Notes

**Quota Awareness:** Each `error()` or `omg()` call creates a Sentry event. On a free/low-tier plan, excessive error logging can exhaust quota quickly.

**Breadcrumbs:** `debug()`, `info()`, and `warning()` create breadcrumbs that are attached to error events but don't consume quota on their own. They provide context when real errors occur.

**Best Practice:** Use `warning()` liberally for expected errors (free breadcrumbs), but be very selective with `error()` and `omg()` (quota cost).
