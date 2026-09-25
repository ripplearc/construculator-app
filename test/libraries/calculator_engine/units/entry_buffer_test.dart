import 'package:construculator/libraries/calculator_engine/calculator_engine.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  EntryBuffer changed(EntryOutcome outcome) {
    if (outcome case EntryChanged(:final buffer)) return buffer;
    throw StateError('expected the buffer to change, got $outcome');
  }

  EntryBuffer type(String keys, [EntryBuffer start = const EntryBuffer()]) {
    var buffer = start;
    for (final key in keys.split('')) {
      buffer = changed(
        key == '/' ? buffer.typeFraction() : buffer.typeDigit(key),
      );
    }
    return buffer;
  }

  group('EntryBuffer', () {
    group('typing digits', () {
      test('fills the open number and echoes it', () {
        final buffer = type('22');
        expect(buffer, const EntryBuffer([Token(digits: '22')]));
        expect(buffer.text, '22');
        expect(buffer.isOpen, isTrue);
        expect(buffer.isComplete, isFalse);
      });

      test('a leading point reads 0.', () {
        expect(type('.5').text, '0.5');
      });

      test('the tokens of a changed buffer cannot be altered from outside', () {
        final buffer = type('5');
        expect(
          () => buffer.tokens.add(const Token(digits: '9')),
          throwsUnsupportedError,
        );
        expect(buffer.text, '5');
      });

      test('a second point is refused', () {
        expect(
          type('30.4').typeDigit('.'),
          const EntryRefused(EntryRefusal.secondDecimalPoint),
        );
      });

      test('a digit after a finished token starts the next token', () {
        final width = changed(type('18').closeWith(Unit.foot));
        final compound = type('8', width);
        expect(compound.text, '18ft 8');
        expect(compound.tokens.length, 2);
      });

      test('a digit after a raised token starts a new token too', () {
        const cubic = EntryBuffer([
          Token(digits: '2511', unit: Unit.foot, power: 3),
        ]);
        expect(type('45', cubic).text, '2511ft³ 45');
      });
    });

    group('fractions', () {
      test('[/] splits the open number and digits fill the denominator', () {
        final buffer = type('7/16');
        expect(
          buffer,
          const EntryBuffer([Token(digits: '7', denominator: '16')]),
        );
        expect(buffer.text, '7/16');
      });

      test('reads 1ft 1/16in the way walkthrough 14.4 types it', () {
        final feet = changed(type('1').closeWith(Unit.foot));
        final inches = changed(type('1/16', feet).closeWith(Unit.inch));
        expect(inches.text, '1ft 1/16in');
        expect(inches.isComplete, isTrue);
      });

      test('[/] with nothing typed needs a numerator', () {
        expect(
          const EntryBuffer().typeFraction(),
          const EntryRefused(EntryRefusal.fractionNeedsNumerator),
        );
        expect(
          changed(type('18').closeWith(Unit.foot)).typeFraction(),
          const EntryRefused(EntryRefusal.fractionNeedsNumerator),
        );
      });

      test('[/] a second time must finish the fraction first', () {
        expect(
          type('7/').typeFraction(),
          const EntryRefused(EntryRefusal.fractionAlreadyOpen),
        );
      });

      test('[/] on a finished fraction goes inside a number, as 7/16 has', () {
        expect(
          type('7/16').typeFraction(),
          const EntryRefused(EntryRefusal.fractionNeedsNumerator),
        );
      });

      test('a decimal cannot take a fraction', () {
        expect(
          type('7.5').typeFraction(),
          const EntryRefused(EntryRefusal.decimalCannotTakeFraction),
        );
      });

      test('a point cannot go into a denominator', () {
        expect(
          type('7/1').typeDigit('.'),
          const EntryRefused(EntryRefusal.decimalInDenominator),
        );
      });
    });

    group('closing with a unit', () {
      test('closes the open number', () {
        final buffer = changed(type('22').closeWith(Unit.foot));
        expect(
          buffer,
          const EntryBuffer([Token(digits: '22', unit: Unit.foot)]),
        );
        expect(buffer.text, '22ft');
        expect(buffer.isComplete, isTrue);
      });

      test('inches after feet make a compound, 18ft 8in', () {
        final feet = changed(type('18').closeWith(Unit.foot));
        final compound = changed(type('8', feet).closeWith(Unit.inch));
        expect(compound.text, '18ft 8in');
      });

      test('centimetres after metres make a compound, 1m 20cm', () {
        final metres = changed(type('1').closeWith(Unit.metre));
        expect(
          changed(type('20', metres).closeWith(Unit.centimetre)).text,
          '1m 20cm',
        );
      });

      test('a unit that cannot continue the compound starts a new value', () {
        final feet = changed(type('18').closeWith(Unit.foot));
        expect(
          type('8', feet).closeWith(Unit.centimetre),
          EntrySplit(
            finished: feet,
            started: const EntryBuffer([
              Token(digits: '8', unit: Unit.centimetre),
            ]),
          ),
        );
        expect(type('8', feet).closeWith(Unit.yard), isA<EntrySplit>());
        expect(type('8', feet).closeWith(Unit.foot), isA<EntrySplit>());
        expect(type('8', feet).closeWith(Unit.pound), isA<EntrySplit>());
      });

      test('a compound never crosses systems, even stepping down', () {
        final feet = changed(type('18').closeWith(Unit.foot));
        expect(type('8', feet).closeWith(Unit.millimetre), isA<EntrySplit>());
        final metres = changed(type('1').closeWith(Unit.metre));
        expect(type('20', metres).closeWith(Unit.inch), isA<EntrySplit>());
      });

      test('a cubic value never becomes a ft-in compound', () {
        const cubic = EntryBuffer([
          Token(digits: '2511', unit: Unit.foot, power: 3),
        ]);
        expect(
          type('45', cubic).closeWith(Unit.inch),
          const EntrySplit(
            finished: cubic,
            started: EntryBuffer([Token(digits: '45', unit: Unit.inch)]),
          ),
        );
      });

      test(
        'while re-editing a tapped chip the same press is refused in place',
        () {
          final feet = changed(type('18').closeWith(Unit.foot));
          expect(
            type('8', feet).closeWith(Unit.centimetre, editing: true),
            const EntryRefused(EntryRefusal.cannotAppendUnit),
          );
        },
      );

      test('a key that takes lengths refuses a weight unit', () {
        expect(
          type('5').closeWith(Unit.pound, holdsLengthOnly: true),
          const EntryRefused(EntryRefusal.needsLength),
        );
        expect(type('5').closeWith(Unit.pound), isA<EntryChanged>());
      });

      test('while re-editing, Width 18ft 8 [Lbs] needs a length', () {
        final feet = changed(type('18').closeWith(Unit.foot));
        expect(
          type(
            '8',
            feet,
          ).closeWith(Unit.pound, editing: true, holdsLengthOnly: true),
          const EntryRefused(EntryRefusal.needsLength),
        );
      });

      test(
        'on fresh entry, Width 18ft 8 [Lbs] starts 8lbs as its own value',
        () {
          final feet = changed(type('18').closeWith(Unit.foot));
          expect(
            type('8', feet).closeWith(Unit.pound, holdsLengthOnly: true),
            EntrySplit(
              finished: feet,
              started: const EntryBuffer([
                Token(digits: '8', unit: Unit.pound),
              ]),
            ),
          );
        },
      );

      test('a fraction over zero closes but is never complete', () {
        final buffer = changed(type('7/0').closeWith(Unit.inch));
        expect(buffer.text, '7/0in');
        expect(buffer.isOpen, isFalse);
        expect(buffer.isComplete, isFalse);
      });

      test('a unit before the denominator must finish the fraction', () {
        expect(
          type('7/').closeWith(Unit.inch),
          const EntryRefused(EntryRefusal.finishTheFraction),
        );
      });

      test('a unit with no open number is not the buffer to close', () {
        expect(
          const EntryBuffer().closeWith(Unit.foot),
          const EntryRefused(EntryRefusal.nothingOpen),
        );
        expect(
          changed(type('22').closeWith(Unit.foot)).closeWith(Unit.inch),
          const EntryRefused(EntryRefusal.nothingOpen),
        );
      });
    });

    group('backspace', () {
      test('unwinds Width 18ft 8in one token at a time (S07)', () {
        final feet = changed(type('18').closeWith(Unit.foot));
        var buffer = changed(type('8', feet).closeWith(Unit.inch));
        final steps = <String>[];
        for (var i = 0; i < 5; i++) {
          buffer = changed(buffer.backspace());
          steps.add(buffer.text);
        }
        expect(steps, ['18ft 8', '18ft', '18', '1', '']);
        expect(buffer.isEmpty, isTrue);
      });

      test('unwinds the power first: in³ → in² → in', () {
        var buffer = const EntryBuffer([
          Token(digits: '2', unit: Unit.inch, power: 3),
        ]);
        buffer = changed(buffer.backspace());
        expect(buffer.text, '2in²');
        buffer = changed(buffer.backspace());
        expect(buffer.text, '2in');
        buffer = changed(buffer.backspace());
        expect(buffer.text, '2');
      });

      test('unwinds a fraction digit by digit, then the [/]', () {
        var buffer = type('7/16');
        final steps = <String>[];
        for (var i = 0; i < 4; i++) {
          buffer = changed(buffer.backspace());
          steps.add(buffer.text);
        }
        expect(steps, ['7/1', '7/', '7', '']);
      });

      test('leaves the 0 of a leading point, as the prototype does', () {
        var buffer = type('.');
        buffer = changed(buffer.backspace());
        expect(buffer.text, '0');
        buffer = changed(buffer.backspace());
        expect(buffer.isEmpty, isTrue);
      });

      test('has nothing to delete on an empty buffer', () {
        expect(
          const EntryBuffer().backspace(),
          const EntryRefused(EntryRefusal.nothingToDelete),
        );
      });
    });

    test('echoes every spelling the tape shows', () {
      const buffer = EntryBuffer([Token(digits: '12', unit: Unit.metricTon)]);
      expect(buffer.text, '12 m tons');
      expect(
        const EntryBuffer([Token(digits: '4', unit: Unit.yard, power: 2)]).text,
        '4yd²',
      );
    });

    test('outcomes compare by what they carry', () {
      final digits = int.parse('22').toString();
      expect(
        EntryChanged(EntryBuffer([Token(digits: digits)])),
        const EntryChanged(EntryBuffer([Token(digits: '22')])),
      );
      final reason = EntryRefusal.values[int.parse('0')];
      expect(
        EntryRefused(reason),
        const EntryRefused(EntryRefusal.fractionNeedsNumerator),
      );
    });

    test('is equal to another buffer with the same tokens', () {
      final digits = int.parse('22').toString();
      expect(
        EntryBuffer([Token(digits: digits)]),
        const EntryBuffer([Token(digits: '22')]),
      );
    });
  });
}
