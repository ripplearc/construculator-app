import 'package:bloc_test/bloc_test.dart';
import 'package:construculator/app/shell/app_shell_bloc/app_shell_bloc.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_test/flutter_test.dart';

class _AppShellBlocTestModule extends Module {
  @override
  void binds(Injector i) {
    i.add<AppShellBloc>(AppShellBloc.new);
  }
}

void main() {
  setUp(() {
    Modular.init(_AppShellBlocTestModule());
  });

  tearDown(() {
    Modular.destroy();
  });

  group('AppShellBloc', () {
    test('initial state has tab 0 loaded', () {
      final bloc = Modular.get<AppShellBloc>();

      expect(bloc.state.selectedTabIndex, 0);
      expect(bloc.state.loadedTabIndexes, {0});

      bloc.close();
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
