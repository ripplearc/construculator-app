// coverage:ignore-file
import 'package:construculator/features/estimation/domain/entities/cost_item_entity.dart';
import 'package:construculator/libraries/either/interfaces/either.dart';
import 'package:construculator/libraries/errors/failures.dart';

/// Repository interface for the contractor's personal saved-rate book
/// ("Your rates"): searching, looking up, and saving [YourRateEntry] rows.
///
/// RLS limits the rows a caller can read to the companies they belong to, so
/// a caller in more than one company reads the rows of all of them. No read
/// here narrows to one company yet. [save] writes a [YourRateEntry.companyId]
/// the backend checks against the caller's actual company membership.
///
/// Names match without regard to capital letters or extra spaces, so
/// `Mini excavator` and ` MINI  excavator ` are one name. A name saved with a
/// day rate and with a job price is two rows.
// TODO: [CA-1180](https://ripplearc.youtrack.cloud/issue/CA-1180) Add an explicit company id to the reads.
abstract class YourRatesRepository {
  /// Searches saved rate entries by item name, optionally scoped to one
  /// [category].
  ///
  /// The [query] is split into words. An entry matches when any word is in
  /// its item name, ignoring case, so `mini excavator 1.5t` finds
  /// `Mini excavator - 1.5 ton`.
  ///
  /// Passing an empty [query] returns every matching row for [category] (or
  /// every category when null), ordered by [YourRateEntry.savedAt]
  /// descending (most recently saved first). There is no separate "recents"
  /// method on this interface — this empty-query form is the primitive
  /// `YourRatesBloc` uses to build its recents list.
  ///
  /// [limit] caps the row count at the database level. Only applied when
  /// [query] is empty: a non-empty query is matched client-side against the
  /// fetched rows, and a database-level cap applied before that match would
  /// drop matches outside the row window.
  Future<Either<Failure, List<YourRateEntry>>> search(
    String query, {
    CostItemType? category,
    int? limit,
  });

  /// Looks up the rate entry for one item within one category.
  ///
  /// The name is matched without regard to capital letters or extra spaces.
  /// Multiple entries can share the same name, distinguished by
  /// [YourRateEntry.equipmentMethod] and [YourRateEntry.entryLabel], so a
  /// single-entry return is ambiguous whenever more than one row shares that
  /// name. To avoid guessing which entry the caller meant, this returns the
  /// entry only when EXACTLY ONE row matches; it returns `Right(null)` both
  /// when no row matches and when multiple rows match — callers that need to
  /// disambiguate should use [search] instead.
  Future<Either<Failure, YourRateEntry?>> getByItemName(
    String itemName,
    CostItemType category,
  );

  /// Saves [entry] into the caller's rate book, applying the collision rule
  /// for its (category, name, [YourRateEntry.equipmentMethod]) grouping:
  ///
  /// - No existing row in the grouping: inserts [entry] as a new row.
  /// - The grouping has existing rows and [entry].entryLabel is null: rejected
  ///   with an `EstimationErrorType.duplicateEntry` failure, whatever the
  ///   existing rows' labels are. An unlabeled save never replaces a saved
  ///   price silently; the caller asks the user to name the new price.
  /// - The grouping has existing rows, [entry].entryLabel is non-null, and an
  ///   existing row has the exact same label: overwrites that row's field
  ///   values.
  /// - The grouping has existing rows, [entry].entryLabel is non-null, and no
  ///   existing row has the same label: inserts [entry] as a new, distinct
  ///   row.
  ///
  /// A row of the same name with the other pricing method is not in the
  /// grouping: a Day price and a Job price for one name are two rows, and
  /// saving one never changes the other.
  ///
  /// The name is saved trimmed. A blank [YourRateEntry.entryLabel] ('' or
  /// whitespace-only) is treated exactly like `null` throughout this rule — a
  /// UI text field naturally hands back '' for an empty input, and this
  /// repository does not rely on callers to normalize that themselves.
  Future<Either<Failure, void>> save(YourRateEntry entry);
}
