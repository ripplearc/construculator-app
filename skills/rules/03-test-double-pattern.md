# RULE 3: Test Double Pattern

## Rule ID
RULE_3

## Category
Testing Strategy

## Severity Levels
- **Critical:** Using mocks or stubs (forbidden in this codebase)
- **Major:** Faking business logic components instead of using real implementations
- **Minor:** Test structure could be improved to test real integration
- **Suggestion:** Consider using Test Double pattern for better integration testing

## Description

Test real integration between components. Only fake external dependencies (database, network, 3rd party libraries). Never fake your own business logic.

**Core Principle:** Test Double pattern ensures tests verify real component interaction and real business logic, catching integration bugs that unit tests with mocks would miss.

## Applicability

Applies to all tests in `test/` directory, particularly unit tests for BLoCs, Services, UseCases, and Repositories.

---

## For Coding Agents (Prescriptive)

### The Test Double Pattern

**When testing Class A that depends on Class B:**

```
✅ CORRECT (Test Double Pattern):
┌─────────────────────────────────────┐
│          Test Suite                  │
│                                      │
│  ┌──────────┐      ┌──────────┐    │
│  │ Real A   │─────▶│  Real B  │    │
│  └──────────┘      └──────────┘    │
│                          │          │
│                          ▼          │
│                    ┌──────────┐    │
│                    │  Fake    │    │
│                    │ External │    │
│                    │   Dep    │    │
│                    └──────────┘    │
└─────────────────────────────────────┘

❌ WRONG (Fake Everything):
┌─────────────────────────────────────┐
│          Test Suite                  │
│                                      │
│  ┌──────────┐      ┌──────────┐    │
│  │ Real A   │─────▶│  Fake B  │    │
│  └──────────┘      └──────────┘    │
│                                      │
│  (Not testing real integration!)    │
└─────────────────────────────────────┘
```

### Decision Tree: Should I Fake This?

```
Is this dependency MY code (in this codebase)?
  ├─ YES → Use REAL implementation
  │        └─ Examples: BLoC → Real UseCase, UseCase → Real Service
  │
  └─ NO → Is it an external dependency?
         └─ YES → Use FAKE implementation
                  └─ Examples: Supabase, Database, File System, HTTP client
```

### What to Fake (External Boundaries Only)

✅ **Always Fake:**
- Database (Supabase, local DB)
- Network (HTTP clients, API calls)
- File system
- Device sensors
- Time/Clock
- Random generators
- 3rd party SDKs

❌ **Never Fake:**
- Your UseCases
- Your Services
- Your Repositories (the interface)
- Your BLoCs
- Your domain logic
- Your mappers/formatters

### How to Write Tests

#### ✅ Correct: Chain real components, fake only external dependencies

```dart
void main() {
  late AuthBloc bloc;
  late FakeAuthDataSource fakeDataSource;

  setUp(() {
    fakeDataSource = FakeAuthDataSource(); // Fake external (Supabase)
    final authRepository = AuthRepositoryImpl(remoteDataSource: fakeDataSource); // Real
    final authService = AuthenticationService(repository: authRepository); // Real
    bloc = AuthBloc(authService: authService); // Real
  });

  test('should emit authenticated state when login succeeds', () {
    fakeDataSource.mockLoginSuccess(userId: '123');
    bloc.add(LoginRequested(email: 'test@example.com', password: 'pass123'));
    expect(bloc.stream, emitsInOrder([AuthLoading(), AuthAuthenticated(userId: '123')]));
  });
}
```

#### ❌ Wrong: Mocking internal business logic

```dart
void main() {
  late MockAuthService mockAuthService; // ❌ Don't mock your own code

  test('should emit authenticated state', () {
    when(mockAuthService.login(any, any)).thenReturn(...); // ❌ Doesn't test real logic
    // Test passes even if AuthService implementation is broken!
  });
}
```

### Implementing Fakes

**Create fakes for external dependencies:**

```dart
// Fake Supabase DataSource
class FakeAuthDataSource implements RemoteAuthDataSource {
  User? _mockUser;
  Exception? _mockException;

  void mockLoginSuccess({required String userId}) {
    _mockUser = User(id: userId);
    _mockException = null;
  }

  void mockLoginFailure(Exception exception) {
    _mockUser = null;
    _mockException = exception;
  }

  @override
  Future<Either<Failure, User>> login(String email, String password) async {
    if (_mockException != null) {
      return Left(ServerFailure(message: _mockException.toString()));
    }
    if (_mockUser != null) {
      return Right(_mockUser!);
    }
    return Left(ServerFailure(message: 'Unknown error'));
  }
}
```

---

## For Review Agents (Detective)

### Detection Patterns

**Check for:**
1. **Forbidden mocks/stubs:** `Mock<`, `when(`, `verify(`, `@GenerateMocks` (Critical)
2. **Faking business logic:** Mock UseCases, Services, Repositories, BLoCs (Major)
3. **Missing integration:** Tests only exercising one layer in isolation (Major)

### Common Violations

| ❌ Violation | ✅ Fix | Severity |
|-------------|--------|----------|
| `MockAuthService` in BLoC test | Use real `AuthService` + fake `AuthDataSource` | Major |
| `when(useCase.execute()).thenReturn(...)` | Use real `UseCase` + fake external dependencies | Major |
| `verify(repository.save(any))` | Assert on observable outputs, not method calls | Major |
| `MockEstimationRepository` | Use real `EstimationRepositoryImpl` + fake `DataSource` | Major |
| Using `mockito` package | Use hand-written fakes for external dependencies | Critical |

---

## References
- [Test Double Pattern Gist](https://gist.github.com/ripplearcgit/89687b7414f62a8c042b16b52e9ceb0b)
- Related: RULE_8 (Widget Test Finders), RULE_9 (Unit Test Behavior)
