# RULE 9: Unit Tests — Behavior Over Implementation

## Rule ID
RULE_9

## Category
Testing - Unit Tests

## Severity Levels
- **Critical:** Tests assert on private methods, internal state, or method call counts (using mocks)
- **Major:** Tests break when refactoring without changing behavior
- **Minor:** Tests are tightly coupled to implementation details
- **Suggestion:** Focus tests on public API outputs and observable side effects

## Description

Unit tests (BLoC, Service, Repository, UseCase) assert observable behavior and outputs, not internal structure. Test *what* the code does, not *how*.

**Core Principle:** If you can refactor code while preserving behavior, tests should still pass.

## Applicability

All unit tests in `test/features/**/` for BLoCs, Services, Repositories, UseCases, and other business logic.

---

## For Coding Agents (Prescriptive)

### Core Principle

**Test the contract, not the implementation.** Focus on public APIs, return values, emitted states, and side effects at boundaries. Never test internal methods or assert that specific private functions were called.

### Decision Tree: What Should I Test?

```
What aspect of this class am I testing?

├─ Public method return value?       → Call method, assert on returned value ✅
├─ Stream/BLoC state emissions?      → Dispatch event, assert on emitted states ✅
├─ Side effects (DB/API writes)?     → Verify data written to fake boundary ✅
├─ Error handling?                   → Trigger error, assert on error output ✅
├─ Private method called?            → DON'T TEST — implementation detail ❌
└─ Method call count?                → DON'T TEST — use fakes (RULE_3), not mocks ❌
```

### Canonical Examples

**BLoC state emissions** — dispatch event, assert on emitted states:

```dart
blocTest<AuthBloc, AuthState>(
  'should emit [Loading, Authenticated] when login succeeds',
  build: () => AuthBloc(authService: authService),
  act: (bloc) => bloc.add(LoginRequested(email: 'test@example.com', password: 'password')),
  expect: () => [
    AuthLoading(),
    AuthAuthenticated(userId: '123'),
  ],
);
```

**Boundary side effects** — assert on the fake's state, not on method calls:

```dart
test('should save estimation to data source', () async {
  final fakeDataSource = FakeEstimationDataSource();
  final repository = EstimationRepositoryImpl(dataSource: fakeDataSource);
  final estimation = Estimation(id: '123', amount: 1000);

  await repository.save(estimation);

  expect(fakeDataSource.savedEstimations, contains(estimation));
});
```

**Async streams** — subscribe with `expectLater` *before* triggering emissions:

```dart
test('should emit sync statuses in order', () async {
  final service = SyncService(dataSource: FakeEstimationDataSource());

  final expectation = expectLater(
    service.syncStatus,
    emitsInOrder([SyncStatus.syncing, SyncStatus.completed]),
  );

  await service.startSync();
  await expectation;
});
```

Broadcast streams don't buffer — a listener attached after emission misses events. Single-subscription streams do buffer, but subscribing first works for both, so always set up `expectLater` before the act step.

Apply the same shape for error paths (trigger via fake, assert on returned `Left(Failure)`) and public-API tests (call the method, assert on return).

---

## For Review Agents (Detective)

### Detection Patterns

| Pattern | Grep | Severity |
|---|---|---|
| Mocks | `grep -rn "Mock<\\|verify(\\|when(" test/` | Critical |
| Private method calls | `grep -rn "\\._[a-zA-Z]" test/` | Critical |
| Private state access | `grep -rn "\\._\\(cache\\|state\\|controller\\)\\b" test/` | Major |
| Tests with no assertion | `grep -A 10 "test(" test/ \| grep -v "expect("` | Major |

### Common Violations

| ❌ Violation | ✅ Fix | Severity |
|-------------|--------|----------|
| `verify(mockRepo.save(any))` | Assert on fake boundary state instead | Critical |
| `calculator._privateMethod()` | Test public API that uses it | Critical |
| `expect(bloc._cache.length, 5)` | Assert on emitted state instead | Major |
| `when(mock.method()).thenReturn(...)` | Use fakes (RULE_3) | Critical |
| No `expect()` in test body | Add assertions on observable outputs | Major |
| Test breaks on behavior-preserving refactor | Test is coupled to implementation; rewrite against public API | Major |

### Review Questions

1. Does this test use `verify()` or `when()`? → Violation (use fakes per RULE_3).
2. Does this test access private methods/fields (`._name`)? → Violation.
3. Would this test break if we refactored without changing behavior? → Coupled to implementation.
4. Does this test assert on something a caller would observe? → If no, it's testing implementation.

---

## Summary: Suggested Fixes

1. **Remove mocks** — replace with fakes (RULE_3).
2. **Test public APIs only** — drop tests of private methods/state.
3. **Assert on outputs** — return values, emitted states, boundary effects.
4. **Make tests refactor-safe** — pass after internal refactoring.

## References

- Review Script Lines: 391-403 in `scripts/review_pr.sh`
- Related: RULE_3 (Test Double Pattern), RULE_8 (Widget Test Finders)

## Notes

**Key Insight:** Good tests specify behavior without constraining implementation. They give freedom to refactor while ensuring correctness.

**Red Flag:** If refactoring working code breaks tests without changing behavior, your tests are coupled to implementation details.
