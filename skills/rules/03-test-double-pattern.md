# RULE 3: Test Double Pattern

## Name
Test Double Pattern

## Category
Testing Strategy

## Severity Levels
- **Critical:** Using mocks or stubs (forbidden in this codebase)
- **Major:** Faking business logic components instead of using real implementations
- **Minor:** Test structure could exercise more real integration
- **Suggestion:** Consider Test Double pattern for better integration testing

## Description

Test real integration between components. Only fake external dependencies (database, network, 3rd-party libraries). Never fake your own business logic.

**Core Principle:** Test Double pattern ensures tests verify real component interaction and real business logic, catching integration bugs that mocked unit tests would miss.

## Applicability

All tests in `test/`, particularly unit tests for BLoCs, Services, UseCases, and Repositories.

---

## For Coding Agents (Prescriptive)

### The Pattern

When testing class A that depends on class B:

| Class under test | Inner project dependencies | External dependencies |
|---|---|---|
| BLoC / UseCase / Service / Repository | **Real** implementation | **Fake** (Supabase, HTTP, Clock, …) |

The chain is wired up with real implementations; only the outermost boundary (the SDK / network / DB / clock) is replaced with a hand-written fake.

### Decision Tree

```
Is this dependency MY code (in this codebase)?
  ├─ YES
  │   ├─ Same feature?             → Use REAL implementation
  │   │    (BLoC → real UseCase → real Service → real RepositoryImpl → real DataSource)
  │   │
  │   └─ From another library/feature? → Use FAKE repository for isolation
  │        (prevents cascading test failures when the library changes)
  │
  └─ NO  → External dependency
           → Use FAKE wrapper  (FakeSupabaseWrapper, FakeClock, HTTP fake, …)
```

### What to Fake — and What Not to Fake

✅ **Always fake** — external boundaries via wrappers: `FakeSupabaseWrapper`, HTTP fakes, `FakeClock`, random generators, 3rd-party SDKs.

✅ **Fake repository when** it belongs to another library/feature (e.g., `FakeProjectRepository` in estimation tests) — prevents coupling across features.

❌ **Never fake** — your own same-feature code: UseCases, Services, RepositoryImpls, DataSources, BLoCs, domain logic, mappers/formatters.

### Canonical Integration Test

The project fakes at the **wrapper level**: `FakeSupabaseWrapper` replaces all Supabase I/O while the entire real chain above it (DataSource → RepositoryImpl → UseCase → BLoC) runs as-is. Wire the module with the fake wrapper and get real objects from DI:

```dart
void main() {
  late FakeSupabaseWrapper fakeSupabase;
  late OtpVerificationBloc bloc;

  setUpAll(() {
    fakeSupabase = FakeSupabaseWrapper(clock: FakeClockImpl()); // ✅ fake at I/O boundary
    Modular.init(AuthTestModule(AppBootstrap(supabaseWrapper: fakeSupabase)));
    bloc = Modular.get<OtpVerificationBloc>();                  // ✅ real chain from DI
  });

  tearDown(() {
    fakeSupabase.reset();
    Modular.destroy();
  });

  blocTest<OtpVerificationBloc, OtpVerificationState>(
    'emits [Loading, Success] when OTP is correct',
    build: () {
      fakeSupabase.shouldThrowOnVerifyOtp = false; // ✅ configure via fake wrapper
      return bloc;
    },
    act: (bloc) => bloc.add(OtpVerificationSubmitted(contact: 'test@example.com', otp: '123456')),
    expect: () => [OtpVerificationLoading(), OtpVerificationSuccess(email: 'test@example.com')],
  );
}
```

### Implementing Fakes

**At the I/O boundary** — the project maintains `FakeSupabaseWrapper` as the single re-usable fake for all Supabase operations. Tests inject it via `AppBootstrap`. See `docs/Testing/Fakes.md` for full usage.

**For library repository dependencies** — when your feature depends on a repository from *another* library/feature, create a fake repository implementing the interface. Expose setup methods and call counters; keep the implementation minimal:

```dart
class FakeProjectRepository implements ProjectRepository {
  Project? _project;
  int getProjectByIdCallCount = 0;

  void setProject(Project project) => _project = project;
  void reset() { _project = null; getProjectByIdCallCount = 0; }

  @override
  Future<Either<Failure, Project>> getProjectById(String id) async {
    getProjectByIdCallCount++;
    return _project != null ? Right(_project!) : Left(NotFoundFailure());
  }
}
```

See `docs/Testing/Fakes.md` for the full decision matrix and `FakeSupabaseWrapper` API.

---

## For Review Agents (Detective)

### Detection

1. Forbidden tooling: `Mock<…>`, `when(…)`, `verify(…)`, `@GenerateMocks`, imports of `mockito`. **Critical.**
2. Faking business logic: `MockAuthService`, `MockUseCase`, `MockRepository`, `MockBloc`. **Major.**
3. Test exercises a single layer in isolation while the rest is mocked. **Major.**

### Common Violations

| ❌ Violation | ✅ Fix | Severity |
|---|---|---|
| `MockAuthService` in a BLoC test | Use real `AuthService` wired via `FakeSupabaseWrapper` | Major |
| `when(useCase.execute()).thenReturn(...)` | Use real `UseCase` + `FakeSupabaseWrapper` at I/O boundary | Major |
| `verify(repository.save(any))` | Assert on observable outputs, not method calls | Major |
| `MockEstimationRepository` | Use real `EstimationRepositoryImpl` + `FakeSupabaseWrapper`; or `FakeEstimationRepository` only if it's a cross-library dependency | Major |
| Using `mockito` package | Use `FakeSupabaseWrapper` or hand-written fake repositories | Critical |

---

## References

- [Test Double Pattern Gist](https://gist.github.com/ripplearcgit/89687b7414f62a8c042b16b52e9ceb0b)
- Related: Widget Test Finders, Unit Test Behavior
- Existing fakes: `test/utils/fake_app_bootstrap_factory.dart`, `test/utils/a11y/` (helpers).
