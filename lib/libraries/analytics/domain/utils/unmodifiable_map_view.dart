/// Defensive-copy helper for entities that expose a `Map` field publicly.
extension UnmodifiableMapView<K, V> on Map<K, V> {
  /// Returns an unmodifiable view of this map, so callers holding a
  /// reference to an entity cannot mutate its internal state after
  /// construction.
  Map<K, V> get unmodifiableView => Map.unmodifiable(this);
}
