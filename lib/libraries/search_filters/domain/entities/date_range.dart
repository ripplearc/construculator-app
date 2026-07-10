/// An inclusive date range, truncated to whole calendar days.
class DateRange {
  /// The first day included in the range.
  final DateTime start;

  /// The last day included in the range.
  final DateTime end;

  /// Creates a [DateRange] spanning [start] to [end], inclusive.
  const DateRange({required this.start, required this.end});

  @override
  bool operator ==(Object other) =>
      other is DateRange && other.start == start && other.end == end;

  @override
  int get hashCode => Object.hash(start, end);
}
