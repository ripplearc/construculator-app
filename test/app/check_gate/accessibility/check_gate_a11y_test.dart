import 'package:construculator/app/check_gate/check_gate.dart';
import 'package:construculator/app/check_gate/check_gate_bloc.dart';
import 'package:construculator/libraries/auth/check/check_state.dart';
import 'package:construculator/libraries/auth/check/testing/fake_check_finished_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../utils/screenshot/font_loader.dart';

void main() {
  late FakeCheckFinishedState checkState;

  setUp(() => checkState = FakeCheckFinishedState());
  tearDown(() => checkState.dispose());

  CheckGateBloc buildBloc() =>
      // ignore: no_direct_instantiation, reason: the bloc is built from its fake
      CheckGateBloc(checkFinishedState: checkState);

  Widget buildGate(ThemeData theme) => MaterialApp(
    theme: theme,
    home: BlocProvider<CheckGateBloc>(
      create: (_) => buildBloc()..add(const CheckGateStarted()),
      child: const CheckGate(child: Text('app screen')),
    ),
  );

  group('CheckGate accessibility', () {
    final themes = {'light': createTestTheme, 'dark': createTestThemeDark};
    for (final entry in themes.entries) {
      testWidgets(
        'the loading screen is the only thing a screen reader finds while the '
        'check runs, in the ${entry.key} theme',
        (tester) async {
          final handle = tester.ensureSemantics();
          await tester.pumpWidget(buildGate(entry.value()));

          expect(find.bySemanticsLabel('Loading'), findsOneWidget);
          expect(find.bySemanticsLabel('app screen'), findsNothing);
          handle.dispose();
        },
      );
    }

    testWidgets('the screen is read again once the check finished', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(buildGate(createTestTheme()));

      checkState.emit(const FinishedNobodySignedIn());
      await tester.pump();

      expect(find.bySemanticsLabel('Loading'), findsNothing);
      expect(find.bySemanticsLabel('app screen'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('a gate with no screen under it still shows the loading '
        'screen', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: createTestTheme(),
          home: BlocProvider<CheckGateBloc>(
            create: (_) => buildBloc()..add(const CheckGateStarted()),
            child: const CheckGate(),
          ),
        ),
      );

      expect(
        find.byKey(const Key('check_gate_loading_screen')),
        findsOneWidget,
      );
    });
  });
}
