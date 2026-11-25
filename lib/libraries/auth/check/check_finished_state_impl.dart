import 'dart:async';

import 'package:construculator/libraries/auth/check/check_state.dart';
import 'package:construculator/libraries/auth/check/interfaces/check_finished_state.dart';
import 'package:flutter/foundation.dart' show protected;
import 'package:flutter_modular/flutter_modular.dart';
import 'package:rxdart/rxdart.dart';

/// [CheckFinishedState] kept in memory.
class CheckFinishedStateImpl implements CheckFinishedState, Disposable {
  final _subject = BehaviorSubject<CheckState>.seeded(const Checking());

  @override
  CheckState get value => _subject.value;

  @override
  Stream<CheckState> get changes => _subject.stream;

  @override
  String? get activeUserId => switch (value) {
    FinishedFor(:final userId) => userId,
    _ => null,
  };

  @override
  Future<String?> whenFinished() async {
    final finished = await changes.firstWhere(
      (state) => state.isFinished,
      orElse: () => const Checking(),
    );
    return switch (finished) {
      FinishedFor(:final userId) => userId,
      _ => null,
    };
  }

  @override
  Future<bool> whenFinishedFor(String userId) async {
    final finished = await changes.firstWhere(
      (state) => state is FinishedFor && state.userId == userId,
      orElse: () => const Checking(),
    );
    return finished is FinishedFor;
  }

  @override
  void sessionEventArrived({
    required String? userId,
    required bool sessionModuleAdded,
  }) {
    final current = value;
    if (current is! FinishedFor && current is! FinishedNobodySignedIn) return;
    final isActiveUser = userId == activeUserId;
    final moduleMissing = userId != null && !sessionModuleAdded;
    if (isActiveUser && !moduleMissing) return;
    setValue(const Checking());
  }

  @override
  void settle({required CheckState result, required bool isNewestEvent}) {
    if (!isNewestEvent) return;
    if (result is Checking || result is RestartRequired) {
      throw ArgumentError.value(result, 'result', 'is not a settled value');
    }
    setValue(result);
  }

  @override
  void requireRestart() => setValue(const RestartRequired());

  /// Sets [next] unless a restart is required or the value is unchanged.
  @protected
  void setValue(CheckState next) {
    if (value is RestartRequired || next == value) return;
    _subject.add(next);
  }

  @override
  void dispose() {
    unawaited(_subject.close());
  }
}
