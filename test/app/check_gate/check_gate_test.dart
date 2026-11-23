import 'package:construculator/app/check_gate/check_gate.dart';
import 'package:construculator/app/check_gate/check_gate_bloc.dart';
import 'package:construculator/libraries/auth/check/check_state.dart';
import 'package:construculator/libraries/auth/check/testing/fake_check_finished_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../utils/screenshot/font_loader.dart';

void main() {
  late FakeCheckFinishedState checkState;
  late int taps;

  setUp(() {
    checkState = FakeCheckFinishedState();
    taps = 0;
  });
  tearDown(() => checkState.dispose());

  CheckGateBloc buildBloc() =>
      // ignore: no_direct_instantiation, reason: the bloc is built from its fake
      CheckGateBloc(checkFinishedState: checkState);

  Widget buildGate({ThemeData? theme}) => MaterialApp(
    theme: theme ?? createTestTheme(),
    home: BlocProvider<CheckGateBloc>(
      create: (_) => buildBloc()..add(const CheckGateStarted()),
      child: CheckGate(
        child: TextButton(
          key: const Key('app_screen'),
          onPressed: () => taps++,
          child: const Text('app screen'),
        ),
      ),
    ),
  );

  group('CheckGate', () {
    testWidgets('covers the screens with the loading screen while the check '
        'runs, and keeps them built underneath', (tester) async {
      await tester.pumpWidget(buildGate());

      expect(
        find.byKey(const Key('check_gate_loading_screen')),
        findsOneWidget,
      );
      expect(find.byKey(const Key('app_screen')), findsOneWidget);
    });

    testWidgets('takes no taps on the covered screen while it is covered', (
      tester,
    ) async {
      await tester.pumpWidget(buildGate());

      await tester.tap(
        find.byKey(const Key('app_screen')),
        warnIfMissed: false,
      );
      expect(taps, 0);

      checkState.emit(const FinishedFor('user-a'));
      await tester.pump();
      await tester.tap(find.byKey(const Key('app_screen')));

      expect(taps, 1);
    });

    testWidgets('leaves the covered screen out of the semantics tree', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(buildGate());

      expect(find.bySemanticsLabel('app screen'), findsNothing);

      checkState.emit(const FinishedFor('user-a'));
      await tester.pump();

      expect(find.bySemanticsLabel('app screen'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('removes the loading screen once the check finished', (
      tester,
    ) async {
      await tester.pumpWidget(buildGate());

      checkState.emit(const FinishedFor('user-a'));
      await tester.pump();

      expect(find.byKey(const Key('check_gate_loading_screen')), findsNothing);
      expect(find.byKey(const Key('app_screen')), findsOneWidget);
    });

    testWidgets('covers the screens again when a different user arrives', (
      tester,
    ) async {
      checkState.emit(const FinishedNobodySignedIn());
      await tester.pumpWidget(buildGate());
      expect(find.byKey(const Key('check_gate_loading_screen')), findsNothing);

      checkState.emit(const Checking());
      await tester.pump();

      expect(
        find.byKey(const Key('check_gate_loading_screen')),
        findsOneWidget,
      );
    });

    testWidgets('keeps the loading screen while blocked', (tester) async {
      await tester.pumpWidget(buildGate());

      checkState.emit(const Blocked('user-a'));
      await tester.pump();

      expect(
        find.byKey(const Key('check_gate_loading_screen')),
        findsOneWidget,
      );
    });
  });
}
