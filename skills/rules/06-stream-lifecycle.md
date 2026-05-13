# RULE 6: Stream Lifecycle & Performance

## Rule ID
RULE_6

## Category
Performance & Memory Management

## Severity Levels
- **Critical:** Memory leaks from unclosed StreamControllers or dangling subscriptions
- **Major:** Network thrashing or unnecessary re-fetches on stream events
- **Minor:** Missing `distinct()` causing excessive UI rebuilds
- **Suggestion:** Consider stream optimization for better performance

## Description

Manage stream lifecycles strictly to prevent memory leaks and minimize redundant network/CPU overhead. Streams must be properly initialized, managed, and disposed to avoid zombie controllers and event flooding.

## Applicability

Applies to all code that creates or manages streams: Repositories, DataSources, BLoCs, and Services in `lib/**/` directories.

---

## For Coding Agents (Prescriptive)

### Core Principles

1. **No Zombies:** Every `StreamController` must have a clear cleanup strategy
2. **No Network Thrashing:** Don't re-fetch everything on every stream tick
3. **No Event Flooding:** Use `distinct()` and `debounceTime()` for high-frequency data
4. **No Dangling Subscriptions:** Cancel all manual subscriptions in `close()` or `dispose()`

### Decision Tree: Do I Need a StreamController?

```
Do I need to expose a stream of data?
  ├─ YES, data comes from external source (Supabase, DB)
  │  └─ Use: Supabase's built-in streams (don't create your own controller)
  │
  ├─ YES, combining multiple streams
  │  └─ Use: Rx.combineLatest, switchMap, etc. (reactive operators)
  │
  ├─ YES, custom stream logic needed
  │  └─ Create: StreamController with proper lifecycle management
  │     └─ MUST implement cleanup in dispose/close
  │
  └─ NO, single async operation
     └─ Use: Future, not Stream
```

### Creating StreamControllers Safely

#### ✅ Correct Pattern

```dart
class EstimationRepository {
  final Map<String, StreamController<List<Estimation>>> _controllers = {};
  final Map<String, StreamSubscription> _subscriptions = {};

  Stream<List<Estimation>> watchEstimations(String projectId) {
    // Return existing stream if already watching
    if (_controllers.containsKey(projectId)) {
      return _controllers[projectId]!.stream;
    }

    // Create new controller with cleanup on cancel
    final controller = StreamController<List<Estimation>>(
      onCancel: () {
        // ✅ Cleanup when no more listeners
        _subscriptions[projectId]?.cancel();
        _subscriptions.remove(projectId);
        _controllers[projectId]?.close();
        _controllers.remove(projectId);
      },
    );

    _controllers[projectId] = controller;

    // Subscribe to Supabase stream
    final subscription = _dataSource
        .watchEstimations(projectId)
        .distinct()  // ✅ Prevent duplicate events
        .listen(
          (data) => controller.add(data),
          onError: (error) => controller.addError(error),
        );

    _subscriptions[projectId] = subscription;

    return controller.stream;
  }

  Future<void> dispose() async {
    // ✅ Cleanup all controllers on dispose
    for (final subscription in _subscriptions.values) {
      await subscription.cancel();
    }
    for (final controller in _controllers.values) {
      await controller.close();
    }
    _controllers.clear();
    _subscriptions.clear();
  }
}
```

#### ❌ Wrong: No Cleanup

```dart
class EstimationRepository {
  final Map<String, StreamController<List<Estimation>>> _controllers = {};

  Stream<List<Estimation>> watchEstimations(String projectId) {
    final controller = StreamController<List<Estimation>>();  // ❌ No onCancel
    _controllers[projectId] = controller;

    _dataSource.watchEstimations(projectId).listen(
      (data) => controller.add(data),  // ❌ No subscription tracking
    );

    return controller.stream;
  }

  // ❌ No dispose method - memory leak!
}
```

### Optimistic UI Pattern (Avoid Network Thrashing)

**Problem:** Every write operation triggers a full network re-fetch

❌ **Bad: Network Thrashing**

```dart
Future<void> addEstimation(Estimation estimation) async {
  await _dataSource.create(estimation);
  // ❌ Full re-fetch after every write
  await _refreshAllEstimations();  // Network call!
}
```

✅ **Good: Optimistic Update**

```dart
Future<void> addEstimation(Estimation estimation) async {
  // ✅ Update local stream immediately
  final current = _estimationsController.value;
  _estimationsController.add([...current, estimation]);

  try {
    // Persist to server
    await _dataSource.create(estimation);
    // Stream will naturally update when Supabase notifies us
  } catch (e) {
    // ✅ Rollback on error
    _estimationsController.add(current);
    rethrow;
  }
}
```

### Preventing Event Flooding

#### ✅ Use `distinct()` for Deduplication

```dart
Stream<List<Estimation>> watchEstimations(String projectId) {
  return _dataSource
      .watchEstimations(projectId)
      .distinct((prev, next) {
        // ✅ Only emit when data actually changed
        return const DeepCollectionEquality().equals(prev, next);
      });
}
```

#### ✅ Use `debounceTime()` for High-Frequency Events

```dart
Stream<String> get searchQuery => _searchController.stream
    .debounceTime(const Duration(milliseconds: 300))  // ✅ Wait for typing to stop
    .distinct();  // ✅ Skip duplicate searches
```

### BLoC Stream Subscriptions

**Always cancel subscriptions in `close()`:**

