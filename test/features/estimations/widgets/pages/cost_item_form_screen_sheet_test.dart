import 'package:construculator/features/estimation/domain/entities/cost_item_entity.dart';
import 'package:construculator/features/estimation/presentation/pages/cost_item_form_screen.dart';
import 'package:construculator/libraries/router/testing/fake_router.dart';
import 'package:construculator/libraries/time/testing/fake_clock_impl.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ripplearc_coreui/ripplearc_coreui.dart';

void main() {
  group('CostItemFormScreen as a sheet', () {
    testWidgets('fails loudly when built without the estimate it adds to', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: CoreTheme.light(),
          home: CostItemFormScreen(
            type: CostItemType.equipment,
            estimationId: 'estimate-1',
            router: FakeAppRouter(),
            yourRatesBlocFactory: () => throw UnimplementedError(),
            clock: FakeClockImpl(),
            presentAsSheet: true,
          ),
        ),
      );

      expect(tester.takeException(), isA<ArgumentError>());
    });
  });
}
