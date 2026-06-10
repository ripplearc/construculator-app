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
    bloc = Modular.get<AppShellBloc>();
    tabModuleManager = Modular.get<TabModuleManager>();
  });

  tearDown(() async {
    await bloc.close();
    Modular.destroy();
  });

  group('AppShellBloc', () {
    blocTest<AppShellBloc, AppShellState>(
      'emits home tab loaded after AppShellInitialized',
      build: () => bloc,
      act: (b) => b.add(const AppShellInitialized()),
      expect: () => [
        AppShellState(
          selectedTabIndex: ShellTab.home.index,
          loadedTabIndexes: {ShellTab.home.index},
        ),
      ],
      verify: (_) => expect(tabModuleManager.isLoaded(ShellTab.home), isTrue),
    );

    test('events expose value equality through props', () {
      expect(
        const AppShellTabSelected(ShellTab.estimation).props,
        const AppShellTabSelected(ShellTab.estimation).props,
      );
      expect(
        const AppShellTabSelected(ShellTab.estimation),
        equals(const AppShellTabSelected(ShellTab.estimation)),
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
      expect(copiedState.props, [
        1,
        {0, 1},
      ]);
      expect(copiedState, equals(state));
    });

    blocTest<AppShellBloc, AppShellState>(
      'processes AppShellTabSelected then AppShellInitialized: loads the selected tab, then initializes home',
      build: () => bloc,
      act: (bloc) {
        bloc.add(const AppShellTabSelected(ShellTab.calculations));
        bloc.add(const AppShellInitialized());
      },
      expect: () => [
        AppShellState(
          selectedTabIndex: ShellTab.calculations.index,
          loadedTabIndexes: {ShellTab.home.index, ShellTab.calculations.index},
        ),
        AppShellState(
          selectedTabIndex: ShellTab.home.index,
          loadedTabIndexes: {ShellTab.home.index},
        ),
      ],
      verify: (bloc) {
        expect(tabModuleManager.isLoaded(ShellTab.home), isTrue);
      },
    );

    blocTest<AppShellBloc, AppShellState>(
      'updates selected tab and tracks lazy-loaded tabs',
      build: () => bloc,
      act: (bloc) {
        bloc.add(const AppShellTabSelected(ShellTab.calculations));
        bloc.add(const AppShellTabSelected(ShellTab.members));
      },
      expect: () => [
        AppShellState(
          selectedTabIndex: ShellTab.calculations.index,
          loadedTabIndexes: {ShellTab.home.index, ShellTab.calculations.index},
        ),
        AppShellState(
          selectedTabIndex: ShellTab.members.index,
          loadedTabIndexes: {
            ShellTab.home.index,
            ShellTab.calculations.index,
            ShellTab.members.index,
          },
        ),
      ],
      verify: (bloc) {
        expect(tabModuleManager.isLoaded(ShellTab.home), isTrue);
        expect(tabModuleManager.isLoaded(ShellTab.calculations), isTrue);
        expect(tabModuleManager.isLoaded(ShellTab.estimation), isFalse);
        expect(tabModuleManager.isLoaded(ShellTab.members), isTrue);
      },
    );

    blocTest<AppShellBloc, AppShellState>(
      'does not emit when selecting current tab',
      build: () => bloc,
      act: (bloc) => bloc.add(const AppShellTabSelected(ShellTab.home)),
      expect: () => <AppShellState>[],
    );
  });
}
