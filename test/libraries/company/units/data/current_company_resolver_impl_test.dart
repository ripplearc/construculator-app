import 'dart:async';

import 'package:construculator/app/app_bootstrap.dart';
import 'package:construculator/libraries/company/company_library_module.dart';
import 'package:construculator/libraries/company/data/current_company_resolver_impl.dart';
import 'package:construculator/libraries/company/domain/current_company_resolver.dart';
import 'package:construculator/libraries/company/domain/types/company_error_type.dart';
import 'package:construculator/libraries/errors/failures.dart';
import 'package:construculator/libraries/supabase/data/supabase_types.dart';
import 'package:construculator/libraries/supabase/database_constants.dart';
import 'package:construculator/libraries/supabase/testing/fake_supabase_wrapper.dart';
import 'package:construculator/libraries/time/testing/fake_clock_impl.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../utils/fake_app_bootstrap_factory.dart';

void main() {
  group('CurrentCompanyResolverImpl', () {
    late FakeSupabaseWrapper supabaseWrapper;
    late CurrentCompanyResolver resolver;

    setUpAll(() {
      // One wrapper/Modular.init for the whole file, not per test:
      // modular_core's Tracker caches every imported module's injector by
      // runtimeType and never clears that cache on Modular.destroy (see
      // shell_routes_test.dart for the same gotcha), so a fresh
      // FakeSupabaseWrapper per test would leave the injector still reading
      // the first test's instance.
      //
      // _CompanyTestAppModule only imports CompanyLibraryModule rather than
      // being that module itself: CompanyLibraryModule only declares
      // exportedBinds (for a real feature module to import), and
      // modular_core only runs a root module's own `binds`, not its
      // `exportedBinds` — so initializing CompanyLibraryModule directly as
      // root would leave CurrentCompanyResolver unregistered.
      supabaseWrapper = FakeSupabaseWrapper(clock: FakeClockImpl());
      Modular.init(
        _CompanyTestAppModule(
          FakeAppBootstrapFactory.create(supabaseWrapper: supabaseWrapper),
        ),
      );
      resolver = Modular.get<CurrentCompanyResolver>();
    });

    tearDownAll(() {
      Modular.destroy();
    });

    setUp(() {
      supabaseWrapper.reset();
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
      // ignore: no_direct_instantiation, reason: needs a wrapper whose rpc calls are held one by one, which Modular's shared fake cannot do
      final raceResolver = CurrentCompanyResolverImpl(
        supabaseWrapper: perCallWrapper,
      );

      final userA = raceResolver.resolve();
      raceResolver.clearCache();
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
  });
}

class _CompanyTestAppModule extends Module {
  final AppBootstrap appBootstrap;
  _CompanyTestAppModule(this.appBootstrap);

  @override
  List<Module> get imports => [CompanyLibraryModule(appBootstrap)];
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
