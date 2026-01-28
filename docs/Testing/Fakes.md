# Testing Strategy: Preferring Real Implementations

## Overview

Our testing strategy follows a clear hierarchy to maximize test fidelity and maintainability:

1. **Real Implementations** (Preferred) - Use actual production code
2. **Fakes** (Second Best) - Behavioral substitutes for external dependencies
3. **Mocks/Stubs** (Last Resort) - Only when other options aren't feasible

This hierarchy ensures you get the most realistic, maintainable, and reliable tests possible while only falling back to less ideal approaches when necessary.

## Why Real Implementations Are Preferred

Real implementations provide the highest fidelity testing because they execute the same code that runs in production.

### Benefits of Real Implementations

- **Higher confidence** that the system under test is working properly
- **Tests fail when there are bugs** in real implementations, which is good because it indicates code won't work properly in production
- **More realistic tests** since all code in the real implementations gets executed
- **Easier refactoring** as tests aren't coupled to implementation details

## Our Approach: Wrapper-Based Faking

To achieve maximum test fidelity while keeping tests fast, we've created **wrapper abstractions** around low-level external dependencies. This allows us to:

- Write tests using **real repositories** and **real use cases**
- Only fake at the **I/O boundary** level
- Avoid creating repetitive fakes for each data source

### Current Wrappers

- **`SupabaseWrapper`** - Abstracts all Supabase operations (auth, database, RPC)
- **Future**: Local storage wrapper (e.g., `LocalStorageWrapper`)

### The Wrapper Fake

We maintain a single, well-tested **`FakeSupabaseWrapper`** that implements the `SupabaseWrapper` interface. This fake:

- Stores data in-memory for instant operations
- Simulates all Supabase behaviors (authentication, queries, errors)
- Provides test utilities for assertions and state manipulation
- Is reusable across all tests that need Supabase functionality

### When to Fake Repositories

While we prefer testing with real repositories **within the same feature**, we also create fake repositories when:

**✅ Fake a repository when it belongs to another feature:**

If your repository depends on another feature's repository, you should fake it to maintain **feature isolation**. This prevents:
- Tests breaking when other features change
- Tight coupling between feature tests
- Accidentally testing other features' logic

**Example**: If your `EstimationRepository` depends on `ProjectRepository` from the project feature, fake the `ProjectRepository` in your estimation feature tests.

## Architecture Pattern

### Within a Single Feature

```
UseCase (Real)
   ↓
Repository (Real)
   ↓
DataSource (Real)
   ↓
SupabaseWrapper (Fake in tests, Real in production)
```

### With Cross-Feature Dependencies

```
EstimationUseCase (Real)
   |
   ├─→ EstimationRepository (Real)
   ├─→ EstimationDataSource (Real)
   │      ↓
   │   SupabaseWrapper (Fake)
   │
   └─→ AuthRepository (Fake - from auth feature)
```

**Key insights**: 
- By faking only at the wrapper level **within your feature**, we test the real coordination logic in UseCases, Repositories, and DataSources
- By faking repositories **from other features**, we maintain feature isolation and prevent cascading test failures

## Example: Testing with Real Implementations

### The Problem: Faking Too High in the Architecture

❌ **Don't do this:**

```dart
class AddCostEstimationUseCaseTest {
  late FakeEstimationRepository fakeRepository; // Faking the repository
  late AddCostEstimationUseCase useCase;
  
  setUp(() {
    fakeRepository = FakeEstimationRepository();
    useCase = AddCostEstimationUseCase(fakeRepository);
  });
  
  test('creates estimation successfully', () async {
    fakeRepository.setCreateResult(
      CostEstimate(
        id: 'est-123',
        projectId: 'proj-123',
        estimateName: 'Test Estimation',
      ),
    );
    
    final result = await useCase(
      estimationName: 'Test Estimation',
      projectId: 'proj-123',
    );
    
    expect(result.isRight(), true);
  });
}
```

**Problems:**
- Not testing real Repository logic
- Repository's data persistence strategy isn't tested
- Real validation and error handling aren't tested
- Coordination between cache and network isn't testeds
- Low test fidelity - only testing UseCase's happy path

### The Solution: Test Real Use Cases and Repositories (Within Feature)

✅ **Do this:**

