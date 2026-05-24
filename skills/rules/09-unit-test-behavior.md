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

Unit tests (BLoC, Service, Repository, UseCase) should assert observable behavior and outputs, not internal structure or implementation details. Tests should verify *what* the code does, not *how* it does it.

**Core Principle:** If you can refactor code while preserving behavior, tests should still pass.

## Applicability

Applies to all unit tests in `test/features/**/` for BLoCs, Services, Repositories, UseCases, and other business logic components.

---

## For Coding Agents (Prescriptive)

### Core Principle

**Test the contract, not the implementation.** Focus on public APIs, return values, emitted states, and side effects at boundaries. Never test internal methods or assert that specific private functions were called.

### Decision Tree: What Should I Test?

```
What aspect of this class am I testing?

├─ Public method return value?
│  └─ Test: Call method, assert on returned value ✅
│
├─ Stream/BLoC state emissions?
│  └─ Test: Dispatch event, assert on emitted states ✅
│
├─ Side effects (DB writes, API calls)?
│  └─ Test: Verify data written to fake boundary ✅
│
├─ Error handling?
│  └─ Test: Trigger error condition, assert on error output ✅
│
├─ Private method called?
│  └─ DON'T TEST: Internal implementation detail ❌
│
└─ Method call count?
   └─ DON'T TEST: Use test doubles (RULE_3), not mocks ❌
```

### What to Test (Observable Behavior)

#### ✅ Public API Return Values

```dart
// Good: Test observable output
test('should return estimation when repository succeeds', () async {
  // Arrange
  fakeDataSource.mockEstimation(
    EstimationDto(id: '123', amount: 1000),
  );

  // Act
  final useCase = GetEstimationUseCase(repository: repository);
  final result = await useCase.execute('123');

  // Assert on observable output
  expect(result.isRight(), true);
  final estimation = result.getOrElse(() => throw Exception());
  expect(estimation.id, '123');
  expect(estimation.amount, 1000);
});
```

#### ✅ State Emissions (BLoC)

```dart
// Good: Test state transitions
blocTest<AuthBloc, AuthState>(
  'should emit [Loading, Authenticated] when login succeeds',
  build: () => AuthBloc(authService: authService),
  act: (bloc) => bloc.add(LoginRequested(
    email: 'test@example.com',
    password: 'password',
  )),
  expect: () => [
    AuthLoading(),  // ✅ Observable state
    AuthAuthenticated(userId: '123'),  // ✅ Observable state
  ],
);
```

#### ✅ Side Effects at Boundaries

```dart
// Good: Verify data written to boundary
test('should save estimation to data source', () async {
  // Arrange
  final estimation = Estimation(id: '123', amount: 1000);
  final fakeDataSource = FakeEstimationDataSource();

  // Act
  final repository = EstimationRepositoryImpl(
    dataSource: fakeDataSource,
  );
  await repository.save(estimation);

  // Assert on boundary side effect
  expect(fakeDataSource.savedEstimations, contains(estimation));  // ✅
});
```

#### ✅ Error Handling

```dart
// Good: Test error propagation
test('should return Failure when network error occurs', () async {
  // Arrange
  fakeDataSource.mockNetworkError();

  // Act
  final result = await useCase.execute('123');

  // Assert on error output
  expect(result.isLeft(), true);
  final failure = result.fold((f) => f, (_) => throw Exception());
  expect(failure, isA<NetworkFailure>());  // ✅ Observable error type
});
```

### What NOT to Test (Implementation Details)

#### ❌ Private Methods

```dart
// Bad: Testing private implementation
class EstimationCalculator {
  double calculateTotal(List<Item> items) {
    return items.fold(0.0, (sum, item) => sum + _itemCost(item));
  }

  double _itemCost(Item item) {  // Private helper
    return item.price * item.quantity;
  }
}

// ❌ DON'T DO THIS:
test('_itemCost should multiply price by quantity', () {
  final calculator = EstimationCalculator();
  final item = Item(price: 10.0, quantity: 3);

  // ❌ Trying to test private method
  final cost = calculator._itemCost(item);  // Shouldn't access private!

  expect(cost, 30.0);
});

// ✅ DO THIS INSTEAD:
test('calculateTotal should sum all item costs', () {
  final calculator = EstimationCalculator();
  final items = [
    Item(price: 10.0, quantity: 3),  // 30
    Item(price: 5.0, quantity: 2),   // 10
  ];

  // ✅ Test public API
  final total = calculator.calculateTotal(items);

  expect(total, 40.0);  // Tests _itemCost indirectly
});
```

#### ❌ Method Call Verification (Mocks)

