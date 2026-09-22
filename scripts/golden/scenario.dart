import 'dart:convert';
import 'dart:io';

import 'package:equatable/equatable.dart';

import 'check.dart';

/// One step of a scenario: a key press the runner replays, or a checkpoint
/// it evaluates. The step kinds are the prototype's replay vocabulary
/// (`REPLAY.run`), kept by name so the runner can say which ones it does
/// not drive yet.
sealed class ScenarioStep extends Equatable {
  const ScenarioStep();

  /// Reads a step the export script wrote.
  factory ScenarioStep.fromJson(Map<String, Object?> json) {
    final kind = json['kind'] as String;
    return switch (kind) {
      'key' => KeyStep(json['key'] as String),
      'sheetKey' => SheetKeyStep(json['key'] as String),
      'accept' => AcceptStep(json['prefix'] as String),
      'tapChip' => TapChipStep(json['prefix'] as String),
      'toggle' => const ToggleStep(),
      'collapse' => const CollapseStep(),
      'expand' => const ExpandStep(),
      'swipe' => SwipeStep(
        json['direction'] as String,
        on: json['on'] as String?,
      ),
      'click' => ClickStep(
        json['selector'] as String,
        withText: json['withText'] as String?,
      ),
      'js' => JsStep(json['source'] as String),
      'checkpoint' => CheckpointStep(
        json['description'] as String,
        Check.fromJson((json['check'] as Map).cast<String, Object?>()),
        source: json['source'] as String,
      ),
      _ => throw FormatException('unknown scenario step kind: $kind'),
    };
  }
}

/// A keypad or function key by its `data-key` ("d:2", "unit:ft", "op:×",
/// "equals", "backspace", "fk:Length"…).
final class KeyStep extends ScenarioStep {
  /// The prototype's `data-key`.
  final String key;

  const KeyStep(this.key);

  @override
  List<Object?> get props => [key];
}

/// A key inside the open value or size sheet.
final class SheetKeyStep extends ScenarioStep {
  /// The prototype's `data-key`.
  final String key;

  const SheetKeyStep(this.key);

  @override
  List<Object?> get props => [key];
}

/// A tap on the first strip chip whose text starts with [prefix].
final class AcceptStep extends ScenarioStep {
  /// The start of the chip's text.
  final String prefix;

  const AcceptStep(this.prefix);

  @override
  List<Object?> get props => [prefix];
}

/// A tap on the first tape chip whose text starts with [prefix].
final class TapChipStep extends ScenarioStep {
  /// The start of the chip's text.
  final String prefix;

  const TapChipStep(this.prefix);

  @override
  List<Object?> get props => [prefix];
}

/// A tap on the strip's ✨/📏 toggle.
final class ToggleStep extends ScenarioStep {
  const ToggleStep();

  @override
  List<Object?> get props => const [];
}

/// Collapsing the keypad sheet.
final class CollapseStep extends ScenarioStep {
  const CollapseStep();

  @override
  List<Object?> get props => const [];
}

/// Expanding the keypad sheet.
final class ExpandStep extends ScenarioStep {
  const ExpandStep();

  @override
  List<Object?> get props => const [];
}

/// A swipe on the display.
final class SwipeStep extends ScenarioStep {
  /// "down" or "up".
  final String direction;

  /// The selector swiped on, when not the display.
  final String? on;

  const SwipeStep(this.direction, {this.on});

  @override
  List<Object?> get props => [direction, on];
}

/// A click on a DOM element, by selector and optional text.
final class ClickStep extends ScenarioStep {
  /// The CSS selector.
  final String selector;

  /// Text the element must contain, when given.
  final String? withText;

  const ClickStep(this.selector, {this.withText});

  @override
  List<Object?> get props => [selector, withText];
}

/// Arbitrary JavaScript the prototype ran (setting a preference, calling
/// render); kept as source for the runner to translate case by case.
final class JsStep extends ScenarioStep {
  /// The closure's source.
  final String source;

  const JsStep(this.source);

  @override
  List<Object?> get props => [source];
}

/// An assertion over the snapshot at this point of the scenario.
final class CheckpointStep extends ScenarioStep {
  /// What the checkpoint verifies, in the prototype's words.
  final String description;

  /// The check to evaluate.
  final Check check;

  /// The closure's source, for the failure diff.
  final String source;

  const CheckpointStep(this.description, this.check, {required this.source});

  @override
  List<Object?> get props => [description, check, source];
}

/// One prototype scenario: its id, name, key path and steps.
class Scenario extends Equatable {
  /// The prototype id ("S01").
  final String id;

  /// The category the prototype files it under.
  final String category;

  /// The scenario's name.
  final String name;

  /// The key path in words, when the prototype gives one.
  final String? keys;

  /// What the prototype says to expect, when it says.
  final String? expected;

  /// The steps, in order.
  final List<ScenarioStep> steps;

  const Scenario({
    required this.id,
    required this.category,
    required this.name,
    this.keys,
    this.expected,
    required this.steps,
  });

  /// Reads a scenario the export script wrote.
  factory Scenario.fromJson(Map<String, Object?> json) => Scenario(
    id: json['id'] as String,
    category: json['category'] as String,
    name: json['name'] as String,
    keys: json['keys'] as String?,
    expected: json['expected'] as String?,
    steps: [
      for (final step in json['steps'] as List)
        ScenarioStep.fromJson((step as Map).cast<String, Object?>()),
    ],
  );

  /// The checkpoints among the steps.
  Iterable<CheckpointStep> get checkpoints => steps.whereType<CheckpointStep>();

  @override
  List<Object?> get props => [id, category, name, keys, expected, steps];
}

/// Reads every scenario from the file the export script wrote.
List<Scenario> loadScenarios(File file) {
  final json = jsonDecode(file.readAsStringSync()) as Map<String, Object?>;
  return [
    for (final scenario in json['scenarios'] as List)
      Scenario.fromJson((scenario as Map).cast<String, Object?>()),
  ];
}