```dart
class AddCostEstimationUseCaseTest {
  late AddCostEstimationUseCase useCase;
  late FakeSupabaseWrapper fakeSupabaseWrapper;
  late FakeClockImpl fakeClock;

  const testProjectId = 'test-project-123';
  const testEstimationName = 'Test Estimation';
  const testUserId = 'test-user-123';
  const testCredentialId = 'test-credential-123';
  const testUserEmail = 'test@example.com';


  setUpAll(() {
    fakeClock = FakeClockImpl();
    
    // Initialize Modular with real implementations
    // Only FakeSupabaseWrapper is fake - everything else is REAL
    Modular.init(
      EstimationModule(
        AppBootstrap(
          supabaseWrapper: FakeSupabaseWrapper(clock: fakeClock),
          config: FakeAppConfig(),
          envLoader: FakeEnvLoader(),
        ),
      ),
    );
    
    fakeSupabaseWrapper = Modular.get<SupabaseWrapper>() as FakeSupabaseWrapper;
    
    // Get REAL use case from dependency injection
    // It will use real repository and real data sources
    useCase = Modular.get<AddCostEstimationUseCase>();
  });

  setUp(() {
    fakeSupabaseWrapper.reset();
  });
  
  test('creates cost estimation successfully with real implementations', () async {
    // Arrange - Set up database state through fake
    setCurrentUser();
    seedUserProfile();
    
    // Act - Execute REAL use case with REAL repository and data sources
    final result = await useCase(
      estimationName: testEstimationName,
      projectId: testProjectId,
    );
    
    // Assert - Verify behavior of real implementations
    expect(result.isRight(), true);
    result.fold(
      (failure) => fail('Expected success but got failure: $failure'),
      (estimation) {
        final expectedEstimation = CostEstimate(
            id: estimation.id,
            projectId: testProjectId,
            estimateName: testEstimationName,
            estimateDescription: null,
            creatorUserId: testUserId,
            markupConfiguration: MarkupConfiguration(
            overallType: MarkupType.overall,
            overallValue: MarkupValue(
                type: MarkupValueType.percentage,
                value: 0.0,
                ),
            ),
            totalCost: 0,
            lockStatus: const UnlockedStatus(),
            createdAt: fakeClock.now(),
            updatedAt: fakeClock.now(),
        );
        expect(estimation, expectedEstimation);
      },
    );
  });
}
```

### Example: Faking Cross-Feature Repository Dependencies

When your repository depends on another feature's repository, fake it to maintain feature isolation.

✅ **Correct approach for cross-feature dependencies:**

```dart
// In your ESTIMATION feature tests
// If the estimation depends on project repository from the PROJECT feature
class AddEstimationItemUseCaseTest {
  late FakeSupabaseWrapper fakeSupabase;
  late FakeProjectRepository fakeProjectRepository; // From PROJECT feature - FAKE IT
  late EstimationDataSource realEstimationDataSource;
  late EstimationRepository realEstimationRepository;
  late AddEstimationItemUseCase realUseCase;
  late FakeClockImpl fakeClock;
  
  setUpAll(() {
    fakeClock = FakeClockImpl();
    
    // Fake the wrapper (I/O boundary)
    fakeSupabase = FakeSupabaseWrapper(clock: fakeClock);
    
    // Fake repository from another feature
    fakeProjectRepository = FakeProjectRepository();
    
    // Use REAL data source from this feature
    realEstimationDataSource = SupabaseEstimationDataSource(fakeSupabase);
    
    // Use REAL repository from this feature
    realEstimationRepository = EstimationRepository(
      dataSource: realEstimationDataSource,
      projectRepository: fakeProjectRepository, // Injected fake
    );
    
    // Use REAL use case
    realUseCase = AddEstimationItemUseCase(realEstimationRepository);
  });
  
  setUp(() {
    fakeSupabase.reset();
    fakeProjectRepository.reset();
  });
  
  test('adds item to estimation with project validation', () async {
    // Arrange - Set up project from other feature
    final project = Project(
      id: 'proj-123',
      name: 'Office Building',
      status: ProjectStatus.active,
    );
    fakeProjectRepository.setProject(project);
    
    // Act - Real estimation logic
    final result = await realUseCase(
      estimationId: 'est-123',
      itemName: 'Concrete',
      quantity: 100,
    );
    
    // Assert - Verify item was added with project validation
    expect(result.isRight(), true);
    result.fold(
      (failure) => fail('Expected success but got failure'),
      (item) {
        expect(item.name, 'Concrete');
        expect(item.quantity, 100);
      },
    );
    
    // Verify interaction with project repository
    expect(fakeProjectRepository.getProjectCallCount, 1);
  });
  
  test('handles inactive project gracefully', () async {
    // Arrange - Project is inactive
    final project = Project(
      id: 'proj-123',
      name: 'Archived Project',
      status: ProjectStatus.archived,
    );
    fakeProjectRepository.setProject(project);
    
    // Act - Real validation logic
    final result = await realUseCase(
      estimationId: 'est-123',
      itemName: 'Concrete',
      quantity: 100,
    );
    
    // Assert - Real error handling
    expect(result.isLeft(), true);
    result.fold(
      (failure) {
        expect(failure, isA<EstimationFailure>());
        expect(
          (failure as EstimationFailure).errorType,
          EstimationErrorType.projectNotActive,
        );
      },
      (item) => fail('Expected failure but got success'),
    );
  });
}
```