```dart
// ❌ BAD: Using mocks to verify calls
test('should call repository.save()', () async {
  final mockRepository = MockEstimationRepository();  // ❌ Mock

  when(mockRepository.save(any))
      .thenAnswer((_) async => Right(unit));

  final useCase = SaveEstimationUseCase(repository: mockRepository);
  await useCase.execute(estimation);

  // ❌ Verifying implementation detail
  verify(mockRepository.save(estimation)).called(1);
});

// ✅ GOOD: Use test doubles, assert on boundary
test('should save estimation', () async {
  final fakeDataSource = FakeEstimationDataSource();  // ✅ Fake
  final repository = EstimationRepositoryImpl(
    dataSource: fakeDataSource,
  );

  final useCase = SaveEstimationUseCase(repository: repository);
  await useCase.execute(estimation);

  // ✅ Assert on observable effect
  expect(fakeDataSource.savedEstimations, contains(estimation));
});
```

#### ❌ Internal State

```dart
// Bad: Testing private state
class EstimationBloc {
  final List<Estimation> _cache = [];  // Private state

  void loadEstimations() {
    // Populates _cache internally
  }
}

// ❌ DON'T DO THIS:
test('_cache should contain estimations after load', () {
  final bloc = EstimationBloc();
  bloc.loadEstimations();

  // ❌ Accessing private state
  expect(bloc._cache.length, 5);  // Shouldn't access private!
});

// ✅ DO THIS INSTEAD:
blocTest<EstimationBloc, EstimationState>(
  'should emit EstimationsLoaded after load',
  build: () => EstimationBloc(repository: repository),
  act: (bloc) => bloc.add(LoadEstimations()),
  expect: () => [
    EstimationLoading(),
    EstimationsLoaded(estimations: [...]),  // ✅ Observable state
  ],
);
```

### Testing Strategies

#### Strategy 1: Test Public Interface

```dart
// Example: Service with complex internal logic
class ValidationService {
  bool isValidEmail(String email) {
    return _hasAtSymbol(email) &&
           _hasValidDomain(email) &&
           _hasValidLocalPart(email);
  }

  // Private helpers (implementation details)
  bool _hasAtSymbol(String email) => email.contains('@');
  bool _hasValidDomain(String email) { /* ... */ }
  bool _hasValidLocalPart(String email) { /* ... */ }
}

// ✅ Test only public method
test('isValidEmail should return true for valid email', () {
  final service = ValidationService();

  expect(service.isValidEmail('test@example.com'), true);  // ✅
  expect(service.isValidEmail('invalid.email'), false);  // ✅
  expect(service.isValidEmail('no-domain@'), false);  // ✅
});

// Don't test _hasAtSymbol, _hasValidDomain, etc. directly ❌
// They're tested indirectly through the public API ✅
```

#### Strategy 2: Test State Transitions

```dart
// BLoC: Test observable state changes
blocTest<EstimationBloc, EstimationState>(
  'should transition from Empty to Loaded to Updated',
  build: () => EstimationBloc(repository: repository),
  act: (bloc) {
    bloc.add(LoadEstimations('project-1'));
    // Wait for load to complete in real test
    bloc.add(UpdateEstimation(estimation));
  },
  expect: () => [
    EstimationLoading(),
    EstimationsLoaded(estimations: initialList),
    EstimationsLoaded(estimations: updatedList),  // ✅ Updated state
  ],
);
```

#### Strategy 3: Test Boundary Interactions

```dart
// Repository: Test data written to/read from data source
test('should fetch from data source and map to domain', () async {
  // Arrange
  fakeDataSource.mockDtos([
    EstimationDto(id: '1', amountCents: 100000),
  ]);

  final repository = EstimationRepositoryImpl(
    dataSource: fakeDataSource,
  );

  // Act
  final result = await repository.getEstimations('project-1');

  // Assert on domain model (observable output)
  expect(result.isRight(), true);
  final estimations = result.getOrElse(() => []);
  expect(estimations.length, 1);
  expect(estimations.first.amount, 1000.0);  // ✅ DTO → Domain mapping tested
});
```

### Common Patterns

#### ✅ Testing Error Paths

```dart
test('should return Failure when validation fails', () async {
  // Arrange: Create invalid input
  final invalidEmail = 'not-an-email';

  // Act
  final result = await useCase.execute(invalidEmail);

  // Assert on error result
  expect(result.isLeft(), true);
  result.fold(
    (failure) {
      expect(failure, isA<ValidationFailure>());  // ✅
      expect(failure.message, contains('Invalid email'));  // ✅
    },
    (_) => fail('Should have returned Failure'),
  );
});
```

#### ✅ Testing Async Streams

