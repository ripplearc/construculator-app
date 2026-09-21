// ignore_for_file: no_direct_instantiation

import 'package:bloc_test/bloc_test.dart';
import 'package:construculator/app/shell/app_shell_bloc/app_shell_bloc.dart';
import 'package:construculator/app/shell/default_tab_providers.dart';
import 'package:construculator/app/shell/shell_module.dart';
import 'package:construculator/app/shell/tab_module_manager.dart';
import 'package:construculator/libraries/analytics/testing/fake_feature_flag_repository.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../utils/fake_app_bootstrap_factory.dart';

AppShellBloc _buildBlocWithFlag(bool? calculatorEnabled) {
  final featureFlagRepository = FakeFeatureFlagRepository();
  if (calculatorEnabled != null) {
    featureFlagRepository.flagOverrides['calculator-enabled'] =
        calculatorEnabled;
  }
  final appBootstrap = FakeAppBootstrapFactory.create(
    featureFlagRepository: featureFlagRepository,
  );
  return AppShellBloc(
    // These tests only exercise flag-driven state emission, not real tab
    // loading, so NoOpTabModuleProvider stands in for both tabs — just
    // enough to satisfy TabModuleManager's minimum-tab-floor check.
    moduleLoader: TabModuleManager(
      appBootstrap,
      providers: const {
        ShellTab.calculations: NoOpTabModuleProvider(),
        ShellTab.estimates: NoOpTabModuleProvider(),
      },
    ),
    featureFlagRepository: featureFlagRepository,
  );
}

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
        const AppShellState(
          selectedTab: ShellTab.calculations,
          loadedTabs: {ShellTab.calculations},
        ),
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
        selectedTab: ShellTab.estimates,
        loadedTabs: {ShellTab.calculations, ShellTab.estimates},
      );

      final copiedState = state.copyWith();

      expect(copiedState.selectedTab, ShellTab.estimates);
      expect(copiedState.loadedTabs, {
        ShellTab.calculations,
        ShellTab.estimates,
      });
      expect(copiedState.props, [
        ShellTab.estimates,
        {ShellTab.calculations, ShellTab.estimates},
        false,
      ]);
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
        const AppShellState(
          selectedTab: ShellTab.estimates,
          loadedTabs: {ShellTab.calculations, ShellTab.estimates},
        ),
        const AppShellState(
          selectedTab: ShellTab.calculations,
          loadedTabs: {ShellTab.calculations},
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
        const AppShellState(
          selectedTab: ShellTab.estimates,
          loadedTabs: {ShellTab.calculations, ShellTab.estimates},
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

  group('calculator-enabled flag', () {
    blocTest<AppShellBloc, AppShellState>(
      'emits calculatorEnabled: true when the flag resolves true',
      build: () => _buildBlocWithFlag(true),
      expect: () => [
        const AppShellState(
          selectedTab: ShellTab.calculations,
          loadedTabs: {ShellTab.calculations},
          calculatorEnabled: true,
        ),
      ],
    );

    blocTest<AppShellBloc, AppShellState>(
      'emits calculatorEnabled: false (fails closed) when the flag is unset',
      build: () => _buildBlocWithFlag(null),
      expect: () => [
        const AppShellState(
          selectedTab: ShellTab.calculations,
          loadedTabs: {ShellTab.calculations},
        ),
      ],
    );

    blocTest<AppShellBloc, AppShellState>(
      'emits calculatorEnabled: false when the flag resolves false',
      build: () => _buildBlocWithFlag(false),
      expect: () => [
        const AppShellState(
          selectedTab: ShellTab.calculations,
          loadedTabs: {ShellTab.calculations},
        ),
      ],
    );
  });
}
