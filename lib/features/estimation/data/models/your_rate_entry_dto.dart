import 'package:construculator/features/estimation/domain/entities/cost_item_entity.dart';
import 'package:equatable/equatable.dart';

/// Data Transfer Object for [YourRateEntry].
///
/// Mirrors the `your_rates` table: snake_case JSON keys matching the backend
/// column names exactly (`company_id`, `item_name`, `rate_amount`,
/// `rate_currency`, `equipment_method`, `entry_label`, `saved_at`).
///
/// [toJson] deliberately returns only the writable columns — it excludes
/// `id`, `created_at`, and `updated_at`, since those are server-managed (`id`
/// is server-generated on insert; `created_at`/`updated_at` are never this
/// DTO's concern to set). This is safe to reuse for both insert and update
/// request bodies. Reading `id`/`created_at`/`updated_at` back always goes
/// through [fromJson] against the server's response, never through a value
/// this DTO itself produced.
class YourRateEntryDto extends Equatable {
  /// Unique identifier for the rate entry; server-generated.
  final String id;

  /// ID of the company this rate entry belongs to.
  final String companyId;

  /// Category of the rate entry: 'material', 'labor', or 'equipment'.
  final String category;

  /// Name of the item this rate is for.
  final String itemName;

  /// The saved rate amount.
  final double rateAmount;

  /// ISO 4217 currency code for [rateAmount].
  final String rateCurrency;

  /// Unit of measurement, matching [Unit.name]; free text on the wire, not a
  /// Postgres enum on the backend.
  final String? unit;

  /// Equipment pricing method, matching [EquipmentPricingMethod.name]:
  /// 'day' or 'job'.
  final String? equipmentMethod;

  /// Optional label distinguishing this entry within its
  /// (company, category, item name) grouping.
  final String? entryLabel;

  /// ISO 8601 timestamp for when this rate was saved, client-supplied.
  final String savedAt;

  /// ISO 8601 timestamp when the row was created; server-managed.
  final String? createdAt;

  /// ISO 8601 timestamp when the row was last updated; server-managed.
  final String? updatedAt;

  /// Creates a new [YourRateEntryDto] instance.
  const YourRateEntryDto({
    required this.id,
    required this.companyId,
    required this.category,
    required this.itemName,
    required this.rateAmount,
    required this.rateCurrency,
    required this.savedAt,
    this.unit,
    this.equipmentMethod,
    this.entryLabel,
    this.createdAt,
    this.updatedAt,
  });

  /// Creates a [YourRateEntryDto] from a JSON map returned by the database.
  factory YourRateEntryDto.fromJson(Map<String, dynamic> json) {
    return YourRateEntryDto(
      id: json['id'] as String,
      companyId: json['company_id'] as String,
      category: json['category'] as String,
      itemName: json['item_name'] as String,
      rateAmount: (json['rate_amount'] as num).toDouble(),
      rateCurrency: json['rate_currency'] as String,
      unit: json['unit'] as String?,
      equipmentMethod: json['equipment_method'] as String?,
      entryLabel: json['entry_label'] as String?,
      savedAt: json['saved_at'] as String,
      createdAt: json['created_at'] as String?,
      updatedAt: json['updated_at'] as String?,
    );
  }

  /// Converts this DTO to the writable JSON body for an insert or update
  /// request. See the class doc comment for why `id`/`created_at`/
  /// `updated_at` are deliberately excluded.
  Map<String, dynamic> toJson() => {
    'company_id': companyId,
    'category': category,
    'item_name': itemName,
    'rate_amount': rateAmount,
    'rate_currency': rateCurrency,
    'unit': unit,
    'equipment_method': equipmentMethod,
    'entry_label': entryLabel,
    'saved_at': savedAt,
  };

  /// Converts this DTO to a domain [YourRateEntry] entity.
  YourRateEntry toEntity() {
    final unit = this.unit;
    final equipmentMethod = this.equipmentMethod;
    return YourRateEntry(
      id: id,
      companyId: companyId,
      itemName: itemName,
      category: CostItemType.fromJson(category),
      rate: Money(amount: rateAmount, currency: rateCurrency),
      unit: unit != null ? Unit.fromJson(unit) : null,
      savedAt: DateTime.parse(savedAt),
      equipmentMethod: equipmentMethod != null
          ? EquipmentPricingMethod.fromJson(equipmentMethod)
          : null,
      entryLabel: entryLabel,
    );
  }

  /// Creates a [YourRateEntryDto] from a domain [YourRateEntry] entity.
  ///
  /// [entry.id] is carried through for round-tripping (e.g. after an
  /// update), but is never emitted by [toJson].
  factory YourRateEntryDto.fromEntity(YourRateEntry entry) {
    return YourRateEntryDto(
      id: entry.id,
      companyId: entry.companyId,
      category: entry.category.toJson(),
      itemName: entry.itemName,
      rateAmount: entry.rate.amount,
      rateCurrency: entry.rate.currency,
      unit: entry.unit?.toJson(),
      equipmentMethod: entry.equipmentMethod?.toJson(),
      entryLabel: entry.entryLabel,
      savedAt: entry.savedAt.toIso8601String(),
    );
  }

  @override
  List<Object?> get props => [
    id,
    companyId,
    category,
    itemName,
    rateAmount,
    rateCurrency,
    unit,
    equipmentMethod,
    entryLabel,
    savedAt,
    createdAt,
    updatedAt,
  ];
}
