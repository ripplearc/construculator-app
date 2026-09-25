/// What a value on the calculator tape measures.
///
/// Every chip is exactly one of these, and arithmetic checks dimensions at
/// every step (UX Design Doc rule 4.2): a length cannot be added to an area,
/// and pounds cannot be divided by feet. The canonical storage unit of each
/// dimension is fixed here so that nothing is rounded until it is displayed
/// (Section 6, "Precision and storage").
enum Dimension {
  /// A distance, stored exactly as a whole number of ticks of 1/64 inch so
  /// that feet-inch-fraction arithmetic never accumulates binary error.
  length,

  /// A surface, stored as the product of two tick counts (square ticks).
  area,

  /// A solid, stored in cubic feet; board feet are a spelling of it.
  volume,

  /// A mass, stored in hundredths of a pound.
  weight,

  /// A rotation, stored in decimal degrees.
  angle,

  /// A bare number: a count, a ratio or a factor.
  scalar,
}