**Why this is correct:**
- ✅ Tests real EstimationRepository coordination logic
- ✅ Tests real EstimationDataSource operations  
- ✅ Tests real AddEstimationItemUseCase business logic
- ✅ Maintains feature isolation - project feature changes won't break estimation tests
- ✅ Only fakes at boundaries: SupabaseWrapper (I/O) and ProjectRepository (cross-feature)

## Why This Is Better

### ✅ High Test Fidelity

- Tests execute **real UseCase validation logic**
- Tests execute **real Repository data persistence logic**
- Tests verify **real coordination** between data sources and database
- Tests verify **real error handling** across all layers

### ✅ Fast Tests

- Only faking I/O boundaries (SupabaseWrapper level)
- In-memory operations are instantaneous
- No network calls or database I/O

### ✅ Easy to Maintain

- Changes to Repository logic are **automatically tested**
- Changes to DataSource logic are **automatically tested**
- No need to update fake Repository when implementation changes
- Single source of truth for Supabase behavior

### ✅ Clean Architecture

- External dependency complexity isolated in Wrapper
- Repositories are pure coordination logic
- Clear separation of concerns

## Using FakeSupabaseWrapper

### Basic Setup

The easiest way to switch between real and fake Supabase wrappers is through **`AppBootstrap`**, which modules use for dependency injection. Simply pass `FakeSupabaseWrapper` when bootstrapping in tests—no need for `Modular.replaceInstance()`.

```dart
setUpAll(() {
  fakeClock = FakeClockImpl();
  
  // AppBootstrap handles injecting the fake wrapper into all modules
  Modular.init(
    EstimationModule(
      AppBootstrap(
        supabaseWrapper: FakeSupabaseWrapper(clock: fakeClock),
        config: FakeAppConfig(),
        envLoader: FakeEnvLoader(),
      ),
    ),
  );
  
  fakeSupabaseWrapper = Modular.get<SupabaseWrapper>() as FakeSupabaseWrapper;
});
```

### Setting Up Data

```dart
// Add table data
fakeSupabaseWrapper.addTableData('cost_estimates', [
  {
    'id': 'est-123',
    'project_id': 'proj-123',
    'estimate_name': 'Building Materials',
    'total_cost': 50000.00,
    'created_at': fakeClock.now().toIso8601String(),
  },
]);
```

### Simulating Errors

```dart
// Configure error behavior
fakeSupabaseWrapper.shouldThrowOnInsert = true;
fakeSupabaseWrapper.insertExceptionType = SupabaseExceptionType.socket;

// Now any insert operation will throw a socket exception
```

### Testing Authentication

```dart
test('handles authentication state changes', () async {
  // Set up auth state
  final user = FakeUser(
    id: 'cred-123',
    email: 'test@example.com',
    createdAt: fakeClock.now().toIso8601String(),
  );
  fakeSupabaseWrapper.setCurrentUser(user);
  
  // Verify auth state
  expect(fakeSupabaseWrapper.isAuthenticated, true);
  expect(fakeSupabaseWrapper.currentUser?.email, 'test@example.com');
});
```

### Verifying Method Calls

```dart
test('calls correct database operations', () async {
  await realDataSource.createEstimation(estimationData);
  
  // Verify the fake received expected calls
  final insertCalls = fakeSupabaseWrapper.getMethodCallsFor('insert');
  expect(insertCalls.length, 1);
  expect(insertCalls.first['table'], 'cost_estimates');
});
```

