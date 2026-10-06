import 'dart:async';

import 'package:construculator/libraries/company/data/current_company_resolver_impl.dart';
import 'package:construculator/libraries/company/data/data_source/interfaces/local_current_company_data_source.dart';
import 'package:construculator/libraries/company/data/data_source/powersync_local_current_company_data_source.dart';
import 'package:construculator/libraries/company/domain/current_company_resolver.dart';
import 'package:construculator/libraries/company/domain/types/company_error_type.dart';
import 'package:construculator/libraries/errors/failures.dart';
import 'package:construculator/libraries/powersync/testing/fake_powersync_database_wrapper.dart';
import 'package:construculator/libraries/supabase/data/supabase_types.dart';
import 'package:construculator/libraries/supabase/database_constants.dart';
import 'package:construculator/libraries/supabase/testing/fake_supabase_user.dart';
import 'package:construculator/libraries/supabase/testing/fake_supabase_wrapper.dart';
import 'package:construculator/libraries/time/testing/fake_clock_impl.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../utils/fake_current_company_database.dart';

void main() {
  group('CurrentCompanyResolverImpl', () {
    late FakeSupabaseWrapper supabaseWrapper;
    late FakeCurrentCompanyDatabase localDatabase;
    late FakePowerSyncDatabaseWrapper failingWrites;
    late FakePowerSyncDatabaseWrapper failingReads;
    late CurrentCompanyResolver resolver;

    setUpAll(() {
      // One wrapper/Modular.init for the whole file, not per test:
      // modular_core's Tracker caches every imported module's injector by
      // runtimeType and never clears that cache on Modular.destroy (see
      // shell_routes_test.dart for the same gotcha), so a fresh
      // FakeSupabaseWrapper per test would leave the injector still reading
      // the first test's instance.
      supabaseWrapper = FakeSupabaseWrapper(clock: FakeClockImpl());
      localDatabase = FakeCurrentCompanyDatabase();
      failingWrites = FakePowerSyncDatabaseWrapper();
      failingReads = FakePowerSyncDatabaseWrapper();
      Modular.init(
        _CompanyTestAppModule(
          supabaseWrapper: supabaseWrapper,
          localDatabase: localDatabase,
          failingWrites: failingWrites,
          failingReads: failingReads,
        ),
      );
      resolver = Modular.get<CurrentCompanyResolver>();
    });

    tearDownAll(() {
      Modular.destroy();
      localDatabase.dispose();
    });

    setUp(() {
      supabaseWrapper.reset();
      supabaseWrapper.setCurrentUser(_userOne);
      failingWrites.reset();
      failingReads.reset();
      // The resolver instance is shared across tests in this file (see
      // setUpAll); clearing its cache here is what makes each test start
      // from a fresh, un-resolved session rather than reusing whatever a
      // previous test already resolved and cached.
      resolver.clearCache();
    });

    test('resolve returns the company id from the RPC', () async {
      supabaseWrapper.setRpcResponse(
        DatabaseConstants.getMyCompanyIdRpcFunction,
        'company-1',
      );

      final result = await resolver.resolve();

      result.fold(
        (_) => fail('Expected Right but got Left'),
        (companyId) => expect(companyId, 'company-1'),
      );
    });

    test('resolve calls the get_my_company_id RPC with no params', () async {
      supabaseWrapper.setRpcResponse(
        DatabaseConstants.getMyCompanyIdRpcFunction,
        'company-1',
      );

      await resolver.resolve();

      final calls = supabaseWrapper.getMethodCallsFor('rpc');
      expect(calls, hasLength(1));
      expect(
        calls.single['functionName'],
        DatabaseConstants.getMyCompanyIdRpcFunction,
      );
      expect(calls.single['params'], isNull);
    });

    test(
      'resolve returns Right(null), not a Failure, when the RPC returns no id',
      () async {
        supabaseWrapper.setRpcResponse(
          DatabaseConstants.getMyCompanyIdRpcFunction,
          null,
        );

        final result = await resolver.resolve();

        result.fold(
          (failure) => fail('Expected Right but got Left($failure)'),
          (companyId) => expect(companyId, isNull),
        );
      },
    );

    test('resolve returns a Failure and does not cache when the RPC throws '
        'before any call has succeeded', () async {
      supabaseWrapper.shouldThrowOnRpc = true;
      supabaseWrapper.rpcExceptionType = SupabaseExceptionType.socket;

      final result = await resolver.resolve();

      result.fold(
        (failure) => expect(
          failure,
          const CompanyFailure(errorType: CompanyErrorType.connectionError),
        ),
        (_) => fail('Expected Left but got Right'),
      );
    });

    test(
      'a second resolve call in the same session does not re-hit the RPC',
      () async {
        supabaseWrapper.setRpcResponse(
          DatabaseConstants.getMyCompanyIdRpcFunction,
          'company-1',
        );

        final first = await resolver.resolve();
        final second = await resolver.resolve();

        expect(
          supabaseWrapper.getMethodCallsFor('rpc'),
          hasLength(1),
          reason: 'the RPC should only be called once per session',
        );
        first.fold(
          (_) => fail('Expected Right but got Left'),
          (companyId) => expect(companyId, 'company-1'),
        );
        second.fold(
          (_) => fail('Expected Right but got Left'),
          (companyId) => expect(companyId, 'company-1'),
        );
      },
    );

    test('two concurrent resolve calls before the RPC responds share one '
        'network call', () async {
      supabaseWrapper.setRpcResponse(
        DatabaseConstants.getMyCompanyIdRpcFunction,
        'company-1',
      );
      supabaseWrapper.shouldDelayOperations = true;
      supabaseWrapper.completer = Completer<void>();

      final firstFuture = resolver.resolve();
      final secondFuture = resolver.resolve();
      supabaseWrapper.completer!.complete();
      final results = await Future.wait([firstFuture, secondFuture]);

      expect(
        supabaseWrapper.getMethodCallsFor('rpc'),
        hasLength(1),
        reason: 'concurrent callers should share the same in-flight call',
      );
      for (final result in results) {
        result.fold(
          (_) => fail('Expected Right but got Left'),
          (companyId) => expect(companyId, 'company-1'),
        );
      }
    });

    test(
      'the cached value is reused when a later call would be offline',
      () async {
        supabaseWrapper.setRpcResponse(
          DatabaseConstants.getMyCompanyIdRpcFunction,
          'company-1',
        );
        final online = await resolver.resolve();
        online.fold(
          (_) => fail('Expected Right but got Left'),
          (companyId) => expect(companyId, 'company-1'),
        );

        // Simulate going offline: any further RPC call would now fail.
        supabaseWrapper.shouldThrowOnRpc = true;
        supabaseWrapper.rpcExceptionType = SupabaseExceptionType.socket;

        final offline = await resolver.resolve();

        offline.fold(
          (failure) => fail('Expected Right but got Left($failure)'),
          (companyId) => expect(companyId, 'company-1'),
        );
        expect(
          supabaseWrapper.getMethodCallsFor('rpc'),
          hasLength(1),
          reason: 'the cached value must be served without hitting the RPC',
        );
      },
    );

    test('a null resolution (no company_users row yet) is not cached, so a '
        'later call retries the RPC and can pick up a real id', () async {
      supabaseWrapper.setRpcResponse(
        DatabaseConstants.getMyCompanyIdRpcFunction,
        null,
      );
      final first = await resolver.resolve();
      first.fold(
        (_) => fail('Expected Right but got Left'),
        (companyId) => expect(companyId, isNull),
      );

      supabaseWrapper.setRpcResponse(
        DatabaseConstants.getMyCompanyIdRpcFunction,
        'company-1',
      );
      final second = await resolver.resolve();

      second.fold(
        (_) => fail('Expected Right but got Left'),
        (companyId) => expect(companyId, 'company-1'),
      );
      expect(
        supabaseWrapper.getMethodCallsFor('rpc'),
        hasLength(2),
        reason: 'a null answer must not be cached as final',
      );
    });

    test('a fetch already in flight when clearCache runs must not overwrite '
        'the next caller with the previous one\'s company id', () async {
      supabaseWrapper.setRpcResponse(
        DatabaseConstants.getMyCompanyIdRpcFunction,
        'company-a',
      );
      supabaseWrapper.shouldDelayOperations = true;
      supabaseWrapper.completer = Completer<void>();

      final staleFuture = resolver.resolve();
      resolver.clearCache();
      supabaseWrapper.completer!.complete();
      final staleResult = await staleFuture;

      staleResult.fold(
        (_) => fail('Expected Right but got Left'),
        (companyId) => expect(
          companyId,
          'company-a',
          reason: 'the original caller still gets its own answer',
        ),
      );

      supabaseWrapper.shouldDelayOperations = false;
      supabaseWrapper.setRpcResponse(
        DatabaseConstants.getMyCompanyIdRpcFunction,
        'company-b',
      );
      final nextResult = await resolver.resolve();

      nextResult.fold(
        (_) => fail('Expected Right but got Left'),
        (companyId) => expect(
          companyId,
          'company-b',
          reason:
              'the stale fetch must not have cached company-a after '
              'clearCache ran',
        ),
      );
    });

    test('a call that starts while the cleared session\'s call is still '
        'running is not cut off when the old call finishes', () async {
      final perCallWrapper = _PerCallRpcWrapper();
      final localDataSource = Modular.get<LocalCurrentCompanyDataSource>();
      // ignore: no_direct_instantiation, reason: needs a wrapper whose rpc calls are held one by one, which Modular's shared fake cannot do
      final raceResolver = CurrentCompanyResolverImpl(
        supabaseWrapper: perCallWrapper,
        localDataSource: localDataSource,
      );

      final userA = raceResolver.resolve();
      await raceResolver.clearCache();
      final userB = raceResolver.resolve();
      expect(perCallWrapper.pending, hasLength(2));

      perCallWrapper.pending[0].complete('company-a');
      expect((await userA).getRightOrNull(), 'company-a');

      final later = raceResolver.resolve();
      expect(
        perCallWrapper.pending,
        hasLength(2),
        reason: 'the second call is still running, so a new caller joins it',
      );

      perCallWrapper.pending[1].complete('company-b');
      expect((await userB).getRightOrNull(), 'company-b');
      expect((await later).getRightOrNull(), 'company-b');
      expect((await raceResolver.resolve()).getRightOrNull(), 'company-b');
      expect(perCallWrapper.pending, hasLength(2));
    });

    test('a different user signing in while another user\'s lookup is still '
        'running gets their own lookup and their own id', () async {
      // ignore: no_direct_instantiation, reason: a test-local wrapper that holds each rpc call open
      final perCallWrapper = _PerCallRpcWrapper();
      final localDataSource = Modular.get<LocalCurrentCompanyDataSource>();
      await localDataSource.clearCompanyId();
      // ignore: no_direct_instantiation, reason: needs a wrapper whose rpc calls are held one by one, which Modular's shared fake cannot do
      final app = CurrentCompanyResolverImpl(
        supabaseWrapper: perCallWrapper,
        localDataSource: localDataSource,
      );

      perCallWrapper.setCurrentUser(_userOne);
      final first = app.resolve();
      perCallWrapper.setCurrentUser(_userTwo);
      final second = app.resolve();
      expect(perCallWrapper.pending, hasLength(2));

      perCallWrapper.pending[0].complete('company-1');
      perCallWrapper.pending[1].complete('company-2');

      expect((await first).getRightOrNull(), 'company-1');
      expect((await second).getRightOrNull(), 'company-2');
      expect(await localDataSource.loadCompanyId(_userOne.id), isNull);
      expect(await localDataSource.loadCompanyId(_userTwo.id), 'company-2');
    });

    test(
      'a failed call caches nothing, so the next call retries the RPC',
      () async {
        supabaseWrapper.shouldThrowOnRpc = true;
        supabaseWrapper.rpcExceptionType = SupabaseExceptionType.socket;

        await resolver.resolve();

        supabaseWrapper.shouldThrowOnRpc = false;
        supabaseWrapper.setRpcResponse(
          DatabaseConstants.getMyCompanyIdRpcFunction,
          'company-1',
        );

        final result = await resolver.resolve();

        result.fold(
          (_) => fail('Expected Right but got Left'),
          (companyId) => expect(companyId, 'company-1'),
        );
        expect(supabaseWrapper.getMethodCallsFor('rpc'), hasLength(2));
      },
    );

    test(
      'clearCache forces the next resolve call to hit the RPC again',
      () async {
        supabaseWrapper.setRpcResponse(
          DatabaseConstants.getMyCompanyIdRpcFunction,
          'company-1',
        );
        await resolver.resolve();

        resolver.clearCache();
        supabaseWrapper.setRpcResponse(
          DatabaseConstants.getMyCompanyIdRpcFunction,
          'company-2',
        );
        final result = await resolver.resolve();

        result.fold(
          (_) => fail('Expected Right but got Left'),
          (companyId) => expect(companyId, 'company-2'),
        );
        expect(
          supabaseWrapper.getMethodCallsFor('rpc'),
          hasLength(2),
          reason: 'clearCache should force a fresh RPC call',
        );
      },
    );

    test('resolve maps a timeout to CompanyErrorType.timeoutError', () async {
      supabaseWrapper.shouldThrowOnRpc = true;
      supabaseWrapper.rpcExceptionType = SupabaseExceptionType.timeout;

      final result = await resolver.resolve();

      result.fold(
        (failure) => expect(
          failure,
          const CompanyFailure(errorType: CompanyErrorType.timeoutError),
        ),
        (_) => fail('Expected Left but got Right'),
      );
    });

    test(
      'resolve maps a PostgrestException to CompanyErrorType.unexpectedDatabaseError',
      () async {
        supabaseWrapper.shouldThrowOnRpc = true;
        supabaseWrapper.rpcExceptionType = SupabaseExceptionType.postgrest;

        final result = await resolver.resolve();

        result.fold(
          (failure) => expect(
            failure,
            const CompanyFailure(
              errorType: CompanyErrorType.unexpectedDatabaseError,
            ),
          ),
          (_) => fail('Expected Left but got Right'),
        );
      },
    );

    test(
      'resolve maps an unrecognized error to CompanyErrorType.unexpectedError',
      () async {
        supabaseWrapper.shouldThrowOnRpc = true;
        supabaseWrapper.rpcExceptionType = null;

        final result = await resolver.resolve();

        result.fold(
          (failure) => expect(
            failure,
            const CompanyFailure(errorType: CompanyErrorType.unexpectedError),
          ),
          (_) => fail('Expected Left but got Right'),
        );
      },
    );

    group('company id kept on the device', () {
      late LocalCurrentCompanyDataSource localDataSource;

      CurrentCompanyResolver restartedApp() =>
          Modular.get<CurrentCompanyResolver>(key: 'restartedApp');

      void answerWith(String? companyId) {
        supabaseWrapper.shouldThrowOnRpc = false;
        supabaseWrapper.setRpcResponse(
          DatabaseConstants.getMyCompanyIdRpcFunction,
          companyId,
        );
      }

      void loseSignal([
        SupabaseExceptionType type = SupabaseExceptionType.socket,
      ]) {
        supabaseWrapper.shouldThrowOnRpc = true;
        supabaseWrapper.rpcExceptionType = type;
      }

      setUp(() async {
        localDataSource = Modular.get<LocalCurrentCompanyDataSource>();
        await localDataSource.clearCompanyId();
      });

      test(
        'finds the company id with no signal after a first sign-in',
        () async {
          answerWith('company-1');
          await resolver.resolve();

          loseSignal();
          final result = await restartedApp().resolve();

          expect(result.getRightOrNull(), 'company-1');
        },
      );

      test('finds the company id after the request times out', () async {
        answerWith('company-1');
        await resolver.resolve();

        loseSignal(SupabaseExceptionType.timeout);
        final result = await restartedApp().resolve();

        expect(result.getRightOrNull(), 'company-1');
      });

      test('asks the network again on the next call after the kept id '
          'answered, so a user back online gets a fresh answer', () async {
        answerWith('company-1');
        await resolver.resolve();
        loseSignal();
        final offlineApp = restartedApp();
        await offlineApp.resolve();

        answerWith('company-2');
        final result = await offlineApp.resolve();

        expect(result.getRightOrNull(), 'company-2');
      });

      test('has nothing to find with no signal before any sign-in', () async {
        loseSignal();

        final result = await restartedApp().resolve();

        expect(
          result.getLeftOrNull(),
          const CompanyFailure(errorType: CompanyErrorType.connectionError),
        );
      });

      test('sign-out clears it, so no signal then finds nothing', () async {
        answerWith('company-1');
        await resolver.resolve();

        await resolver.clearCache();
        loseSignal();
        final result = await restartedApp().resolve();

        expect(
          result.getLeftOrNull(),
          const CompanyFailure(errorType: CompanyErrorType.connectionError),
        );
      });

      test('a second user on the same phone gets their own id', () async {
        answerWith('company-1');
        await resolver.resolve();

        supabaseWrapper.setCurrentUser(_userTwo);
        answerWith('company-2');
        final secondUserOnline = await restartedApp().resolve();
        loseSignal();
        final secondUserOffline = await restartedApp().resolve();

        expect(secondUserOnline.getRightOrNull(), 'company-2');
        expect(secondUserOffline.getRightOrNull(), 'company-2');
      });

      test('never returns the first user\'s id to a second user with no '
          'signal', () async {
        answerWith('company-1');
        await resolver.resolve();

        supabaseWrapper.setCurrentUser(_userTwo);
        loseSignal();
        final result = await restartedApp().resolve();

        expect(
          result.getLeftOrNull(),
          const CompanyFailure(errorType: CompanyErrorType.connectionError),
        );
      });

      test('a different user signing in without a sign-out in between gets '
          'their own id, not the cached one', () async {
        answerWith('company-1');
        await resolver.resolve();

        supabaseWrapper.setCurrentUser(_userTwo);
        answerWith('company-2');
        final result = await resolver.resolve();

        expect(result.getRightOrNull(), 'company-2');
      });

      test('does not keep a missing id', () async {
        answerWith(null);

        await resolver.resolve();

        expect(await localDataSource.loadCompanyId(_userOne.id), isNull);
      });

      test('forgets a kept id once the backend says there is no company '
          'for the user', () async {
        answerWith('company-1');
        await resolver.resolve();
        answerWith(null);
        await restartedApp().resolve();

        expect(await localDataSource.loadCompanyId(_userOne.id), isNull);
        loseSignal();
        final result = await restartedApp().resolve();

        expect(result.isLeft(), isTrue);
      });

      test('does not fall back to the kept id on a server error', () async {
        answerWith('company-1');
        await resolver.resolve();

        loseSignal(SupabaseExceptionType.postgrest);
        final result = await restartedApp().resolve();

        expect(
          result.getLeftOrNull(),
          const CompanyFailure(
            errorType: CompanyErrorType.unexpectedDatabaseError,
          ),
        );
      });

      test('keeps nothing when nobody is signed in', () async {
        supabaseWrapper.setCurrentUser(null);
        answerWith('company-1');

        final result = await resolver.resolve();
        loseSignal();
        final offline = await restartedApp().resolve();

        expect(result.getRightOrNull(), 'company-1');
        expect(offline.isLeft(), isTrue);
      });

      test(
        'still returns the id when keeping it on the device fails',
        () async {
          failingWrites.writeTransactionError = StateError('disk full');
          answerWith('company-1');

          final result = await Modular.get<CurrentCompanyResolver>(
            key: 'failingWrites',
          ).resolve();

          expect(result.getRightOrNull(), 'company-1');
        },
      );

      test('sign-out still resets the session when clearing the device '
          'fails', () async {
        answerWith('company-1');
        final app = Modular.get<CurrentCompanyResolver>(key: 'failingWrites');
        await app.resolve();

        failingWrites.executeError = StateError('disk full');
        await app.clearCache();
        loseSignal();
        final result = await app.resolve();

        expect(result.isLeft(), isTrue);
      });

      test('returns the connection failure when the kept id cannot be '
          'read', () async {
        failingReads.getAllError = StateError('database locked');
        loseSignal();

        final result = await Modular.get<CurrentCompanyResolver>(
          key: 'failingReads',
        ).resolve();

        expect(
          result.getLeftOrNull(),
          const CompanyFailure(errorType: CompanyErrorType.connectionError),
        );
      });
    });
    group('resolveAfterSignIn', () {
      int callsTo(String function) => supabaseWrapper
          .getMethodCallsFor('rpc')
          .where((call) => call['functionName'] == function)
          .length;

      void answerEnsureWith(String? companyId) {
        supabaseWrapper.setRpcResponse(
          DatabaseConstants.ensureMyCompanyRpcFunction,
          companyId,
        );
      }

      void answerLookupWith(String? companyId) {
        supabaseWrapper.setRpcResponse(
          DatabaseConstants.getMyCompanyIdRpcFunction,
          companyId,
        );
      }

      test('returns the id the ensure call made for an account with no '
          'company', () async {
        answerEnsureWith('new-company');

        final result = await resolver.resolveAfterSignIn();

        expect(result.getRightOrNull(), 'new-company');
        expect(callsTo(DatabaseConstants.getMyCompanyIdRpcFunction), 0);
      });

      test('asks the server to ensure the company once, and later lookups '
          'reuse the id', () async {
        answerEnsureWith('new-company');

        await resolver.resolveAfterSignIn();
        await resolver.resolveAfterSignIn();
        final lookup = await resolver.resolve();

        expect(lookup.getRightOrNull(), 'new-company');
        expect(callsTo(DatabaseConstants.ensureMyCompanyRpcFunction), 1);
        expect(callsTo(DatabaseConstants.getMyCompanyIdRpcFunction), 0);
      });

      test('keeps the new id on the device', () async {
        answerEnsureWith('new-company');

        await resolver.resolveAfterSignIn();

        final store = Modular.get<LocalCurrentCompanyDataSource>();
        expect(await store.loadCompanyId(_userOne.id), 'new-company');
      });

      test('returns the same id when signing in again as an account that '
          'already has a company', () async {
        answerEnsureWith('existing-company');
        final first = await resolver.resolveAfterSignIn();
        await resolver.clearCache();

        final second = await resolver.resolveAfterSignIn();

        expect(first.getRightOrNull(), 'existing-company');
        expect(second.getRightOrNull(), 'existing-company');
      });

      test('returns Right(null) and does not cache it when the account has '
          'no profile yet', () async {
        answerEnsureWith(null);
        answerLookupWith('company-after-signup');

        final signIn = await resolver.resolveAfterSignIn();
        final later = await resolver.resolve();

        expect(signIn.getRightOrNull(), isNull);
        expect(signIn.isRight(), isTrue);
        expect(later.getRightOrNull(), 'company-after-signup');
      });

      test('tries the plain lookup after a failed ensure call, and returns '
          'its failure when that fails too', () async {
        supabaseWrapper.shouldThrowOnRpc = true;
        supabaseWrapper.rpcExceptionType = SupabaseExceptionType.postgrest;
        final signIn = await resolver.resolveAfterSignIn();

        expect(signIn.isLeft(), isTrue);
        expect(callsTo(DatabaseConstants.ensureMyCompanyRpcFunction), 1);
        expect(callsTo(DatabaseConstants.getMyCompanyIdRpcFunction), 1);
      });

      test(
        'returns the lookup answer when only the ensure call fails',
        () async {
          answerLookupWith('existing-company');

          final result = await resolver.resolveAfterSignIn();

          expect(result.getRightOrNull(), 'existing-company');
          expect(callsTo(DatabaseConstants.ensureMyCompanyRpcFunction), 1);
        },
      );

      test('a plain lookup started while sign-in runs gets the lookup answer '
          'when the ensure call fails', () async {
        answerLookupWith('existing-company');

        final signIn = resolver.resolveAfterSignIn();
        final lookup = resolver.resolve();

        expect((await lookup).getRightOrNull(), 'existing-company');
        expect((await signIn).getRightOrNull(), 'existing-company');
        expect(callsTo(DatabaseConstants.ensureMyCompanyRpcFunction), 1);
        expect(callsTo(DatabaseConstants.getMyCompanyIdRpcFunction), 1);
      });

      test(
        'finds the kept id with no signal after an earlier sign-in',
        () async {
          answerEnsureWith('new-company');
          await resolver.resolveAfterSignIn();
          await resolver.clearCache();
          final store = Modular.get<LocalCurrentCompanyDataSource>();
          await store.saveCompanyId(
            userId: _userOne.id,
            companyId: 'new-company',
          );

          supabaseWrapper.shouldThrowOnRpc = true;
          supabaseWrapper.rpcExceptionType = SupabaseExceptionType.socket;
          final result = await resolver.resolveAfterSignIn();

          expect(result.getRightOrNull(), 'new-company');
        },
      );

      test('a different user signing in gets their own ensure call', () async {
        answerEnsureWith('company-one');
        await resolver.resolveAfterSignIn();

        supabaseWrapper.setCurrentUser(_userTwo);
        answerEnsureWith('company-two');
        final result = await resolver.resolveAfterSignIn();

        expect(result.getRightOrNull(), 'company-two');
        expect(callsTo(DatabaseConstants.ensureMyCompanyRpcFunction), 2);
      });
    });
  });
}

