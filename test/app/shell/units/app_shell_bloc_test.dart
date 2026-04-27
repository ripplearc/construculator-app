import 'package:bloc_test/bloc_test.dart';
import 'package:construculator/app/shell/app_shell_bloc/app_shell_bloc.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppShellBloc bloc;

  setUpAll(() {
    Modular.init(_AppShellBlocTestModule());
  });

  tearDownAll(() {
    Modular.destroy();
  });

  setUp(() {
    bloc = Modular.get<AppShellBloc>();
  });

  tearDown(() async {
    await bloc.close();
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
      build: () => Modular.get<AppShellBloc>(),
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
      build: () => Modular.get<AppShellBloc>(),
      act: (bloc) => bloc.add(const AppShellTabSelected(0)),
      expect: () => <AppShellState>[],
    );
  });
}

class _AppShellBlocTestModule extends Module {
  @override
  void binds(Injector i) {
    i.add<AppShellBloc>(AppShellBloc.new);
  }
}
