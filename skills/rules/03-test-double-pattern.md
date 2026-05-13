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

#### Example 1: Testing a BLoC

```dart
// ✅ CORRECT: Real UseCase + Fake DataSource
void main() {
  late AuthBloc bloc;
  late AuthenticationService authService;
  late FakeAuthDataSource fakeDataSource; // Fake external dependency

  setUp(() {
    // Fake the external dependency (Supabase)
    fakeDataSource = FakeAuthDataSource();

    // Real repository implementation
    final authRepository = AuthRepositoryImpl(
      remoteDataSource: fakeDataSource,  // Inject fake
    );

    // Real service
    authService = AuthenticationService(
      repository: authRepository,  // Inject real
    );

    // Real BLoC
    bloc = AuthBloc(
      authService: authService,  // Inject real
    );
  });

  test('should emit authenticated state when login succeeds', () {
    // Arrange: Configure fake to return success
    fakeDataSource.mockLoginSuccess(userId: '123');

    // Act: Use real BLoC
    bloc.add(LoginRequested(email: 'test@example.com', password: 'pass123'));

    // Assert: Verify real state emission
    expect(
      bloc.stream,
      emitsInOrder([
        AuthLoading(),
        AuthAuthenticated(userId: '123'),
      ]),
    );
  });
}

// ❌ WRONG: Faking the UseCase/Service
void main() {
  late AuthBloc bloc;
  late MockAuthService mockAuthService;  // ❌ Don't mock your own code

  setUp(() {
    mockAuthService = MockAuthService();
    bloc = AuthBloc(authService: mockAuthService);
  });

  test('should emit authenticated state when login succeeds', () {
    // ❌ This doesn't test real business logic
    when(mockAuthService.login(any, any))
        .thenAnswer((_) async => Right(User(id: '123')));

    bloc.add(LoginRequested(email: 'test@example.com', password: 'pass123'));

    // This test passes even if AuthService implementation is broken!
    expect(bloc.stream, emitsInOrder([...]));
  });
}
```

#### Example 2: Testing a UseCase

```dart
// ✅ CORRECT: Real Repository + Fake DataSource
void main() {
  late GetEstimationsUseCase useCase;
  late EstimationRepository repository;
  late FakeEstimationDataSource fakeDataSource;

  setUp(() {
    fakeDataSource = FakeEstimationDataSource();

    repository = EstimationRepositoryImpl(
      remoteDataSource: fakeDataSource,  // Fake external
    );

    useCase = GetEstimationsUseCase(
      repository: repository,  // Real repository
    );
  });

  test('should return estimations when repository succeeds', () async {
    // Arrange
    fakeDataSource.mockEstimations([
      EstimationDto(id: '1', amount: 100),
      EstimationDto(id: '2', amount: 200),
    ]);

    // Act: Test real UseCase → Real Repository → Fake DataSource
    final result = await useCase.execute('project-123');

    // Assert
    expect(result.isRight(), true);
    expect(result.getOrElse(() => []).length, 2);
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

**Pattern 1: Forbidden Mocks/Stubs**

```bash
# Search for mockito usage in tests
grep -rn "Mock<" test/
grep -rn "when(" test/
grep -rn "verify(" test/
grep -rn "@GenerateMocks" test/
```

**Severity:** Critical if found

**Pattern 2: Faking Business Logic**

Look for test files that fake:
- UseCases (e.g., `MockGetUserUseCase`)
- Services (e.g., `MockAuthenticationService`)
- Repositories interfaces (e.g., `MockEstimationRepository`)
- BLoCs (e.g., `MockAuthBloc`)

**Severity:** Major violation

**Pattern 3: Missing Real Integration**

Check if tests:
- Only test one layer in isolation
- Don't exercise real business logic flow
- Use stubs/mocks for internal components

### Common Violations

| ❌ Violation | ✅ Fix | Severity |
|-------------|--------|----------|
| `MockAuthService` in BLoC test | Use real `AuthService` + fake `AuthDataSource` | Major |
| `when(useCase.execute()).thenReturn(...)` | Use real `UseCase` + fake external dependencies | Major |
| `verify(repository.save(any))` | Assert on observable outputs, not method calls | Major |
| `MockEstimationRepository` | Use real `EstimationRepositoryImpl` + fake `DataSource` | Major |
| Using `mockito` package | Use hand-written fakes for external dependencies | Critical |

### Review Questions

When reviewing tests, ask:

1. **Are any internal components mocked/stubbed?**
   - If YES → Violation (should use real implementations)

2. **Does the test exercise real business logic?**
   - If NO → Violation (test is too isolated)

3. **What is being faked?**
   - If it's YOUR code → Violation
   - If it's external dependency → Correct ✅

4. **Does test setup chain real implementations?**
   - BLoC → Real UseCase → Real Repository → Fake DataSource ✅

---

## Key Benefits

**Why Test Double Pattern is Better:**

1. **Catches Integration Bugs:** Tests verify components work together correctly
2. **Refactor-Safe:** Internal refactors don't break tests if behavior unchanged
3. **Documents Real Flow:** Test setup shows how components actually integrate
4. **Realistic Testing:** Exercises the same code paths production uses
5. **Prevents False Confidence:** Can't pass tests by stubbing everything

**Example of Bug Caught by Test Double:**

```dart
// Bug: UseCase passes wrong parameter to Repository
class GetEstimationsUseCase {
  Future<Either<Failure, List<Estimation>>> execute(String projectId) {
    // 🐛 Bug: passing empty string instead of projectId
    return repository.getEstimations('');
  }
}

// ❌ Mock-based test WOULD NOT CATCH THIS:
when(mockRepository.getEstimations(any))  // Accepts any argument
    .thenAnswer((_) => Right([...]));

// ✅ Test Double WOULD CATCH THIS:
fakeDataSource.expectProjectId('project-123');  // Fake validates arguments
final result = await useCase.execute('project-123');
// Test fails because UseCase passed '' instead of 'project-123'
```

---

## References
- [Test Double Pattern Gist](https://gist.github.com/ripplearcgit/89687b7414f62a8c042b16b52e9ceb0b)
- Related: RULE_8 (Widget Test Finders), RULE_9 (Unit Test Behavior)

## Notes

**Forbidden Tools:**
- 🚫 `mockito` package
- 🚫 `mocktail` package
- 🚫 Any auto-mocking framework

**Allowed Tools:**
- ✅ Hand-written Fakes for external dependencies
- ✅ In-memory implementations for DataSources
- ✅ Test doubles for system/platform services
