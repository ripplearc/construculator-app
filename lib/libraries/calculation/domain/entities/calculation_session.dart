import 'package:construculator/libraries/calculator_engine/models/quantity.dart';
import 'package:equatable/equatable.dart';

/// A banked tape: what the history stage and the Calculations tab list
/// (UX Design Doc Section 1.7, term 2.19; Full Design Doc, "Domain
/// model").
///
/// A session belongs to the phone it was banked on. It has no project and
/// no privacy flag, is never uploaded and is not shared, so the only user
/// it names is [creatorUserId], the account that was signed in when the
/// tape was banked. The tape itself — every chip, operator and bracket as
/// typed — is its own row (`calculator_tapes`, the `computation` JSON);
/// the session row keeps what a history card shows without re-running the
/// formatter: [title], the last result's [resultText] and its [result].
class CalculationSession extends Equatable {
  /// The row id.
  final String id;

  /// The account signed in when the tape was banked.
  final String creatorUserId;

  /// The name shown on the card: the one the user gave, or the one the
  /// bank made from the result.
  final String? title;

  /// The last result as it read when the tape was banked ("410.67ft²"),
  /// or `null` for a tape banked without one ("Not finished").
  final String? resultText;

  /// The last result's value, or `null` for a tape banked without one.
  final Quantity? result;

  /// When the session row was written.
  final DateTime createdAt;

  /// When the session row last changed (a rename, a restore).
  final DateTime updatedAt;

  /// When the tape was last banked into this session; what history sorts
  /// by, newest first.
  final DateTime lastCalculationAt;

  const CalculationSession({
    required this.id,
    required this.creatorUserId,
    required this.createdAt,
    required this.updatedAt,
    required this.lastCalculationAt,
    this.title,
    this.resultText,
    this.result,
  });

  /// A copy with the given fields replaced; [title], [resultText] and
  /// [result] take a function so that `null` can be set.
  CalculationSession copyWith({
    String? id,
    String? creatorUserId,
    String? Function()? title,
    String? Function()? resultText,
    Quantity? Function()? result,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? lastCalculationAt,
  }) => CalculationSession(
    id: id ?? this.id,
    creatorUserId: creatorUserId ?? this.creatorUserId,
    title: title != null ? title() : this.title,
    resultText: resultText != null ? resultText() : this.resultText,
    result: result != null ? result() : this.result,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    lastCalculationAt: lastCalculationAt ?? this.lastCalculationAt,
  );

  @override
  List<Object?> get props => [
    id,
    creatorUserId,
    title,
    resultText,
    result,
    createdAt,
    updatedAt,
    lastCalculationAt,
  ];
}
