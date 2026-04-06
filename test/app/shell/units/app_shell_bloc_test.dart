// ignore_for_file: no_direct_instantiation
import 'package:bloc_test/bloc_test.dart';
import 'package:construculator/app/shell/app_shell_bloc/app_shell_bloc.dart';
import 'package:construculator/app/shell/default_tab_providers.dart';
import 'package:construculator/app/shell/tab_module_manager.dart';
import 'package:construculator/libraries/supabase/testing/fake_supabase_wrapper.dart';
import 'package:construculator/libraries/time/testing/fake_clock_impl.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../utils/fake_app_bootstrap_factory.dart';

TabModuleManager _noOpLoader() {
  final clock = FakeClockImpl();
  return TabModuleManager(
    FakeAppBootstrapFactory.create(
      supabaseWrapper: FakeSupabaseWrapper(clock: clock),
    ),
    providers: {
      for (final tab in ShellTab.values) tab: const NoOpTabModuleProvider(),
    },
  );
}

void main() {
  late AppShellBloc bloc;

  setUp(() {
    Modular.init(_AppShellBlocTestModule());
    bloc = Modular.get<AppShellBloc>();
  });

  tearDown(() async {
    await bloc.close();
    Modular.destroy();
  });

  group('AppShellBloc', () {
    test('initial state has tab 0 loaded', () {
      expect(bloc.state.selectedTabIndex, 0);
      expect(bloc.state.loadedTabIndexes, {0});
    });

    test('events expose value equality through props', () {
      expect(
        const AppShellTabSelected(2).props,
        const AppShellTabSelected(2).props,
      );
      expect(
        const AppShellTabSelected(2),
        equals(const AppShellTabSelected(2)),
      );
    });

    test('state copyWith preserves values when parameters are omitted', () {
      const state = AppShellState(
        selectedTabIndex: 1,
        loadedTabIndexes: {0, 1},
      );

      final copiedState = state.copyWith();

      expect(copiedState.selectedTabIndex, 1);
      expect(copiedState.loadedTabIndexes, {0, 1});
      expect(copiedState.props, [
        1,
        {0, 1},
      ]);
      expect(copiedState, equals(state));
    });

    blocTest<AppShellBloc, AppShellState>(
      'updates selected tab and tracks lazy-loaded tabs',
      build: () => AppShellBloc(),
      act: (bloc) {
        bloc.add(const AppShellTabSelected(1));
        bloc.add(const AppShellTabSelected(3));
      },
      expect: () => [
        const AppShellState(selectedTabIndex: 1, loadedTabIndexes: {0, 1}),
        const AppShellState(selectedTabIndex: 3, loadedTabIndexes: {0, 1, 3}),
      ],
    );

    blocTest<AppShellBloc, AppShellState>(
      'does not emit when selecting current tab',
      build: () => AppShellBloc(),
      act: (bloc) => bloc.add(const AppShellTabSelected(0)),
      expect: () => <AppShellState>[],
    );
  });
}

class _AppShellBlocTestModule extends Module {
  @override
  void binds(Injector i) {
    i.add<TabModuleManager>(_noOpLoader);
    i.add<AppShellBloc>(() => AppShellBloc(moduleLoader: i.get()));
  }
}
