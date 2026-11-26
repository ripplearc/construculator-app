import 'package:construculator/libraries/calculation/domain/entities/calculation_session.dart';
import 'package:construculator/libraries/calculator_engine/calculator_engine.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final banked = DateTime.utc(2026, 11, 25, 9, 30);
  final later = DateTime.utc(2026, 11, 25, 10);

  CalculationSession session({Quantity? result, String? resultText}) =>
      CalculationSession(
        id: 'session-1',
        creatorUserId: 'user-1',
        title: 'Drywall for the hall',
        resultText: resultText,
        result: result,
        createdAt: banked,
        updatedAt: later,
        lastCalculationAt: later,
      );

  group('CalculationSession', () {
    test('two sessions alike in every field are equal, and one banked '
        'without a result differs from one banked with it', () {
      expect(session(), session());
      expect(
        session(result: const Scalar(2), resultText: '2'),
        session(result: const Scalar(2), resultText: '2'),
      );
      expect(session(), isNot(session(result: const Scalar(2))));
      expect(session(), isNot(session(resultText: '2')));
      expect(
        session(result: const Scalar(2)),
        isNot(session(result: const Scalar(3))),
      );
    });

    test('copyWith with nothing given is equal to the original', () {
      final full = session(result: const Scalar(2), resultText: '2');
      expect(full.copyWith(), full);
      expect(session().copyWith(), session());
    });

    test('copyWith can clear the title, text and result, and set them', () {
      final full = session(result: const Scalar(2), resultText: '2');
      final cleared = full.copyWith(
        title: () => null,
        resultText: () => null,
        result: () => null,
      );
      expect(cleared.title, isNull);
      expect(cleared.resultText, isNull);
      expect(cleared.result, isNull);
      expect(cleared.id, full.id);
      expect(cleared.createdAt, full.createdAt);
      expect(full.copyWith(title: () => 'Hall').title, 'Hall');
      expect(
        session().copyWith(result: () => const Scalar(5)).result,
        const Scalar(5),
      );
      expect(
        full.copyWith(updatedAt: later.add(const Duration(hours: 1))).updatedAt,
        later.add(const Duration(hours: 1)),
      );
    });
  });
}
