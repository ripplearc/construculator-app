// coverage:ignore-file
import 'package:construculator/features/estimation/domain/entities/cost_item_entity.dart';
import 'package:construculator/libraries/either/interfaces/either.dart';
import 'package:construculator/libraries/errors/failures.dart';

/// Repository interface for the contractor's personal saved-rate book
/// ("Your rates"): searching, looking up, and saving [YourRateEntry] rows.
///
/// All reads are scoped by RLS to the caller's own company; no method here
/// takes an explicit company id filter for that reason. [save] is the
/// exception — it writes a [YourRateEntry.companyId] the backend checks
/// against the caller's actual company membership.
abstract class YourRatesRepository {
  /// Searches saved rate entries by case-insensitive substring match on item
  /// name, optionally scoped to one [category].
  ///
  /// Passing an empty [query] returns every matching row for [category] (or
  /// every category when null), ordered by [YourRateEntry.savedAt]
  /// descending (most recently saved first). There is no separate "recents"
  /// method on this interface — this empty-query form is the primitive
  /// `YourRatesBloc` uses to build its recents list.
  Future<Either<Failure, List<YourRateEntry>>> search(
    String query, {
    CostItemType? category,
  });

  /// Looks up the rate entry for one item within one category.
  ///
  /// Multiple entries can share the same (companyId, category, itemName)
  /// grouping, distinguished by [YourRateEntry.entryLabel], so a
  /// single-entry return is ambiguous whenever more than one row shares that
  /// grouping. To avoid guessing which entry the caller meant, this returns
  /// the entry only when EXACTLY ONE row matches; it returns `Right(null)`
  /// both when no row matches and when multiple rows match — callers that
  /// need to disambiguate a multi-row grouping should use [search] instead.
  Future<Either<Failure, YourRateEntry?>> getByItemName(
    String itemName,
    CostItemType category,
  );

  /// Saves [entry] into the caller's rate book, applying the collision rule
  /// for its (companyId, category, itemName) grouping:
  ///
  /// - No existing row in the grouping: inserts [entry] as a new row.
  /// - An existing row shares the exact same [YourRateEntry.entryLabel]
  ///   (including both being null): silently overwrites that row's field
  ///   values.
  /// - The grouping has existing rows, none sharing the same label, and
  ///   [entry].entryLabel is null: rejected with an
  ///   `EstimationErrorType.duplicateEntry` failure — an unlabeled save into
  ///   an already-populated grouping can't tell which row it should replace.
  /// - The grouping has existing rows, none sharing the same label, and
  ///   [entry].entryLabel is non-null: inserts [entry] as a new, distinct
  ///   row.
  ///
  /// A blank [YourRateEntry.entryLabel] ('' or whitespace-only) is treated
  /// exactly like `null` throughout this rule — a UI text field naturally
  /// hands back '' for an empty input, and this repository does not rely on
  /// callers to normalize that themselves.
  Future<Either<Failure, void>> save(YourRateEntry entry);
}
