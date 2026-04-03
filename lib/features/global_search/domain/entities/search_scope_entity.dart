/// Domain-level enum identifying which domain(s) the global search operates across.
///
/// Mirrors [SearchScope] in the data layer without introducing a data-layer
/// dependency into the domain. The data layer maps to this type via
/// [SearchScope.values.byName].
enum SearchScope { dashboard, calculation, estimation, member }