### Testing Async Behavior

```dart
test('handles delayed operations', () async {
  // Set up delayed operation
  fakeSupabaseWrapper.shouldDelayOperations = true;
  fakeSupabaseWrapper.completer = Completer();
  
  // Start operation
  final future = realUseCase(
    estimationName: 'Test',
    projectId: 'proj-123',
  );
  
  // Operation is still pending
  await Future.delayed(Duration(milliseconds: 10));
  
  // Complete the operation
  fakeSupabaseWrapper.completer!.complete();
  
  final result = await future;
  expect(result.isRight(), true);
});
```

## When to Create New Fakes

### ✅ Create a new wrapper + fake when:

- You're integrating a new external service (e.g., analytics, payment gateway)
- The service has complex APIs that would be tedious to fake repeatedly
- Multiple data sources will use this service
- You want to maintain consistent behavior across tests

### ✅ Create a fake repository when:

- Your repository depends on a repository from **another feature**
- You want to maintain **feature isolation** in tests
- The other feature's repository has complex logic you don't want to test indirectly
- You want to prevent cascading test failures when other features change

**Example**: Create `FakeUserRepository` for use in order feature tests, `FakeProductRepository` for use in cart feature tests, etc.

### ❌ Don't create a fake when:

- A real implementation is fast and has no external dependencies
- You're testing pure business logic with no I/O
- The dependency is a simple value object or data structure
- The repository belongs to the **same feature** you're testing

## Guidelines for Writing Fakes

### For Wrapper Fakes (like FakeSupabaseWrapper)

When you need to create a new wrapper fake:

1. **Implement the entire interface** - Use `implements` not `extends`
2. **Store state in-memory** - Use maps, lists, or simple objects
3. **Provide test utilities** - Methods to configure behavior and verify calls
4. **Support error scenarios** - Flags to throw exceptions on demand
5. **Document expected behavior** - Make it clear how the fake differs from reality
6. **Keep it simple** - Don't replicate complex production logic, just the interface

### For Repository Fakes (for cross-feature dependencies)

When you need to fake a repository from another feature:

1. **Implement only what you need** - Don't implement the entire interface unless necessary
2. **Use simple, predictable behavior** - Return configured values, don't replicate business logic
3. **Provide setup methods** - Methods like `setCurrentUser()`, `setProducts()` to configure state
4. **Track method calls** - Add counters to verify interactions (e.g., `getCallCount`)
5. **Keep it minimal** - Only implement methods that your feature actually uses
6. **Use `noSuchMethod`** - Let Dart handle unimplemented methods with clear errors

**Example structure for a fake repository:**

```dart
class FakeProjectRepository implements ProjectRepository {
  // State
  Project? _project;
  final List<Project> _projects = [];
  
  // Call tracking
  int getProjectCallCount = 0;
  int getProjectByIdCallCount = 0;
  
  // Setup methods
  void setProject(Project? project) => _project = project;
  void addProject(Project project) => _projects.add(project);
  void reset() {
    _project = null;
    _projects.clear();
    getProjectCallCount = 0;
    getProjectByIdCallCount = 0;
  }
  
  // Interface implementation
  @override
  Future<Either<Failure, Project>> getProjectById(String id) async {
    getProjectByIdCallCount++;
    if (_project != null && _project!.id == id) {
      return Right(_project!);
    }
    final project = _projects.firstWhere(
      (p) => p.id == id,
      orElse: () => throw Exception('Project not found'),
    );
    return Right(project);
  }
  
  @override
  Future<Either<Failure, List<Project>>> getProjects() async {
    getProjectCallCount++;
    return Right(_projects);
  }
  
  // Let unimplemented methods fail clearly
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
```

## Testing Pyramid

```
        ┌─────────────┐
        │   E2E Tests │  ← Few, use real implementations
        │    (Real)   │
        ├─────────────┤
        │Integration  │  ← Some, use real implementations
        │    Tests    │     with fake wrappers
        │   (Real +   │
        │    Fakes)   │
        ├─────────────┤
        │   Unit      │  ← Many, use real implementations
        │   Tests     │     with fake wrappers
        │  (Real +    │
        │   Fakes)    │
        └─────────────┘
```

