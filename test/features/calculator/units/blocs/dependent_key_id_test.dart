import 'package:construculator/features/calculator/presentation/bloc/calculator_bloc/calculator_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ripplearc_coreui/ripplearc_coreui.dart';

void main() {
  group('DependentKeyId', () {
    test(
      'the two respelling pills are toggles, every other pill is editable',
      () {
        final toggles = DependentKeyId.values
            .where((id) => id.kind == CoreDependentKeyKind.toggle)
            .toSet();
        expect(toggles, {DependentKeyId.shownAs, DependentKeyId.across});
        for (final id in DependentKeyId.values.toSet().difference(toggles)) {
          expect(id.kind, CoreDependentKeyKind.editable, reason: id.name);
        }
      },
    );

    test('no pill is a one-time offer, which the prototype has none of', () {
      expect(
        DependentKeyId.values.map((id) => id.kind),
        isNot(contains(CoreDependentKeyKind.offer)),
      );
    });
  });
}
