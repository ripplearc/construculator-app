// coverage:ignore-file
part of 'calculator_bloc.dart';

/// The stable ids of the five function-key groups (UX Design Doc Section 3;
/// Appendix B), in the order the keyboard shows them until the user drags
/// one to a new place in the "View all" sheet (Section 1.5). An id never
/// changes with the locale; the page names each group through the
/// localization layer.
abstract final class CalculatorGroupId {
  /// Basic geometry: Width, Length, Height, Pitch, Run, Rise, Diag, Slope.
  static const String basicGeometry = 'Basic Geometry';

  /// Shapes: Diameter, Radius, Sides, Chord, Rise, Height, Arc, ColCon.
  static const String shapes = 'Shapes';

  /// Materials: Msnry, Drywal, Footng, Fence, Qty@OC, Cost, Weight.
  static const String materials = 'Materials';

  /// Unit: bf, m, cm, mm, lbs, kg, ton, m ton.
  static const String unit = 'Unit';

  /// Trigonometry: SIN, COS, TAN, ASIN, ACOS, ATAN, D:M:S.
  static const String trigonometry = 'Trigonometry';

  /// The order of Appendix B, which the keyboard opens with.
  static const List<String> defaultOrder = [
    basicGeometry,
    shapes,
    materials,
    unit,
    trigonometry,
  ];
}
