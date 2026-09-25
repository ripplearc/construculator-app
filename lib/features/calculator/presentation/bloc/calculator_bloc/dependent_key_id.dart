// coverage:ignore-file

part of 'calculator_bloc.dart';

/// The pills the prototype shows under a result, by what they change.
///
/// The bloc names a pill by this id and the page supplies the visible
/// text from i18n, in line with the keyboard's stable key ids.
enum DependentKeyId {
  /// The on-centre spacing behind a fence or framing count.
  onCentre(CoreDependentKeyKind.editable),

  /// The sheet size behind a drywall count.
  sheetSize(CoreDependentKeyKind.editable),

  /// The piece size behind a masonry count.
  pieceSize(CoreDependentKeyKind.editable),

  /// The cross-section behind a footing volume.
  crossSection(CoreDependentKeyKind.editable),

  /// The rails per section behind a fence rail count.
  railsPerSection(CoreDependentKeyKind.editable),

  /// The unit rate behind a cost.
  rate(CoreDependentKeyKind.editable),

  /// The waste allowance behind a cost.
  waste(CoreDependentKeyKind.editable),

  /// The material density behind a weight.
  density(CoreDependentKeyKind.editable),

  /// How a pitch is spelled: in/12in, degrees or grade.
  shownAs(CoreDependentKeyKind.toggle),

  /// Which way a spacing runs across a span.
  across(CoreDependentKeyKind.toggle);

  const DependentKeyId(this.kind);

  /// The pill's visual kind: an editor opens, or the value respells in place.
  final CoreDependentKeyKind kind;
}