```dart
class EstimationBloc extends Bloc<EstimationEvent, EstimationState> {
  final EstimationRepository repository;
  StreamSubscription<List<Estimation>>? _estimationsSubscription;

  EstimationBloc({required this.repository}) : super(EstimationInitial()) {
    on<LoadEstimations>(_onLoadEstimations);
  }

  Future<void> _onLoadEstimations(
    LoadEstimations event,
    Emitter<EstimationState> emit,
  ) async {
    // ✅ Cancel previous subscription
    await _estimationsSubscription?.cancel();

    // Subscribe to stream
    _estimationsSubscription = repository
        .watchEstimations(event.projectId)
        .listen((estimations) {
          add(_EstimationsUpdated(estimations));  // Internal event
        });
  }

  @override
  Future<void> close() async {
    // ✅ Cancel subscription on dispose
    await _estimationsSubscription?.cancel();
    return super.close();
  }
}
```

### Common Patterns

#### Pattern 1: Single BehaviorSubject (Stateful Stream)

```dart
class UserRepository {
  final BehaviorSubject<User?> _userSubject = BehaviorSubject<User?>.seeded(null);

  Stream<User?> get userStream => _userSubject.stream.distinct();

  Future<void> updateUser(User user) async {
    // ✅ Optimistic update
    _userSubject.add(user);

    try {
      await _dataSource.updateUser(user);
    } catch (e) {
      // ✅ Rollback on error
      _userSubject.add(null);
      rethrow;
    }
  }

  Future<void> dispose() async {
    await _userSubject.close();  // ✅ Cleanup
  }
}
```

#### Pattern 2: Combining Multiple Streams

```dart
Stream<ScreenState> get state => Rx.combineLatest3(
  authBloc.stream,
  estimationBloc.stream,
  projectBloc.stream,
  (auth, estimation, project) => ScreenState(
    canEdit: auth.isAuthenticated && project.isOwner,
    estimations: estimation.items,
    projectName: project.name,
  ),
).distinct();  // ✅ Emit only when combined result changes
```

### Red Flags to Avoid

❌ **Zombie Controllers:**
```dart
// StreamController stored but never closed
final _controller = StreamController();  // ❌ Leak
```

❌ **Network Thrashing:**
```dart
// Re-fetching everything on every write
await create(item);
await getAllItems();  // ❌ Unnecessary network call
```

❌ **Event Flooding:**
```dart
// No distinct() on frequently updating stream
stream.listen((data) {
  setState(() {});  // ❌ Rebuilds on every tick, even duplicates
});
```

❌ **Dangling Subscriptions:**
```dart
class MyBloc {
  MyBloc() {
    repository.stream.listen(...);  // ❌ Never cancelled
  }
  // ❌ No close() method
}
```

---

## For Review Agents (Detective)

### Detection Patterns

**Pattern 1: Unclosed StreamControllers**

Search for `StreamController` creation without corresponding cleanup:

```bash
# Find StreamControllers
grep -rn "StreamController<" lib/

# Check if file has dispose/close method
grep -A 50 "StreamController" {file} | grep -E "(dispose|close)\s*\("
```

**Severity:** Critical if no cleanup found

**Pattern 2: Missing onCancel**

```bash
# Find StreamControllers without onCancel
grep -A 5 "StreamController<" lib/ | grep -v "onCancel"
```

**Severity:** Major

**Pattern 3: Network Thrashing**

Look for write operations followed by full re-fetch:

```dart
// Anti-pattern
await create(...);
await getAll();  // ❌ Full re-fetch
```

**Regex:** `await\s+(?:create|update|delete)\([^)]*\);[\s\n]*await\s+(?:getAll|fetch|load)`

**Severity:** Major

**Pattern 4: Missing distinct()**

Streams without `distinct()` that feed into UI:

```bash
grep -rn "\.stream" lib/features/**/presentation/ | grep -v "distinct()"
```

**Severity:** Minor

**Pattern 5: Uncancelled Subscriptions in BLoC**

BLoCs with `listen()` but no `close()` method:

```bash
# Find BLoCs with subscriptions
grep -A 20 "class.*Bloc" lib/ | grep "\.listen("

# Check for close() method
grep -A 100 "class.*Bloc" {file} | grep "@override.*close()"
```

**Severity:** Critical

### Common Violations

| ❌ Violation | ✅ Fix | Severity |
|-------------|--------|----------|
| `StreamController()` without `onCancel` | Add `onCancel: () { cleanup }` | Major |
| No `dispose()` method with controllers | Add `dispose()` and close all controllers | Critical |
| BLoC subscription without cleanup | Cancel in `close()` override | Critical |
| Stream without `distinct()` | Add `.distinct()` before `listen()` | Minor |
| Re-fetch after every write | Use optimistic updates | Major |
| `listen()` without storing subscription | Store subscription, cancel in dispose | Major |

---

## Summary: Suggested Fixes

1. **Add cleanup logic:** Every `StreamController` needs `onCancel` callback or explicit `dispose()`
2. **Cancel subscriptions:** Store and cancel all subscriptions in `close()` or `dispose()`
3. **Use distinct():** Add `.distinct()` to prevent duplicate events from triggering rebuilds
4. **Optimistic updates:** Update local stream immediately, don't re-fetch after writes
5. **Leverage built-in streams:** Use Supabase/Firebase streams directly instead of wrapping in custom controllers

## References

- [RULE_6 Gist: Stream Performance](https://gist.github.com/ripplearcgit/7818b412bf5fbe06269e0c3830e136f5)
- [Dart Streams Documentation](https://dart.dev/tutorials/language/streams)
- [RxDart Documentation](https://pub.dev/packages/rxdart)
- Review Script Lines: 319-334 in `scripts/review_pr.sh`

## Notes

**Common Stream Libraries:**
- `dart:async` - Built-in StreamController, StreamSubscription
- `rxdart` - BehaviorSubject, combineLatest, debounceTime, distinct
- `stream_transform` - Additional stream operators

**Key Principle:** Streams are powerful but dangerous. Treat them like file handles - always clean up when done.
