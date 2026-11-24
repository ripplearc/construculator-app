import 'package:construculator/libraries/analytics/testing/fake_analytics_repository.dart';
import 'package:construculator/libraries/auth/auth_manager_impl.dart';
import 'package:construculator/libraries/auth/check/check_finished_state_impl.dart';
import 'package:construculator/libraries/auth/check/check_state.dart';
import 'package:construculator/libraries/auth/check/testing/fake_check_finished_state.dart';
import 'package:construculator/libraries/auth/data/models/auth_state.dart';
import 'package:construculator/libraries/auth/domain/types/auth_types.dart';
import 'package:construculator/libraries/auth/testing/fake_auth_notifier.dart';
import 'package:construculator/libraries/auth/testing/fake_auth_repository.dart';
import 'package:construculator/libraries/sentry/fake_sentry_wrapper.dart';
import 'package:construculator/libraries/session/testing/fake_session_service.dart';
import 'package:construculator/libraries/supabase/testing/fake_supabase_user.dart';
import 'package:construculator/libraries/supabase/testing/fake_supabase_wrapper.dart';
import 'package:construculator/libraries/time/testing/fake_clock_impl.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late FakeSupabaseWrapper wrapper;
  late FakeAuthNotifier notifier;
  late FakeCheckFinishedState checkState;
  late FakeAnalyticsRepository analytics;
  late FakeSentryWrapper sentry;
  late List<AuthStatus> statuses;

  FakeUser user(String id) => FakeUser(id: id, createdAt: '2026-01-01');

  AuthManagerImpl buildManager() {
    final clock = FakeClockImpl();
    // ignore: no_direct_instantiation, reason: the manager under test is built from its fakes
    return AuthManagerImpl(
      wrapper: wrapper,
      authRepository: FakeAuthRepository(clock: clock),
      authNotifier: notifier,
      sentryWrapper: sentry,
      analyticsRepository: analytics,
      currentCompanyResolver: () => null,
      clearKeptCompanyId: () async {},
      sessionService: FakeSessionService(),
      activeUserProvider: checkState,
    );
  }

  setUp(() {
    wrapper = FakeSupabaseWrapper(clock: FakeClockImpl());
    notifier = FakeAuthNotifier();
    checkState = FakeCheckFinishedState();
    analytics = FakeAnalyticsRepository();
    sentry = FakeSentryWrapper();
    statuses = [];
    notifier.onAuthStateChanged.listen((state) => statuses.add(state.status));
  });

  tearDown(() => checkState.dispose());

  group('AuthManagerImpl and the check-finished state', () {
    test('holds back authenticated while the check runs and emits it once it '
        'finished for the signed-in user', () async {
      final manager = buildManager();
      addTearDown(manager.dispose);

      wrapper.setCurrentUser(user('user-a'));
      await checkState.whenFinishedAsked;
      expect(statuses, isNot(contains(AuthStatus.authenticated)));

      final authenticated = expectLater(
        notifier.onAuthStateChanged,
        emits(
          predicate<AuthState>((s) => s.status == AuthStatus.authenticated),
        ),
      );
      checkState.emit(const FinishedFor('user-a'));
      await authenticated;

      expect(statuses, [AuthStatus.unauthenticated, AuthStatus.authenticated]);
    });

    test(
      'never emits authenticated for a user the check did not finish for',
      () async {
        final manager = buildManager();
        addTearDown(manager.dispose);
        checkState.emit(const FinishedFor('user-b'));
        final emittedUsers = <String?>[];
        notifier.onAuthStateChanged.listen(
          (state) => emittedUsers.add(state.user?.id),
        );
        final authenticated = expectLater(
          notifier.onAuthStateChanged,
          emits(
            predicate<AuthState>((s) => s.status == AuthStatus.authenticated),
          ),
        );

        wrapper.setCurrentUser(user('user-a'));
        wrapper.setCurrentUser(user('user-b'));
        await authenticated;

        expect(emittedUsers.whereType<String>(), ['user-b']);
      },
    );

    test('holds back authenticated and the user identity for a resumed '
        'session at construction', () async {
      wrapper.setCurrentUser(user('user-a'));
      final manager = buildManager();
      addTearDown(manager.dispose);
      await checkState.whenFinishedAsked;
      expect(statuses, isEmpty);
      expect(sentry.userId, isNull);
      expect(analytics.identifyCalls, isEmpty);

      final authenticated = expectLater(
        notifier.onAuthStateChanged,
        emits(
          predicate<AuthState>((s) => s.status == AuthStatus.authenticated),
        ),
      );
      checkState.emit(const FinishedFor('user-a'));
      await authenticated;

      expect(sentry.userId, 'user-a');
      expect(analytics.identifyCalls.single.userId, 'user-a');
    });

    test('a finished value left from an earlier user does not release a new '
        'sign-in, whatever order the listeners were added in', () async {
      // ignore: no_direct_instantiation, reason: the real state decides what is left over from an earlier user
      final realState = CheckFinishedStateImpl();
      addTearDown(realState.dispose);
      realState.settle(
        result: const FinishedNobodySignedIn(),
        isNewestEvent: true,
      );
      // ignore: no_direct_instantiation, reason: the manager under test is built from its fakes
      final manager = AuthManagerImpl(
        wrapper: wrapper,
        authRepository: FakeAuthRepository(clock: FakeClockImpl()),
        authNotifier: notifier,
        sentryWrapper: sentry,
        analyticsRepository: analytics,
        currentCompanyResolver: () => null,
        clearKeptCompanyId: () async {},
        sessionService: FakeSessionService(),
        activeUserProvider: realState,
      );
      addTearDown(manager.dispose);
      final authenticated = expectLater(
        notifier.onAuthStateChanged,
        emits(
          predicate<AuthState>((s) => s.status == AuthStatus.authenticated),
        ),
      );

      wrapper.setCurrentUser(user('user-a'));
      realState.sessionEventArrived(
        userId: 'user-a',
        sessionModuleAdded: false,
      );
      realState.settle(
        result: const FinishedFor('user-a'),
        isNewestEvent: true,
      );
      await authenticated;

      expect(statuses, contains(AuthStatus.authenticated));
    });

    test('two sign-in events for the same user while the check runs emit '
        'authenticated once', () async {
      final manager = buildManager();
      addTearDown(manager.dispose);
      final authenticatedCount = <AuthStatus>[];
      notifier.onAuthStateChanged
          .where((state) => state.status == AuthStatus.authenticated)
          .listen((state) => authenticatedCount.add(state.status));

      final authenticated = expectLater(
        notifier.onAuthStateChanged,
        emits(
          predicate<AuthState>((s) => s.status == AuthStatus.authenticated),
        ),
      );
      wrapper.setCurrentUser(user('user-a'));
      wrapper.setCurrentUser(user('user-a'));
      checkState.emit(const FinishedFor('user-a'));
      await authenticated;
      final signedOut = expectLater(
        notifier.onAuthStateChanged,
        emits(
          predicate<AuthState>((s) => s.status == AuthStatus.unauthenticated),
        ),
      );
      wrapper.setCurrentUser(null);
      await signedOut;

      expect(authenticatedCount, hasLength(1));
    });

    test(
      'a sign-in that is waiting is dropped when the user signs out',
      () async {
        final manager = buildManager();
        addTearDown(manager.dispose);
        wrapper.setCurrentUser(user('user-a'));
        await checkState.whenFinishedAsked;
        final signedOut = expectLater(
          notifier.onAuthStateChanged,
          emits(
            predicate<AuthState>((s) => s.status == AuthStatus.unauthenticated),
          ),
        );
        wrapper.setCurrentUser(null);
        await signedOut;

        checkState.emit(const FinishedFor('user-a'));
        await checkState.whenFinishedFor('user-a');

        expect(statuses, isNot(contains(AuthStatus.authenticated)));
      },
    );

    test('never holds back unauthenticated', () async {
      final manager = buildManager();
      addTearDown(manager.dispose);
      final unauthenticated = expectLater(
        notifier.onAuthStateChanged,
        emits(
          predicate<AuthState>((s) => s.status == AuthStatus.unauthenticated),
        ),
      );

      wrapper.setCurrentUser(null);
      await unauthenticated;

      expect(checkState.value, const Checking());
    });

    test(
      'a manager that was disposed while holding back emits nothing',
      () async {
        wrapper.setCurrentUser(user('user-a'));
        final disposed = buildManager();
        disposed.dispose();
        final sentinel = buildManager();
        addTearDown(sentinel.dispose);
        final authenticated = expectLater(
          notifier.onAuthStateChanged,
          emits(
            predicate<AuthState>((s) => s.status == AuthStatus.authenticated),
          ),
        );

        checkState.emit(const FinishedFor('user-a'));
        await authenticated;

        expect(analytics.identifyCalls, hasLength(1));
      },
    );
  });
}
