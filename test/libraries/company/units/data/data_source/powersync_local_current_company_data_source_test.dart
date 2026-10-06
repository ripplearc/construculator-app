import 'package:construculator/libraries/company/data/data_source/interfaces/local_current_company_data_source.dart';
import 'package:construculator/libraries/company/data/data_source/powersync_local_current_company_data_source.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../../utils/fake_current_company_database.dart';

void main() {
  group('PowerSyncLocalCurrentCompanyDataSource', () {
    late FakeCurrentCompanyDatabase database;
    late LocalCurrentCompanyDataSource dataSource;

    setUp(() {
      database = FakeCurrentCompanyDatabase();
      Modular.init(_DataSourceTestModule(database));
      dataSource = Modular.get<LocalCurrentCompanyDataSource>();
    });

    tearDown(Modular.destroy);

    test('finds nothing before any id is saved', () async {
      expect(await dataSource.loadCompanyId('user-1'), isNull);
    });

    test('returns the id saved for the same user', () async {
      await dataSource.saveCompanyId(userId: 'user-1', companyId: 'company-1');

      expect(await dataSource.loadCompanyId('user-1'), 'company-1');
    });

    test('finds nothing for a different user than the one saved', () async {
      await dataSource.saveCompanyId(userId: 'user-1', companyId: 'company-1');

      expect(await dataSource.loadCompanyId('user-2'), isNull);
    });

    test('saving for a second user replaces the first user\'s id', () async {
      await dataSource.saveCompanyId(userId: 'user-1', companyId: 'company-1');
      await dataSource.saveCompanyId(userId: 'user-2', companyId: 'company-2');

      expect(await dataSource.loadCompanyId('user-1'), isNull);
      expect(await dataSource.loadCompanyId('user-2'), 'company-2');
    });

    test('saving twice for one user keeps only the latest id', () async {
      await dataSource.saveCompanyId(userId: 'user-1', companyId: 'company-1');
      await dataSource.saveCompanyId(userId: 'user-1', companyId: 'company-9');

      expect(await dataSource.loadCompanyId('user-1'), 'company-9');
    });

    test('the delete and insert of a save run in one transaction', () async {
      await dataSource.saveCompanyId(userId: 'user-1', companyId: 'company-1');

      expect(database.writeTransactionCallCount, 1);
      expect(database.executeCalls, hasLength(2));
    });

    test('clearing forgets the saved id', () async {
      await dataSource.saveCompanyId(userId: 'user-1', companyId: 'company-1');

      await dataSource.clearCompanyId();

      expect(await dataSource.loadCompanyId('user-1'), isNull);
    });

    test('a failed write is reported to the caller', () async {
      database.writeTransactionError = StateError('disk full');

      await expectLater(
        dataSource.saveCompanyId(userId: 'user-1', companyId: 'company-1'),
        throwsStateError,
      );
    });
  });
}

class _DataSourceTestModule extends Module {
  final FakeCurrentCompanyDatabase database;

  _DataSourceTestModule(this.database);

  @override
  void binds(Injector i) {
    i.addSingleton<LocalCurrentCompanyDataSource>(
      () => PowerSyncLocalCurrentCompanyDataSource(database: database),
    );
  }
}
