// ignore_for_file: no_direct_instantiation
import 'package:bloc_test/bloc_test.dart';
import 'package:construculator/app/shell/app_shell_bloc/app_shell_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppShellBloc bloc;

  setUp(() {
    bloc = AppShellBloc();
  });

  tearDown(() async {
    await bloc.close();
  });

  group('AppShellBloc', () {
    test('initial state has tab 0 loaded', () {
      expect(bloc.state.selectedTabIndex, 0);
      expect(bloc.state.loadedTabIndexes, {0});
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