```dart
test('should emit multiple values over time', () async {
  // Arrange
  final repository = EstimationRepositoryImpl(
    dataSource: fakeDataSource,
  );

  fakeDataSource.setupStreamWithDelays([
    EstimationDto(id: '1', amount: 100),
    EstimationDto(id: '2', amount: 200),
  ]);

  // Act: Subscribe to stream
  final stream = repository.watchEstimations('project-1');

  // Assert on emitted values
  await expectLater(
    stream,
    emitsInOrder([
      [Estimation(id: '1', amount: 100)],  // ✅ First emission
      [Estimation(id: '1', amount: 100), Estimation(id: '2', amount: 200)],  // ✅ Second
    ]),
  );
});
```

### Refactor-Safe Tests

**Good tests survive refactoring:**

```dart
// Original implementation
class Calculator {
  double calculate(int a, int b) {
    return (a + b).toDouble();
  }
}

// Test (focuses on behavior)
test('calculate should return sum', () {
  final calculator = Calculator();
  expect(calculator.calculate(2, 3), 5.0);  // ✅
});

// Refactored implementation (different approach, same behavior)
class Calculator {
  double calculate(int a, int b) {
    return _add(a, b);
  }

  double _add(int x, int y) => (x + y).toDouble();
}

// ✅ Test still passes! No changes needed.
// This is a good test - it tests behavior, not implementation.
```

**Bad tests break on refactoring:**

```dart
// Bad test (coupled to implementation)
test('calculate should call _add', () {
  final calculator = Calculator();
  final spy = SpyCalculator();  // ❌ Spying on internals

  calculator.calculate(2, 3);

  expect(spy.addWasCalled, true);  // ❌ Implementation detail
});

// This test breaks if we refactor to not use _add
// even though behavior is the same!
```

---

## For Review Agents (Detective)

### Detection Patterns

**Pattern 1: Mock/Verify Usage (Forbidden)**

```bash
# Find mock usage
grep -rn "Mock<" test/
grep -rn "verify(" test/
grep -rn "when(" test/
```

**Severity:** Critical

**Pattern 2: Testing Private Methods**

```bash
# Find underscore-prefixed method calls in tests
grep -rn "\._[a-zA-Z]" test/
```

**Severity:** Critical

**Pattern 3: Accessing Private State**

```bash
# Look for accessing private fields
grep -rn "\._(cache|state|controller|[a-z][a-zA-Z]*)\b" test/
```

**Severity:** Major

**Pattern 4: Tests Without Assertions**

```bash
# Tests that might only verify calls, not outputs
grep -A 10 "test(" test/ | grep -v "expect("
```

**Severity:** Major

### Common Violations

| ❌ Violation | ✅ Fix | Severity |
|-------------|--------|----------|
| `verify(mockRepo.save(any))` | Assert on fake boundary state instead | Critical |
| `calculator._privateMethod()` | Test public API that uses private method | Critical |
| `expect(bloc._cache.length, 5)` | Assert on emitted state instead | Major |
| `when(mock.method()).thenReturn(...)` | Use test doubles (RULE_3) | Critical |
| No `expect()` in test body | Add assertions on observable outputs | Major |

### Review Questions

1. **Does this test use `verify()` or `when()`?**
   - If YES → Violation (should use test doubles per RULE_3)

2. **Does this test access private methods/fields?**
   - If YES → Violation (test public API instead)

3. **Would this test break if we refactored without changing behavior?**
   - If YES → Test is too coupled to implementation

4. **Does this test assert on something a user/caller would observe?**
   - If NO → Test is probably testing implementation

---

## Summary: Suggested Fixes

1. **Remove mocks:** Replace with test doubles (fake implementations per RULE_3)
2. **Test public APIs only:** Remove tests of private methods/state
3. **Assert on outputs:** Test return values, emitted states, boundary effects
4. **Make tests refactor-safe:** Tests should pass after internal refactoring
5. **Focus on behavior:** Test *what* code does, not *how* it does it

## References

- [Test-Driven Development by Kent Beck](https://www.amazon.com/Test-Driven-Development-Kent-Beck/dp/0321146530)
- [Growing Object-Oriented Software, Guided by Tests](https://www.amazon.com/Growing-Object-Oriented-Software-Guided-Tests/dp/0321503627)
- Review Script Lines: 391-403 in `scripts/review_pr.sh`
- Related: RULE_3 (Test Double Pattern), RULE_8 (Widget Test Finders)

## Notes

**Key Insight:** Good tests provide a specification of behavior without constraining implementation. They give you freedom to refactor while ensuring correctness.

**Red Flag:** If refactoring working code breaks tests without changing behavior, your tests are coupled to implementation details.
