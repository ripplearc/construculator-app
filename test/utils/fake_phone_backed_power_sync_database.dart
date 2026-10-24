import 'package:construculator/libraries/powersync/testing/fake_powersync_database.dart';
import 'package:sqlite3/common.dart';

import 'fake_your_rates_database.dart';

/// A [FakePowerSyncDatabase] whose reads and writes land on [phone], so the
/// upload step and the data sources see the same device tables.
class FakePhoneBackedPowerSyncDatabase extends FakePowerSyncDatabase {
  final FakeYourRatesDatabase phone;

  FakePhoneBackedPowerSyncDatabase(this.phone);

  @override
  Future<Row?> getOptional(
    String sql, [
    List<Object?> parameters = const [],
  ]) async {
    final rows = await phone.getAll(sql, parameters);
    if (rows.isEmpty) return null;
    final columns = rows.first.keys.toList();
    return ResultSet(columns, null, [
      [for (final column in columns) rows.first[column]],
    ]).first;
  }

  @override
  Future<ResultSet> execute(
    String sql, [
    List<Object?> parameters = const [],
  ]) async {
    await phone.execute(sql, parameters);
    return ResultSet(const [], null, const []);
  }
}
