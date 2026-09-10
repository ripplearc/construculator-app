import 'package:construculator/features/dashboard/dashboard_module.dart';
import 'package:construculator/features/dashboard/presentation/bloc/dashboard_bloc/dashboard_bloc.dart';
import 'package:construculator/features/dashboard/presentation/bloc/project_dropdown_bloc/project_dropdown_bloc.dart';
import 'package:construculator/features/dashboard/presentation/bloc/recent_estimations_bloc/recent_estimations_bloc.dart';
import 'package:construculator/libraries/estimation/domain/repositories/cost_estimation_repository.dart';
import 'package:construculator/libraries/estimation/testing/fake_cost_estimation_repository.dart';
import 'package:construculator/libraries/project/domain/repositories/project_repository.dart';
import 'package:construculator/libraries/project/testing/fake_project_repository.dart';
import 'package:construculator/libraries/supabase/testing/fake_supabase_wrapper.dart';
import 'package:construculator/libraries/time/testing/fake_clock_impl.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_modular/flutter_modular.dart' hide ModularWatchExtension;
import 'package:flutter_test/flutter_test.dart';

import '../../../utils/dashboard_shell_test_module.dart';
import '../../../utils/fake_app_bootstrap_factory.dart';

void main() {
  group('DashboardModule.buildDashboardScope', () {
    setUp(() {
      final fakeSupabase = FakeSupabaseWrapper(clock: FakeClockImpl());
      Modular.init(
        DashboardShellTestModule(
          FakeAppBootstrapFactory.create(supabaseWrapper: fakeSupabase),
        ),
      );
      Modular.replaceInstance<ProjectRepository>(FakeProjectRepository());
      Modular.replaceInstance<CostEstimationRepository>(
        FakeCostEstimationRepository(),
      );
    });

    tearDown(Modular.destroy);

    Future<BuildContext> pumpScope(WidgetTester tester) async {
      late BuildContext childContext;
      await tester.pumpWidget(
        MaterialApp(
          home: DashboardModule.buildDashboardScope(
            child: Builder(
              builder: (context) {
                childContext = context;
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
      );
      await tester.pump();
      return childContext;
    }

    testWidgets(
      'provides DashboardBloc, ProjectDropdownBloc, and RecentEstimationsBloc '
      'to the wrapped child',
      (tester) async {
        final childContext = await pumpScope(tester);

        expect(childContext.read<DashboardBloc>(), isA<DashboardBloc>());
        expect(
          childContext.read<ProjectDropdownBloc>(),
          isA<ProjectDropdownBloc>(),
        );
        expect(
          childContext.read<RecentEstimationsBloc>(),
          isA<RecentEstimationsBloc>(),
        );
      },
    );

    testWidgets(
      'shares the ProjectDropdownBloc lazy singleton by value instead of '
      'constructing a new one',
      (tester) async {
        final childContext = await pumpScope(tester);

        expect(
          childContext.read<ProjectDropdownBloc>(),
          same(Modular.get<ProjectDropdownBloc>()),
        );
      },
    );
  });
}
