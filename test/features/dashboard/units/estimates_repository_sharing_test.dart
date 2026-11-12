import 'package:async/async.dart';
import 'package:construculator/app/app_bootstrap.dart';
import 'package:construculator/features/dashboard/dashboard_module.dart';
import 'package:construculator/features/dashboard/domain/usecases/watch_recent_estimations_usecase.dart';
import 'package:construculator/features/estimation/estimation_module.dart';
import 'package:construculator/libraries/auth/auth_library_module.dart';
import 'package:construculator/libraries/estimation/data/models/cost_estimate_dto.dart';
import 'package:construculator/libraries/estimation/domain/repositories/cost_estimation_repository.dart';
import 'package:construculator/libraries/estimation/testing/fake_cost_estimates_database.dart';
import 'package:construculator/libraries/powersync/interfaces/powersync_database_wrapper.dart';
import 'package:construculator/libraries/project/interfaces/current_project_notifier.dart';
import 'package:construculator/libraries/project/testing/fake_current_project_notifier.dart';
import 'package:construculator/libraries/router/testing/router_test_module.dart';
import 'package:construculator/libraries/supabase/testing/fake_supabase_wrapper.dart';
import 'package:construculator/libraries/time/testing/clock_test_module.dart';
import 'package:construculator/libraries/time/testing/fake_clock_impl.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../libraries/estimation/helpers/estimation_test_data_map_factory.dart';
import '../../../utils/fake_app_bootstrap_factory.dart';

class _BothTabsTestModule extends Module {
  final AppBootstrap appBootstrap;

  _BothTabsTestModule(this.appBootstrap);

  @override
  List<Module> get imports => [
    RouterTestModule(),
    ClockTestModule(),
    AuthLibraryModule(appBootstrap),
    EstimationModule(appBootstrap),
    DashboardModule(appBootstrap),
  ];
}

void main() {
  late FakeCostEstimatesDatabase fakePhoneDatabase;

  setUp(() {
    fakePhoneDatabase = FakeCostEstimatesDatabase();
    final fakeSupabase = FakeSupabaseWrapper(
      clock: FakeClockImpl(DateTime.utc(2026, 6, 1)),
    );
    Modular.init(
      _BothTabsTestModule(
        FakeAppBootstrapFactory.create(supabaseWrapper: fakeSupabase),
      ),
    );
    Modular.replaceInstance<PowerSyncDatabaseWrapper>(fakePhoneDatabase);
    Modular.replaceInstance<CurrentProjectNotifier>(
      FakeCurrentProjectNotifier()..setCurrentProjectId(testProjectId),
    );
  });

  tearDown(() {
    Modular.destroy();
    fakePhoneDatabase.dispose();
  });

  test('an estimate created through the Estimates tab repository shows on the '
      'dashboard', () async {
    final recent = Modular.get<WatchRecentEstimationsUseCase>()(
      const RecentEstimationsParams(),
    );
    // ignore: no_direct_instantiation, reason: StreamQueue is a test utility from package:async
    final queue = StreamQueue(recent);
    await queue.next;

    await Modular.get<CostEstimationRepository>().createEstimation(
      CostEstimateDto.fromJson(
        EstimationTestDataMapFactory.createFakeEstimationData(
          estimateName: 'Created on the Estimates tab',
        ),
      ).toDomain(),
    );
    final shown = await queue.next;

    expect(
      shown.getRightOrNull()!.map((estimate) => estimate.estimateName),
      contains('Created on the Estimates tab'),
    );
    await queue.cancel();
  });
}
