import 'dart:convert';
import 'dart:io';

import 'package:equatable/equatable.dart';

import 'check.dart';

/// One place where the Dart calculator differs from the prototype on purpose:
/// a whole scenario, or one checkpoint of it, with the reason.
///
/// The list lives in `test/golden/intended_differences.json`. The owner's
/// rule (7 October 2026): "134 of 134" only means "same as the prototype",
/// not "correct", so a scenario that fails for a decided reason is listed
/// with that reason and a failing scenario always means something new.
class IntendedDifference extends Equatable {
  /// The scenario id, `S87`.
  final String scenario;

  /// The checkpoint's description, or `null` when the whole scenario is
  /// a difference (a prototype-only preference, for example).
  final String? checkpoint;

  /// Why the Dart answer differs, with the design rule it follows.
  final String reason;

  /// The decided Dart answer, evaluated in the prototype check's place: a
  /// listed checkpoint differs on purpose only while this holds, and fails
  /// otherwise, so the list can never accept a wrong answer. `null` for a
  /// whole-scenario entry, which is not replayed.
  final Check? dart;

  const IntendedDifference({
    required this.scenario,
    required this.reason,
    this.checkpoint,
    this.dart,
  });

  /// Reads one entry: `{"scenario": "S87", "checkpoint": "…", "reason": "…",
  /// "dart": {"kind": "toastIncludes", "text": "…"}}`. A checkpoint entry
  /// without its `dart` answer is a [FormatException]: the list must say
  /// what the Dart calculator shows, not only that it differs.
  factory IntendedDifference.fromJson(Map<String, Object?> json) {
    final scenario = json['scenario'] as String;
    final checkpoint = json['checkpoint'] as String?;
    final dart = json['dart'];
    if (checkpoint != null && dart is! Map) {
      throw FormatException(
        '$scenario "$checkpoint" needs the decided Dart answer under "dart"',
      );
    }
    return IntendedDifference(
      scenario: scenario,
      checkpoint: checkpoint,
      reason: json['reason'] as String,
      dart: dart is Map ? Check.fromJson(dart.cast<String, Object?>()) : null,
    );
  }

  /// Whether this entry covers the whole scenario.
  bool get wholeScenario => checkpoint == null;

  @override
  List<Object?> get props => [scenario, checkpoint, reason, dart];
}

/// The list of intended differences, looked up by scenario and checkpoint.
class IntendedDifferences {
  /// Every listed difference, whole scenarios and single checkpoints alike,
  /// in the file's order.
  final List<IntendedDifference> entries;

  const IntendedDifferences(this.entries);

  /// No differences at all.
  static const none = IntendedDifferences([]);

  /// The entry covering the whole scenario, or `null`.
  IntendedDifference? forScenario(String id) {
    for (final entry in entries) {
      if (entry.scenario == id && entry.wholeScenario) return entry;
    }
    return null;
  }

  /// The entry covering one checkpoint of a scenario, or `null`.
  IntendedDifference? forCheckpoint(String id, String description) {
    for (final entry in entries) {
      if (entry.scenario == id && entry.checkpoint == description) {
        return entry;
      }
    }
    return null;
  }
}

/// Reads `test/golden/intended_differences.json`.
IntendedDifferences loadIntendedDifferences(File file) {
  final json = jsonDecode(file.readAsStringSync()) as Map<String, Object?>;
  return IntendedDifferences([
    for (final entry in json['differences'] as List)
      IntendedDifference.fromJson((entry as Map).cast<String, Object?>()),
  ]);
}