class _CompanyTestAppModule extends Module {
  final FakeSupabaseWrapper supabaseWrapper;
  final FakeCurrentCompanyDatabase localDatabase;
  final FakePowerSyncDatabaseWrapper failingWrites;
  final FakePowerSyncDatabaseWrapper failingReads;

  _CompanyTestAppModule({
    required this.supabaseWrapper,
    required this.localDatabase,
    required this.failingWrites,
    required this.failingReads,
  });

  @override
  void binds(Injector i) {
    i.addSingleton<LocalCurrentCompanyDataSource>(
      () => PowerSyncLocalCurrentCompanyDataSource(database: localDatabase),
    );
    i.addSingleton<CurrentCompanyResolver>(
      () => CurrentCompanyResolverImpl(
        supabaseWrapper: supabaseWrapper,
        localDataSource: i(),
      ),
    );
    // A new instance per get: an app restart is a new resolver over the same
    // device storage.
    i.add<CurrentCompanyResolver>(
      () => CurrentCompanyResolverImpl(
        supabaseWrapper: supabaseWrapper,
        localDataSource: i(),
      ),
      key: 'restartedApp',
    );
    i.add<CurrentCompanyResolver>(
      () => CurrentCompanyResolverImpl(
        supabaseWrapper: supabaseWrapper,
        localDataSource: PowerSyncLocalCurrentCompanyDataSource(
          database: failingWrites,
        ),
      ),
      key: 'failingWrites',
    );
    i.add<CurrentCompanyResolver>(
      () => CurrentCompanyResolverImpl(
        supabaseWrapper: supabaseWrapper,
        localDataSource: PowerSyncLocalCurrentCompanyDataSource(
          database: failingReads,
        ),
      ),
      key: 'failingReads',
    );
  }
}

class _PerCallRpcWrapper extends FakeSupabaseWrapper {
  _PerCallRpcWrapper() : super(clock: FakeClockImpl());

  final List<Completer<String?>> pending = [];

  @override
  Future<T> rpc<T>(String functionName, {Map<String, dynamic>? params}) {
    final completer = Completer<String?>();
    pending.add(completer);
    return completer.future.then((value) => value as T);
  }
}

final _userOne = FakeUser(id: 'user-1', createdAt: '2026-01-01T00:00:00Z');
final _userTwo = FakeUser(id: 'user-2', createdAt: '2026-01-01T00:00:00Z');
