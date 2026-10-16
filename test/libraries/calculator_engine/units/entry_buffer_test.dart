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
      test('CA-1236: a digit past 19,999,999.99 is refused as Too large', () {
        const tooLarge = EntryRefused(EntryRefusal.tooLarge);
        final edge = type('19999999');
        expect(edge.typeDigit('9'), tooLarge);
        expect(type('.99', edge).text, '19999999.99');
        expect(type('.99', edge).typeDigit('1'), tooLarge);
        expect(type('2000000').typeDigit('0'), tooLarge);
        final bottom = type('1/9999999');
        expect(bottom.typeDigit('9'), tooLarge);
        expect(type('1/19999999').typeDigit('9'), tooLarge);
        expect(type('1/19999999').text, '1/19999999');
        expect(type('1999999').typeDigit('9'), isA<EntryChanged>());
      });

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

      test('[/] on a finished fraction wants the unit key (CA-1234)', () {
        expect(
          type('7/16').typeFraction(),
          const EntryRefused(EntryRefusal.fractionNeedsUnit),
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
        final split = type('8', feet).closeWith(Unit.pound) as EntrySplit;
        expect(
          () => split.finished.tokens.add(const Token(digits: '9')),
          throwsUnsupportedError,
        );
        expect(
          () => split.started.tokens.add(const Token(digits: '9')),
          throwsUnsupportedError,
        );
      });

      test('a zero whole part is left out: 0in 1/2 reads 1/2in', () {
        final zeroInches = changed(type('0').closeWith(Unit.inch));
        expect(
          changed(type('1/2', zeroInches).closeWith(Unit.inch)).text,
          '1/2in',
        );
        final feetAndZero = changed(
          type(
            '0',
            changed(type('5').closeWith(Unit.foot)),
          ).closeWith(Unit.inch),
        );
        expect(
          changed(type('1/2', feetAndZero).closeWith(Unit.inch)).text,
          '5ft 1/2in',
        );
        expect(zeroInches.text, '0in');
      });

      test('only [Inch] closes a fraction after whole inches as inches', () {
        final half = type('1/2', changed(type('7').closeWith(Unit.inch)));
        expect(
          half.closeWith(Unit.foot),
          const EntrySplit(
            finished: EntryBuffer([Token(digits: '7', unit: Unit.inch)]),
            started: EntryBuffer([
              Token(digits: '1', denominator: '2', unit: Unit.foot),
            ]),
          ),
        );
      });

      test('a fraction closed as inches after whole inches reads 7-1/2in', () {
        final inches = changed(type('7').closeWith(Unit.inch));
        final half = type('1/2', inches);
        expect(half.text, '7in 1/2');
        expect(changed(half.closeWith(Unit.inch)).text, '7-1/2in');
        final feet = changed(type('5').closeWith(Unit.foot));
        expect(
          changed(type('1/2', feet).closeWith(Unit.inch)).text,
          '5ft 1/2in',
        );
        final decimal = changed(type('7.5').closeWith(Unit.inch));
        expect(type('1/2', decimal).closeWith(Unit.inch), isA<EntrySplit>());
      });

      test('a part as large as the unit above it is carried up (CA-1234)', () {
        final feet = changed(type('18').closeWith(Unit.foot));
        expect(
          type('13', feet).closeWith(Unit.inch),
          const EntryCarried(
            EntryBuffer([
              Token(digits: '19', unit: Unit.foot),
              Token(digits: '1', unit: Unit.inch),
            ]),
          ),
        );
        String carried(EntryOutcome outcome) =>
            (outcome as EntryCarried).buffer.text;
        expect(carried(type('12', feet).closeWith(Unit.inch)), '19ft 0in');
        expect(carried(type('30', feet).closeWith(Unit.inch)), '20ft 6in');
        final metres = changed(type('1').closeWith(Unit.metre));
        expect(
          carried(type('100', metres).closeWith(Unit.centimetre)),
          '2m 0cm',
        );
        expect(
          carried(type('1000', metres).closeWith(Unit.millimetre)),
          '2m 0mm',
        );
        final yards = changed(type('2').closeWith(Unit.yard));
        expect(carried(type('3', yards).closeWith(Unit.foot)), '3yd 0ft');
      });

      test('the carry runs on up the ladder (CA-1234)', () {
        String carried(EntryOutcome outcome) =>
            (outcome as EntryCarried).buffer.text;
        final metres = changed(type('1').closeWith(Unit.metre));
        final centimetres = changed(
          type('95', metres).closeWith(Unit.centimetre),
        );
        expect(
          carried(type('100', centimetres).closeWith(Unit.millimetre)),
          '2m 5cm 0mm',
        );
        final yards = changed(type('2').closeWith(Unit.yard));
        final feet = changed(type('2', yards).closeWith(Unit.foot));
        expect(carried(type('24', feet).closeWith(Unit.inch)), '3yd 1ft 0in');
        expect(carried(type('13', feet).closeWith(Unit.inch)), '3yd 0ft 1in');
        final oneFoot = changed(type('1', yards).closeWith(Unit.foot));
        expect(
          carried(type('13', oneFoot).closeWith(Unit.inch)),
          '2yd 2ft 1in',
        );
      });

      test('a decimal part is carried on its whole inches', () {
        final feet = changed(type('18').closeWith(Unit.foot));
        String carried(EntryOutcome outcome) =>
            (outcome as EntryCarried).buffer.text;
        expect(carried(type('13.5', feet).closeWith(Unit.inch)), '19ft 1.5in');
        expect(
          carried(type('25.25', feet).closeWith(Unit.inch)),
          '20ft 1.25in',
        );
        expect(carried(type('12.', feet).closeWith(Unit.inch)), '19ft 0.in');
        expect(
          changed(type('11.9', feet).closeWith(Unit.inch)).text,
          '18ft 11.9in',
        );
        final metres = changed(type('1').closeWith(Unit.metre));
        expect(
          carried(type('100.5', metres).closeWith(Unit.centimetre)),
          '2m 0.5cm',
        );
      });

      test(
        'a smaller part, a fraction or a decimal above it is not carried',
        () {
          final feet = changed(type('18').closeWith(Unit.foot));
          expect(
            changed(type('11', feet).closeWith(Unit.inch)).text,
            '18ft 11in',
          );
          expect(
            changed(type('13/2', feet).closeWith(Unit.inch)).text,
            '18ft 13/2in',
          );
          final fractionFeet = changed(type('3/4').closeWith(Unit.foot));
          expect(
            changed(type('13', fractionFeet).closeWith(Unit.inch)).text,
            '3/4ft 13in',
          );
          final decimalFeet = changed(type('18.5').closeWith(Unit.foot));
          expect(
            changed(type('13', decimalFeet).closeWith(Unit.inch)).text,
            '18.5ft 13in',
          );
        },
      );

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
          const EntryRefused(EntryRefusal.tailNeedsLength),
        );
      });

      test(
        'on fresh entry too, Width 18ft 8 [Lbs] needs a length (CA-1234)',
        () {
          final feet = changed(type('18').closeWith(Unit.foot));
          final tail = type('8', feet);
          expect(
            tail.closeWith(Unit.pound, holdsLengthOnly: true),
            const EntryRefused(EntryRefusal.tailNeedsLength),
          );
          expect(
            changed(tail.closeWith(Unit.inch, holdsLengthOnly: true)).text,
            '18ft 8in',
          );
          expect(
            tail.closeWith(Unit.foot, holdsLengthOnly: true),
            isA<EntrySplit>(),
          );
        },
      );

      test(
        'a fraction right after whole inches joins the compound (CA-1235)',
        () {
          final inches = changed(
            type(
              '7',
              changed(type('5').closeWith(Unit.foot)),
            ).closeWith(Unit.inch),
          );
          final half = type('1/2', inches);
          expect(half.endsWithFractionAfterWholeInches, isTrue);
          expect(half.endsWithUnitlessFraction, isTrue);
          expect(changed(half.closeWith(Unit.inch)).text, '5ft 7-1/2in');
          for (final before in [
            changed(type('5').closeWith(Unit.foot)),
            changed(type('7.5').closeWith(Unit.inch)),
            changed(type('7/16').closeWith(Unit.inch)),
            const EntryBuffer(),
          ]) {
            final fraction = type('1/2', before);
            expect(
              fraction.endsWithFractionAfterWholeInches,
              isFalse,
              reason: before.text,
            );
            expect(
              fraction.endsWithUnitlessFraction,
              isTrue,
              reason: before.text,
            );
          }
          expect(type('1/').endsWithUnitlessFraction, isFalse);
          expect(
            changed(type('1/2').closeWith(Unit.inch)).endsWithUnitlessFraction,
            isFalse,
          );
        },
      );

      test('a zero under the line is refused as it is typed (CA-1233)', () {
        expect(
          type('7/').typeDigit('0'),
          const EntryRefused(EntryRefusal.zeroDenominator),
        );
        for (final denominator in ['10', '16', '20', '100']) {
          expect(type('7/$denominator').text, '7/$denominator');
        }
      });

      test('a fraction over zero closes but is never complete', () {
        const overZero = EntryBuffer([Token(digits: '7', denominator: '0')]);
        final buffer = changed(overZero.closeWith(Unit.inch));
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

    group('degrees, minutes and seconds (CA-1070)', () {
      EntryBuffer typeAngle(
        String keys, [
        EntryBuffer start = const EntryBuffer(),
      ]) {
        var buffer = start;
        for (final key in keys.split('')) {
          buffer = changed(
            key == ':'
                ? buffer.closeDegreesMinutesSeconds()
                : buffer.typeDigit(key, readsAngles: true),
          );
        }
        return buffer;
      }

      test('a second point re-reads the number as degrees and minutes, and '
          'the digits go on into the seconds (S85)', () {
        expect(typeAngle('23.16').text, '23.16');
        final promoted = typeAngle('23.16.');
        expect(promoted.text, "23°16'");
        expect(promoted.isDegreesMinutesSeconds, isTrue);
        expect(promoted.tokens.single.minutes, '16');
        expect(promoted.tokens.single.seconds, '');
        expect(typeAngle('23.16.45').text, '23°16\'45"');
        expect(
          typeAngle('23.16.45').tokens.single.value,
          23 + 16 / 60 + 45 / 3600,
        );
      });

      test('a second point is refused where the number cannot be an angle', () {
        expect(
          type('30.4').typeDigit('.', readsAngles: false),
          const EntryRefused(EntryRefusal.secondDecimalPoint),
        );
        final compound = changed(type('18').closeWith(Unit.foot));
        expect(
          type('8.5', compound).typeDigit('.', readsAngles: true),
          const EntryRefused(EntryRefusal.secondDecimalPoint),
        );
      });

      test('closing the minutes carries 60 and more into the degrees', () {
        expect(typeAngle('30.89.').text, "31°29'");
        expect(typeAngle('30.89.00').text, '31°29\'0"');
        expect(
          typeAngle('30.89.').tokens.single,
          const Token(
            digits: '31',
            minutes: '29',
            seconds: '',
            typedAs: '30.89',
          ),
        );
      });

      test('a trailing point re-reads as whole degrees with no minutes', () {
        expect(typeAngle('8..').text, "8°00'");
        expect(typeAngle('8..').tokens.single.value, 8);
      });

      test('the D:M:S key closes one segment per press (walkthrough 16.3)', () {
        expect(typeAngle('38:').text, '38°');
        expect(typeAngle('38:30').text, "38°30'");
        expect(typeAngle('38:30:').text, "38°30'");
        expect(typeAngle('38:30:45').text, '38°30\'45"');
        expect(typeAngle('38:30:45').tokens.single.value, 38.5125);
      });

      test('the D:M:S key on a decimal closes the minutes, and on a trailing '
          'point leaves them open', () {
        expect(typeAngle('38.3:').text, "38°03'");
        expect(typeAngle('38.3:').tokens.single.seconds, '');
        expect(typeAngle('38.:').text, '38°');
        expect(typeAngle('38.:').tokens.single.minutes, '');
      });

      test('a fourth segment is refused without eating the third (S90), and '
          'so is a third point', () {
        final full = typeAngle('38:30:45');
        expect(full.closeDegreesMinutesSeconds(), EntryChanged(full));
        expect(full.typeDigit('.', readsAngles: true), EntryChanged(full));
        final open = typeAngle('38:30:');
        expect(open.closeDegreesMinutesSeconds(), EntryChanged(open));
      });

      test('the padding is the seal (S113): closed minutes read two digits, '
          'open ones do not, seconds never', () {
        expect(typeAngle('38:5').text, "38°5'");
        expect(typeAngle('38:59').text, "38°59'");
        expect(typeAngle('38:5:').text, "38°05'");
        expect(typeAngle('38:5:9').text, '38°05\'9"');
      });

      test('seconds above 59 normalise at display', () {
        expect(typeAngle('38:30:75').text, '38°31\'15"');
        expect(typeAngle('0:0:3600').text, '1°00\'0"');
      });

      test('the seconds are rounded, not cut: 0°01\'1" is 60.999… seconds '
          'in floating point', () {
        expect(typeAngle('0:1:1').text, '0°01\'1"');
        expect(typeAngle('0:0:1').text, '0°00\'1"');
      });

      test('a point on an angle is the key: it opens the next segment, and '
          'a third one changes nothing', () {
        expect(typeAngle('38:30.45').text, '38°30\'45"');
        expect(typeAngle('38.30.45').text, '38°30\'45"');
        final full = typeAngle('38:30:45');
        expect(full.typeDigit('.', readsAngles: true), EntryChanged(full));
      });

      test('the carry runs up to 2⁵³ minutes exactly, and stops past it', () {
        // The degrees stop at the typed limit (19,999,999), so the minutes
        // segment, which has no limit, carries the total to 2⁵³.
        expect(
          typeAngle('19999999:9007198054741052:').text,
          "150119987579016°32'",
          reason: '9,007,199,254,740,992 minutes, the last exact carry',
        );
        expect(
          typeAngle('19999999:9007198054741054:').text,
          "19999999°9007198054741054'",
          reason: 'two past it: the segments are left as typed',
        );
      });

      test('one angle spells the same whether typed or computed (S113)', () {
        const formatter = QuantityFormatter();
        for (final digits in ['45.2', '12.1', '6.0', '30.89', '38.5']) {
          final entry = typeAngle('$digits:');
          final spelled = formatter.format(
            Angle(
              entry.tokens.single.value,
              spelling: AngleSpelling.degreesMinutesSeconds,
            ),
          );
          expect(entry.text, spelled, reason: digits);
        }
      });

      test('the way back: the D:M:S key keeps the typed digits, a segment '
          'digit typed or removed forgets them, reopening keeps them', () {
        final closed = typeAngle('45.2:');
        expect(closed.tokens.single.typedAs, '45.2');
        expect(typeAngle('45.2:5').tokens.single.typedAs, isNull);
        final reopened = changed(closed.backspace());
        expect(reopened.text, "45°2'");
        expect(reopened.tokens.single.typedAs, '45.2');
        final shortened = changed(reopened.backspace());
        expect(shortened.text, '45°');
        expect(shortened.tokens.single.typedAs, isNull);
        expect(
          typeAngle('38:').tokens.single.typedAs,
          isNull,
          reason: 'a whole number has one reading, so no way back',
        );
        expect(typeAngle('38.:').tokens.single.typedAs, '38.');
        expect(typeAngle('38.:3').tokens.single.typedAs, isNull);
        final reclosed = changed(
          changed(typeAngle('38.30:').backspace()).closeDegreesMinutesSeconds(),
        );
        expect(reclosed.text, "38°30'");
        expect(
          reclosed.tokens.single.typedAs,
          '38.30',
          reason: 'the key re-closes the same digits',
        );
        expect(
          const Token(digits: '38', minutes: '30', typedAs: '38.30'),
          isNot(const Token(digits: '38', minutes: '30')),
          reason: 'two tokens that differ only in the way back are not equal',
        );
      });

      test('segments past 2⁵³ minutes are left as typed', () {
        final huge = typeAngle('19999999:99999999999999999:');
        expect(huge.text, "19999999°99999999999999999'");
        expect(typeAngle('9', huge).text, '19999999°99999999999999999\'9"');
      });

      test(
        'the key needs an open number, and a fraction cannot be an angle',
        () {
          expect(
            const EntryBuffer().closeDegreesMinutesSeconds(),
            const EntryRefused(EntryRefusal.nothingOpen),
          );
          expect(
            changed(
              type('38').closeWith(Unit.foot),
            ).closeDegreesMinutesSeconds(),
            const EntryRefused(EntryRefusal.nothingOpen),
          );
          expect(
            type('7/16').closeDegreesMinutesSeconds(),
            const EntryRefused(EntryRefusal.fractionNeedsUnit),
          );
          expect(
            typeAngle('38:').typeFraction(),
            const EntryRefused(EntryRefusal.decimalCannotTakeFraction),
          );
        },
      );

      test('an angle is refused a unit: it is already an angle', () {
        expect(
          typeAngle('38:30').closeWith(Unit.foot),
          const EntryRefused(EntryRefusal.alreadyAnAngle),
        );
        expect(typeAngle('38:30').isOpen, isTrue);
        expect(typeAngle('38:30').isComplete, isFalse);
      });

      test('backspace steps back through the segments', () {
        var buffer = typeAngle('38:30:45');
        buffer = changed(buffer.backspace());
        expect(buffer.text, '38°30\'4"');
        buffer = changed(buffer.backspace());
        expect(buffer.tokens.single.seconds, '');
        buffer = changed(buffer.backspace());
        expect(buffer.tokens.single.seconds, isNull);
        expect(buffer.text, "38°30'");
        buffer = changed(buffer.backspace());
        expect(buffer.text, "38°3'");
        buffer = changed(buffer.backspace());
        expect(buffer.text, '38°');
        buffer = changed(buffer.backspace());
        expect(buffer, type('38'));
        expect(buffer.isDegreesMinutesSeconds, isFalse);
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
      expect(
        EntryCarried(EntryBuffer([Token(digits: digits)])),
        const EntryCarried(EntryBuffer([Token(digits: '22')])),
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
