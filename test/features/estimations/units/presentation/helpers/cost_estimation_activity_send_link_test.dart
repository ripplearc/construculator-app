import 'package:construculator/features/estimation/domain/entities/cost_estimation_activity_type.dart';
import 'package:construculator/features/estimation/presentation/helpers/cost_estimation_activity_send_link.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CostEstimationActivitySendLink.opensSendScreen', () {
    const sendScreenKinds = {
      CostEstimationActivityType.costEstimationSent,
      CostEstimationActivityType.costEstimationOpened,
      CostEstimationActivityType.costEstimationApproved,
      CostEstimationActivityType.costEstimationChangesRequested,
    };

    for (final kind in sendScreenKinds) {
      test('${kind.name} opens the Send screen', () {
        expect(kind.opensSendScreen, isTrue);
      });
    }

    for (final kind in [
      CostEstimationActivityType.costEstimationSendFailed,
      CostEstimationActivityType.costEstimationRevoked,
      CostEstimationActivityType.costEstimationPdfShared,
    ]) {
      test('${kind.name} does not open the Send screen', () {
        expect(kind.opensSendScreen, isFalse);
      });
    }

    test('only the four Send screen kinds open it', () {
      final opening = CostEstimationActivityType.values
          .where((kind) => kind.opensSendScreen)
          .toSet();

      expect(opening, sendScreenKinds);
    });
  });
}