All levels prefer real implementations. The only difference is **what gets faked**:

- **Unit tests**: Fake external dependencies (SupabaseWrapper)
- **Integration tests**: Fake external dependencies (SupabaseWrapper)
- **E2E tests**: Use real everything (including real Supabase)

## Decision Tree: What Should I Fake?

Use this decision tree when setting up tests:

```
Is it an external service (database, network, file system)?
├─ YES → Use wrapper fake (e.g., FakeSupabaseWrapper)
└─ NO → Continue...

Is it a repository from ANOTHER feature?
├─ YES → Create/use fake repository (e.g., FakeUserRepository)
└─ NO → Continue...

Is it from the SAME feature?
├─ UseCase → Use REAL
├─ Repository → Use REAL
└─ DataSource → Use REAL
```

**Quick Reference Table:**

| Component Type | Same Feature | Other Feature | External Service |
|---------------|--------------|---------------|------------------|
| **UseCase** | ✅ Real | N/A | N/A |
| **Repository** | ✅ Real | ❌ Fake | N/A |
| **DataSource** | ✅ Real | N/A | N/A |
| **Wrapper** | N/A | N/A | ❌ Fake |

## Common Pitfalls to Avoid

### ❌ Faking Too High in the Stack (Same Feature)

```dart
// DON'T: Faking repository within the same feature loses valuable test coverage
final fakeRepo = FakeEstimationRepository();
final useCase = AddCostEstimationUseCase(fakeRepo);
```

### ❌ Not Faking Cross-Feature Dependencies

```dart
// DON'T: Using real repository from another feature creates tight coupling
final realProjectRepo = ProjectRepository(...); // From project feature
final estimationRepo = EstimationRepository(
  dataSource: realEstimationDataSource,
  projectRepository: realProjectRepo, // Couples estimation tests to project feature
);

// DO: Fake repositories from other features
final fakeProjectRepo = FakeProjectRepository();
final estimationRepo = EstimationRepository(
  dataSource: realEstimationDataSource,
  projectRepository: fakeProjectRepo, // Feature isolation maintained
);
);
```

### ❌ Using Mocks for Business Logic

```dart
// DON'T: Mocking obscures what's actually being tested
final mockRepo = MockEstimationRepository();
when(mockRepo.createEstimation(any)).thenReturn(estimation);
```

### ❌ Not Testing Error Paths

```dart
// DON'T: Only testing happy path
test('creates estimation successfully', () {
  // ... only success case
});

// DO: Test error scenarios
test('handles database errors gracefully', () {
  fakeSupabaseWrapper.shouldThrowOnInsert = true;
  fakeSupabaseWrapper.insertExceptionType = SupabaseExceptionType.socket;
  // ...
});
```

### ❌ Skipping Real Coordination Logic

```dart
// DON'T: Only testing individual pieces
test('use case validates input', () { /* test use case alone */ });
test('repository creates data', () { /* test repository alone */ });

// DO: Test them working together
test('use case and repository coordinate correctly', () {
  // Test real use case calling real repository
  // This tests validation, persistence, error handling together
});
```

## Summary

**The Golden Rule**: Use real implementations wherever possible. Only fake at boundaries (I/O and cross-feature).

**Our Pattern**:
- Real UseCases (always)
- Real Repositories (within same feature)
- Real DataSources (within same feature)
- Fake Wrappers (SupabaseWrapper, etc.) - for I/O boundaries
- Fake Repositories (from other features) - for feature isolation

**What to Fake**:
- ✅ External service wrappers (SupabaseWrapper, LocalStorageWrapper)
- ✅ Repositories from other features (ProjectRepository in estimation tests)
- ❌ Repositories from the same feature
- ❌ UseCases from the same feature
- ❌ DataSources from the same feature

**Benefits**:
- High test fidelity within features
- Feature isolation across features
- Fast test execution
- Easy refactoring
- Fewer tests to update when implementation changes
- Bugs caught early when they exist in production code
- Prevents cascading test failures across features

**Next Steps**:
1. Identify external dependencies in your feature
2. Check if a wrapper already exists (e.g., SupabaseWrapper)
3. Identify dependencies on other features' repositories
4. Create fake repositories for cross-feature dependencies
5. Write tests using real UseCases and Repositories (from your feature)
6. Only fake wrappers and cross-feature repositories
7. Test both happy paths and error scenarios