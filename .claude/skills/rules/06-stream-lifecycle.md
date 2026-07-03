# RULE 6: Stream Lifecycle & Performance

## Name
Stream Lifecycle

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

| ✅ Required | ❌ Forbidden |
|------------|-------------|
| `StreamController(onCancel: () => cleanup())` | No `onCancel` callback |
| Track subscriptions in `Map<String, StreamSubscription>` | Untracked subscriptions |
| `dispose()` method cancels all subscriptions | No `dispose()` method |
| `.distinct()` on streams to prevent duplicates | Duplicate event flooding |

### Key Patterns

| Pattern | Implementation | Purpose |
|---------|---------------|---------|
| **Optimistic Update** | Update stream first, persist to server, rollback on error | Avoid network thrashing |
| **Deduplication** | `.distinct()` on streams | Skip duplicate events |
| **Debouncing** | `.debounceTime(Duration(milliseconds: 300))` | Handle high-frequency input |
| **BLoC Cleanup** | Cancel subscriptions in `close()` method | Prevent memory leaks |
| **Combining Streams** | `Rx.combineLatest()` with `.distinct()` | Coordinate multiple data sources |

### Red Flags

| ❌ Violation | Description |
|------------|-------------|
| **Zombie Controllers** | `StreamController` never closed in `dispose()` |
| **Network Thrashing** | Full re-fetch after every write operation |
| **Event Flooding** | No `.distinct()` on frequently updating streams |
| **Dangling Subscriptions** | `.listen()` without cancellation in `close()` |

---

## For Review Agents (Detective)

### Detection Patterns

| Violation | What to Check | Severity |
|-----------|--------------|----------|
| **Unclosed StreamControllers** | `StreamController` without `dispose()` or `close()` method | Critical |
| **Missing onCancel** | `StreamController()` without `onCancel: () {}` callback | Major |
| **Network Thrashing** | Write operation followed by full re-fetch (pattern: `await create/update/delete` + `await getAll`) | Major |
| **Missing distinct()** | Streams feeding UI without `.distinct()` | Minor |
| **Uncancelled BLoC Subscriptions** | `.listen()` in BLoC without `close()` override | Critical |
| **Untracked Subscriptions** | `.listen()` without storing `StreamSubscription` | Major |

---

## References

- [Stream Lifecycle Gist: Stream Performance](https://gist.github.com/ripplearcgit/7818b412bf5fbe06269e0c3830e136f5)
- [Dart Streams Documentation](https://dart.dev/tutorials/language/streams)
- [RxDart Documentation](https://pub.dev/packages/rxdart)
