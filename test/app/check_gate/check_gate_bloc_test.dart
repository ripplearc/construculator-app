import 'package:bloc_test/bloc_test.dart';
import 'package:construculator/app/check_gate/check_gate_bloc.dart';
import 'package:construculator/libraries/auth/check/check_state.dart';
import 'package:construculator/libraries/auth/check/testing/fake_check_finished_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late FakeCheckFinishedState checkState;

  setUp(() => checkState = FakeCheckFinishedState());
  tearDown(() => checkState.dispose());

  CheckGateBloc buildBloc() =>
      // ignore: no_direct_instantiation, reason: the bloc under test is built from its fake
      CheckGateBloc(checkFinishedState: checkState);

  group('CheckGateBloc', () {
    test('starts holding while the check runs', () {
      expect(buildBloc().state, const CheckGateHolding());
    });

    test('starts released when the check already finished', () {
      checkState.emit(const FinishedFor('user-a'));

      expect(buildBloc().state, const CheckGateReleased());
    });

    blocTest<CheckGateBloc, CheckGateState>(
      'releases when the check finishes for a user',
      build: buildBloc,
      act: (bloc) async {
        bloc.add(const CheckGateStarted());
        await bloc.stream.first;
        checkState.emit(const FinishedFor('user-a'));
      },
      expect: () => [const CheckGateHolding(), const CheckGateReleased()],
    );

    blocTest<CheckGateBloc, CheckGateState>(
      'releases when the check finishes with nobody signed in',
      build: buildBloc,
      act: (bloc) async {
        bloc.add(const CheckGateStarted());
        await bloc.stream.first;
        checkState.emit(const FinishedNobodySignedIn());
      },
      expect: () => [const CheckGateHolding(), const CheckGateReleased()],
    );

    blocTest<CheckGateBloc, CheckGateState>(
      'holds again when a different user arrives',
      setUp: () => checkState.emit(const FinishedFor('user-a')),
      build: buildBloc,
      act: (bloc) async {
        bloc.add(const CheckGateStarted());
        await bloc.stream.first;
        checkState.emit(const Checking());
      },
      expect: () => [const CheckGateReleased(), const CheckGateHolding()],
    );

    blocTest<CheckGateBloc, CheckGateState>(
      'holds while blocked and keeps holding after a restart is required',
      setUp: () => checkState.emit(const FinishedFor('user-a')),
      build: buildBloc,
      act: (bloc) async {
        bloc.add(const CheckGateStarted());
        await bloc.stream.first;
        checkState.emit(const Blocked('user-a'));
        checkState.emit(const RestartRequired());
      },
      expect: () => [const CheckGateReleased(), const CheckGateHolding()],
    );
  });
}
