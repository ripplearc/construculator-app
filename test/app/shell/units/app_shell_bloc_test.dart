import 'package:bloc_test/bloc_test.dart';
import 'package:construculator/app/shell/app_shell_bloc/app_shell_bloc.dart';
import 'package:construculator/app/shell/shell_module.dart';
import 'package:construculator/app/shell/tab_module_manager.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../utils/fake_app_bootstrap_factory.dart';

void main() {
  late AppShellBloc bloc;
  late TabModuleManager tabModuleManager;

  setUp(() {
    Modular.init(ShellModule(FakeAppBootstrapFactory.create()));
    tabModuleManager = Modular.get<TabModuleManager>();
    bloc = Modular.get<AppShellBloc>();
  });

  tearDown(() async {
    await bloc.close();
    Modular.destroy();
  });

  group('AppShellBloc', () {
    blocTest<AppShellBloc, AppShellState>(
      'emits calculations tab loaded after AppShellInitialized',
      build: () => Modular.get<AppShellBloc>(),
      act: (b) => b.add(const AppShellInitialized()),
      expect: () => [
        const AppShellState(selectedTabIndex: 0, loadedTabIndexes: {0}),
      ],
      verify: (_) => expect(tabModuleManager.isLoaded(ShellTab.calculations), isTrue),
    );

    test('events expose value equality through props', () {
      expect(
        const AppShellTabSelected(ShellTab.estimates).props,
        const AppShellTabSelected(ShellTab.estimates).props,
      );
      expect(
        const AppShellTabSelected(ShellTab.estimates),
        equals(const AppShellTabSelected(ShellTab.estimates)),
      );
      expect(const AppShellInitialized().props, isEmpty);
      expect(const AppShellInitialized(), equals(const AppShellInitialized()));
    });

    test('state copyWith preserves values when parameters are omitted', () {
      const state = AppShellState(
        selectedTabIndex: 1,
        loadedTabIndexes: {0, 1},
      );

      final copiedState = state.copyWith();

      expect(copiedState.selectedTabIndex, 1);
      expect(copiedState.loadedTabIndexes, {0, 1});
      expect(copiedState.props, [1, {0, 1}]);
      expect(copiedState, equals(state));
    });

    blocTest<AppShellBloc, AppShellState>(
      'processes AppShellTabSelected then AppShellInitialized: loads the selected tab, then initializes calculations',
      build: () => bloc,
      act: (bloc) {
        bloc.add(const AppShellTabSelected(ShellTab.estimates));
        bloc.add(const AppShellInitialized());
      },
      expect: () => [
        AppShellState(
          selectedTabIndex: ShellTab.estimates.index,
          loadedTabIndexes: {ShellTab.calculations.index, ShellTab.estimates.index},
        ),
        AppShellState(
          selectedTabIndex: ShellTab.calculations.index,
          loadedTabIndexes: {ShellTab.calculations.index},
        ),
      ],
      verify: (bloc) {
        expect(tabModuleManager.isLoaded(ShellTab.calculations), isTrue);
      },
    );

    blocTest<AppShellBloc, AppShellState>(
      'updates selected tab and tracks lazy-loaded tabs',
      build: () => bloc,
      act: (bloc) {
        bloc.add(const AppShellTabSelected(ShellTab.estimates));
      },
      expect: () => [
        AppShellState(
          selectedTabIndex: ShellTab.estimates.index,
          loadedTabIndexes: {ShellTab.calculations.index, ShellTab.estimates.index},
        ),
      ],
      verify: (bloc) {
        expect(tabModuleManager.isLoaded(ShellTab.calculations), isTrue);
        expect(tabModuleManager.isLoaded(ShellTab.estimates), isTrue);
      },
    );

    blocTest<AppShellBloc, AppShellState>(
      'does not emit when selecting current tab',
      build: () => bloc,
      act: (bloc) => bloc.add(const AppShellTabSelected(ShellTab.calculations)),
      expect: () => <AppShellState>[],
    );
  });
}
