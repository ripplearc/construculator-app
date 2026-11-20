import 'package:construculator/features/estimation/presentation/helpers/number_pad_put_back_label.dart';
import 'package:construculator/l10n/generated/app_localizations.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final l10n = lookupAppLocalizations(const Locale('en'));

  test('reads Clear for a field that was empty', () {
    expect(numberPadPutBackLabel(l10n, ''), 'Clear');
  });

  test('names the value the field held, with no unit word', () {
    expect(numberPadPutBackLabel(l10n, '25'), 'Back to 25');
    expect(numberPadPutBackLabel(l10n, '0.5'), 'Back to 0.5');
  });

  test('names a rate with its currency sign and no cents added', () {
    expect(
      numberPadPutBackLabel(l10n, '52', shown: l10n.numberPadRateValue),
      r'Back to $52',
    );
  });

  test('names a percentage with its sign', () {
    expect(
      numberPadPutBackLabel(l10n, '10', shown: (value) => '$value%'),
      'Back to 10%',
    );
  });

  test('reads Clear for an empty field even when a sign is given', () {
    expect(
      numberPadPutBackLabel(l10n, '', shown: l10n.numberPadRateValue),
      'Clear',
    );
  });
}
