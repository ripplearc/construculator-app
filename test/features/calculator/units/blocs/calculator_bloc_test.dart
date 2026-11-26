import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:construculator/features/calculator/data/models/trade_store_seeds.dart';
import 'package:construculator/features/calculator/domain/entities/trade_store_entities.dart';
import 'package:construculator/features/calculator/domain/usecases/add_material_size_usecase.dart';
import 'package:construculator/features/calculator/domain/usecases/bank_calculation_session_usecase.dart';
import 'package:construculator/features/calculator/domain/usecases/delete_calculation_session_usecase.dart';
import 'package:construculator/features/calculator/domain/usecases/delete_material_size_usecase.dart';
import 'package:construculator/features/calculator/domain/usecases/watch_trade_stores_usecase.dart';
import 'package:construculator/features/calculator/presentation/bloc/calculator_bloc/calculator_bloc.dart';
import 'package:construculator/features/calculator/presentation/formatters/calculator_label_formatter.dart';
import 'package:construculator/features/calculator/presentation/formatters/size_entry_parser.dart';
import 'package:construculator/features/calculator/testing/fake_trade_stores_repository.dart';
import 'package:construculator/l10n/generated/app_localizations_en.dart';
import 'package:construculator/libraries/calculation/domain/entities/calculation_session.dart';
import 'package:construculator/libraries/calculation/testing/fake_calculation_session_repository.dart';
import 'package:construculator/libraries/calculator_engine/calculator_engine.dart';
import 'package:construculator/libraries/either/either.dart';
import 'package:construculator/libraries/errors/calculator_error_type.dart';
import 'package:construculator/libraries/errors/failures.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ripplearc_coreui/ripplearc_coreui.dart';

// TODO: [CA-1536] Build the bloc over the real TradeStoresRepositoryImpl and
// a fake database, as the use case tests do.
// https://ripplearc.youtrack.cloud/issue/CA-1536
/// Test module that provides [CalculatorBloc] as a factory (`i.add`) over
/// the real [WatchTradeStoresUseCase] and [DeleteMaterialSizeUseCase]
/// and a fake trade-stores repository
/// showing Appendix B's defaults, as the production module wires it, so
/// each test resolves a fresh instance via `Modular.get`. History is the
/// calculation library's, so its fake stands in for it.
class _CalculatorBlocTestModule extends Module {
  final FakeTradeStoresRepository stores;
  final FakeCalculationSessionRepository history;

  _CalculatorBlocTestModule(this.stores, this.history);

  @override
  void binds(Injector i) {
    i.add<WatchTradeStoresUseCase>(
      () => WatchTradeStoresUseCase(repository: stores),
    );
    i.add<DeleteMaterialSizeUseCase>(
      () => DeleteMaterialSizeUseCase(repository: stores),
    );
    i.add<AddMaterialSizeUseCase>(
      () => AddMaterialSizeUseCase(repository: stores),
    );
    i.add<BankCalculationSessionUseCase>(
      () => BankCalculationSessionUseCase(repository: history),
    );
    i.add<DeleteCalculationSessionUseCase>(
      () => DeleteCalculationSessionUseCase(repository: history),
    );
    i.add<CalculatorBloc>(
      () => CalculatorBloc(
        tradeStores: i(),
        deleteMaterialSize: i(),
        addMaterialSize: i(),
        bankSession: i(),
        deleteSession: i(),
      ),
    );
  }
}

/// The calculation library's fake history with a gate on its writes: while
/// [gate] is set, a bank waits for it, so a test can press keys, or leave
/// the calculator, before the store has answered.
class _GatedHistory extends FakeCalculationSessionRepository {
  Completer<void>? gate;

  @override
  Future<Either<Failure, CalculationSession>> bankSession(
    Tape tape, {
    String? title,
  }) async {
    await gate?.future;
    return super.bankSession(tape, title: title);
  }
}

/// The sheet counts row 1 of [state] still offers, each with its size
/// inside the chip (term 2.10; Section 9, "One chip per stored size").
List<CalculatorSuggestion> countOffers(CalculatorState state) => [
  for (final suggestion in state.suggestions)
    if (suggestion.kind == CalculatorSuggestionKind.materialCount) suggestion,
];

void main() {
  late FakeTradeStoresRepository stores;
  late _GatedHistory history;
  late CalculatorBloc bloc;

  setUp(() {
    stores = FakeTradeStoresRepository();
    history = _GatedHistory();
    Modular.init(_CalculatorBlocTestModule(stores, history));
    bloc = Modular.get<CalculatorBloc>();
  });

  tearDown(() async {
    // leaving banks the open tape, so history outlives the bloc
    await bloc.close();
    stores.dispose();
    history.dispose();
    Modular.destroy();
  });

  /// The tape after [keys] pressed on the engine directly, the expectation
  /// every bloc test is held to: the bloc adds nothing of its own.
  Tape pressed(String keys, {Tape tape = const Tape()}) {
    var current = tape;
    for (final key in keys.split(' ')) {
      if (key.isEmpty) continue;
      final outcome = switch (key) {
        'ft' => current.pressUnit(Unit.foot),
        'in' => current.pressUnit(Unit.inch),
        'yd' => current.pressUnit(Unit.yard),
        'm' => current.pressUnit(Unit.metre),
        'lbs' => current.pressUnit(Unit.pound),
        'bf' => current.pressUnit(Unit.boardFoot),
        '/' => current.typeFraction(),
        '×' => current.pressOperator(Operator.multiply),
        '÷' => current.pressOperator(Operator.divide),
        '+' => current.pressOperator(Operator.add),
        '−' => current.pressOperator(Operator.subtract),
        '=' => current.pressEquals(),
        '%' => current.pressPercent(),
        '⌫' => current.backspace(),
        '(' => current.pressBracket(),
        '[DMS]' => current.pressDmsKey(),
        '✕' => current.clearActive(),
        '[SIN]' => current.pressTrigKey(TrigFunction.sine),
        '[COS]' => current.pressTrigKey(TrigFunction.cosine),
        '[TAN]' => current.pressTrigKey(TrigFunction.tangent),
        '[ASIN]' => current.pressTrigKey(TrigFunction.arcsine),
        '[ACOS]' => current.pressTrigKey(TrigFunction.arccosine),
        '[ATAN]' => current.pressTrigKey(TrigFunction.arctangent),
        _ when key.startsWith('tap:') => current.tapChip(
          int.parse(key.substring(4)),
        ),
        _ when key.startsWith('[') => current.pressFunctionKey(
          key.substring(1, key.length - 1),
          keyWantsUnit: !PlainNumberKeys.all.contains(
            key.substring(1, key.length - 1),
          ),
          readsDegrees: key == '[${PlainNumberKeys.pitch}]',
        ),
        _ => current.typeDigit(key),
      };
      if (outcome case TapeChanged(:final tape)) current = tape;
    }
    return current;
  }

  CalculatorState tapeState(Tape tape, {TapeNotice? notice}) =>
      CalculatorState(tape: tape, notice: notice);

  /// The tape an operator opens after the result [finished] ends on (rule
  /// 4.9): the result carried forward as a Calc chip, then [keys].
  Tape carriedForward(String finished, String keys) => pressed(
    keys,
    tape: Tape(
      chips: [
        switch (pressed(finished).chips.last) {
          ResultChip(:final value) => ResultChip(
            key: Tape.calcKey,
            value: value,
          ),
          final chip => chip,
        },
      ],
    ),
  );

  /// Appendix B's sheet sizes under [system], as the engine counts them.
  List<PieceSize> appendixBSheets([
    MeasurementSystem system = MeasurementSystem.imperial,
  ]) => [
    for (final size in TradeStoreSeeds.sizes(SizeStore.sheet, system))
      PieceSize(width: size.width, height: size.height, id: size.seed),
  ];

  /// Appendix B's stores under the system [state] renders by: what the
  /// bloc's watch brings in behind the key that put an area on the display.
  TradeStores storesOf(CalculatorState state) {
    final system = state.tape.preferences.system;
    return TradeStores(
      sheetSizes: appendixBSheets(system),
      masonrySizes: [
        for (final size in TradeStoreSeeds.sizes(SizeStore.masonry, system))
          PieceSize(width: size.width, height: size.height, id: size.seed),
      ],
    );
  }

  /// The counts of the area [state] has on screen over Appendix B's sheet
  /// sizes: what the ladder counts once the stores have answered.
  List<TradeCount> sheetCountsOf(CalculatorState state) =>
      const Trades().countsFor(
        Trade.drywall,
        state.areaForCounts!,
        appendixBSheets(state.tape.preferences.system),
      );

  group('CalculatorBloc', () {
    group('walkthrough 11.1: Length 22ft then Width 18ft 8in', () {
      blocTest<CalculatorBloc, CalculatorState>(
        'produces the engine\'s tape step by step, every key a state',
        build: () => bloc,
        act: (bloc) => bloc
          ..add(const CalculatorKeySelected('Length'))
          ..add(const CalculatorDigitPressed('2'))
          ..add(const CalculatorDigitPressed('2'))
          ..add(const CalculatorUnitSelected(Unit.foot))
          ..add(const CalculatorKeySelected('Width'))
          ..add(const CalculatorDigitPressed('1'))
          ..add(const CalculatorDigitPressed('8'))
          ..add(const CalculatorUnitSelected(Unit.foot))
          ..add(const CalculatorDigitPressed('8'))
          ..add(const CalculatorUnitSelected(Unit.inch)),
        expect: () => [
          tapeState(pressed('[Length]')),
          tapeState(pressed('[Length] 2')),
          tapeState(pressed('[Length] 2 2')),
          tapeState(pressed('[Length] 2 2 ft')),
          tapeState(pressed('[Length] 2 2 ft [Width]')),
          tapeState(pressed('[Length] 2 2 ft [Width] 1')),
          tapeState(pressed('[Length] 2 2 ft [Width] 1 8')),
          tapeState(pressed('[Length] 2 2 ft [Width] 1 8 ft')),
          tapeState(pressed('[Length] 2 2 ft [Width] 1 8 ft 8')),
          tapeState(pressed('[Length] 2 2 ft [Width] 1 8 ft 8 in')),
        ],
      );

      test('and the state reads the tape back for the display', () {
        final state = tapeState(pressed('[Length] 2 2 ft [Width] 1 8 ft 8 in'));
        expect(state.tape.beingTyped, isNotNull);
        expect(state.labelKeyId, 'Width');
        expect(state.valueText, '18ft 8in');
        expect(
          [for (final chip in state.chipsList) '${chip.label}${chip.value}'],
          ['Length22ft', 'Width18ft 8in'],
        );
        expect(state.chipsList.first.type, CoreCalculatorChipType.editable);
        expect(state.chipsList.last.type, CoreCalculatorChipType.active);
      });
    });

    group('each key reaches its tape method', () {
      blocTest<CalculatorBloc, CalculatorState>(
        'a decimal point, a fraction and an operator',
        build: () => bloc,
        act: (bloc) => bloc
          ..add(const CalculatorDigitPressed('1'))
          ..add(const CalculatorDigitPressed('.'))
          ..add(const CalculatorDigitPressed('5'))
          ..add(const CalculatorUnitSelected(Unit.foot))
          ..add(const CalculatorOperatorPressed(Operator.add))
          ..add(const CalculatorDigitPressed('1'))
          ..add(const CalculatorFractionPressed())
          ..add(const CalculatorDigitPressed('2'))
          ..add(const CalculatorUnitSelected(Unit.inch)),
        skip: 8,
        expect: () => [tapeState(pressed('1 . 5 ft + 1 / 2 in'))],
      );

      blocTest<CalculatorBloc, CalculatorState>(
        'equals lands the running total: 2ft × 3 = is Calc 6ft 0in',
        build: () => bloc,
        act: (bloc) => bloc
          ..add(const CalculatorDigitPressed('2'))
          ..add(const CalculatorUnitSelected(Unit.foot))
          ..add(const CalculatorOperatorPressed(Operator.multiply))
          ..add(const CalculatorDigitPressed('3'))
          ..add(const CalculatorEqualsPressed()),
        skip: 4,
        expect: () => [tapeState(pressed('2 ft × 3 ='))],
        verify: (bloc) {
          expect(bloc.state.labelKeyId, Tape.calcKey);
          expect(bloc.state.valueText, '6ft 0in');
          expect(bloc.state.tape.beingTyped, isNull);
          expect(
            [for (final chip in bloc.state.chipsList) chip.value],
            ['2ft', '×3', '6ft 0in'],
          );
          expect(bloc.state.chipsList.last.type, CoreCalculatorChipType.result);
        },
      );

      blocTest<CalculatorBloc, CalculatorState>(
        '⌫ removes the last token and C clears the tape',
        build: () => bloc,
        act: (bloc) => bloc
          ..add(const CalculatorDigitPressed('2'))
          ..add(const CalculatorDigitPressed('4'))
          ..add(const CalculatorControlActioned(ControlAction.delete))
          ..add(const CalculatorControlActioned(ControlAction.clearAll)),
        skip: 2,
        expect: () => [tapeState(pressed('2 4 ⌫')), CalculatorState.initial()],
      );

      blocTest<CalculatorBloc, CalculatorState>(
        'the bracket key opens a bracket and closes it, as one chip',
        build: () => bloc,
        act: (bloc) => bloc
          ..add(const CalculatorDigitPressed('2'))
          ..add(const CalculatorOperatorPressed(Operator.add))
          ..add(const CalculatorControlActioned(ControlAction.paren))
          ..add(const CalculatorDigitPressed('3'))
          ..add(const CalculatorOperatorPressed(Operator.multiply))
          ..add(const CalculatorDigitPressed('4'))
          ..add(const CalculatorControlActioned(ControlAction.paren)),
        skip: 6,
        expect: () => [tapeState(pressed('2 + ( 3 × 4 ('))],
        verify: (bloc) {
          expect(
            [for (final chip in bloc.state.chipsList) chip.value],
            ['2', '3×4'],
          );
          final bracket = bloc.state.chipsList.last;
          expect(bracket.type, CoreCalculatorChipType.bracketClosed);
          expect(bracket.factor, CoreIcons.addOperator);
          expect(
            [for (final chip in bloc.state.chipsList) chip.inert],
            [false, false],
          );
          expect(bloc.state.labelKeyId, isNull);
        },
      );

      blocTest<CalculatorBloc, CalculatorState>(
        'an open bracket reads as one with no closing parenthesis',
        build: () => bloc,
        act: (bloc) => bloc
          ..add(const CalculatorControlActioned(ControlAction.paren))
          ..add(const CalculatorDigitPressed('3')),
        skip: 1,
        expect: () => [tapeState(pressed('( 3'))],
        verify: (bloc) {
          final bracket = bloc.state.chipsList.single;
          expect(bracket.value, '3');
          expect(bracket.type, CoreCalculatorChipType.bracketOpen);
          expect(bracket.factor, isNull);
          expect(bracket.label, isNull);
        },
      );

      blocTest<CalculatorBloc, CalculatorState>(
        'typing inside a bracket reads as typing: the label and the value '
        'row read the chip inside, the tape the whole bracket',
        build: () => bloc,
        act: (bloc) => bloc
          ..add(const CalculatorDigitPressed('2'))
          ..add(const CalculatorOperatorPressed(Operator.add))
          ..add(const CalculatorControlActioned(ControlAction.paren))
          ..add(const CalculatorDigitPressed('3'))
          ..add(const CalculatorOperatorPressed(Operator.multiply))
          ..add(const CalculatorDigitPressed('4')),
        skip: 5,
        expect: () => [tapeState(pressed('2 + ( 3 × 4'))],
        verify: (bloc) {
          expect(bloc.state.tape.beingTyped, isNotNull);
          expect(bloc.state.labelKeyId, isNull);
          expect(bloc.state.valueText, '4');
          expect(
            [for (final chip in bloc.state.chipsList) chip.value],
            ['2', '3×4'],
          );
          expect(
            [for (final chip in bloc.state.chipsList) chip.type],
            [
              CoreCalculatorChipType.editable,
              CoreCalculatorChipType.bracketOpen,
            ],
          );
          expect(bloc.state.chipsList.last.factor, CoreIcons.addOperator);
        },
      );

      blocTest<CalculatorBloc, CalculatorState>(
        'the chips before an open bracket are inert until it closes (term '
        '2.22: dimmed and cannot be tapped)',
        build: () => bloc,
        act: (bloc) => bloc
          ..add(const CalculatorDigitPressed('2'))
          ..add(const CalculatorOperatorPressed(Operator.add))
          ..add(const CalculatorControlActioned(ControlAction.paren))
          ..add(const CalculatorDigitPressed('3'))
          ..add(const CalculatorControlActioned(ControlAction.paren)),
        skip: 3,
        expect: () => [
          tapeState(pressed('2 + ( 3')),
          tapeState(pressed('2 + ( 3 (')),
        ],
        verify: (bloc) {
          expect(
            [for (final chip in bloc.state.chipsList) chip.inert],
            [false, false],
          );
        },
      );

      test('while a bracket is open every chip before it is inert, and the '
          'bracket itself is not', () {
        final open = tapeState(pressed('2 + ( 3'));
        expect([for (final chip in open.chipsList) chip.inert], [true, false]);
        expect(open.chipsList.last.type, CoreCalculatorChipType.bracketOpen);
      });
    });

    group('what the tape says comes with the state', () {
      blocTest<CalculatorBloc, CalculatorState>(
        'a refused key keeps the tape and carries the refusal; the next '
        'taken key clears it',
        build: () => bloc,
        act: (bloc) => bloc
          ..add(const CalculatorEqualsPressed())
          ..add(const CalculatorDigitPressed('5')),
        expect: () => [
          const CalculatorState(
            refusal: TapeRefused(TapeRefusal.nothingToCompute),
          ),
          tapeState(pressed('5')),
        ],
      );

      blocTest<CalculatorBloc, CalculatorState>(
        'the same refusal twice in a row is one state',
        build: () => bloc,
        act: (bloc) => bloc
          ..add(const CalculatorEqualsPressed())
          ..add(const CalculatorEqualsPressed()),
        expect: () => [
          const CalculatorState(
            refusal: TapeRefused(TapeRefusal.nothingToCompute),
          ),
        ],
      );

      blocTest<CalculatorBloc, CalculatorState>(
        'a refused unit, an unfinished fraction and a zero under the fraction '
        'line each carry their own reason',
        build: () => bloc,
        act: (bloc) => bloc
          ..add(const CalculatorUnitSelected(Unit.foot))
          ..add(const CalculatorDigitPressed('1'))
          ..add(const CalculatorFractionPressed())
          ..add(const CalculatorOperatorPressed(Operator.add))
          ..add(const CalculatorDigitPressed('0')),
        expect: () => [
          const CalculatorState(
            refusal: TapeRefused(TapeRefusal.typeANumberFirst),
            refusedUnit: Unit.foot,
          ),
          tapeState(pressed('1')),
          tapeState(pressed('1 /')),
          tapeState(pressed('1 /')).copyWith(
            refusal: () => const TapeRefused(TapeRefusal.finishThisValueFirst),
            toastsRaised: 1,
          ),
          tapeState(pressed('1 /')).copyWith(
            refusal: () => const TapeEntryRefused(EntryRefusal.zeroDenominator),
            toastsRaised: 1,
          ),
        ],
      );

      blocTest<CalculatorBloc, CalculatorState>(
        'a notice rides with the change that caused it and goes with the next',
        build: () => bloc,
        act: (bloc) => bloc
          ..add(const CalculatorDigitPressed('2'))
          ..add(const CalculatorOperatorPressed(Operator.add))
          ..add(const CalculatorControlActioned(ControlAction.paren))
          ..add(const CalculatorControlActioned(ControlAction.paren))
          ..add(const CalculatorDigitPressed('3')),
        skip: 3,
        expect: () => [
          tapeState(pressed('2 +'), notice: TapeNotice.emptyBracketsRemoved),
          tapeState(pressed('2 + 3')),
        ],
      );

      blocTest<CalculatorBloc, CalculatorState>(
        'an error chip is read as its error for the label and no value',
        build: () => bloc,
        act: (bloc) => bloc
          ..add(const CalculatorDigitPressed('7'))
          ..add(const CalculatorDigitPressed('8'))
          ..add(const CalculatorKeySelected('lbs'))
          ..add(const CalculatorOperatorPressed(Operator.divide))
          ..add(const CalculatorDigitPressed('1'))
          ..add(const CalculatorDigitPressed('2'))
          ..add(const CalculatorUnitSelected(Unit.foot))
          ..add(const CalculatorEqualsPressed()),
        skip: 7,
        expect: () => [tapeState(pressed('7 8 lbs ÷ 1 2 ft ='))],
        verify: (bloc) {
          expect(bloc.state.labelKeyId, CalculationError.dimensionError.name);
          expect(bloc.state.valueText, '');
          final chip = bloc.state.chipsList.last;
          expect(chip.label, CalculationError.dimensionError.name);
          expect(chip.value, isNull);
          expect(chip.type, CoreCalculatorChipType.error);
        },
      );
    });

    group('a unit under a length-only key (Section 3, "Takes: A length")', () {
      blocTest<CalculatorBloc, CalculatorState>(
        'a weight unit from the Unit group or the unit column is refused '
        'under Width and Height, and the number stays typed for a length '
        'unit to finish',
        build: () => bloc,
        act: (bloc) => bloc
          ..add(const CalculatorKeySelected('Width'))
          ..add(const CalculatorDigitPressed('5'))
          ..add(const CalculatorKeySelected('lbs'))
          ..add(const CalculatorUnitSelected(Unit.foot))
          ..add(const CalculatorKeySelected('Height'))
          ..add(const CalculatorDigitPressed('5'))
          ..add(const CalculatorUnitSelected(Unit.kilogram)),
        skip: 2,
        expect: () => [
          tapeState(pressed('[Width] 5')).copyWith(
            refusal: () => const TapeEntryRefused(EntryRefusal.needsLength),
            refusedUnit: () => Unit.pound,
            toastsRaised: 1,
          ),
          tapeState(pressed('[Width] 5 ft')).copyWith(toastsRaised: 1),
          tapeState(pressed('[Width] 5 ft [Height]')).copyWith(toastsRaised: 1),
          tapeState(
            pressed('[Width] 5 ft [Height] 5'),
          ).copyWith(toastsRaised: 1),
          tapeState(pressed('[Width] 5 ft [Height] 5')).copyWith(
            refusal: () => const TapeEntryRefused(EntryRefusal.needsLength),
            refusedUnit: () => Unit.kilogram,
            toastsRaised: 2,
          ),
        ],
        verify: (bloc) => expect(bloc.state.valueText, '5'),
      );

      blocTest<CalculatorBloc, CalculatorState>(
        'a weight unit after a finished length under Width is refused and '
        'the tail stays typed (Width 18 [Feet] 8 [Lbs]), and a unit pressed '
        'again under Width keeps the length instead of raising it to an area',
        build: () => bloc,
        act: (bloc) => bloc
          ..add(const CalculatorKeySelected('Width'))
          ..add(const CalculatorDigitPressed('1'))
          ..add(const CalculatorDigitPressed('8'))
          ..add(const CalculatorUnitSelected(Unit.foot))
          ..add(const CalculatorDigitPressed('8'))
          ..add(const CalculatorKeySelected('lbs'))
          ..add(const CalculatorUnitSelected(Unit.inch))
          ..add(const CalculatorControlActioned(ControlAction.clearAll))
          ..add(const CalculatorKeySelected('Width'))
          ..add(const CalculatorDigitPressed('5'))
          ..add(const CalculatorUnitSelected(Unit.foot))
          ..add(const CalculatorUnitSelected(Unit.foot)),
        skip: 5,
        expect: () => [
          tapeState(pressed('[Width] 1 8 ft 8')).copyWith(
            refusal: () => const TapeEntryRefused(EntryRefusal.tailNeedsLength),
            refusedUnit: () => Unit.pound,
            toastsRaised: 1,
          ),
          tapeState(pressed('[Width] 1 8 ft 8 in')).copyWith(toastsRaised: 1),
          const CalculatorState(toastsRaised: 1),
          tapeState(pressed('[Width]')).copyWith(toastsRaised: 1),
          tapeState(pressed('[Width] 5')).copyWith(toastsRaised: 1),
          tapeState(pressed('[Width] 5 ft')).copyWith(toastsRaised: 1),
          tapeState(pressed('[Width] 5 ft')).copyWith(
            refusal: () => const TapeUnitRefused(
              UnitKeyRefused(UnitKeyRefusal.keepsLength),
            ),
            refusedUnit: () => Unit.foot,
            toastsRaised: 2,
          ),
        ],
        verify: (bloc) => expect(bloc.state.valueText, '5ft'),
      );

      blocTest<CalculatorBloc, CalculatorState>(
        'a bare number and a chip inside a bracket hold any unit: the flag '
        'is read off the chip being typed, not the key before the bracket',
        build: () => bloc,
        act: (bloc) => bloc
          ..add(const CalculatorDigitPressed('5'))
          ..add(const CalculatorKeySelected('lbs'))
          ..add(const CalculatorOperatorPressed(Operator.add))
          ..add(const CalculatorKeySelected('Width'))
          ..add(const CalculatorDigitPressed('5'))
          ..add(const CalculatorUnitSelected(Unit.foot))
          ..add(const CalculatorOperatorPressed(Operator.add))
          ..add(const CalculatorControlActioned(ControlAction.paren))
          ..add(const CalculatorDigitPressed('3'))
          ..add(const CalculatorKeySelected('lbs')),
        skip: 9,
        expect: () => [tapeState(pressed('5 lbs + [Width] 5 ft + ( 3 lbs'))],
        verify: (bloc) => expect(bloc.state.valueText, '3lbs'),
      );
    });

    group('S1a 2/2: the keys the bloc tells apart', () {
      blocTest<CalculatorBloc, CalculatorState>(
        'a trig key presses its function, after its number (38 [SIN]) or '
        'before it ([ATAN] 16)',
        build: () => bloc,
        act: (bloc) => bloc
          ..add(const CalculatorDigitPressed('3'))
          ..add(const CalculatorDigitPressed('8'))
          ..add(const CalculatorKeySelected('SIN'))
          ..add(const CalculatorControlActioned(ControlAction.clearAll))
          ..add(const CalculatorKeySelected('ATAN'))
          ..add(const CalculatorDigitPressed('1'))
          ..add(const CalculatorDigitPressed('6')),
        skip: 2,
        expect: () => [
          tapeState(pressed('3 8 [SIN]')),
          CalculatorState.initial(),
          tapeState(pressed('[ATAN]')),
          tapeState(pressed('[ATAN] 1')),
          tapeState(pressed('[ATAN] 1 6')),
          // C banked the sine tape, and its card follows the keys typed
          // while the store took it (U1)
          tapeState(pressed('[ATAN] 1 6')).copyWith(
            bankedTape: () => pressed('3 8 [SIN]'),
            bankedSessionId: () => 'session-1',
            toastsRaised: 1,
          ),
        ],
        verify: (bloc) {
          expect(bloc.state.labelKeyId, TrigFunction.arctangent.key);
          expect(bloc.state.valueText, '16');
          expect(bloc.state.tape.beingTyped, isNotNull);
        },
      );

      blocTest<CalculatorBloc, CalculatorState>(
        "the keyboard's SIN id reaches the engine's sine: 38 [SIN] answers "
        'Sine 0.615661 on the tape',
        build: () => bloc,
        act: (bloc) => bloc
          ..add(const CalculatorDigitPressed('3'))
          ..add(const CalculatorDigitPressed('8'))
          ..add(const CalculatorKeySelected('SIN')),
        skip: 2,
        expect: () => [tapeState(pressed('3 8 [SIN]'))],
        verify: (bloc) {
          expect(bloc.state.labelKeyId, TrigFunction.sine.key);
          expect(bloc.state.valueText, '0.615661');
          expect(bloc.state.tape.beingTyped, isNull);
          expect(bloc.state.chipsList.last.label, TrigFunction.sine.key);
          expect(bloc.state.chipsList.last.value, '0.615661');
        },
      );

      blocTest<CalculatorBloc, CalculatorState>(
        "the keyboard's ATAN id reaches the engine's arctangent: [ATAN] 1 6 "
        'offers Arctangent 86.42°',
        build: () => bloc,
        act: (bloc) => bloc
          ..add(const CalculatorKeySelected('ATAN'))
          ..add(const CalculatorDigitPressed('1'))
          ..add(const CalculatorDigitPressed('6')),
        skip: 2,
        expect: () => [tapeState(pressed('[ATAN] 1 6'))],
        verify: (bloc) {
          expect(bloc.state.labelKeyId, TrigFunction.arctangent.key);
          expect(bloc.state.valueText, '16');
          expect(
            bloc.state.tape.trigAnswer,
            isA<Answer>().having(
              (answer) => const QuantityFormatter().format(answer.value),
              'text',
              '86.42°',
            ),
          );
        },
      );

      blocTest<CalculatorBloc, CalculatorState>(
        'the D:M:S key types a segment: 38 [DMS] 30 [DMS] 45',
        build: () => bloc,
        act: (bloc) => bloc
          ..add(const CalculatorDigitPressed('3'))
          ..add(const CalculatorDigitPressed('8'))
          ..add(const CalculatorKeySelected('DMS'))
          ..add(const CalculatorDigitPressed('3'))
          ..add(const CalculatorDigitPressed('0'))
          ..add(const CalculatorKeySelected('DMS'))
          ..add(const CalculatorDigitPressed('4'))
          ..add(const CalculatorDigitPressed('5')),
        skip: 7,
        expect: () => [tapeState(pressed('3 8 [DMS] 3 0 [DMS] 4 5'))],
        verify: (bloc) => expect(bloc.state.valueText, '38°30\'45"'),
      );

      blocTest<CalculatorBloc, CalculatorState>(
        'Pitch, Slope and Sides take a plain number, so an operator leaves '
        'the bare number as complete',
        build: () => bloc,
        act: (bloc) => bloc
          ..add(const CalculatorKeySelected('Pitch'))
          ..add(const CalculatorDigitPressed('3'))
          ..add(const CalculatorDigitPressed('0'))
          ..add(const CalculatorOperatorPressed(Operator.add))
          ..add(const CalculatorKeySelected('Sides'))
          ..add(const CalculatorDigitPressed('6'))
          ..add(const CalculatorOperatorPressed(Operator.add)),
        skip: 3,
        expect: () => [
          tapeState(pressed('[Pitch] 3 0 +')),
          tapeState(pressed('[Pitch] 3 0 + [Sides]')),
          tapeState(pressed('[Pitch] 3 0 + [Sides] 6')),
          tapeState(pressed('[Pitch] 3 0 + [Sides] 6 +')),
        ],
        verify: (bloc) {
          expect(
            [for (final chip in bloc.state.chipsList) chip.value],
            ['30°', '+6', '+'],
          );
        },
      );

      blocTest<CalculatorBloc, CalculatorState>(
        'a length unit under Slope is refused with the tape\'s own reason',
        build: () => bloc,
        act: (bloc) => bloc
          ..add(const CalculatorKeySelected('Slope'))
          ..add(const CalculatorDigitPressed('6'))
          ..add(const CalculatorUnitSelected(Unit.foot)),
        skip: 2,
        expect: () => [
          tapeState(pressed('[Slope] 6')).copyWith(
            refusal: () => const TapeRefused(TapeRefusal.slopeTakesAGrade),
            refusedUnit: () => Unit.foot,
          ),
        ],
      );

      blocTest<CalculatorBloc, CalculatorState>(
        'R2 (review of 18 Nov, F1): Sides takes a count, so every unit under '
        'it is refused and the 6 stays: Sides 6 [Feet], a second [Feet] and '
        '[Lbs] never read 6ft, 6ft² or 6lbs',
        build: () => bloc,
        act: (bloc) => bloc
          ..add(const CalculatorKeySelected('Sides'))
          ..add(const CalculatorDigitPressed('6'))
          ..add(const CalculatorUnitSelected(Unit.foot))
          ..add(const CalculatorUnitSelected(Unit.foot))
          ..add(const CalculatorKeySelected('lbs')),
        verify: (bloc) {
          expect(bloc.state.tape, pressed('[Sides] 6'));
          expect(
            bloc.state.refusal,
            const TapeRefused(TapeRefusal.sidesTakesACount),
          );
          expect(bloc.state.valueText, '6');
        },
      );

      blocTest<CalculatorBloc, CalculatorState>(
        'Pitch holds a length only: a unit pressed again under it keeps the '
        'length instead of raising it to an area (Pitch 6 [Inch] [Inch] stays '
        'Pitch 6in), and a weight under it is refused with the number kept',
        build: () => bloc,
        act: (bloc) => bloc
          ..add(const CalculatorKeySelected('Pitch'))
          ..add(const CalculatorDigitPressed('6'))
          ..add(const CalculatorUnitSelected(Unit.inch))
          ..add(const CalculatorUnitSelected(Unit.inch))
          ..add(const CalculatorUnitSelected(Unit.foot))
          ..add(const CalculatorControlActioned(ControlAction.clearAll))
          ..add(const CalculatorKeySelected('Pitch'))
          ..add(const CalculatorDigitPressed('6'))
          ..add(const CalculatorKeySelected('lbs')),
        skip: 3,
        expect: () => [
          tapeState(pressed('[Pitch] 6 in')).copyWith(
            refusal: () => const TapeUnitRefused(
              UnitKeyRefused(UnitKeyRefusal.keepsLength),
            ),
            refusedUnit: () => Unit.inch,
            toastsRaised: 1,
          ),
          tapeState(pressed('[Pitch] 6 in ft')).copyWith(toastsRaised: 1),
          const CalculatorState(toastsRaised: 1),
          tapeState(pressed('[Pitch]')).copyWith(toastsRaised: 1),
          tapeState(pressed('[Pitch] 6')).copyWith(toastsRaised: 1),
          tapeState(pressed('[Pitch] 6')).copyWith(
            refusal: () => const TapeEntryRefused(EntryRefusal.needsLength),
            refusedUnit: () => Unit.pound,
            toastsRaised: 2,
          ),
        ],
        verify: (bloc) => expect(bloc.state.tape.active!.entry.text, '6'),
      );

      blocTest<CalculatorBloc, CalculatorState>(
        '✕ in a bracket with nothing typed in it yet is refused with its own '
        'reason, and inside it clears the chip being typed there',
        build: () => bloc,
        act: (bloc) => bloc
          ..add(const CalculatorDigitPressed('2'))
          ..add(const CalculatorOperatorPressed(Operator.add))
          ..add(const CalculatorControlActioned(ControlAction.paren))
          ..add(const CalculatorActiveValueCleared())
          ..add(const CalculatorDigitPressed('3'))
          ..add(const CalculatorActiveValueCleared())
          ..add(const CalculatorActiveValueCleared()),
        skip: 3,
        expect: () => [
          tapeState(pressed('2 + (')).copyWith(
            refusal: () => const TapeRefused(TapeRefusal.nothingTypedInGroup),
          ),
          tapeState(pressed('2 + ( 3')),
          tapeState(pressed('2 + ( 3 ✕')),
          tapeState(pressed('2 + ( 3 ✕')).copyWith(
            refusal: () => const TapeRefused(TapeRefusal.nothingTypedInGroup),
          ),
        ],
      );

      blocTest<CalculatorBloc, CalculatorState>(
        '✕ clears the value being typed and leaves the tape before it; with '
        'nothing typed in the chip it emptied, a second ✕ closes the '
        'calculator',
        build: () => bloc,
        act: (bloc) => bloc
          ..add(const CalculatorDigitPressed('2'))
          ..add(const CalculatorUnitSelected(Unit.foot))
          ..add(const CalculatorOperatorPressed(Operator.add))
          ..add(const CalculatorDigitPressed('1'))
          ..add(const CalculatorDigitPressed('8'))
          ..add(const CalculatorActiveValueCleared())
          ..add(const CalculatorEqualsPressed())
          ..add(const CalculatorActiveValueCleared()),
        skip: 5,
        expect: () => [
          tapeState(pressed('2 ft + 1 8 ✕')),
          tapeState(pressed('2 ft + 1 8 ✕')).copyWith(
            refusal: () => const TapeRefused(TapeRefusal.operatorNeedsANumber),
          ),
          tapeState(pressed('2 ft + 1 8 ✕')).copyWith(closesCalculator: true),
        ],
      );
    });

    group(
      'T1a (CA-1092): ✕ with no value in progress closes the calculator',
      () {
        blocTest<CalculatorBloc, CalculatorState>(
          'on an empty tape ✕ closes the calculator and the tape stays empty',
          build: () => bloc,
          act: (bloc) => bloc.add(const CalculatorActiveValueCleared()),
          expect: () => [const CalculatorState(closesCalculator: true)],
        );

        blocTest<CalculatorBloc, CalculatorState>(
          'after an answer ✕ closes the calculator: a result is not a value in '
          'progress',
          build: () => bloc,
          act: (bloc) => bloc
            ..add(const CalculatorDigitPressed('2'))
            ..add(const CalculatorOperatorPressed(Operator.multiply))
            ..add(const CalculatorDigitPressed('3'))
            ..add(const CalculatorEqualsPressed())
            ..add(const CalculatorActiveValueCleared()),
          skip: 4,
          expect: () => [
            tapeState(pressed('2 × 3 =')).copyWith(closesCalculator: true),
          ],
        );

        blocTest<CalculatorBloc, CalculatorState>(
          'inside an open bracket ✕ on the empty chip an operator opened is '
          'refused, not a close: 2 + (3 + ✕ 4) = is 9',
          build: () => bloc,
          act: (bloc) => bloc
            ..add(const CalculatorDigitPressed('2'))
            ..add(const CalculatorOperatorPressed(Operator.add))
            ..add(const CalculatorControlActioned(ControlAction.paren))
            ..add(const CalculatorDigitPressed('3'))
            ..add(const CalculatorOperatorPressed(Operator.add))
            ..add(const CalculatorActiveValueCleared())
            ..add(const CalculatorDigitPressed('4'))
            ..add(const CalculatorControlActioned(ControlAction.paren))
            ..add(const CalculatorEqualsPressed()),
          skip: 5,
          expect: () => [
            tapeState(pressed('2 + ( 3 +')).copyWith(
              refusal: () => const TapeRefused(TapeRefusal.nothingTypedInGroup),
            ),
            tapeState(pressed('2 + ( 3 + 4')),
            tapeState(pressed('2 + ( 3 + 4 (')),
            tapeState(pressed('2 + ( 3 + 4 ( =')),
          ],
        );

        blocTest<CalculatorBloc, CalculatorState>(
          'after ÷ 0 = the divisor is reopened with nothing typed in it, so ✕ '
          'closes the calculator, as the prototype\'s does after its error',
          build: () => bloc,
          act: (bloc) => bloc
            ..add(const CalculatorDigitPressed('5'))
            ..add(const CalculatorOperatorPressed(Operator.divide))
            ..add(const CalculatorDigitPressed('0'))
            ..add(const CalculatorEqualsPressed())
            ..add(const CalculatorActiveValueCleared()),
          skip: 4,
          expect: () => [
            tapeState(pressed('5 ÷ 0 =')).copyWith(closesCalculator: true),
          ],
        );

        blocTest<CalculatorBloc, CalculatorState>(
          'the fraction key with nothing typed is refused with the same word '
          'and closes nothing',
          build: () => bloc,
          act: (bloc) => bloc.add(const CalculatorFractionPressed()),
          expect: () => [
            const CalculatorState(
              refusal: TapeRefused(TapeRefusal.nothingBeingTyped),
            ),
          ],
        );

        blocTest<CalculatorBloc, CalculatorState>(
          'a waiting chip "…" is a value in progress: the first ✕ clears it '
          'and the tape stays open with the operator waiting again, and only '
          'a second ✕ closes the calculator (Section 1.1)',
          build: () => bloc,
          act: (bloc) => bloc
            ..add(const CalculatorDigitPressed('2'))
            ..add(const CalculatorDigitPressed('2'))
            ..add(const CalculatorUnitSelected(Unit.foot))
            ..add(const CalculatorOperatorPressed(Operator.add))
            ..add(const CalculatorKeySelected('Length'))
            ..add(const CalculatorActiveValueCleared())
            ..add(const CalculatorActiveValueCleared()),
          skip: 5,
          expect: () => [
            tapeState(pressed('2 2 ft +')),
            tapeState(pressed('2 2 ft +')).copyWith(closesCalculator: true),
          ],
        );

        blocTest<CalculatorBloc, CalculatorState>(
          'the next key taken or refused clears the close, as it clears a '
          'notice or a refusal',
          build: () => bloc,
          act: (bloc) => bloc
            ..add(const CalculatorActiveValueCleared())
            ..add(const CalculatorDigitPressed('5'))
            ..add(const CalculatorActiveValueCleared())
            ..add(const CalculatorActiveValueCleared())
            ..add(const CalculatorEqualsPressed()),
          expect: () => [
            const CalculatorState(closesCalculator: true),
            tapeState(pressed('5')),
            tapeState(pressed('5 ✕')),
            tapeState(pressed('5 ✕')).copyWith(closesCalculator: true),
            tapeState(pressed('5 ✕')).copyWith(
              refusal: () => const TapeRefused(TapeRefusal.nothingToCompute),
            ),
          ],
        );
      },
    );

    group('the keyboard around the tape', () {
      blocTest<CalculatorBloc, CalculatorState>(
        'selecting a group changes only the group',
        build: () => bloc,
        act: (bloc) => bloc.add(const CalculatorGroupSelected(2)),
        expect: () => [const CalculatorState(currentGroupIndex: 2)],
      );

      blocTest<CalculatorBloc, CalculatorState>(
        'the System of units toggle sets the tape\'s own preferences, so a '
        'mixed sum follows it',
        build: () => bloc,
        act: (bloc) => bloc
          ..add(const CalculatorUnitSystemChanged(UnitSystem.metric))
          ..add(const CalculatorDigitPressed('1'))
          ..add(const CalculatorUnitSelected(Unit.metre))
          ..add(const CalculatorOperatorPressed(Operator.add))
          ..add(const CalculatorDigitPressed('1'))
          ..add(const CalculatorUnitSelected(Unit.foot))
          ..add(const CalculatorEqualsPressed()),
        skip: 6,
        expect: () => [
          tapeState(
            pressed(
              '1 m + 1 ft =',
              tape: const Tape(
                preferences: CalculatorPreferences(
                  system: MeasurementSystem.metric,
                ),
              ),
            ),
          ),
        ],
        verify: (bloc) {
          expect(bloc.state.currentUnitSystem, UnitSystem.metric);
          expect(bloc.state.valueText, '1.3m');
        },
      );

      blocTest<CalculatorBloc, CalculatorState>(
        'R3 (review of 18 Nov): the toggle is refused once a result is on '
        'the tape, so 12ft + 1m = keeps reading 15ft 3-3/8in under Imperial '
        'and never claims Metric (Section 1.1: the toggle shows only while '
        'the tape is empty)',
        build: () => bloc,
        act: (bloc) => bloc
          ..add(const CalculatorDigitPressed('1'))
          ..add(const CalculatorDigitPressed('2'))
          ..add(const CalculatorUnitSelected(Unit.foot))
          ..add(const CalculatorOperatorPressed(Operator.add))
          ..add(const CalculatorDigitPressed('1'))
          ..add(const CalculatorUnitSelected(Unit.metre))
          ..add(const CalculatorEqualsPressed())
          ..add(const CalculatorUnitSystemChanged(UnitSystem.metric)),
        skip: 6,
        expect: () => [tapeState(pressed('1 2 ft + 1 m ='))],
        verify: (bloc) {
          expect(bloc.state.currentUnitSystem, UnitSystem.imperial);
          expect(bloc.state.valueText, '15ft 3-3/8in');
        },
      );

      blocTest<CalculatorBloc, CalculatorState>(
        'R3: the toggle is refused while a value is being typed, and the '
        'value stays typed',
        build: () => bloc,
        act: (bloc) => bloc
          ..add(const CalculatorDigitPressed('5'))
          ..add(const CalculatorUnitSystemChanged(UnitSystem.metric)),
        expect: () => [tapeState(pressed('5'))],
        verify: (bloc) =>
            expect(bloc.state.currentUnitSystem, UnitSystem.imperial),
      );

      blocTest<CalculatorBloc, CalculatorState>(
        'R3: after C the tape is empty again, so the toggle works',
        build: () => bloc,
        act: (bloc) => bloc
          ..add(const CalculatorDigitPressed('4'))
          ..add(const CalculatorControlActioned(ControlAction.clearAll))
          ..add(const CalculatorUnitSystemChanged(UnitSystem.metric)),
        skip: 2,
        expect: () => [
          const CalculatorState(
            tape: Tape(
              preferences: CalculatorPreferences(
                system: MeasurementSystem.metric,
              ),
            ),
          ),
        ],
      );

      blocTest<CalculatorBloc, CalculatorState>(
        'C and a reset keep the System of units and the group',
        build: () => bloc,
        act: (bloc) => bloc
          ..add(const CalculatorUnitSystemChanged(UnitSystem.metric))
          ..add(const CalculatorGroupSelected(3))
          ..add(const CalculatorDigitPressed('4'))
          ..add(const CalculatorControlActioned(ControlAction.clearAll))
          ..add(const CalculatorDigitPressed('4'))
          ..add(const CalculatorResetRequested()),
        skip: 3,
        expect: () => [
          const CalculatorState(
            tape: Tape(
              preferences: CalculatorPreferences(
                system: MeasurementSystem.metric,
              ),
            ),
            currentGroupIndex: 3,
          ),
          tapeState(
            pressed(
              '4',
              tape: const Tape(
                preferences: CalculatorPreferences(
                  system: MeasurementSystem.metric,
                ),
              ),
            ),
          ).copyWith(currentGroupIndex: 3),
          const CalculatorState(
            tape: Tape(
              preferences: CalculatorPreferences(
                system: MeasurementSystem.metric,
              ),
            ),
            currentGroupIndex: 3,
          ),
        ],
      );
    });

    group('S1c 3/5: a tap on a chip of the tape (rule 4.8)', () {
      Tape lengthWidthArea() {
        final typed = pressed('[Length] 2 2 ft [Width] 1 8 ft 8 in');
        final area = const DeterministicRules()
            .answersFor(typed.namedValues)
            .firstWhere((answer) => answer.key == 'Area');
        return (typed.landAnswer('Area', area.value) as TapeChanged).tape;
      }

      test('the equals key reads Update while a chip is edited and the tape '
          'has a result, and the = sign while it has none, where the press '
          'still lands what the strip offers (B1; product decision of 13 '
          'November 2026)', () {
        final landed = lengthWidthArea();
        expect(CalculatorState(tape: landed).equalsKeyId, isNull);
        final edited = (landed.tapChip(1) as TapeChanged).tape;
        expect(
          CalculatorState(tape: edited).equalsKeyId,
          CalculatorState.updateKey,
        );
        final typed = pressed('[Length] 2 2 ft [Width] 1 8 ft 8 in');
        expect(
          CalculatorState(tape: typed).equalsKeyId,
          DeterministicRules.areaKey,
        );
        final editedFirst = (typed.tapChip(0) as TapeChanged).tape;
        final state = CalculatorState(tape: editedFirst);
        expect(state.equalsKeyId, isNull);
        expect(state.equalsLands, isNotNull);
        expect(
          state.equalsLands!.key,
          DeterministicRules.areaKey,
          reason: '= still lands Area while the key shows the = sign',
        );
      });

      blocTest<CalculatorBloc, CalculatorState>(
        'a tapped chip reaches the tape as tapChip, and nothing else',
        build: () => bloc,
        seed: () => CalculatorState(tape: lengthWidthArea()),
        act: (bloc) => bloc.add(const CalculatorChipTapped(0)),
        expect: () => [
          tapeState((lengthWidthArea().tapChip(0) as TapeChanged).tape),
        ],
        verify: (bloc) {
          expect(bloc.state.tape.editing!.index, 0);
          expect(bloc.state.labelKeyId, 'Length');
        },
      );

      blocTest<CalculatorBloc, CalculatorState>(
        'a tap the tape refuses is carried as the refusal',
        build: () => bloc,
        seed: () => CalculatorState(tape: lengthWidthArea()),
        act: (bloc) => bloc.add(const CalculatorChipTapped(2)),
        // the Area stays on the display, so the store's answer for it
        // follows the refusal (S2a 2/2)
        expect: () {
          final refused = CalculatorState(
            tape: lengthWidthArea(),
            refusal: const TapeRefused(TapeRefusal.chipCannotBeEdited),
          );
          return [refused, refused.copyWith(stores: storesOf(refused))];
        },
      );

      test('while a chip is edited the results after it are drawn dashed, '
          'the edited chip active, and the results before it stay results', () {
        final tape = pressed('3 × 4 = × 2 =');
        expect(tape.chips, hasLength(5));
        final editing = (tape.tapChip(3) as TapeChanged).tape;

        final faces = [
          for (final chip in CalculatorState(tape: editing).chipsList)
            chip.type,
        ];
        expect(faces, [
          CoreCalculatorChipType.editable,
          CoreCalculatorChipType.editable,
          CoreCalculatorChipType.result,
          CoreCalculatorChipType.active,
          CoreCalculatorChipType.dashed,
        ]);

        final sealed = (editing.pressEquals() as TapeChanged).tape;
        expect([
          for (final chip in CalculatorState(tape: sealed).chipsList) chip.type,
        ], everyElement(isNot(CoreCalculatorChipType.dashed)));
      });

      test('the editing guard reads as a toast with the incomplete number, or '
          'with no number for an empty chip (Section 5, "Finish this value '
          'first")', () {
        final dangling = CalculatorState(
          tape: pressed('[Length] 1 8'),
          refusal: const TapeRefused(TapeRefusal.finishThisValueFirst),
        );
        expect(dangling.toast, const CalculatorFinishValueToast(value: '18'));

        final emptied = (lengthWidthArea().tapChip(1) as TapeChanged).tape;
        final empty = CalculatorState(
          tape: (emptied.clearActive() as TapeChanged).tape,
          refusal: const TapeRefused(TapeRefusal.finishThisValueFirst),
        );
        expect(empty.toast, const CalculatorFinishValueToast(value: ''));
      });

      test('⌫ again on the emptied first chip of a chain reads "Type a new '
          'first value" (rule 4.8)', () {
        final chain = pressed('2 + 3 =');
        final reopened = (chain.tapChip(0) as TapeChanged).tape;
        final emptied = (reopened.clearActive() as TapeChanged).tape;
        final refusal = emptied.backspace();
        expect(refusal, const TapeRefused(TapeRefusal.typeANewFirstValue));
        expect(
          CalculatorState(tape: emptied, refusal: refusal).toast,
          const CalculatorTypeNewFirstValueToast(),
        );
      });

      test('a refusal with no words yet reads as no toast, and so does the '
          'tape\'s refusal of a tap on a result, which the page never sends '
          'since a result chip takes no tap', () {
        expect(
          CalculatorState(
            tape: lengthWidthArea(),
            refusal: const TapeRefused(TapeRefusal.chipCannotBeEdited),
          ).toast,
          isNull,
        );
        expect(
          CalculatorState(
            tape: lengthWidthArea(),
            refusal: const TapeRefused(TapeRefusal.typeANumberFirst),
          ).toast,
          isNull,
        );
      });

      blocTest<CalculatorBloc, CalculatorState>(
        'a result an edit removes is named in the state for its message, and '
        'the next key clears it',
        build: () => bloc,
        seed: () => CalculatorState(
          tape: (pressed('0 . 5 [ASIN]').tapChip(0) as TapeChanged).tape,
        ),
        act: (bloc) => bloc
          ..add(const CalculatorControlActioned(ControlAction.delete))
          ..add(const CalculatorControlActioned(ControlAction.delete))
          ..add(const CalculatorControlActioned(ControlAction.delete))
          ..add(const CalculatorDigitPressed('2'))
          ..add(const CalculatorChipTapped(0))
          ..add(const CalculatorDigitPressed('3')),
        skip: 4,
        verify: (bloc) {
          expect(bloc.state.removedResults, isEmpty);
          expect(bloc.state.toast, isNull);
          expect(bloc.state.valueText, '3');
        },
        expect: () {
          final retyped =
              (pressed('0 . 5 [ASIN]').tapChip(0) as TapeChanged).tape;
          final edited = pressed('⌫ ⌫ ⌫ 2', tape: retyped);
          final sealed = edited.tapChip(0) as TapeChanged;
          expect(sealed.removed, ['Arcsine']);
          return [
            CalculatorState(
              tape: sealed.tape,
              notice: TapeNotice.resultRemoved,
              removedResults: const ['Arcsine'],
              toastsRaised: 1,
            ),
            tapeState(
              pressed('3', tape: sealed.tape),
            ).copyWith(toastsRaised: 1),
          ];
        },
      );

      blocTest<CalculatorBloc, CalculatorState>(
        'the Alert\'s ✕ marks the message closed, and the next key taken or '
        'refused opens the way for the next one (Section 5: ✕ or the next '
        'key closes it)',
        build: () => bloc,
        act: (bloc) => bloc
          ..add(const CalculatorKeySelected('Length'))
          ..add(const CalculatorDigitPressed('1'))
          ..add(const CalculatorKeySelected('Width'))
          ..add(const CalculatorToastClosed())
          ..add(const CalculatorGroupSelected(2))
          ..add(const CalculatorKeySelected('Width'))
          ..add(const CalculatorToastClosed())
          ..add(const CalculatorUnitSelected(Unit.foot)),
        skip: 2,
        expect: () => [
          tapeState(pressed('[Length] 1')).copyWith(
            refusal: () => const TapeRefused(TapeRefusal.finishThisValueFirst),
            toastsRaised: 1,
          ),
          tapeState(pressed('[Length] 1')).copyWith(
            refusal: () => const TapeRefused(TapeRefusal.finishThisValueFirst),
            toastsRaised: 1,
            toastClosed: true,
          ),
          tapeState(pressed('[Length] 1')).copyWith(
            refusal: () => const TapeRefused(TapeRefusal.finishThisValueFirst),
            toastsRaised: 1,
            toastClosed: true,
            currentGroupIndex: 2,
          ),
          tapeState(pressed('[Length] 1')).copyWith(
            refusal: () => const TapeRefused(TapeRefusal.finishThisValueFirst),
            toastsRaised: 2,
            currentGroupIndex: 2,
          ),
          tapeState(pressed('[Length] 1')).copyWith(
            refusal: () => const TapeRefused(TapeRefusal.finishThisValueFirst),
            toastsRaised: 2,
            toastClosed: true,
            currentGroupIndex: 2,
          ),
          tapeState(
            pressed('[Length] 1 ft'),
          ).copyWith(toastsRaised: 2, currentGroupIndex: 2),
        ],
      );

      blocTest<CalculatorBloc, CalculatorState>(
        'a key the tape refuses clears a removed result too, so the toast is '
        'not shown twice',
        build: () => bloc,
        seed: () => CalculatorState(
          tape: pressed('[Length] 1 8'),
          removedResults: const ['Arcsine'],
        ),
        act: (bloc) => bloc.add(const CalculatorKeySelected('Width')),
        expect: () => [
          CalculatorState(
            tape: pressed('[Length] 1 8'),
            refusal: const TapeRefused(TapeRefusal.finishThisValueFirst),
            toastsRaised: 1,
          ),
        ],
      );

      blocTest<CalculatorBloc, CalculatorState>(
        'the same guard raised twice is counted twice, so the page shows its '
        'toast twice, and a key that says nothing leaves the count alone',
        build: () => bloc,
        act: (bloc) => bloc
          ..add(const CalculatorKeySelected('Length'))
          ..add(const CalculatorDigitPressed('1'))
          ..add(const CalculatorDigitPressed('8'))
          ..add(const CalculatorKeySelected('Width'))
          ..add(const CalculatorKeySelected('Width'))
          ..add(const CalculatorUnitSelected(Unit.foot)),
        skip: 3,
        expect: () => [
          tapeState(pressed('[Length] 1 8')).copyWith(
            refusal: () => const TapeRefused(TapeRefusal.finishThisValueFirst),
            toastsRaised: 1,
          ),
          tapeState(pressed('[Length] 1 8')).copyWith(
            refusal: () => const TapeRefused(TapeRefusal.finishThisValueFirst),
            toastsRaised: 2,
          ),
          tapeState(pressed('[Length] 1 8 ft')).copyWith(toastsRaised: 2),
        ],
      );

      Tape widthReopened(String keys) => pressed(
        keys,
        tape: (lengthWidthArea().tapChip(1) as TapeChanged).tape,
      );

      blocTest<CalculatorBloc, CalculatorState>(
        'a unit the reopened compound cannot take is kept with the refusal, '
        'and the toast names it (S65: "Can\'t append yards here")',
        build: () => bloc,
        seed: () => CalculatorState(tape: widthReopened('7 8')),
        act: (bloc) => bloc.add(const CalculatorUnitSelected(Unit.yard)),
        expect: () => [
          CalculatorState(
            tape: widthReopened('7 8'),
            refusal: const TapeEntryRefused(EntryRefusal.cannotAppendUnit),
            refusedUnit: Unit.yard,
            toastsRaised: 1,
          ),
        ],
        verify: (bloc) => expect(
          bloc.state.toast,
          const CalculatorCannotAppendUnitToast(
            value: '18ft 8in 78',
            unit: Unit.yard,
          ),
        ),
      );

      blocTest<CalculatorBloc, CalculatorState>(
        'a weight key under a dimension key names the key and the unit, the '
        'same message after a finished length (S69; B2, product decision of '
        '13 November 2026)',
        build: () => bloc,
        seed: () => CalculatorState(tape: widthReopened('✕ 5')),
        act: (bloc) => bloc
          ..add(const CalculatorKeySelected('lbs'))
          ..add(const CalculatorUnitSelected(Unit.foot))
          ..add(const CalculatorDigitPressed('8'))
          ..add(const CalculatorKeySelected('kg')),
        verify: (bloc) => expect(
          bloc.state.toast,
          const CalculatorNeedsLengthToast(key: 'Width', unit: Unit.kilogram),
        ),
        expect: () => [
          CalculatorState(
            tape: widthReopened('✕ 5'),
            refusal: const TapeEntryRefused(EntryRefusal.needsLength),
            refusedUnit: Unit.pound,
            toastsRaised: 1,
          ),
          CalculatorState(tape: widthReopened('✕ 5 ft'), toastsRaised: 1),
          CalculatorState(tape: widthReopened('✕ 5 ft 8'), toastsRaised: 1),
          CalculatorState(
            tape: widthReopened('✕ 5 ft 8'),
            refusal: const TapeEntryRefused(EntryRefusal.tailNeedsLength),
            refusedUnit: Unit.kilogram,
            toastsRaised: 2,
          ),
        ],
      );

      for (final (unitKey, unit) in const [
        ('lbs', Unit.pound),
        ('bf', Unit.boardFoot),
      ]) {
        blocTest<CalculatorBloc, CalculatorState>(
          'a weight or board feet under Pitch is refused in the Pitch words, '
          'never the length words: Pitch 6 then $unitKey (B3; rule 4.10)',
          build: () => bloc,
          act: (bloc) => bloc
            ..add(const CalculatorKeySelected('Pitch'))
            ..add(const CalculatorDigitPressed('6'))
            ..add(CalculatorKeySelected(unitKey)),
          skip: 2,
          expect: () => [
            isA<CalculatorState>()
                .having((s) => s.valueText, 'valueText', '6°')
                .having(
                  (s) => s.refusal,
                  'refusal',
                  const TapeEntryRefused(EntryRefusal.needsLength),
                )
                .having(
                  (s) => s.toast,
                  'toast',
                  CalculatorPitchUnitToast(unit: unit, value: '6'),
                ),
          ],
        );
      }

      for (final (name, digits) in const [
        ('1/4, where = is refused', ['1', '4']),
        ('6/12, where = gives 26.57°', ['6', '1', '2']),
      ]) {
        blocTest<CalculatorBloc, CalculatorState>(
          'a weight under a fraction typed under Pitch is refused with no '
          'words, since the Pitch body would name a = that is not true: '
          'Pitch $name (B4; rule 4.10)',
          build: () => bloc,
          act: (bloc) {
            bloc
              ..add(const CalculatorKeySelected('Pitch'))
              ..add(CalculatorDigitPressed(digits.first))
              ..add(const CalculatorFractionPressed());
            for (final digit in digits.skip(1)) {
              bloc.add(CalculatorDigitPressed(digit));
            }
            bloc.add(const CalculatorKeySelected('lbs'));
          },
          skip: digits.length + 2,
          expect: () => [
            isA<CalculatorState>()
                .having(
                  (s) => s.refusal,
                  'refusal',
                  const TapeEntryRefused(EntryRefusal.needsLength),
                )
                .having((s) => s.toast, 'toast', isNull),
          ],
        );
      }

      blocTest<CalculatorBloc, CalculatorState>(
        'a weight after a rise already typed under Pitch is refused with no '
        'words, since the doc has none for it and the length words would '
        'send the user to Feet (B3)',
        build: () => bloc,
        act: (bloc) => bloc
          ..add(const CalculatorKeySelected('Pitch'))
          ..add(const CalculatorDigitPressed('6'))
          ..add(const CalculatorUnitSelected(Unit.inch))
          ..add(const CalculatorDigitPressed('5'))
          ..add(const CalculatorKeySelected('lbs')),
        skip: 4,
        expect: () => [
          isA<CalculatorState>()
              .having(
                (s) => s.refusal,
                'refusal',
                const TapeEntryRefused(EntryRefusal.tailNeedsLength),
              )
              .having((s) => s.toast, 'toast', isNull),
        ],
      );

      test('the first refusal reads as "Width takes a length", the words the '
          'tail order gets', () {
        final state = CalculatorState(
          tape: widthReopened('✕ 5'),
          refusal: const TapeEntryRefused(EntryRefusal.needsLength),
          refusedUnit: Unit.pound,
        );
        expect(
          state.toast,
          const CalculatorNeedsLengthToast(key: 'Width', unit: Unit.pound),
        );
      });

      blocTest<CalculatorBloc, CalculatorState>(
        'a unit pressed again under a dimension key is kept with the refusal, '
        'and the toast says what it would make (S65: "would make this 4in²")',
        build: () => bloc,
        seed: () => CalculatorState(tape: widthReopened('✕ 4 in')),
        act: (bloc) => bloc.add(const CalculatorUnitSelected(Unit.inch)),
        expect: () => [
          CalculatorState(
            tape: widthReopened('✕ 4 in'),
            refusal: const TapeUnitRefused(
              UnitKeyRefused(UnitKeyRefusal.keepsLength),
            ),
            refusedUnit: Unit.inch,
            toastsRaised: 1,
          ),
        ],
        verify: (bloc) => expect(
          bloc.state.toast,
          const CalculatorKeepsLengthToast(
            key: 'Width',
            unit: Unit.inch,
            value: '4in',
          ),
        ),
      );

      blocTest<CalculatorBloc, CalculatorState>(
        'a unit key on a result that would raise it is refused with no '
        'message: the "keeps" message speaks only under a dimension key '
        '(B1; Section 5.2)',
        build: () => bloc,
        act: (bloc) => bloc
          ..add(const CalculatorDigitPressed('1'))
          ..add(const CalculatorDigitPressed('2'))
          ..add(const CalculatorUnitSelected(Unit.foot))
          ..add(const CalculatorOperatorPressed(Operator.multiply))
          ..add(const CalculatorDigitPressed('1'))
          ..add(const CalculatorDigitPressed('0'))
          ..add(const CalculatorUnitSelected(Unit.foot))
          ..add(const CalculatorEqualsPressed())
          ..add(const CalculatorUnitSelected(Unit.foot)),
        skip: 8,
        expect: () => [
          tapeState(pressed('1 2 ft × 1 0 ft =')).copyWith(
            refusal: () => const TapeUnitRefused(
              UnitKeyRefused(UnitKeyRefusal.keepsLength),
            ),
            refusedUnit: () => Unit.foot,
          ),
        ],
        verify: (bloc) {
          expect(bloc.state.toast, isNull);
          expect(bloc.state.toastsRaised, 0);
        },
      );

      test('a unit that is not a length under a dimension key raises one '
          'message in both key orders, named for the unit pressed: Width 8 '
          '[Bd Ft] and Width 18 [Feet] 8 [Bd Ft] alike (B2; product decision '
          'of 13 November 2026)', () {
        const toast = CalculatorNeedsLengthToast(
          key: 'Width',
          unit: Unit.boardFoot,
        );
        expect(
          CalculatorState(
            tape: pressed('[Width] 8'),
            refusal: const TapeEntryRefused(EntryRefusal.needsLength),
            refusedUnit: Unit.boardFoot,
          ).toast,
          toast,
        );
        expect(
          CalculatorState(
            tape: pressed('[Width] 1 8 ft 8'),
            refusal: const TapeEntryRefused(EntryRefusal.tailNeedsLength),
            refusedUnit: Unit.boardFoot,
          ).toast,
          toast,
        );
        expect(
          CalculatorState(
            tape: pressed('[Width] 1 8 ft 7 / 1 6'),
            refusal: const TapeEntryRefused(EntryRefusal.tailNeedsLength),
            refusedUnit: Unit.pound,
          ).toast,
          const CalculatorNeedsLengthToast(key: 'Width', unit: Unit.pound),
        );
      });

      test(
        'a refusal that is not a unit\'s, or a unit refusal the bloc did not '
        'name, has no unit toast',
        () {
          expect(
            CalculatorState(
              tape: widthReopened('✕ 4 in'),
              refusal: const TapeUnitRefused(
                UnitKeyRefused(UnitKeyRefusal.keepsLength),
              ),
            ).toast,
            isNull,
          );
          expect(
            CalculatorState(
              tape: widthReopened('7 8'),
              refusal: const TapeEntryRefused(EntryRefusal.secondDecimalPoint),
              refusedUnit: Unit.yard,
            ).toast,
            isNull,
          );
        },
      );

      test('removed results read as their message, all of them named', () {
        expect(
          const CalculatorState(removedResults: ['Arcsine']).toast,
          const CalculatorResultRemovedToast(keys: ['Arcsine']),
        );
        expect(
          const CalculatorState(removedResults: ['Diagonal', 'Calc']).toast,
          const CalculatorResultRemovedToast(keys: ['Diagonal', 'Calc']),
        );
      });

      test(
        'while a bracket is reopened in the middle every other chip waits, '
        'and a result after it keeps its label but reads a dash (Section 7)',
        () {
          final open = pressed('2 + ( 3 × 4 ( × 5 = tap:1');
          final chips = CalculatorState(tape: open).chipsList;

          expect(
            [for (final chip in chips) chip.inert],
            [true, false, true, true],
          );
          expect(chips[1].type, CoreCalculatorChipType.bracketOpen);
          expect(chips[3].label, Tape.calcKey);
          expect(chips[3].value, '—');
          expect(chips[3].type, CoreCalculatorChipType.result);

          final closed = CalculatorState(
            tape: pressed('2 + ( 3 × 4 ( × 5 = tap:1 ('),
          );
          expect([
            for (final chip in closed.chipsList) chip.inert,
          ], everyElement(isFalse));
          expect(closed.chipsList[3].value, '70');
        },
      );

      blocTest<CalculatorBloc, CalculatorState>(
        'the "Editing this group" toast shows the first three times a bracket '
        'is reopened, and no more (Section 5.6)',
        build: () => bloc,
        seed: () => CalculatorState(tape: pressed('2 + ( 3 × 4 (')),
        act: (bloc) {
          for (var reopened = 1; reopened <= 4; reopened++) {
            bloc
              ..add(const CalculatorChipTapped(1))
              ..add(const CalculatorControlActioned(ControlAction.paren));
          }
        },
        verify: (bloc) => expect(bloc.state.groupEditsNoticed, 4),
        expect: () {
          final closed = pressed('2 + ( 3 × 4 (');
          final open = pressed('2 + ( 3 × 4 ( tap:1');
          // The first three reopenings raise the toast; the fourth does not.
          int raised(int reopened) =>
              reopened < CalculatorState.groupEditToastsShown
              ? reopened
              : CalculatorState.groupEditToastsShown;
          return [
            for (var reopened = 1; reopened <= 4; reopened++) ...[
              CalculatorState(
                tape: open,
                notice: TapeNotice.editingThisGroup,
                groupEditsNoticed: reopened,
                toastsRaised: raised(reopened),
              ),
              CalculatorState(
                tape: closed,
                groupEditsNoticed: reopened,
                toastsRaised: raised(reopened),
              ),
            ],
          ];
        },
      );

      test(
        'the toast reads only while the count is within the first three',
        () {
          final open = pressed('2 + ( 3 × 4 ( tap:1');
          expect(
            CalculatorState(
              tape: open,
              notice: TapeNotice.editingThisGroup,
              groupEditsNoticed: 3,
            ).toast,
            const CalculatorEditingGroupToast(),
          );
          expect(
            CalculatorState(
              tape: open,
              notice: TapeNotice.editingThisGroup,
              groupEditsNoticed: 4,
            ).toast,
            isNull,
          );
          expect(
            CalculatorState(tape: open, groupEditsNoticed: 1).toast,
            isNull,
            reason: 'the next key clears the notice and with it the toast',
          );
        },
      );

      test('a chip being typed at the end leaves no result dashed', () {
        final tape = pressed('3 × 4 = × 2');
        expect([
          for (final chip in CalculatorState(tape: tape).chipsList) chip.type,
        ], isNot(contains(CoreCalculatorChipType.dashed)));
      });
    });

    group('S1c bracket edit: the count of reopenings (Section 5.6)', () {
      blocTest<CalculatorBloc, CalculatorState>(
        'C starts a fresh tape, not a fresh screen: the reopenings already '
        'counted stay counted, so the toast does not come back',
        build: () => bloc,
        seed: () => CalculatorState(
          tape: pressed('2 + ( 3 × 4 ('),
          groupEditsNoticed: CalculatorState.groupEditToastsShown,
          toastsRaised: 3,
        ),
        act: (bloc) => bloc
          ..add(const CalculatorControlActioned(ControlAction.clearAll))
          ..add(const CalculatorDigitPressed('2'))
          ..add(const CalculatorOperatorPressed(Operator.add))
          ..add(const CalculatorControlActioned(ControlAction.paren))
          ..add(const CalculatorDigitPressed('3'))
          ..add(const CalculatorControlActioned(ControlAction.paren))
          ..add(const CalculatorChipTapped(1)),
        skip: 6,
        verify: (bloc) => expect(bloc.state.toast, isNull),
        expect: () => [
          tapeState(
            pressed('2 + ( 3 ( tap:1'),
            notice: TapeNotice.editingThisGroup,
          ).copyWith(
            groupEditsNoticed: CalculatorState.groupEditToastsShown + 1,
            toastsRaised: 3,
          ),
        ],
      );

      blocTest<CalculatorBloc, CalculatorState>(
        '⌫ straight after ) reopens the bracket and counts as a reopening, '
        'with the toast raised, as a tap does',
        build: () => bloc,
        seed: () => CalculatorState(tape: pressed('2 + ( 3 × 4 (')),
        act: (bloc) =>
            bloc.add(const CalculatorControlActioned(ControlAction.delete)),
        verify: (bloc) =>
            expect(bloc.state.toast, const CalculatorEditingGroupToast()),
        expect: () => [
          tapeState(
            pressed('2 + ( 3 × 4 ( ⌫'),
            notice: TapeNotice.editingThisGroup,
          ).copyWith(groupEditsNoticed: 1, toastsRaised: 1),
        ],
      );

      test('a result before the reopened bracket keeps its number; only the '
          'results after it read a dash', () {
        final tape = pressed('2 + ( 3 ( = + ( 4 ( tap:3');
        expect(tape.openBracketIndex, 3);

        final chips = CalculatorState(tape: tape).chipsList;
        expect(chips[2].value, '5');
        expect(chips[2].inert, isTrue);
        expect(chips[3].inert, isFalse);
      });
    });

    group('CA-1372 2/2: the red Alerts of an angle\'s parts (rule 4.10; '
        'decision tree rows 172 to 177, 370)', () {
      void type(CalculatorBloc bloc, String keys) {
        for (final key in keys.split(' ')) {
          bloc.add(switch (key) {
            'DMS' => const CalculatorKeySelected('DMS'),
            'SIN' => const CalculatorKeySelected('SIN'),
            _ when key.startsWith('[') => CalculatorKeySelected(
              key.substring(1, key.length - 1),
            ),
            _ => CalculatorDigitPressed(key),
          });
        }
      }

      blocTest<CalculatorBloc, CalculatorState>(
        '38 [D:M:S] 7 then 5 is refused with "Minutes must be under 60", the '
        'chip stays 38°7′, and the Alert is raised once (rows 172, 177)',
        build: () => bloc,
        act: (bloc) => type(bloc, 'SIN 3 8 DMS 7 5'),
        skip: 5,
        expect: () => [
          tapeState(pressed('[SIN] 3 8 [DMS] 7')).copyWith(
            refusal: () =>
                const TapeEntryRefused(EntryRefusal.partOfSixtyOrMore),
            toastsRaised: 1,
          ),
        ],
        verify: (bloc) {
          expect(bloc.state.toast, const CalculatorPartUnderSixtyToast());
          expect(bloc.state.valueText, '38°7\'00"');
        },
      );

      blocTest<CalculatorBloc, CalculatorState>(
        'the point that would close 89 minutes is refused with the same '
        'words, and 30.89 stays a decimal (row 370; S85)',
        build: () => bloc,
        act: (bloc) => type(bloc, '[Pitch] 3 0 . 8 9 .'),
        skip: 6,
        expect: () => [
          tapeState(pressed('[Pitch] 3 0 . 8 9')).copyWith(
            refusal: () =>
                const TapeEntryRefused(EntryRefusal.partOfSixtyOrMore),
            toastsRaised: 1,
          ),
        ],
        verify: (bloc) =>
            expect(bloc.state.toast, const CalculatorPartUnderSixtyToast()),
      );

      blocTest<CalculatorBloc, CalculatorState>(
        'a third digit in the minutes reads "Minutes have two digits", in the '
        'seconds "Seconds have two digits", and a point after the seconds '
        '"An angle has three parts" (rows 173, 174, 176)',
        build: () => bloc,
        act: (bloc) => type(bloc, 'SIN 3 8 DMS 5 9 0 DMS 1 2 3 .'),
        skip: 6,
        expect: () => [
          tapeState(pressed('[SIN] 3 8 [DMS] 5 9')).copyWith(
            refusal: () =>
                const TapeEntryRefused(EntryRefusal.minutesHaveTwoDigits),
            toastsRaised: 1,
          ),
          tapeState(
            pressed('[SIN] 3 8 [DMS] 5 9 [DMS]'),
          ).copyWith(toastsRaised: 1),
          tapeState(
            pressed('[SIN] 3 8 [DMS] 5 9 [DMS] 1'),
          ).copyWith(toastsRaised: 1),
          tapeState(
            pressed('[SIN] 3 8 [DMS] 5 9 [DMS] 1 2'),
          ).copyWith(toastsRaised: 1),
          tapeState(pressed('[SIN] 3 8 [DMS] 5 9 [DMS] 1 2')).copyWith(
            refusal: () =>
                const TapeEntryRefused(EntryRefusal.secondsHaveTwoDigits),
            toastsRaised: 2,
          ),
          tapeState(pressed('[SIN] 3 8 [DMS] 5 9 [DMS] 1 2')).copyWith(
            refusal: () =>
                const TapeEntryRefused(EntryRefusal.angleHasThreeParts),
            toastsRaised: 3,
          ),
        ],
        verify: (bloc) =>
            expect(bloc.state.toast, const CalculatorAngleThreePartsToast()),
      );

      test('each Alert reads in the words of rule 4.10', () {
        final labels = CalculatorLabelFormatter(AppLocalizationsEn());
        final toasts = {
          const CalculatorPartUnderSixtyToast(): (
            EntryRefusal.partOfSixtyOrMore,
            'Minutes must be under 60',
            'Press ⌫ and type the minutes again.',
          ),
          const CalculatorMinutesTwoDigitsToast(): (
            EntryRefusal.minutesHaveTwoDigits,
            'Minutes have two digits',
            'Press . to type the seconds, or = to finish the angle.',
          ),
          const CalculatorSecondsTwoDigitsToast(): (
            EntryRefusal.secondsHaveTwoDigits,
            'Seconds have two digits',
            'Press = or an operator to finish the angle.',
          ),
          const CalculatorAngleThreePartsToast(): (
            EntryRefusal.angleHasThreeParts,
            'An angle has three parts',
            'Press = or an operator to finish the angle.',
          ),
        };
        for (final MapEntry(key: toast, value: (reason, title, body))
            in toasts.entries) {
          expect(
            CalculatorState(
              tape: pressed('[SIN] 3 8 [DMS] 5 9'),
              refusal: TapeEntryRefused(reason),
            ).toast,
            toast,
          );
          expect(labels.toastTitle(toast), title);
          expect(labels.toastBody(toast), body);
        }
      });
    });

    group('CA-1094: strip notes (Section 1.8)', () {
      test('a Sides count no regular polygon has takes the strip with "Sides '
          'needs a whole number, 3 or more.", and a whole count of 3 or more '
          'gives the strip back (decision tree row 339)', () {
        final notWhole = CalculatorState(
          tape: pressed('[Diameter] 1 2 ft [Sides] 6 . 5'),
        );
        expect(notWhole.stripNote, const CalculatorSidesNotWholeNote());
        expect(notWhole.suggestions, isEmpty);
        expect(notWhole.conversions, isEmpty);
        expect(
          CalculatorState(
            tape: pressed('[Sides] 2 [Diameter] 1 2 ft'),
          ).stripNote,
          const CalculatorSidesNotWholeNote(),
          reason: 'a count of 2 finished by the next key',
        );
        final whole = CalculatorState(
          tape: pressed('[Diameter] 1 2 ft [Sides] 6'),
        );
        expect(whole.stripNote, isNull);
        expect(whole.suggestions, isNotEmpty);
        expect(
          CalculatorLabelFormatter(
            AppLocalizationsEn(),
          ).noteText(const CalculatorSidesNotWholeNote()),
          'Sides needs a whole number, 3 or more.',
        );
      });

      test('the Sides note waits while the count is still being typed: after '
          '[Sides] 1 the answers stay and no note shows, 12 is a count, and a '
          '0 or a decimal part is noted at once (Section 1.8, "Shown only '
          'once the entry is finished")', () {
        final one = CalculatorState(
          tape: pressed('[Diameter] 1 2 ft [Sides] 1'),
        );
        expect(one.stripNote, isNull);
        final twelve = CalculatorState(
          tape: pressed('[Diameter] 1 2 ft [Sides] 1 2'),
        );
        expect(twelve.stripNote, isNull);
        expect(twelve.suggestions, isNotEmpty);
        for (final keys in [
          '[Diameter] 1 2 ft [Sides] 0',
          '[Diameter] 1 2 ft [Sides] 1 . 5',
        ]) {
          expect(
            CalculatorState(tape: pressed(keys)).stripNote,
            const CalculatorSidesNotWholeNote(),
            reason: keys,
          );
        }
      });

      blocTest<CalculatorBloc, CalculatorState>(
        '= while the pitch note shows raises a red Alert in the words of the '
        'note, and the tape does not change (decision tree row 375)',
        build: () => bloc,
        seed: () => CalculatorState(tape: pressed('[Pitch] 9 5 [Run] 1 0 ft')),
        act: (bloc) => bloc.add(const CalculatorEqualsPressed()),
        expect: () => [
          CalculatorState(
            tape: pressed('[Pitch] 9 5 [Run] 1 0 ft'),
            refusal: const TapeRefused(TapeRefusal.nothingToCompute),
            toastsRaised: 1,
          ),
        ],
        verify: (bloc) => expect(
          bloc.state.toast,
          const CalculatorRangeWarningToast(
            CalculatorRangeWarning.pitchUnderRightAngle,
          ),
        ),
      );

      test('each warning = repeats reads as its note does, title then body, '
          'and = with no warning on the strip raises no Alert', () {
        final labels = CalculatorLabelFormatter(AppLocalizationsEn());
        const nothingToCompute = TapeRefused(TapeRefusal.nothingToCompute);
        final warnings = {
          '[Pitch] 9 5 [Run] 1 0 ft': (
            CalculatorRangeWarning.pitchUnderRightAngle,
            'A pitch must be under 90°',
            'Edit the Pitch chip.',
          ),
          '[Pitch] 0 [Rise] 1 0 ft': (
            CalculatorRangeWarning.flatPitchHasNoRun,
            'A flat pitch has no run',
            'Edit the Pitch chip.',
          ),
          '[Slope] 0 [Run] 1 0 ft': (
            CalculatorRangeWarning.slopeAboveZero,
            'Slope must be more than 0%',
            'Edit the Slope chip.',
          ),
        };
        for (final MapEntry(key: keys, value: (warning, title, body))
            in warnings.entries) {
          final state = CalculatorState(
            tape: pressed(keys),
            refusal: nothingToCompute,
          );
          final toast = CalculatorRangeWarningToast(warning);
          expect(state.toast, toast, reason: keys);
          expect(labels.toastTitle(toast), title);
          expect(labels.toastBody(toast), body);
          expect(
            labels.noteText(state.stripNote),
            '$title. $body',
            reason: 'the Alert repeats the note word for word',
          );
        }
        const belowZero = CalculatorRangeWarningToast(
          CalculatorRangeWarning.pitchAtLeastZero,
        );
        final recalledBelowZero = CalculatorState(
          tape: const Tape(
            chips: [
              ValueChip(
                key: 'Pitch',
                entry: EntryBuffer([Token(digits: '-5')]),
                exact: (
                  spelled: EntryBuffer([Token(digits: '-5')]),
                  value: Angle(-5),
                ),
                readsDegrees: true,
                isActive: false,
              ),
              ValueChip(
                key: 'Run',
                entry: EntryBuffer([Token(digits: '10', unit: Unit.foot)]),
                isActive: false,
              ),
            ],
          ),
          refusal: nothingToCompute,
        );
        expect(
          recalledBelowZero.stripNote,
          const CalculatorPitchOutOfRangeNote(isAtLeastARightAngle: false),
        );
        expect(recalledBelowZero.toast, belowZero);
        expect(labels.toastTitle(belowZero), 'A pitch must be 0° or more');
        expect(labels.toastBody(belowZero), 'Edit the Pitch chip.');
        expect(
          CalculatorState(
            tape: pressed('[Diameter] 1 2 ft [Sides] 6 . 5'),
            refusal: nothingToCompute,
          ).toast,
          isNull,
        );
        expect(
          CalculatorState(
            tape: pressed('1 2 ft'),
            refusal: nothingToCompute,
          ).toast,
          isNull,
        );
      });
    });

    group('CA-1376 2/3: the % key, its chip and its red Alerts (Section 7, '
        '"Percent"; rule 4.12)', () {
      final labels = CalculatorLabelFormatter(AppLocalizationsEn());

      blocTest<CalculatorBloc, CalculatorState>(
        'the % key presses the percent on the tape',
        build: () => bloc,
        seed: () => CalculatorState(tape: pressed('5 0 + 1 0')),
        act: (bloc) => bloc.add(const CalculatorPercentPressed()),
        expect: () => [CalculatorState(tape: pressed('5 0 + 1 0 %'))],
      );

      test('the chip reads "+10%", and a bracket "(5+5)%" (row 386)', () {
        expect(
          [
            for (final chip in CalculatorState(
              tape: pressed('1 0 0 0 + 5 0 0 + 1 0 %'),
            ).chipsList)
              chip.value,
          ],
          ['1000', '+500', '+10%'],
        );
        expect(
          CalculatorState(
            tape: pressed('2 0 0 + ( 5 + 5 ( %'),
          ).chipsList.last.value,
          '(5+5)%',
          reason: 'the bracket chip draws its operator as its factor',
        );
        expect(
          CalculatorState(
            tape: pressed('2 0 0 + ( 5 + 5 ( %'),
          ).chipsList.last.type,
          CoreCalculatorChipType.editable,
          reason: 'the closed-bracket chip has no place for a % after its )',
        );
        expect(
          CalculatorState(
            tape: pressed('2 0 0 + ( 5 + 5 ('),
          ).chipsList.last.type,
          CoreCalculatorChipType.bracketClosed,
        );
      });

      test('a reopened percent bracket reads like any open bracket, "5+5" in '
          'the open-bracket chip, and shows its % again once it closes', () {
        final reopened = CalculatorState(
          tape: pressed('2 0 0 + ( 5 + 5 ( % + 3 tap:1'),
        ).chipsList[1];
        expect(reopened.value, '5+5');
        expect(reopened.type, CoreCalculatorChipType.bracketOpen);

        final closedAgain = CalculatorState(
          tape: pressed('2 0 0 + ( 5 + 5 ( % + 3 tap:1 ('),
        ).chipsList[1];
        expect(closedAgain.value, '(5+5)%');
        expect(closedAgain.type, CoreCalculatorChipType.editable);
      });

      test('each refusal raises its red Alert in the words of rule 4.12', () {
        final cases = {
          '1 2 +': (
            TapeRefusal.percentNeedsANumber,
            const CalculatorPercentNeedsANumberToast(operator: '+'),
            'Type a number first',
            'Type the number after +, then press %.',
          ),
          '( 1 2': (
            TapeRefusal.percentNeedsAnOperator,
            const CalculatorPercentNeedsAnOperatorToast(insideABracket: true),
            '% needs an operator first',
            'Press ) and +, −, × or ÷, then the percent.',
          ),
          '1 2': (
            TapeRefusal.percentNeedsAnOperator,
            const CalculatorPercentNeedsAnOperatorToast(insideABracket: false),
            '% needs an operator first',
            'Press +, −, × or ÷, then the percent.',
          ),
          '2 0 0 × 1 0 %': (
            TapeRefusal.alreadyAPercent,
            const CalculatorAlreadyAPercentToast(),
            'Already a percent',
            'Press +, −, × or ÷ to go on, or ⌫ to remove the %.',
          ),
          '5 0 + 1 0 %': (
            TapeRefusal.percentTakesNoUnit,
            const CalculatorPercentTakesNoUnitToast(),
            'That number is a percent',
            'A percent has no unit. Press +, −, × or ÷ to go on.',
          ),
          '5 ft + 1 0 ft': (
            TapeRefusal.percentHasNoUnit,
            const CalculatorPercentHasNoUnitToast(),
            'A percent has no unit',
            'Press ⌫ to remove the unit, then press %.',
          ),
          '5 ÷ ( 2 − 2 (': (
            TapeRefusal.percentDividesByZero,
            const CalculatorPercentDividesByZeroToast(bracket: '(2−2)'),
            'Cannot divide by zero',
            'The bracket (2−2) is 0. Press ⌫ to change the bracket.',
          ),
        };
        for (final MapEntry(key: keys, value: (reason, toast, title, body))
            in cases.entries) {
          final state = CalculatorState(
            tape: pressed(keys),
            refusal: TapeRefused(reason),
          );
          expect(state.toast, toast, reason: keys);
          expect(labels.toastTitle(toast), title, reason: keys);
          expect(labels.toastBody(toast), body, reason: keys);
        }
      });

      blocTest<CalculatorBloc, CalculatorState>(
        '5 ÷ ( 2 − 2 ) then % is refused and the Alert names the bracket',
        build: () => bloc,
        seed: () => CalculatorState(tape: pressed('5 ÷ ( 2 − 2 (')),
        act: (bloc) => bloc.add(const CalculatorPercentPressed()),
        expect: () => [
          CalculatorState(
            tape: pressed('5 ÷ ( 2 − 2 ('),
            refusal: const TapeRefused(TapeRefusal.percentDividesByZero),
            toastsRaised: 1,
          ),
        ],
        verify: (bloc) => expect(
          bloc.state.toast,
          const CalculatorPercentDividesByZeroToast(bracket: '(2−2)'),
        ),
      );
    });

    group('CA-1376 3/3: the percent tip (Section 1.8, "A percent tip"; '
        'Section 7, "Percent")', () {
      final labels = CalculatorLabelFormatter(AppLocalizationsEn());
      String? tipOf(String keys) =>
          switch (CalculatorState(tape: pressed(keys)).stripNote) {
            final CalculatorPercentTipNote tip => labels.noteText(tip),
            _ => null,
          };

      test('the tip says what the percent adds or takes off, of the total or '
          'of the bracket, in the total\'s unit (rows 386, 387, 389, 390, '
          '393)', () {
        expect(
          tipOf('1 0 0 0 + 5 0 0 + 1 0 %'),
          'Adds 10% of the total 1,500 = 150.',
        );
        expect(
          tipOf('1 0 0 0 − 1 0 %'),
          'Takes off 10% of the total 1,000 = 100.',
        );
        expect(tipOf('5 0 + 1 0 %'), 'Adds 10% of the total 50 = 5.');
        expect(
          tipOf('5 0 + 1 0 % + 1 0 %'),
          'Adds 10% of the total 55 = 5.5.',
          reason: 'each % follows its own +, so two tips show',
        );
        expect(
          tipOf('1 3 7 ft ft + 1 0 %'),
          'Adds 10% of the total 137ft² = 13.7ft².',
        );
        expect(tipOf('5 ft + 1 0 %'), 'Adds 10% of the total 5ft = 6in.');
        expect(
          tipOf('1 0 ft + 1 0 %'),
          'Adds 10% of the total 10ft = 1ft.',
          reason: 'only a length shorter than a foot is spelled in inches',
        );
        expect(
          tipOf('( 1 0 0 0 + 5 0 0 + 1 0 %'),
          'Adds 10% of the bracket 1,500 = 150.',
        );
        expect(
          tipOf('( 1 0 0 0 − 1 0 %'),
          'Takes off 10% of the bracket 1,000 = 100.',
        );
        expect(
          tipOf('2 0 0 + ( 5 + 5 ( %'),
          'Adds (5+5)% of the total 200 = 20.',
        );
      });

      test('no tip after × or ÷, where the percent is only the number ÷ 100 '
          '(row 388)', () {
        expect(tipOf('2 0 0 ÷ 1 0 %'), isNull);
        expect(tipOf('2 0 0 × 1 0 %'), isNull);
        expect(
          CalculatorState(tape: pressed('2 0 0 ÷ 1 0 %')).stripNote,
          isNull,
        );
      });

      test('the tip closes on the next key: =, +, ⌫ and C, and a refused '
          'digit; a warning wins over it (row 392)', () {
        expect(tipOf('5 0 + 1 0 % ='), isNull);
        expect(tipOf('5 0 + 1 0 % +'), isNull);
        expect(tipOf('5 0 + 1 0 % ⌫'), isNull);
        expect(tipOf('5 0 + 1 0 % ✕'), isNull);
        expect(
          CalculatorState(
            tape: pressed('5 0 + 1 0 %'),
            refusal: const TapeRefused(TapeRefusal.alreadyAPercent),
          ).stripNote,
          isNull,
          reason: 'a refused key is the next key too',
        );
        expect(
          CalculatorState(
            tape: pressed('[Pitch] 9 5 [Run] 1 0 ft + 1 0 %'),
          ).stripNote,
          const CalculatorPitchOutOfRangeNote(isAtLeastARightAngle: true),
        );
      });

      test('a tip over 52 characters shows its short form (Section 1.8)', () {
        const tip = CalculatorPercentTipNote(
          addsToTheTotal: true,
          percent: '12.5%',
          total: '1,234,567,890',
          amount: '154,320,986.25',
          ofTheBracket: false,
        );
        expect(
          AppLocalizationsEn()
              .calculatorNotePercentAddsOfTheTotal(
                tip.percent,
                tip.total,
                tip.amount,
              )
              .length,
          greaterThan(CalculatorLabelFormatter.longestNote),
        );
        expect(labels.noteText(tip), 'Adds 12.5% of the total so far.');
        expect(
          labels.noteText(
            const CalculatorPercentTipNote(
              addsToTheTotal: false,
              percent: '12.5%',
              total: '123,456,789',
              amount: '15,432,098.63',
              ofTheBracket: true,
            ),
          ),
          'Takes off 12.5% of the total so far.',
        );
        expect(
          labels.noteText(
            const CalculatorPercentTipNote(
              addsToTheTotal: true,
              percent: '10%',
              total: '1,234,567,890',
              amount: '1',
              ofTheBracket: false,
            ),
          ),
          'Adds 10% of the total 1,234,567,890 = 1.',
          reason: 'a tip within the limit is shown whole',
        );
      });
    });

    group('S2b: the history stage and the keypad fold live in the bloc '
        '(Sections 1.4 and 1.6; CA-1091)', () {
      blocTest<CalculatorBloc, CalculatorState>(
        'the display pulled down and pushed back, and the keypad folded and '
        'unfolded, are states; the panel shows only with the keypad folded '
        'under a collapsed display',
        build: () => bloc,
        act: (bloc) => bloc
          ..add(const CalculatorKeypadFoldChanged(true))
          ..add(
            const CalculatorHistoryStageChanged(
              DisplayAreaStage.expandedCurrent,
            ),
          )
          ..add(const CalculatorHistoryStageChanged(DisplayAreaStage.collapsed))
          ..add(const CalculatorKeypadFoldChanged(false)),
        expect: () => [
          const CalculatorState(isKeypadFolded: true),
          const CalculatorState(
            isKeypadFolded: true,
            historyStage: DisplayAreaStage.expandedCurrent,
          ),
          const CalculatorState(isKeypadFolded: true),
          const CalculatorState(),
        ],
        verify: (bloc) => expect(bloc.state.showsDetailPanel, isFalse),
      );

      blocTest<CalculatorBloc, CalculatorState>(
        'the display settling on the same stage twice, and the keypad folded '
        'twice over, are one state each: the next key is the next state',
        build: () => bloc,
        act: (bloc) => bloc
          ..add(
            const CalculatorHistoryStageChanged(
              DisplayAreaStage.expandedCurrent,
            ),
          )
          ..add(
            const CalculatorHistoryStageChanged(
              DisplayAreaStage.expandedCurrent,
            ),
          )
          ..add(const CalculatorKeypadFoldChanged(true))
          ..add(const CalculatorKeypadFoldChanged(true))
          ..add(const CalculatorDigitPressed('9')),
        expect: () => [
          const CalculatorState(historyStage: DisplayAreaStage.expandedCurrent),
          const CalculatorState(
            historyStage: DisplayAreaStage.expandedCurrent,
            isKeypadFolded: true,
          ),
          tapeState(pressed('9')).copyWith(
            historyStage: DisplayAreaStage.expandedCurrent,
            isKeypadFolded: true,
          ),
        ],
      );

      blocTest<CalculatorBloc, CalculatorState>(
        'the keypad folded under a full-screen display shows no panel; the '
        'panel comes when the display is pushed back',
        build: () => bloc,
        act: (bloc) => bloc
          ..add(
            const CalculatorHistoryStageChanged(DisplayAreaStage.fullScreen),
          )
          ..add(const CalculatorKeypadFoldChanged(true)),
        expect: () => [
          const CalculatorState(historyStage: DisplayAreaStage.fullScreen),
          const CalculatorState(
            historyStage: DisplayAreaStage.fullScreen,
            isKeypadFolded: true,
          ),
        ],
        verify: (bloc) {
          expect(bloc.state.showsDetailPanel, isFalse);
          expect(
            bloc.state
                .copyWith(historyStage: DisplayAreaStage.collapsed)
                .showsDetailPanel,
            isTrue,
          );
        },
      );

      test('the panel shows under no pulled-down display, full screen '
          'included, however the keypad stands', () {
        for (final stage in const [
          DisplayAreaStage.expandedCurrent,
          DisplayAreaStage.expandedPrevious,
          DisplayAreaStage.fullScreen,
        ]) {
          expect(
            CalculatorState(
              isKeypadFolded: true,
              historyStage: stage,
            ).showsDetailPanel,
            isFalse,
            reason: '$stage, folded',
          );
          expect(
            CalculatorState(historyStage: stage).showsDetailPanel,
            isFalse,
            reason: '$stage, unfolded',
          );
        }
      });

      blocTest<CalculatorBloc, CalculatorState>(
        'a reset keeps the stage and the fold, as C does',
        build: () => bloc,
        seed: () => tapeState(pressed('2 + 3 =')).copyWith(
          isKeypadFolded: true,
          historyStage: DisplayAreaStage.expandedCurrent,
        ),
        act: (bloc) => bloc.add(const CalculatorResetRequested()),
        expect: () => [
          const CalculatorState(
            isKeypadFolded: true,
            historyStage: DisplayAreaStage.expandedCurrent,
          ),
        ],
        verify: (bloc) {
          expect(bloc.state.tape.chips, isEmpty);
          expect(bloc.state.showsDetailPanel, isFalse);
        },
      );

      test('the panel shows under a collapsed display with the keypad '
          'folded, and not otherwise', () {
        expect(
          const CalculatorState(isKeypadFolded: true).showsDetailPanel,
          isTrue,
        );
        expect(const CalculatorState().showsDetailPanel, isFalse);
        expect(
          const CalculatorState(
            isKeypadFolded: true,
            historyStage: DisplayAreaStage.expandedPrevious,
          ).showsDetailPanel,
          isFalse,
        );
        expect(
          const CalculatorState(
            historyStage: DisplayAreaStage.collapsed,
          ).showsDetailPanel,
          isFalse,
        );
      });

      blocTest<CalculatorBloc, CalculatorState>(
        'C keeps the stage and the fold, as it keeps the group order',
        build: () => bloc,
        seed: () => tapeState(pressed('2 + 3 =')).copyWith(
          isKeypadFolded: true,
          historyStage: DisplayAreaStage.expandedCurrent,
        ),
        act: (bloc) =>
            bloc.add(const CalculatorControlActioned(ControlAction.clearAll)),
        verify: (bloc) {
          expect(bloc.state.tape.chips, isEmpty);
          expect(bloc.state.isKeypadFolded, isTrue);
          expect(bloc.state.historyStage, DisplayAreaStage.expandedCurrent);
        },
      );
    });

    group('S2b 2/2: the "Saved to history" card and the pending Undo '
        '(Section 1.7, term 2.19, rule 4.9; CA-1091)', () {
      blocTest<CalculatorBloc, CalculatorState>(
        'a banked tape shows the card with its result, and the next key '
        'closes the card and still does its job',
        build: () => bloc,
        act: (bloc) => bloc
          ..add(CalculatorSessionBanked(pressed('2 + 3 =')))
          ..add(const CalculatorDigitPressed('9')),
        expect: () => [
          CalculatorState(bankedTape: pressed('2 + 3 ='), toastsRaised: 1),
          tapeState(pressed('9')).copyWith(toastsRaised: 1),
        ],
        verify: (bloc) => expect(bloc.state.toast, isNull),
      );

      test('the card names the key and the result the tape rendered, and '
          'says carried forward when an operator took it', () {
        expect(
          CalculatorState(bankedTape: pressed('2 + 3 =')).toast,
          const CalculatorSavedToHistoryToast(
            resultKey: 'Calc',
            resultText: '5',
            carriedForward: false,
          ),
        );
        expect(
          CalculatorState(
            bankedTape: pressed('2 + 3 ='),
            bankedCarriedForward: true,
          ).toast,
          const CalculatorSavedToHistoryToast(
            resultKey: 'Calc',
            resultText: '5',
            carriedForward: true,
          ),
        );
        expect(
          CalculatorState(bankedTape: pressed('[Length] 2 2 ft')).toast,
          const CalculatorSavedToHistoryToast(
            resultKey: null,
            resultText: null,
            carriedForward: false,
          ),
        );
      });

      blocTest<CalculatorBloc, CalculatorState>(
        'Undo brings the banked tape back exactly and closes the card; Undo '
        'with no card does nothing',
        build: () => bloc,
        act: (bloc) => bloc
          ..add(CalculatorSessionBanked(pressed('[Length] 2 2 ft × 2 =')))
          ..add(const CalculatorUndoPressed())
          ..add(const CalculatorUndoPressed()),
        expect: () => [
          CalculatorState(
            bankedTape: pressed('[Length] 2 2 ft × 2 ='),
            toastsRaised: 1,
          ),
          tapeState(pressed('[Length] 2 2 ft × 2 =')).copyWith(toastsRaised: 1),
        ],
        verify: (bloc) {
          expect(bloc.state.tape, pressed('[Length] 2 2 ft × 2 ='));
          expect(bloc.state.toast, isNull);
        },
      );

      blocTest<CalculatorBloc, CalculatorState>(
        'View opens history full screen and closes the card; a new bank '
        'replaces the card',
        build: () => bloc,
        act: (bloc) => bloc
          ..add(CalculatorSessionBanked(pressed('2 + 3 =')))
          ..add(
            CalculatorSessionBanked(pressed('4 × 5 ='), carriedForward: true),
          )
          ..add(const CalculatorHistoryViewPressed()),
        expect: () => [
          CalculatorState(bankedTape: pressed('2 + 3 ='), toastsRaised: 1),
          CalculatorState(
            bankedTape: pressed('4 × 5 ='),
            bankedCarriedForward: true,
            toastsRaised: 2,
          ),
          const CalculatorState(
            bankedCarriedForward: true,
            toastsRaised: 2,
            historyStage: DisplayAreaStage.fullScreen,
          ),
        ],
        verify: (bloc) => expect(bloc.state.toast, isNull),
      );

      blocTest<CalculatorBloc, CalculatorState>(
        'banking an empty tape shows the card with no result',
        build: () => bloc,
        act: (bloc) => bloc.add(const CalculatorSessionBanked(Tape())),
        expect: () => [
          const CalculatorState(bankedTape: Tape(), toastsRaised: 1),
        ],
        verify: (bloc) => expect(
          bloc.state.toast,
          const CalculatorSavedToHistoryToast(
            resultKey: null,
            resultText: null,
            carriedForward: false,
          ),
        ),
      );

      blocTest<CalculatorBloc, CalculatorState>(
        'a tape that ended in an error banks with the card naming no result',
        build: () => bloc,
        act: (bloc) => bloc.add(CalculatorSessionBanked(pressed('5 ÷ 0 ='))),
        verify: (bloc) {
          expect(bloc.state.bankedTape, isNotNull);
          expect(bloc.state.bankedTape!.chips.last, isNot(isA<ResultChip>()));
          expect(
            bloc.state.toast,
            const CalculatorSavedToHistoryToast(
              resultKey: null,
              resultText: null,
              carriedForward: false,
            ),
          );
        },
      );

      test('the card renders a result with its unit as the tape did', () {
        expect(
          CalculatorState(
            bankedTape: pressed('[Length] 1 2 ft × 5 ft ='),
          ).toast,
          const CalculatorSavedToHistoryToast(
            resultKey: 'Calc',
            resultText: '60ft²',
            carriedForward: false,
          ),
        );
      });

      blocTest<CalculatorBloc, CalculatorState>(
        'Undo after the next key closed the card does nothing: the typed key '
        'stays',
        build: () => bloc,
        act: (bloc) => bloc
          ..add(CalculatorSessionBanked(pressed('2 + 3 =')))
          ..add(const CalculatorDigitPressed('9'))
          ..add(const CalculatorUndoPressed()),
        expect: () => [
          CalculatorState(bankedTape: pressed('2 + 3 ='), toastsRaised: 1),
          tapeState(pressed('9')).copyWith(toastsRaised: 1),
        ],
        verify: (bloc) {
          expect(bloc.state.tape, pressed('9'));
          expect(bloc.state.bankedTape, isNull);
        },
      );

      blocTest<CalculatorBloc, CalculatorState>(
        'View twice is one state: the next key is the next state, typed into '
        'the full-screen display',
        build: () => bloc,
        act: (bloc) => bloc
          ..add(CalculatorSessionBanked(pressed('2 + 3 =')))
          ..add(const CalculatorHistoryViewPressed())
          ..add(const CalculatorHistoryViewPressed())
          ..add(const CalculatorDigitPressed('9')),
        expect: () => [
          CalculatorState(bankedTape: pressed('2 + 3 ='), toastsRaised: 1),
          const CalculatorState(
            toastsRaised: 1,
            historyStage: DisplayAreaStage.fullScreen,
          ),
          tapeState(pressed('9')).copyWith(
            toastsRaised: 1,
            historyStage: DisplayAreaStage.fullScreen,
          ),
        ],
      );

      blocTest<CalculatorBloc, CalculatorState>(
        'C after a bank closes the card with the tape, and a reset does too',
        build: () => bloc,
        act: (bloc) => bloc
          ..add(CalculatorSessionBanked(pressed('2 + 3 =')))
          ..add(const CalculatorControlActioned(ControlAction.clearAll))
          ..add(CalculatorSessionBanked(pressed('4 × 5 =')))
          ..add(const CalculatorResetRequested()),
        expect: () => [
          CalculatorState(bankedTape: pressed('2 + 3 ='), toastsRaised: 1),
          const CalculatorState(toastsRaised: 1),
          CalculatorState(bankedTape: pressed('4 × 5 ='), toastsRaised: 2),
          const CalculatorState(toastsRaised: 2),
        ],
        verify: (bloc) {
          expect(bloc.state.bankedTape, isNull);
          expect(bloc.state.toast, isNull);
        },
      );

      blocTest<CalculatorBloc, CalculatorState>(
        'the card\'s ✕ hides the card and leaves the banked tape, as Undo is '
        'reachable from the card alone',
        build: () => bloc,
        act: (bloc) => bloc
          ..add(CalculatorSessionBanked(pressed('2 + 3 =')))
          ..add(const CalculatorToastClosed()),
        expect: () => [
          CalculatorState(bankedTape: pressed('2 + 3 ='), toastsRaised: 1),
          CalculatorState(
            bankedTape: pressed('2 + 3 ='),
            toastsRaised: 1,
            toastClosed: true,
          ),
        ],
        verify: (bloc) {
          expect(bloc.state.toastClosed, isTrue);
          expect(bloc.state.bankedTape, pressed('2 + 3 ='));
        },
      );

      test('a bank while an edit\'s removed result is still to be said shows '
          'the removed-result Alert, not the card', () {
        expect(
          CalculatorState(
            bankedTape: pressed('2 + 3 ='),
            removedResults: const ['Arcsine'],
          ).toast,
          const CalculatorResultRemovedToast(keys: ['Arcsine']),
        );
      });

      blocTest<CalculatorBloc, CalculatorState>(
        'a bank arriving while the removed-result Alert shows keeps that '
        'Alert and holds the tape for Undo behind it',
        build: () => bloc,
        seed: () => const CalculatorState(removedResults: ['Arcsine']),
        act: (bloc) => bloc.add(CalculatorSessionBanked(pressed('2 + 3 ='))),
        verify: (bloc) {
          expect(bloc.state.bankedTape, pressed('2 + 3 ='));
          expect(
            bloc.state.toast,
            const CalculatorResultRemovedToast(keys: ['Arcsine']),
          );
        },
      );

      blocTest<CalculatorBloc, CalculatorState>(
        'a refused key after a bank closes the card too, and its Alert shows',
        build: () => bloc,
        act: (bloc) => bloc
          ..add(CalculatorSessionBanked(pressed('2 + 3 =')))
          ..add(const CalculatorUnitSelected(Unit.foot)),
        skip: 1,
        verify: (bloc) {
          expect(bloc.state.bankedTape, isNull);
          expect(bloc.state.refusal, isNotNull);
          expect(bloc.state.toast, isNot(isA<CalculatorSavedToHistoryToast>()));
        },
      );
    });

    group('U1 1/2 (CA-1097): the card names the session history keeps its '
        'tape under, and Undo takes that session out again (walkthrough '
        '13.2)', () {
      List<String> sessionIds() => [
        for (final session in history.sessions) session.id,
      ];

      blocTest<CalculatorBloc, CalculatorState>(
        'Undo brings the tape back and takes the session the card names out '
        'of history; the other sessions stay',
        build: () => bloc,
        act: (bloc) async {
          await history.bankSession(pressed('1 + 1 ='));
          await history.bankSession(pressed('2 + 3 ='));
          bloc
            ..add(
              CalculatorSessionBanked(
                pressed('2 + 3 ='),
                sessionId: 'session-2',
              ),
            )
            ..add(const CalculatorUndoPressed());
        },
        expect: () => [
          CalculatorState(
            bankedTape: pressed('2 + 3 ='),
            bankedSessionId: 'session-2',
            toastsRaised: 1,
          ),
          tapeState(pressed('2 + 3 =')).copyWith(toastsRaised: 1),
        ],
        verify: (bloc) {
          expect(sessionIds(), contains('session-1'));
          expect(sessionIds(), isNot(contains('session-2')));
          expect(history.tapes.keys, isNot(contains('session-2')));
        },
      );

      blocTest<CalculatorBloc, CalculatorState>(
        'a card that names no session undoes the tape and takes nothing out '
        'of history',
        build: () => bloc,
        act: (bloc) async {
          await history.bankSession(pressed('2 + 3 ='));
          bloc
            ..add(CalculatorSessionBanked(pressed('2 + 3 =')))
            ..add(const CalculatorUndoPressed());
        },
        skip: 1,
        expect: () => [tapeState(pressed('2 + 3 =')).copyWith(toastsRaised: 1)],
        verify: (bloc) => expect(sessionIds(), contains('session-1')),
      );

      blocTest<CalculatorBloc, CalculatorState>(
        'View forgets the session with the card, so an Undo after it takes '
        'nothing out of history',
        build: () => bloc,
        act: (bloc) async {
          await history.bankSession(pressed('2 + 3 ='));
          bloc
            ..add(
              CalculatorSessionBanked(
                pressed('2 + 3 ='),
                sessionId: 'session-1',
              ),
            )
            ..add(const CalculatorHistoryViewPressed())
            ..add(const CalculatorUndoPressed());
        },
        skip: 1,
        expect: () => [
          const CalculatorState(
            toastsRaised: 1,
            historyStage: DisplayAreaStage.fullScreen,
          ),
        ],
        verify: (bloc) => expect(sessionIds(), contains('session-1')),
      );

      blocTest<CalculatorBloc, CalculatorState>(
        'the next key forgets the session with the card, and so does a key '
        'the tape refuses',
        build: () => bloc,
        act: (bloc) async {
          await history.bankSession(pressed('2 + 3 ='));
          bloc
            ..add(
              CalculatorSessionBanked(
                pressed('2 + 3 ='),
                sessionId: 'session-1',
              ),
            )
            ..add(const CalculatorDigitPressed('9'))
            ..add(
              CalculatorSessionBanked(
                pressed('2 + 3 ='),
                sessionId: 'session-1',
              ),
            )
            ..add(const CalculatorEqualsPressed())
            ..add(const CalculatorUndoPressed());
        },
        skip: 1,
        verify: (bloc) {
          expect(bloc.state.refusal, isNotNull);
          expect(bloc.state.bankedTape, isNull);
          expect(bloc.state.bankedSessionId, isNull);
          expect(sessionIds(), contains('session-1'));
        },
        expect: () => [
          tapeState(pressed('9')).copyWith(toastsRaised: 1),
          tapeState(pressed('9')).copyWith(
            bankedTape: () => pressed('2 + 3 ='),
            bankedSessionId: () => 'session-1',
            toastsRaised: 2,
          ),
          isA<CalculatorState>()
              .having((state) => state.tape, 'tape', pressed('9'))
              .having((state) => state.refusal, 'refusal', isNotNull)
              .having((state) => state.bankedTape, 'card', isNull)
              .having((state) => state.bankedSessionId, 'session', isNull),
        ],
      );

      blocTest<CalculatorBloc, CalculatorState>(
        'Undo still brings the tape back when the session is gone from '
        'history already',
        build: () => bloc,
        act: (bloc) => bloc
          ..add(
            CalculatorSessionBanked(pressed('2 + 3 ='), sessionId: 'session-9'),
          )
          ..add(const CalculatorUndoPressed()),
        skip: 1,
        expect: () => [tapeState(pressed('2 + 3 =')).copyWith(toastsRaised: 1)],
      );

      test('two cards that name different sessions are different states', () {
        expect(
          const CalculatorState(bankedSessionId: 'session-1'),
          isNot(const CalculatorState(bankedSessionId: 'session-2')),
        );
        expect(
          const CalculatorState(bankedSessionId: 'session-1'),
          const CalculatorState(bankedSessionId: 'session-1'),
        );
      });
    });

    group(
      'U1 2/2 (CA-1097): a finished tape banks itself (rule 4.9, term 2.19; '
      'decision tree rows 5, 32, 317 to 319)',
      () {
        void type(CalculatorBloc bloc, String keys) {
          for (final key in keys.split(' ')) {
            bloc.add(switch (key) {
              'ft' => const CalculatorUnitSelected(Unit.foot),
              'in' => const CalculatorUnitSelected(Unit.inch),
              'yd' => const CalculatorUnitSelected(Unit.yard),
              'lbs' => const CalculatorKeySelected('lbs'),
              '×' => const CalculatorOperatorPressed(Operator.multiply),
              '÷' => const CalculatorOperatorPressed(Operator.divide),
              '+' => const CalculatorOperatorPressed(Operator.add),
              '−' => const CalculatorOperatorPressed(Operator.subtract),
              '=' => const CalculatorEqualsPressed(),
              '(' => const CalculatorControlActioned(ControlAction.paren),
              '⌫' => const CalculatorControlActioned(ControlAction.delete),
              'C' => const CalculatorControlActioned(ControlAction.clearAll),
              'SIN' || 'COS' || 'ATAN' => CalculatorKeySelected(key),
              _ when key.startsWith('tap:') => CalculatorChipTapped(
                int.parse(key.substring(4)),
              ),
              _ when key.startsWith('[') => CalculatorKeySelected(
                key.substring(1, key.length - 1),
              ),
              _ => CalculatorDigitPressed(key),
            });
          }
        }

        /// [fresh] with the card of [banked] over it, as the state reads once
        /// the store has taken the tape.
        CalculatorState carded(
          Tape fresh,
          Tape banked, {
          String sessionId = 'session-1',
          bool carried = false,
        }) => CalculatorState(
          tape: fresh,
          bankedTape: banked,
          bankedSessionId: sessionId,
          bankedCarriedForward: carried,
          toastsRaised: 1,
        );

        Future<void> cardShows(CalculatorBloc bloc) =>
            bloc.stream.firstWhere((state) => state.bankedTape != null);

        /// [keys] with the leading suggestion landed, as = lands it.
        Tape landedLeading(String keys) {
          final tape = pressed(keys);
          final leading = CalculatorState(tape: tape).suggestions.first;
          return switch (tape.landAnswer(leading.key!, leading.value)) {
            TapeChanged(:final tape) => tape,
            _ => tape,
          };
        }

        /// The clean tape the last key of [keys] opened its chip on.
        Tape opened(String keys) => Tape(chips: [pressed(keys).chips.last]);

        blocTest<CalculatorBloc, CalculatorState>(
          'a digit after a result starts a clean tape at once, the finished '
          'tape goes to history whole, and the card names its result once the '
          'store has taken it (rows 5 and 317; S62)',
          build: () => bloc,
          act: (bloc) => type(bloc, '1 2 ft × 5 ft = 9'),
          skip: 7,
          expect: () => [
            tapeState(pressed('9')),
            carded(pressed('9'), pressed('1 2 ft × 5 ft =')),
          ],
          verify: (bloc) {
            expect(
              bloc.state.toast,
              const CalculatorSavedToHistoryToast(
                resultKey: 'Calc',
                resultText: '60ft²',
                carriedForward: false,
              ),
            );
            expect(history.sessions.single.resultText, '60ft²');
            expect(history.tapes['session-1'], pressed('1 2 ft × 5 ft ='));
          },
        );

        blocTest<CalculatorBloc, CalculatorState>(
          'Undo brings the banked tape back, drops the tape typed since and '
          'takes the session out of history; the tape it brought back is '
          'banked again when the calculator is left (row 317; walkthrough '
          '13.2)',
          build: () => bloc,
          act: (bloc) async {
            type(bloc, '2 + 3 = 9');
            await cardShows(bloc);
            bloc.add(const CalculatorUndoPressed());
          },
          skip: 6,
          expect: () => [
            tapeState(pressed('2 + 3 =')).copyWith(toastsRaised: 1),
          ],
          verify: (bloc) {
            expect(bloc.state.bankedSessionId, isNull);
            expect(bloc.state.toast, isNull);
            expect(
              [for (final session in history.sessions) session.id],
              ['session-2'],
            );
            expect(history.tapes['session-2'], pressed('2 + 3 ='));
          },
        );

        blocTest<CalculatorBloc, CalculatorState>(
          'typing after Undo banks the tape again, so the fresh-digit path has '
          'no hole (S78), and the second card replaces the first',
          build: () => bloc,
          act: (bloc) async {
            type(bloc, '2 + 3 = 9');
            await cardShows(bloc);
            bloc.add(const CalculatorUndoPressed());
            await bloc.stream.firstWhere((state) => state.bankedTape == null);
            type(bloc, '8');
          },
          skip: 7,
          expect: () => [
            tapeState(pressed('8')).copyWith(toastsRaised: 1),
            carded(
              pressed('8'),
              pressed('2 + 3 ='),
              sessionId: 'session-2',
            ).copyWith(toastsRaised: 2),
          ],
          verify: (bloc) => expect(history.sessions, hasLength(1)),
        );

        blocTest<CalculatorBloc, CalculatorState>(
          'an operator after a result banks the tape and carries the result '
          'forward as the Calc chip of the new one; the card says so and the '
          'equals key reads Ans (row 318; S17, S22)',
          build: () => bloc,
          act: (bloc) => type(bloc, '3 6 ft ÷ 1 2 ft = × 8 9'),
          skip: 9,
          expect: () => [
            tapeState(carriedForward('3 6 ft ÷ 1 2 ft =', '× 8')),
            tapeState(carriedForward('3 6 ft ÷ 1 2 ft =', '× 8 9')),
            carded(
              carriedForward('3 6 ft ÷ 1 2 ft =', '× 8 9'),
              pressed('3 6 ft ÷ 1 2 ft ='),
              carried: true,
            ),
          ],
          verify: (bloc) {
            expect(
              bloc.state.toast,
              const CalculatorSavedToHistoryToast(
                resultKey: 'Calc',
                resultText: '3',
                carriedForward: true,
              ),
            );
            expect(bloc.state.equalsKeyId, CalculatorState.ansKey);
            expect(bloc.state.suggestions.single.text, '267');
            expect(history.tapes['session-1'], pressed('3 6 ft ÷ 1 2 ft ='));
          },
        );

        blocTest<CalculatorBloc, CalculatorState>(
          'a named answer is carried forward as a Calc chip too: Area 180ft² '
          'then × opens the new tape on Calc 180ft² (rule 4.9: "the result '
          'opens the new tape as a Calc chip")',
          build: () => bloc,
          seed: () => tapeState(landedLeading('[Length] 2 0 ft [Height] 9 ft')),
          act: (bloc) => type(bloc, '×'),
          verify: (bloc) {
            expect(
              [
                for (final chip in bloc.state.chipsList)
                  '${chip.label} ${chip.value}',
              ],
              ['Calc 180ft²', 'null ×'],
            );
            expect(
              history.tapes['session-1'],
              landedLeading('[Length] 2 0 ft [Height] 9 ft'),
            );
            expect(history.sessions.last.resultText, '180ft²');
          },
        );

        blocTest<CalculatorBloc, CalculatorState>(
          'a function key after a result banks the tape and opens its chip on '
          'a clean one when the tape holds no named value: 38 SIN then Pitch '
          '(walkthrough 23.1, "Saved to history · Sine"; row 262)',
          build: () => bloc,
          act: (bloc) => type(bloc, '3 8 SIN [Pitch]'),
          skip: 3,
          expect: () => [
            tapeState(opened('3 8 [SIN] [Pitch]')),
            carded(opened('3 8 [SIN] [Pitch]'), pressed('3 8 [SIN]')),
          ],
          verify: (bloc) =>
              expect(history.sessions.single.resultText, '0.615661'),
        );

        blocTest<CalculatorBloc, CalculatorState>(
          'a dimension key after an answer banks the tape whatever it holds '
          'and opens its chip on a clean one: Rise 6in Run 12in = then Width '
          'sends the pitch tape to history (decision tree row 32)',
          build: () => bloc,
          act: (bloc) async {
            type(bloc, '[Rise] 6 in [Run] 1 2 in =');
            final answered = await bloc.stream.firstWhere(
              (state) => state.tape.endsWithResult,
            );
            final carded = bloc.stream.firstWhere(
              (state) => state.bankedTape != null,
            );
            type(bloc, '[Width]');
            final banked = await carded;
            expect(banked.bankedTape, answered.tape);
            expect(answered.tape.chips.last, isA<ResultChip>());
            expect(history.tapes.values.single, answered.tape);
          },
          verify: (bloc) {
            expect(bloc.state.tape, pressed('[Width]'));
            expect(history.sessions, hasLength(1));
          },
        );

        blocTest<CalculatorBloc, CalculatorState>(
          'an accepted answer counts as a result too: Diagonal accepted, then '
          'Height banks the room and opens Height alone (row 32; the doc\'s '
          'walkthrough 15.1 goes on with the tape, and the tree wins)',
          build: () => bloc,
          act: (bloc) async {
            type(bloc, '[Length] 2 2 ft [Width] 1 8 ft 8 in');
            final offered = await bloc.stream.firstWhere(
              (state) => state.valueText == '18ft 8in',
            );
            final carded = bloc.stream.firstWhere(
              (state) => state.bankedTape != null,
            );
            bloc.add(CalculatorSuggestionAccepted(offered.suggestions[1]));
            type(bloc, '[Height] 9 ft');
            await carded;
          },
          verify: (bloc) {
            expect(bloc.state.tape, pressed('[Height] 9 ft'));
            expect(
              [
                for (final chip in bloc.state.bankedTape!.chips)
                  if (chip case ResultChip(:final key)) key,
              ],
              [DeterministicRules.diagonalKey],
            );
          },
        );

        blocTest<CalculatorBloc, CalculatorState>(
          'after an error a dimension key starts a clean tape whatever the '
          'tape held: Length 22ft ÷ 2lbs = then Width banks the error tape '
          '(rule 4.12)',
          build: () => bloc,
          act: (bloc) => type(bloc, '[Length] 2 2 ft ÷ 2 lbs = [Width]'),
          skip: 8,
          expect: () => [
            tapeState(pressed('[Width]')),
            carded(pressed('[Width]'), pressed('[Length] 2 2 ft ÷ 2 lbs =')),
          ],
          verify: (bloc) =>
              expect(history.tapes['session-1']!.endsWithError, isTrue),
        );

        blocTest<CalculatorBloc, CalculatorState>(
          'the bracket key after a result banks the tape, and the new tape '
          'starts with the open bracket (row 319, case 2)',
          build: () => bloc,
          act: (bloc) => type(bloc, '5 + 5 = ('),
          skip: 4,
          expect: () => [
            tapeState(pressed('(')),
            carded(pressed('('), pressed('5 + 5 =')),
          ],
          verify: (bloc) => expect(bloc.state.tape.openBracket, isNotNull),
        );

        blocTest<CalculatorBloc, CalculatorState>(
          'a trig key that can use the result works on it and starts no new '
          'tape: 12 + 0 = then ATAN (rule 4.9; row 1)',
          build: () => bloc,
          act: (bloc) => type(bloc, '1 2 + 0 = ATAN'),
          skip: 5,
          expect: () => [tapeState(pressed('1 2 + 0 = [ATAN]'))],
        );

        blocTest<CalculatorBloc, CalculatorState>(
          'a trig key that cannot use the answer opens its chip on a clean '
          'tape, and the tape before it is banked: 38 SIN then COS (S96)',
          build: () => bloc,
          act: (bloc) => type(bloc, '3 8 SIN COS'),
          skip: 3,
          expect: () => [
            tapeState(opened('3 8 [SIN] [COS]')),
            carded(opened('3 8 [SIN] [COS]'), pressed('3 8 [SIN]')),
          ],
          verify: (bloc) =>
              expect(bloc.state.labelKeyId, TrigFunction.cosine.key),
        );

        blocTest<CalculatorBloc, CalculatorState>(
          'a key that works on the answer starts no session: a unit key '
          'converts it, an accepted chip lands beside it, and = says the '
          'result is shown',
          build: () => bloc,
          act: (bloc) async {
            type(bloc, '1 2 ft × 5 ft = yd =');
            await bloc.stream.firstWhere((state) => state.refusal != null);
            bloc.add(
              CalculatorSuggestionAccepted(bloc.state.conversions.first),
            );
          },
          skip: 7,
          verify: (bloc) {
            expect(bloc.state.bankedTape, isNull);
            expect(bloc.state.tape.chips, hasLength(3));
            expect(
              history.tapes.values.single.chips,
              bloc.state.tape.chips,
              reason: 'banked once, whole, when the calculator is left',
            );
          },
        );

        for (final key in const [
          'Msnry',
          'Drywal',
          'Footng',
          'Fence',
          'Qty@OC',
          'Cost',
          'Weight',
        ]) {
          blocTest<CalculatorBloc, CalculatorState>(
            'the Materials key $key asks about the tape it is pressed on, so '
            'after a result it goes on with that tape and banks nothing '
            '(term 2.7)',
            build: () => bloc,
            act: (bloc) => type(bloc, '1 2 ft × 5 ft = [$key]'),
            skip: 7,
            expect: () => [tapeState(pressed('1 2 ft × 5 ft = [$key]'))],
          );
        }

        blocTest<CalculatorBloc, CalculatorState>(
          'after an error a function key or a digit starts a clean tape and '
          'the error tape goes to history, its card naming no result (rule '
          '4.12; S71)',
          build: () => bloc,
          act: (bloc) => type(bloc, '7 8 lbs ÷ 1 2 ft = [Length]'),
          skip: 8,
          expect: () => [
            tapeState(pressed('[Length]')),
            carded(pressed('[Length]'), pressed('7 8 lbs ÷ 1 2 ft =')),
          ],
          verify: (bloc) {
            expect(
              bloc.state.toast,
              const CalculatorSavedToHistoryToast(
                resultKey: null,
                resultText: null,
                carriedForward: false,
              ),
            );
            expect(history.sessions.single.resultText, isNull);
          },
        );

        blocTest<CalculatorBloc, CalculatorState>(
          'after ÷ 0 = the next digit goes into the reopened divisor: no new '
          'tape and nothing banked by the key (rows 80 and 453)',
          build: () => bloc,
          act: (bloc) => type(bloc, '5 ÷ 0 = 7'),
          skip: 4,
          expect: () => [tapeState(pressed('5 ÷ 0 = 7'))],
        );

        blocTest<CalculatorBloc, CalculatorState>(
          'a key that leaves an edit and opens a chip after the result banks '
          'the tape as the edit left it, its result worked out again',
          build: () => bloc,
          act: (bloc) => type(bloc, '2 + 3 = tap:0 ⌫ 7 [Width]'),
          skip: 7,
          expect: () => [
            tapeState(pressed('[Width]')),
            carded(
              pressed('[Width]'),
              Tape(
                chips: pressed('2 + 3 = tap:0 ⌫ 7 [Width]').chips.sublist(0, 3),
              ),
            ),
          ],
          verify: (bloc) => expect(history.sessions.single.resultText, '10'),
        );

        blocTest<CalculatorBloc, CalculatorState>(
          'C on a tape that holds a result clears it, banks it and shows the '
          'card, and Undo brings it back (row 319, case 1)',
          build: () => bloc,
          act: (bloc) async {
            type(bloc, '5 + 5 = C');
            await cardShows(bloc);
            bloc.add(const CalculatorUndoPressed());
          },
          skip: 4,
          expect: () => [
            CalculatorState.initial(),
            carded(const Tape(), pressed('5 + 5 =')),
            tapeState(pressed('5 + 5 =')).copyWith(toastsRaised: 1),
          ],
        );

        blocTest<CalculatorBloc, CalculatorState>(
          'C on a tape with no result banks nothing, and C on a chain that '
          'went on from a carried result banks that chain too, since the tape '
          'holds a result',
          build: () => bloc,
          act: (bloc) => type(bloc, '5 + C 5 + 5 = × 2 C'),
          verify: (bloc) {
            expect(bloc.state.tape.chips, isEmpty);
            expect(
              [for (final session in history.sessions) session.resultText],
              [null, '10'],
              reason:
                  '5 + 5 = when × carried it forward, then Calc 10 × 2 when C '
                  'cleared it; never the 5 +',
            );
            expect(
              history.tapes['session-2'],
              carriedForward('5 + 5 =', '× 2'),
            );
          },
        );

        blocTest<CalculatorBloc, CalculatorState>(
          'a tape the store refuses shows no card: the key still does its job '
          'and nothing claims to be saved',
          build: () => bloc,
          setUp: () => history.writeFailure = const CalculatorFailure(
            errorType: CalculatorErrorType.storageError,
          ),
          act: (bloc) => type(bloc, '2 + 3 = 9 C'),
          skip: 4,
          expect: () => [tapeState(pressed('9')), CalculatorState.initial()],
          verify: (bloc) {
            expect(history.bankCallCount, 1);
            expect(history.sessions, isEmpty);
          },
        );

        blocTest<CalculatorBloc, CalculatorState>(
          'with nobody signed in a bank is refused and Undo has nothing to '
          'bring back',
          build: () => bloc,
          setUp: () => history.signedIn = false,
          act: (bloc) {
            type(bloc, '2 + 3 = 9');
            bloc.add(const CalculatorUndoPressed());
          },
          skip: 4,
          expect: () => [tapeState(pressed('9'))],
        );

        blocTest<CalculatorBloc, CalculatorState>(
          'View after a bank opens history, closes the card and forgets the '
          'pending Undo',
          build: () => bloc,
          act: (bloc) async {
            type(bloc, '2 + 3 = 9');
            await cardShows(bloc);
            bloc
              ..add(const CalculatorHistoryViewPressed())
              ..add(const CalculatorUndoPressed());
          },
          skip: 6,
          expect: () => [
            tapeState(pressed('9')).copyWith(
              toastsRaised: 1,
              historyStage: DisplayAreaStage.fullScreen,
            ),
          ],
          verify: (bloc) => expect(history.sessions, hasLength(1)),
        );

        blocTest<CalculatorBloc, CalculatorState>(
          '⌫ on a result takes the result off and reopens the value before '
          'it: one chip fewer is no new tape, and nothing is banked (row 117)',
          build: () => bloc,
          act: (bloc) => type(bloc, '2 + 3 = ⌫'),
          skip: 4,
          expect: () => [tapeState(pressed('2 + 3 = ⌫'))],
          verify: (bloc) => expect(bloc.state.tape.chips, hasLength(2)),
        );

        blocTest<CalculatorBloc, CalculatorState>(
          'the key does its job before the store answers, and the card shows '
          'when it has: keys typed meanwhile are kept, and Undo then brings '
          'the banked tape back over them',
          build: () => bloc,
          setUp: () => history.gate = Completer<void>(),
          act: (bloc) async {
            type(bloc, '2 + 3 = 9 4');
            await bloc.stream.firstWhere((state) => state.valueText == '94');
            history.gate!.complete();
            await cardShows(bloc);
            bloc.add(const CalculatorUndoPressed());
          },
          skip: 4,
          expect: () => [
            tapeState(pressed('9')),
            tapeState(pressed('9 4')),
            carded(pressed('9 4'), pressed('2 + 3 =')),
            tapeState(pressed('2 + 3 =')).copyWith(toastsRaised: 1),
          ],
        );

        blocTest<CalculatorBloc, CalculatorState>(
          'a bank still on its way when the calculator is left shows no card '
          'and raises nothing: the tape is in history all the same',
          build: () => bloc,
          setUp: () => history.gate = Completer<void>(),
          act: (bloc) async {
            type(bloc, '2 + 3 = 9');
            await bloc.stream.firstWhere((state) => state.valueText == '9');
            final left = bloc.close();
            history.gate!.complete();
            await left;
          },
          skip: 4,
          expect: () => [tapeState(pressed('9'))],
          verify: (bloc) =>
              expect(history.tapes.values.single, pressed('2 + 3 =')),
        );

        group('leaving the calculator (term 2.19; Section 5.1, "Closes the '
            'calculator"; rows 421 and 422)', () {
          blocTest<CalculatorBloc, CalculatorState>(
            'banks the open tape, finished or not: 5 + is kept with no result',
            build: () => bloc,
            act: (bloc) => type(bloc, '5 +'),
            verify: (bloc) {
              expect(history.tapes.values.single, pressed('5 +'));
              expect(history.sessions.single.resultText, isNull);
            },
          );

          blocTest<CalculatorBloc, CalculatorState>(
            'banks a finished tape once, with its result',
            build: () => bloc,
            act: (bloc) => type(bloc, '5 + 5 ='),
            verify: (bloc) => expect(history.sessions.single.resultText, '10'),
          );

          blocTest<CalculatorBloc, CalculatorState>(
            'banks nothing from an empty tape (row 422, case 2)',
            build: () => bloc,
            act: (bloc) => type(bloc, '5 + C'),
            verify: (bloc) => expect(history.sessions, isEmpty),
          );

          blocTest<CalculatorBloc, CalculatorState>(
            'banks nothing from a lone number that never sealed (rule 4.13)',
            build: () => bloc,
            act: (bloc) => type(bloc, '[Length] 5'),
            verify: (bloc) => expect(history.sessions, isEmpty),
          );

          blocTest<CalculatorBloc, CalculatorState>(
            'banks nothing from the bracket a key opened after a result: 5 + '
            '5 = then ( leaves the one session the key banked',
            build: () => bloc,
            act: (bloc) => type(bloc, '5 + 5 = ('),
            verify: (bloc) =>
                expect(history.tapes.values.single, pressed('5 + 5 =')),
          );

          blocTest<CalculatorBloc, CalculatorState>(
            'banks once, however often the bloc is closed',
            build: () => bloc,
            act: (bloc) => type(bloc, '5 +'),
            verify: (bloc) async {
              await bloc.close();

              expect(history.tapes.values.single, pressed('5 +'));
            },
          );

          blocTest<CalculatorBloc, CalculatorState>(
            'banks nothing more after a key already banked the tape: 2 + 3 = '
            'then 9 leaves one session',
            build: () => bloc,
            act: (bloc) => type(bloc, '2 + 3 = 9'),
            verify: (bloc) => expect(history.sessions, hasLength(1)),
          );

          test('the state says whether there is work to bank', () {
            expect(const CalculatorState().holdsWorkToBank, isFalse);
            expect(tapeState(pressed('5')).holdsWorkToBank, isFalse);
            expect(tapeState(pressed('[Length]')).holdsWorkToBank, isFalse);
            expect(tapeState(pressed('5 +')).holdsWorkToBank, isTrue);
            expect(tapeState(pressed('5 + 5 =')).holdsWorkToBank, isTrue);
            expect(tapeState(pressed('5 ft [Width]')).holdsWorkToBank, isTrue);
            expect(
              tapeState(carriedForward('5 + 5 =', '')).holdsWorkToBank,
              isTrue,
              reason: 'one finished chip and nothing being typed',
            );
            expect(tapeState(pressed('(')).holdsWorkToBank, isFalse);
            expect(tapeState(pressed('( 5')).holdsWorkToBank, isFalse);
            expect(tapeState(pressed('( 5 +')).holdsWorkToBank, isTrue);
            expect(tapeState(pressed('5 + (')).holdsWorkToBank, isTrue);
          });
        });
      },
    );

    group('T1b: the order of the function-key groups (Section 1.5)', () {
      const reorderedUnitFirst = [
        CalculatorGroupId.unit,
        CalculatorGroupId.basicGeometry,
        CalculatorGroupId.shapes,
        CalculatorGroupId.materials,
        CalculatorGroupId.trigonometry,
      ];

      blocTest<CalculatorBloc, CalculatorState>(
        'a group dragged to the front in View all leads the order, and the '
        'group on the keyboard follows to its new index',
        build: () => bloc,
        act: (bloc) => bloc
          ..add(const CalculatorGroupSelected(3))
          ..add(const CalculatorGroupsReordered(oldIndex: 3, newIndex: 0)),
        skip: 1,
        expect: () => [
          const CalculatorState(
            currentGroupIndex: 0,
            groupOrder: reorderedUnitFirst,
          ),
        ],
      );

      blocTest<CalculatorBloc, CalculatorState>(
        'a group dragged in front of the one on the keyboard moves that one '
        'back by a place',
        build: () => bloc,
        act: (bloc) =>
            bloc.add(const CalculatorGroupsReordered(oldIndex: 4, newIndex: 0)),
        expect: () => [
          const CalculatorState(
            currentGroupIndex: 1,
            groupOrder: [
              CalculatorGroupId.trigonometry,
              CalculatorGroupId.basicGeometry,
              CalculatorGroupId.shapes,
              CalculatorGroupId.materials,
              CalculatorGroupId.unit,
            ],
          ),
        ],
      );

      blocTest<CalculatorBloc, CalculatorState>(
        'a drag that leaves the shown group where it is still changes the '
        'order',
        build: () => bloc,
        act: (bloc) =>
            bloc.add(const CalculatorGroupsReordered(oldIndex: 3, newIndex: 4)),
        expect: () => [
          const CalculatorState(
            groupOrder: [
              CalculatorGroupId.basicGeometry,
              CalculatorGroupId.shapes,
              CalculatorGroupId.materials,
              CalculatorGroupId.trigonometry,
              CalculatorGroupId.unit,
            ],
          ),
        ],
      );

      test('two states that differ only in the order of the groups are not '
          'equal, so the keyboard redraws after a drag', () {
        expect(
          const CalculatorState(groupOrder: reorderedUnitFirst),
          isNot(equals(const CalculatorState())),
        );
      });

      blocTest<CalculatorBloc, CalculatorState>(
        'a drag that ends where it started changes nothing',
        build: () => bloc,
        act: (bloc) =>
            bloc.add(const CalculatorGroupsReordered(oldIndex: 2, newIndex: 2)),
        expect: () => const <CalculatorState>[],
      );

      blocTest<CalculatorBloc, CalculatorState>(
        'a drag from or to a place outside the five groups changes nothing',
        build: () => bloc,
        act: (bloc) => bloc
          ..add(const CalculatorGroupsReordered(oldIndex: 0, newIndex: 5))
          ..add(const CalculatorGroupsReordered(oldIndex: 5, newIndex: 0))
          ..add(const CalculatorGroupsReordered(oldIndex: -1, newIndex: 0))
          ..add(const CalculatorGroupsReordered(oldIndex: 0, newIndex: -1)),
        expect: () => const <CalculatorState>[],
      );

      blocTest<CalculatorBloc, CalculatorState>(
        'C and a reset keep the order of the groups',
        build: () => bloc,
        act: (bloc) => bloc
          ..add(const CalculatorGroupsReordered(oldIndex: 3, newIndex: 0))
          ..add(const CalculatorDigitPressed('4'))
          ..add(const CalculatorControlActioned(ControlAction.clearAll))
          ..add(const CalculatorDigitPressed('4'))
          ..add(const CalculatorResetRequested()),
        skip: 2,
        expect: () => [
          const CalculatorState(
            currentGroupIndex: 1,
            groupOrder: reorderedUnitFirst,
          ),
          tapeState(
            pressed('4'),
          ).copyWith(currentGroupIndex: 1, groupOrder: reorderedUnitFirst),
          const CalculatorState(
            currentGroupIndex: 1,
            groupOrder: reorderedUnitFirst,
          ),
        ],
      );
    });

    group('S1b 2/4: the strip and the equals key', () {
      List<String> row1(CalculatorState state) => [
        for (final suggestion in state.suggestions)
          '${suggestion.key}: ${suggestion.text}',
      ];

      List<String> row2(CalculatorState state) => [
        for (final suggestion in state.conversions) suggestion.text,
      ];

      CalculatorSuggestion leadingOf(String keys) =>
          CalculatorState(tape: pressed(keys)).suggestions.first;

      CalculatorSuggestion conversionOf(String keys, {int index = 0}) =>
          CalculatorState(tape: pressed(keys)).conversions[index];

      void type(CalculatorBloc bloc, String keys) {
        for (final key in keys.split(' ')) {
          bloc.add(switch (key) {
            'ft' => const CalculatorUnitSelected(Unit.foot),
            'in' => const CalculatorUnitSelected(Unit.inch),
            'yd' => const CalculatorUnitSelected(Unit.yard),
            'lbs' => const CalculatorKeySelected('lbs'),
            '×' => const CalculatorOperatorPressed(Operator.multiply),
            '÷' => const CalculatorOperatorPressed(Operator.divide),
            '+' => const CalculatorOperatorPressed(Operator.add),
            '=' => const CalculatorEqualsPressed(),
            '(' => const CalculatorControlActioned(ControlAction.paren),
            '/' => const CalculatorFractionPressed(),
            _ when key.startsWith('[') => CalculatorKeySelected(
              key.substring(1, key.length - 1),
            ),
            _ => CalculatorDigitPressed(key),
          });
        }
      }

      blocTest<CalculatorBloc, CalculatorState>(
        'two named sides earn the rectangle answers on row 1, the value on '
        'screen its conversions on row 2, and the equals key reads Area (S01)',
        build: () => bloc,
        act: (bloc) => type(bloc, '[Length] 2 2 ft [Width] 1 8 ft 8 in'),
        skip: 9,
        expect: () => [
          tapeState(pressed('[Length] 2 2 ft [Width] 1 8 ft 8 in')),
        ],
        verify: (bloc) {
          expect(row1(bloc.state), [
            'Area: 410.67ft²',
            'Diagonal: 28.85ft',
            'Perimeter: 81.33ft',
          ]);
          expect(row2(bloc.state), ['224in', '5.69m']);
          expect([
            for (final s in bloc.state.suggestions) s.kind,
          ], everyElement(CalculatorSuggestionKind.answer));
          expect([
            for (final s in bloc.state.conversions) s.kind,
          ], everyElement(CalculatorSuggestionKind.conversion));
          expect(bloc.state.equalsKeyId, DeterministicRules.areaKey);
        },
      );

      test('Rise and Run earn the three pitch spellings first, and a landed '
          'spelling leaves the row (S08)', () {
        final offered = CalculatorState(
          tape: pressed('[Rise] 6 ft [Run] 1 2 ft'),
        );
        expect(row1(offered), [
          'Pitch-rise per 12in run: 6in/12in',
          'Pitch-degrees: 26.57°',
          'Pitch-grade: 50%',
          'Diagonal: 13.42ft',
          'Arc angle: 180°',
          'Arc radius: 6ft',
          'Arc length: 18.85ft',
        ]);
        expect(offered.equalsKeyId, DeterministicRules.pitchRiseKey);
        final landed = CalculatorState(
          tape: pressed('[Rise] 6 ft [Run] 1 2 ft [Pitch]'),
        );
        expect(row1(landed), [
          'Pitch-degrees: 26.57°',
          'Pitch-grade: 50%',
          'Diagonal: 13.42ft',
          'Arc angle: 180°',
          'Arc radius: 6ft',
          'Arc length: 18.85ft',
        ]);
        expect(row2(landed), isEmpty);
      });

      test('row 2 offers no D:M:S under a pitch answer, which is not a pitch '
          'reading, while another angle answer still offers it', () {
        final degrees = CalculatorState(
          tape: pressed('[Rise] 6 ft [Run] 1 2 ft [Pitch] [Pitch]'),
        );
        expect(degrees.valueText, '26.57°');
        expect(row2(degrees), isEmpty);
        expect(row2(CalculatorState(tape: pressed('1 2 ÷ 2 3 [ATAN]'))), [
          '27°33\'10"',
        ]);
      });

      test('row 2 offers no lengths for a number typed under Pitch in inches, '
          'which is a rise per 12in, while a length under another key still '
          'converts', () {
        for (final keys in ['[Pitch] 8 in', '[Pitch] 0 in']) {
          expect(row2(CalculatorState(tape: pressed(keys))), isEmpty);
        }
        expect(row2(CalculatorState(tape: pressed('[Rise] 8 in'))), isNotEmpty);
      });

      test('a division by zero silences the strip while it is typed, after '
          'the = that lands its error chip, and until the divisor is retyped '
          '(doc line 771)', () {
        const sides = '[Length] 2 2 ft [Width] 1 8 ft 8 in';
        final typed = CalculatorState(tape: pressed('$sides ÷ 0'));
        expect(row1(typed), isEmpty);
        expect(row2(typed), isEmpty);
        expect(typed.equalsKeyId, isNull);
        final landed = CalculatorState(tape: pressed('$sides ÷ 0 ='));
        expect(landed.tape.endsWithError, isFalse);
        expect(row1(landed), isEmpty);
        expect(row2(landed), isEmpty);
        expect(landed.equalsKeyId, isNull);
        final retyped = CalculatorState(tape: pressed('$sides ÷ 0 = 2'));
        expect(row1(retyped), ['Calc: 9ft 4in']);
        expect(retyped.equalsKeyId, Tape.calcKey);
      });

      test('the equals key names only an answer = lands: after a result or '
          'with an operator waiting for its number it reads =, though the '
          'strip still offers answers (term 2.15, Section 1.2)', () {
        const sides = '[Length] 2 0 ft [Width] 1 0 ft';
        final offered = CalculatorState(tape: pressed(sides));
        final CalculatorSuggestion(:value) = offered.suggestions.first;
        expect(offered.equalsLands, offered.suggestions.first);
        expect(offered.equalsKeyId, DeterministicRules.areaKey);
        final landed = pressed(
          sides,
        ).landAnswer(DeterministicRules.areaKey, value);
        for (final state in [
          CalculatorState(tape: (landed as TapeChanged).tape),
          CalculatorState(tape: pressed('$sides +')),
        ]) {
          expect(state.suggestions, isNotEmpty);
          expect(state.equalsLands, isNull);
          expect(state.equalsKeyId, isNull);
        }
      });

      test('an error chip that ends the chain hides the rule answers the '
          'named values would earn, and a result after it starts a chain '
          'that is offered again', () {
        final error = CalculatorState(
          tape: pressed('[Length] 2 2 ft [Width] 1 8 ft + 7 8 lbs ='),
        );
        expect(error.tape.endsWithError, isTrue);
        expect(row1(error), isEmpty);
        expect(row2(error), isEmpty);
        expect(error.equalsKeyId, isNull);
        expect(row1(CalculatorState(tape: pressed('5 ÷ 0 = 2 = + 1'))), [
          'Calc: 3.5',
        ]);
      });

      test('a new value typed after an error chip brings the strip back: the '
          'silence reaches back only to the chip that starts the chain, '
          'never past a chip with no operator', () {
        final bare = CalculatorState(tape: pressed('7 8 lbs ÷ 1 2 ft = 3 ft'));
        expect(row2(bare), ['36in', '1yd', '0.91m']);
        expect(bare.equalsKeyId, isNull);
        final named = CalculatorState(
          tape: pressed('[Length] 2 2 ft [Width] 1 8 ft + 7 8 lbs = 3 ft'),
        );
        expect(row2(named), ['36in', '1yd', '0.91m']);
        expect(
          row1(named),
          isNot(isEmpty),
          reason: 'the named values before the error keep their answers',
        );
      });

      test('an open bracket after named values keeps the strip empty, with '
          'nothing on the equals key, until it closes (Section 7)', () {
        final open = CalculatorState(
          tape: pressed('[Length] 2 2 ft [Width] 1 8 ft + ( 2'),
        );
        expect(row1(open), isEmpty);
        expect(row2(open), isEmpty);
        expect(open.equalsKeyId, isNull);
        final closed = CalculatorState(
          tape: pressed('[Length] 2 2 ft [Width] 1 8 ft + ( 2 ft ('),
        );
        expect(row1(closed), isNot(isEmpty));
        expect(closed.equalsKeyId, isNotNull);
      });

      test('a trig chip that continues a chain follows Calc, so = lands the '
          'chain; one that stands alone or builds its own ratio leads '
          '(term 2.15, rule 4.6, walkthrough 23.3)', () {
        final product = CalculatorState(tape: pressed('5 × [SIN] 3 0'));
        expect(row1(product), ['Calc: 2.5', 'Sine: 0.5']);
        expect(product.equalsKeyId, Tape.calcKey);
        final sum = CalculatorState(tape: pressed('5 + [SIN] 3 0'));
        expect(row1(sum), ['Calc: 5.5', 'Sine: 0.5']);
        expect(sum.equalsKeyId, Tape.calcKey);
        final reach = CalculatorState(tape: pressed('5 + [ATAN] 1 6 ÷ 1 2'));
        expect(row1(reach), ['Calc: 58.13°', 'Arctangent(16 ÷ 12): 53.13°']);
        expect(reach.equalsKeyId, Tape.calcKey);
        final alone = CalculatorState(tape: pressed('[ATAN] 1 6 ÷ 1 2'));
        expect(row1(alone), ['Arctangent(16 ÷ 12): 53.13°', 'Calc: 1.33']);
        expect(alone.equalsKeyId, 'Arctangent(16 ÷ 12)');
        final typed = CalculatorState(tape: pressed('[SIN] 3 0'));
        expect(row1(typed), ['Sine: 0.5']);
        expect(typed.equalsKeyId, 'Sine');
      });

      test('a bracket that continues a chain from a result offers Calc with '
          'Ans on the equals key (doc line 1011)', () {
        final group = CalculatorState(
          tape: pressed('3 6 ft ÷ 1 2 ft = × ( 4 + 1 ('),
        );
        expect(row1(group), ['Calc: 15']);
        expect(group.equalsKeyId, CalculatorState.ansKey);
        final open = CalculatorState(tape: pressed('3 6 ft ÷ 1 2 ft = × ( 4'));
        expect(row1(open), isEmpty);
        expect(open.equalsKeyId, isNull);
      });

      test('row 2 holds the value on screen in its other units: a typed '
          'length, a result, an angle answer (S03, S16)', () {
        final typed = CalculatorState(tape: pressed('[Length] 2 2 ft'));
        expect(row1(typed), isEmpty);
        expect(typed.equalsKeyId, isNull);
        expect(row2(typed), ['264in', '7.33yd', '6.71m']);
        expect(row2(CalculatorState(tape: pressed('[Length] 2 2 ft in'))), [
          '22ft 0in',
          '6,706mm',
        ]);
        expect(row2(CalculatorState(tape: pressed('1 2 ft × 5 ft ='))), [
          '6.67yd²',
          '8,640in²',
          '5.57m²',
        ]);
        expect(row2(CalculatorState(tape: pressed('1 2 ÷ 2 3 [ATAN]'))), [
          '27°33\'10"',
        ]);
        expect([
          for (final s in typed.conversions) s.kind,
        ], everyElement(CalculatorSuggestionKind.conversion));
      });

      blocTest<CalculatorBloc, CalculatorState>(
        'an operator with values on both sides offers Calc, the equals key '
        'reads Calc, and = lands it (S14)',
        build: () => bloc,
        act: (bloc) => type(bloc, '7 8 × 5 6 ft ='),
        skip: 5,
        expect: () => [
          tapeState(pressed('7 8 × 5 6 ft')),
          tapeState(pressed('7 8 × 5 6 ft =')),
        ],
        verify: (bloc) {
          final before = CalculatorState(tape: pressed('7 8 × 5 6 ft'));
          expect(row1(before), ['Calc: 4368ft 0in']);
          expect(
            before.suggestions.single.kind,
            CalculatorSuggestionKind.runningTotal,
          );
          expect(before.equalsKeyId, Tape.calcKey);
          expect(row2(before), ['672in', '18.67yd', '17.07m']);
          expect(bloc.state.valueText, '4368ft 0in');
          expect(row1(bloc.state), isEmpty);
        },
      );

      blocTest<CalculatorBloc, CalculatorState>(
        'a chain continuing from a result relabels the equals key Ans while '
        'the strip still says Calc (S22; rule 4.9)',
        build: () => bloc,
        act: (bloc) => type(bloc, '3 6 ft ÷ 1 2 ft = × 4'),
        skip: 9,
        expect: () => [
          tapeState(carriedForward('3 6 ft ÷ 1 2 ft =', '× 4')),
          tapeState(carriedForward('3 6 ft ÷ 1 2 ft =', '× 4')).copyWith(
            bankedTape: () => pressed('3 6 ft ÷ 1 2 ft ='),
            bankedSessionId: () => 'session-1',
            bankedCarriedForward: true,
            toastsRaised: 1,
          ),
        ],
        verify: (bloc) {
          expect(row1(bloc.state), ['Calc: 12']);
          expect(bloc.state.equalsKeyId, CalculatorState.ansKey);
        },
      );

      blocTest<CalculatorBloc, CalculatorState>(
        'a chain started afresh after a result reads Calc again, not Ans',
        build: () => bloc,
        act: (bloc) => type(bloc, '3 6 ft ÷ 1 2 ft = [Length] 2 ft × 4'),
        skip: 12,
        expect: () => [
          tapeState(pressed('[Length] 2 ft × 4')),
          tapeState(pressed('[Length] 2 ft × 4')).copyWith(
            bankedTape: () => pressed('3 6 ft ÷ 1 2 ft ='),
            bankedSessionId: () => 'session-1',
            toastsRaised: 1,
          ),
        ],
        verify: (bloc) {
          expect(row1(bloc.state), ['Calc: 8ft 0in']);
          expect(bloc.state.equalsKeyId, Tape.calcKey);
        },
      );

      blocTest<CalculatorBloc, CalculatorState>(
        'a pending trig chip leads the row with its answer and the ratio it '
        'builds across ÷ keeps the Calc beside it (S111)',
        build: () => bloc,
        act: (bloc) => type(bloc, '[ATAN] 1 6 ÷ 1 2'),
        skip: 5,
        expect: () => [tapeState(pressed('[ATAN] 1 6 ÷ 1 2'))],
        verify: (bloc) {
          expect(row1(bloc.state), [
            'Arctangent(16 ÷ 12): 53.13°',
            'Calc: 1.33',
          ]);
          expect(bloc.state.equalsKeyId, 'Arctangent(16 ÷ 12)');
          expect(row2(bloc.state), isEmpty);
        },
      );

      blocTest<CalculatorBloc, CalculatorState>(
        'the strip is empty while a bracket is open and offers the whole '
        'chain\'s Calc once it closes (S128)',
        build: () => bloc,
        act: (bloc) => type(bloc, '2 + ( 3 × 4 ('),
        skip: 5,
        expect: () => [
          tapeState(pressed('2 + ( 3 × 4')),
          tapeState(pressed('2 + ( 3 × 4 (')),
        ],
        verify: (bloc) {
          final open = CalculatorState(tape: pressed('2 + ( 3 × 4'));
          expect(open.suggestions, isEmpty);
          expect(open.conversions, isEmpty);
          expect(open.equalsKeyId, isNull);
          expect(row1(bloc.state), ['Calc: 14']);
        },
      );

      blocTest<CalculatorBloc, CalculatorState>(
        'after an error chip both rows stay empty on purpose',
        build: () => bloc,
        act: (bloc) => type(bloc, '7 8 lbs ÷ 1 2 ft ='),
        skip: 7,
        expect: () => [tapeState(pressed('7 8 lbs ÷ 1 2 ft ='))],
        verify: (bloc) {
          expect(bloc.state.suggestions, isEmpty);
          expect(bloc.state.conversions, isEmpty);
          expect(bloc.state.equalsKeyId, isNull);
        },
      );

      test('a typed angle, a bare number and a weight read as the doc says: '
          'no conversions for the first two, weights for the third', () {
        expect(
          row2(CalculatorState(tape: pressed('[Pitch] 8 . 4 5'))),
          isEmpty,
        );
        expect(row2(CalculatorState(tape: pressed('7 8'))), isEmpty);
        expect(row2(CalculatorState(tape: pressed('7 8 lbs'))), [
          '35.38kg',
          '0.04 ton',
        ]);
        expect(
          row2(
            CalculatorState(tape: pressed('[Length] 2 2 ft [Width] 1 8 ft 8')),
          ),
          isEmpty,
          reason: 'an unfinished compound has no value to convert yet',
        );
      });

      blocTest<CalculatorBloc, CalculatorState>(
        'accepting Area lands it as a result chip; the other answers stay on '
        'offer and the result\'s conversions take row 2',
        build: () => bloc,
        act: (bloc) => bloc
          ..add(const CalculatorKeySelected('Length'))
          ..add(const CalculatorDigitPressed('2'))
          ..add(const CalculatorDigitPressed('2'))
          ..add(const CalculatorUnitSelected(Unit.foot))
          ..add(const CalculatorKeySelected('Width'))
          ..add(const CalculatorDigitPressed('1'))
          ..add(const CalculatorDigitPressed('8'))
          ..add(const CalculatorUnitSelected(Unit.foot))
          ..add(const CalculatorDigitPressed('8'))
          ..add(const CalculatorUnitSelected(Unit.inch))
          ..add(
            CalculatorSuggestionAccepted(
              leadingOf('[Length] 2 2 ft [Width] 1 8 ft 8 in'),
            ),
          ),
        skip: 10,
        expect: () {
          final landed = tapeState(
            pressed('[Length] 2 2 ft [Width] 1 8 ft 8 in').append(
              ResultChip(
                key: DeterministicRules.areaKey,
                value: leadingOf('[Length] 2 2 ft [Width] 1 8 ft 8 in').value,
              ),
            ),
          );
          // the store's answer for the new area follows the key (S2a 2/2)
          return [landed, landed.copyWith(stores: storesOf(landed))];
        },
        verify: (bloc) {
          expect(
            [
              for (final chip in bloc.state.chipsList)
                '${chip.label}${chip.value}',
            ],
            ['Length22ft', 'Width18ft 8in', 'Area410.67ft²'],
          );
          expect(bloc.state.labelKeyId, DeterministicRules.areaKey);
          expect(bloc.state.valueText, '410.67ft²');
          expect(row1(bloc.state), [
            'Drywall: 12.83',
            'Drywall: 11.41',
            'Drywall: 10.27',
            'Diagonal: 28.85ft',
            'Perimeter: 81.33ft',
          ]);
          expect(row2(bloc.state), [
            '45.63yd²',
            '59,136in²',
            '38.15m²',
            '0.0094acre',
          ]);
        },
      );

      blocTest<CalculatorBloc, CalculatorState>(
        '= lands the leading suggestion when the strip has one (Area), as '
        'accepting it would',
        build: () => bloc,
        act: (bloc) => type(bloc, '[Length] 2 0 ft [Width] 1 0 ft ='),
        skip: 8,
        expect: () {
          final landed = tapeState(
            pressed('[Length] 2 0 ft [Width] 1 0 ft').append(
              ResultChip(
                key: DeterministicRules.areaKey,
                value: leadingOf('[Length] 2 0 ft [Width] 1 0 ft').value,
              ),
            ),
          );
          return [landed, landed.copyWith(stores: storesOf(landed))];
        },
        verify: (bloc) => expect(bloc.state.valueText, '200ft²'),
      );

      blocTest<CalculatorBloc, CalculatorState>(
        'Rise and Run earn the three pitch spellings; the long name keeps the '
        'equals key\'s own id, and the accepted spelling leaves the row (S08)',
        build: () => bloc,
        act: (bloc) {
          type(bloc, '[Rise] 6 ft [Run] 1 2 ft');
          bloc.add(
            CalculatorSuggestionAccepted(leadingOf('[Rise] 6 ft [Run] 1 2 ft')),
          );
        },
        skip: 6,
        expect: () => [
          tapeState(pressed('[Rise] 6 ft [Run] 1 2 ft')),
          tapeState(
            pressed('[Rise] 6 ft [Run] 1 2 ft').append(
              ResultChip(
                key: DeterministicRules.pitchRiseKey,
                value: leadingOf('[Rise] 6 ft [Run] 1 2 ft').value,
              ),
            ),
          ),
        ],
        verify: (bloc) {
          final before = CalculatorState(
            tape: pressed('[Rise] 6 ft [Run] 1 2 ft'),
          );
          expect(row1(before).take(3), [
            'Pitch-rise per 12in run: 6in/12in',
            'Pitch-degrees: 26.57°',
            'Pitch-grade: 50%',
          ]);
          expect(before.equalsKeyId, DeterministicRules.pitchRiseKey);
          expect(bloc.state.valueText, '6in/12in');
          expect(row1(bloc.state).take(2), [
            'Pitch-degrees: 26.57°',
            'Pitch-grade: 50%',
          ]);
          expect(row2(bloc.state), isEmpty);
        },
      );

      blocTest<CalculatorBloc, CalculatorState>(
        'accepting a prefix trig answer lands the tape the postfix order '
        'lands (rule 4.11)',
        build: () => bloc,
        act: (bloc) {
          type(bloc, '[SIN] 3 8');
          bloc.add(CalculatorSuggestionAccepted(leadingOf('[SIN] 3 8')));
        },
        skip: 3,
        expect: () => [tapeState(pressed('3 8 [SIN]'))],
        verify: (bloc) {
          expect(row1(CalculatorState(tape: pressed('[SIN] 3 8'))), [
            'Sine: 0.615661',
          ]);
          expect(row1(bloc.state), isEmpty);
        },
      );

      blocTest<CalculatorBloc, CalculatorState>(
        'a typed length offers its conversions, and accepting one converts '
        'it in place through the unit key (S03, S05)',
        build: () => bloc,
        act: (bloc) {
          type(bloc, '[Length] 2 2 ft');
          bloc.add(
            CalculatorSuggestionAccepted(conversionOf('[Length] 2 2 ft')),
          );
        },
        skip: 3,
        expect: () => [
          tapeState(pressed('[Length] 2 2 ft')),
          tapeState(pressed('[Length] 2 2 ft in')),
        ],
        verify: (bloc) {
          final typed = CalculatorState(tape: pressed('[Length] 2 2 ft'));
          expect(row1(typed), isEmpty);
          expect(typed.equalsKeyId, isNull);
          expect(row2(typed), ['264in', '7.33yd', '6.71m']);
          expect(bloc.state.valueText, '264in');
          expect(row2(bloc.state), ['22ft 0in', '6,706mm']);
        },
      );

      blocTest<CalculatorBloc, CalculatorState>(
        'a result offers its conversions and accepting one re-spells the '
        'result in place',
        build: () => bloc,
        act: (bloc) {
          type(bloc, '1 2 ft × 5 ft =');
          bloc.add(
            CalculatorSuggestionAccepted(conversionOf('1 2 ft × 5 ft =')),
          );
        },
        skip: 7,
        expect: () => [tapeState(pressed('1 2 ft × 5 ft = yd'))],
        verify: (bloc) {
          expect(row2(CalculatorState(tape: pressed('1 2 ft × 5 ft ='))), [
            '6.67yd²',
            '8,640in²',
            '5.57m²',
          ]);
          expect(bloc.state.valueText, '6.67yd²');
        },
      );

      blocTest<CalculatorBloc, CalculatorState>(
        'an angle answer offers its other spelling, and accepting it respells '
        'the answer as the D:M:S key does',
        build: () => bloc,
        act: (bloc) {
          type(bloc, '1 2 ÷ 2 3 [ATAN]');
          bloc.add(
            CalculatorSuggestionAccepted(conversionOf('1 2 ÷ 2 3 [ATAN]')),
          );
        },
        skip: 6,
        expect: () => [tapeState(pressed('1 2 ÷ 2 3 [ATAN] [DMS]'))],
        verify: (bloc) {
          expect(row2(CalculatorState(tape: pressed('1 2 ÷ 2 3 [ATAN]'))), [
            '27°33\'10"',
          ]);
          expect(bloc.state.valueText, '27°33\'10"');
          expect(row2(bloc.state), ['27.55°']);
        },
      );

      blocTest<CalculatorBloc, CalculatorState>(
        'accepting an answer drops the empty chip a key had opened',
        build: () => bloc,
        act: (bloc) {
          type(bloc, '[Length] 2 0 ft [Width] 1 0 ft [Height]');
          bloc.add(
            CalculatorSuggestionAccepted(
              leadingOf('[Length] 2 0 ft [Width] 1 0 ft [Height]'),
            ),
          );
        },
        skip: 9,
        expect: () {
          final landed = tapeState(
            pressed('[Length] 2 0 ft [Width] 1 0 ft').append(
              ResultChip(
                key: DeterministicRules.areaKey,
                value: leadingOf('[Length] 2 0 ft [Width] 1 0 ft').value,
              ),
            ),
          );
          return [landed, landed.copyWith(stores: storesOf(landed))];
        },
      );

      blocTest<CalculatorBloc, CalculatorState>(
        'accepting an answer while a value is unfinished is refused the way '
        '= is, and the tape keeps the dangling number',
        build: () => bloc,
        act: (bloc) {
          type(bloc, '[Length] 2 0 ft [Width] 1 0 ft [Height] 8');
          bloc.add(
            CalculatorSuggestionAccepted(
              leadingOf('[Length] 2 0 ft [Width] 1 0 ft [Height] 8'),
            ),
          );
        },
        skip: 10,
        expect: () => [
          tapeState(
            pressed('[Length] 2 0 ft [Width] 1 0 ft [Height] 8'),
          ).copyWith(
            refusal: () => const TapeRefused(TapeRefusal.finishThisValueFirst),
            toastsRaised: 1,
          ),
        ],
      );

      blocTest<CalculatorBloc, CalculatorState>(
        'accepting an answer over a dangling fraction is refused with the '
        'fraction\'s own reason, as = refuses it',
        build: () => bloc,
        act: (bloc) {
          type(bloc, '[Length] 2 0 ft [Width] 1 0 ft [Height] 7 / 1 6');
          bloc.add(
            CalculatorSuggestionAccepted(
              leadingOf('[Length] 2 0 ft [Width] 1 0 ft [Height] 7 / 1 6'),
            ),
          );
        },
        skip: 13,
        expect: () => [
          tapeState(
            pressed('[Length] 2 0 ft [Width] 1 0 ft [Height] 7 / 1 6'),
          ).copyWith(
            refusal: () =>
                const TapeEntryRefused(EntryRefusal.fractionNeedsUnit),
          ),
        ],
      );

      blocTest<CalculatorBloc, CalculatorState>(
        'a chip the strip no longer offers, tapped again before the strip '
        'redrew, changes nothing',
        build: () => bloc,
        act: (bloc) {
          type(bloc, '[Length] 2 2 ft [Width] 1 8 ft 8 in');
          final area = leadingOf('[Length] 2 2 ft [Width] 1 8 ft 8 in');
          bloc
            ..add(CalculatorSuggestionAccepted(area))
            ..add(CalculatorSuggestionAccepted(area));
        },
        skip: 11,
        // the second tap changes nothing; the one state left is the store's
        // answer for the Area the first tap landed (S2a 2/2)
        expect: () {
          final landed = tapeState(
            pressed('[Length] 2 2 ft [Width] 1 8 ft 8 in').append(
              ResultChip(
                key: DeterministicRules.areaKey,
                value: leadingOf('[Length] 2 2 ft [Width] 1 8 ft 8 in').value,
              ),
            ),
          );
          return [landed.copyWith(stores: storesOf(landed))];
        },
        verify: (bloc) => expect(
          [for (final chip in bloc.state.chipsList) chip.label],
          ['Length', 'Width', DeterministicRules.areaKey],
        ),
      );

      blocTest<CalculatorBloc, CalculatorState>(
        'a conversion of a bare number and an answer with no key, which the '
        'strip never offers, change nothing',
        build: () => bloc,
        act: (bloc) => bloc
          ..add(const CalculatorDigitPressed('5'))
          ..add(
            const CalculatorSuggestionAccepted(
              CalculatorSuggestion(
                key: null,
                value: Scalar(5),
                kind: CalculatorSuggestionKind.conversion,
                text: '5',
              ),
            ),
          )
          ..add(
            const CalculatorSuggestionAccepted(
              CalculatorSuggestion(
                key: null,
                value: Scalar(5),
                kind: CalculatorSuggestionKind.answer,
                text: '5',
              ),
            ),
          ),
        skip: 1,
        expect: () => <CalculatorState>[],
      );

      blocTest<CalculatorBloc, CalculatorState>(
        'with named values and an operator pending, the strip shows the '
        'running total in place of the rule answers, and = lands it (2.15; '
        'walkthrough 12.3)',
        build: () => bloc,
        act: (bloc) => type(bloc, '[Rise] 6 ft [Run] 1 2 ft × 2 ='),
        skip: 8,
        expect: () => [
          tapeState(pressed('[Rise] 6 ft [Run] 1 2 ft × 2')),
          tapeState(pressed('[Rise] 6 ft [Run] 1 2 ft × 2 =')),
        ],
        verify: (bloc) {
          final pending = CalculatorState(
            tape: pressed('[Rise] 6 ft [Run] 1 2 ft × 2'),
          );
          expect(row1(pending), ['Calc: 24ft 0in']);
          expect(pending.equalsKeyId, Tape.calcKey);
          expect(bloc.state.valueText, '24ft 0in');
          expect(bloc.state.labelKeyId, Tape.calcKey);
        },
      );
    });

    group('S1b 3/6: what = lands and what an accepted chip lands', () {
      CalculatorState stateOf(String keys) =>
          CalculatorState(tape: pressed(keys));

      void type(CalculatorBloc bloc, String keys) {
        for (final key in keys.split(' ')) {
          bloc.add(switch (key) {
            'ft' => const CalculatorUnitSelected(Unit.foot),
            'in' => const CalculatorUnitSelected(Unit.inch),
            'yd' => const CalculatorUnitSelected(Unit.yard),
            'm' => const CalculatorKeySelected('m'),
            'bf' => const CalculatorKeySelected('bf'),
            'lbs' => const CalculatorKeySelected('lbs'),
            '/' => const CalculatorFractionPressed(),
            '×' => const CalculatorOperatorPressed(Operator.multiply),
            '÷' => const CalculatorOperatorPressed(Operator.divide),
            '+' => const CalculatorOperatorPressed(Operator.add),
            '=' => const CalculatorEqualsPressed(),
            _ when key.startsWith('[') => CalculatorKeySelected(
              key.substring(1, key.length - 1),
            ),
            _ => CalculatorDigitPressed(key),
          });
        }
      }

      for (final (keys, calc) in const [
        ('5 + [SIN] 3 0 =', '5.5'),
        ('2 × [COS] 6 0 =', '1'),
        ('5 + [ATAN] 1 6 ÷ 1 2 =', '58.13°'),
      ]) {
        blocTest<CalculatorBloc, CalculatorState>(
          '= lands the chain a trig chip continues, not the trig answer: '
          '$keys is Calc $calc (term 2.15, rule 4.6)',
          build: () => bloc,
          act: (bloc) => type(bloc, keys),
          skip: keys.split(' ').length - 1,
          expect: () => [tapeState(pressed(keys))],
          verify: (bloc) {
            expect(bloc.state.labelKeyId, Tape.calcKey);
            expect(bloc.state.valueText, calc);
          },
        );
      }

      for (final operator in const ['+', '×']) {
        blocTest<CalculatorBloc, CalculatorState>(
          '= after a trailing $operator is refused and keeps the operator, '
          'in place of landing the leading suggestion over it (rule 4.12)',
          build: () => bloc,
          act: (bloc) =>
              type(bloc, '[Length] 2 0 ft [Width] 1 0 ft $operator ='),
          skip: 9,
          expect: () => [
            tapeState(
              pressed('[Length] 2 0 ft [Width] 1 0 ft $operator'),
            ).copyWith(
              refusal: () =>
                  const TapeRefused(TapeRefusal.operatorNeedsANumber),
            ),
          ],
          verify: (bloc) {
            expect(bloc.state.tape.endsWithOperator, isTrue);
            expect(
              bloc.state.suggestions.first.key,
              DeterministicRules.areaKey,
            );
            expect(
              [for (final chip in bloc.state.chipsList) chip.value],
              ['20ft', '10ft', operator],
            );
          },
        );
      }

      Tape landedOn(Tape tape, int offer) {
        final answer = CalculatorState(tape: tape).suggestions[offer];
        return switch (tape.landAnswer(answer.key!, answer.value)) {
          TapeChanged(:final tape) => tape,
          final other => throw StateError('$other'),
        };
      }

      blocTest<CalculatorBloc, CalculatorState>(
        'the first = lands Area; a second and a third = are refused as the '
        'result already shown, while a tapped chip still lands its answer',
        build: () => bloc,
        act: (bloc) {
          type(bloc, '[Length] 2 0 ft [Width] 1 0 ft = = =');
          bloc.add(
            CalculatorSuggestionAccepted(
              CalculatorState(
                tape: landedOn(pressed('[Length] 2 0 ft [Width] 1 0 ft'), 0),
              ).suggestions.first,
            ),
          );
        },
        skip: 8,
        expect: () {
          final area = landedOn(pressed('[Length] 2 0 ft [Width] 1 0 ft'), 0);
          // the store's answer for Area 200ft² is queued behind the three
          // keys and arrives once Diagonal is on the display: no longer
          // watched, it is dropped (S2a 2/2)
          return [
            tapeState(area),
            tapeState(area).copyWith(
              refusal: () => const TapeRefused(TapeRefusal.resultAlreadyShown),
            ),
            tapeState(landedOn(area, 0)),
          ];
        },
        verify: (bloc) {
          expect(
            [for (final chip in bloc.state.chipsList) chip.label],
            ['Length', 'Width', 'Area', 'Diagonal'],
          );
        },
      );

      blocTest<CalculatorBloc, CalculatorState>(
        'accepting the acre chip converts the area result in place '
        '(walkthrough 14.5), and the other conversions stay on offer',
        build: () => bloc,
        act: (bloc) {
          type(bloc, '2 0 0 ft × 8 0 ft =');
          bloc.add(
            CalculatorSuggestionAccepted(
              stateOf('2 0 0 ft × 8 0 ft =').conversions.last,
            ),
          );
        },
        skip: 9,
        expect: () => [
          isA<CalculatorState>()
              .having((s) => s.valueText, 'valueText', '0.3673acre')
              .having((s) => s.labelKeyId, 'labelKeyId', Tape.calcKey)
              .having((s) => s.refusal, 'refusal', isNull),
        ],
        verify: (bloc) {
          expect(
            [for (final s in bloc.state.conversions) s.text],
            ['16,000ft²', '1,777.78yd²', '2,304,000in²', '1,486.45m²'],
          );
        },
      );

      for (final (keys, index, chip) in const [
        ('2 yd', 0, '6ft 0in'),
        ('2 6 4 in', 0, '22ft 0in'),
        ('1 m', 0, '3ft 3-3/8in'),
        ('1 m', 1, '39-3/8in'),
        ('[Width] 7 / 1 6 in', 0, '0ft 0-7/16in'),
        ('1 0 bf', 0, '0.83ft³'),
        ('5 0 0 0 lbs', 1, '2.5 ton'),
        ('1 2 ft × 5 ft =', 0, '6.67yd²'),
      ]) {
        blocTest<CalculatorBloc, CalculatorState>(
          'accepting the conversion chip "$chip" lands the text the chip '
          'shows: $keys (Section 1.2, walkthrough 14.2; decision tree row '
          '201)',
          build: () => bloc,
          act: (bloc) {
            type(bloc, keys);
            bloc.add(
              CalculatorSuggestionAccepted(stateOf(keys).conversions[index]),
            );
          },
          skip: keys.split(' ').length,
          expect: () => [
            isA<CalculatorState>()
                .having((s) => s.valueText, 'valueText', chip)
                .having((s) => s.refusal, 'refusal', isNull),
          ],
          verify: (bloc) => expect(stateOf(keys).conversions[index].text, chip),
        );
      }

      blocTest<CalculatorBloc, CalculatorState>(
        'a strip chip tapped while an operator waits for its number is '
        'refused as = is, and the operator stays (walkthrough 21.3)',
        build: () => bloc,
        act: (bloc) {
          type(bloc, '[Length] 1 2 ft [Width] 1 0 ft ×');
          bloc.add(
            CalculatorSuggestionAccepted(
              stateOf('[Length] 1 2 ft [Width] 1 0 ft').suggestions.first,
            ),
          );
        },
        skip: 9,
        expect: () => [
          tapeState(pressed('[Length] 1 2 ft [Width] 1 0 ft ×')).copyWith(
            refusal: () => const TapeRefused(TapeRefusal.operatorNeedsANumber),
          ),
        ],
        verify: (bloc) {
          expect(
            [for (final chip in bloc.state.chipsList) chip.value],
            ['12ft', '10ft', '×'],
          );
          expect(
            bloc.state.suggestions.first.key,
            DeterministicRules.areaKey,
            reason: 'the strip still offers Area for the next tap',
          );
        },
      );
    });

    group('S1b 4/6: the label and the value', () {
      CalculatorState stateOf(String keys) =>
          CalculatorState(tape: pressed(keys));

      test(
        'the label names the key, the operator of a chip with no key, or '
        'a bare value, with the reading of a bare number (S134, S42, S95)',
        () {
          expect(stateOf('').displayLabel, isNull);
          expect(
            stateOf('1 2 ft').displayLabel,
            const CalculatorDisplayLabel(),
          );
          expect(
            stateOf('5 ÷ 0 =').displayLabel,
            CalculatorDisplayLabel(keyId: CalculationError.divisionByZero.name),
            reason:
                'the reopened divisor is titled by its error, with no '
                'dots, while the value reads Error (Section 5.3)',
          );
          expect(
            stateOf('5 ÷ 0 = 2').displayLabel,
            const CalculatorDisplayLabel(operator: Operator.divide),
          );
          expect(stateOf('5 ÷ 0 =').valueReadsError, isTrue);
          expect(stateOf('5 ÷ 0 = 2').valueReadsError, isFalse);
          expect(stateOf('7 8 lbs ÷ 1 2 ft =').valueReadsError, isTrue);
          expect(
            stateOf('1 2').displayLabel,
            const CalculatorDisplayLabel(isTyping: true),
          );
          expect(
            stateOf('[Length] 2 2').displayLabel,
            const CalculatorDisplayLabel(keyId: 'Length', isTyping: true),
          );
          expect(
            stateOf('[Length] 2 2 ft').displayLabel,
            const CalculatorDisplayLabel(keyId: 'Length'),
          );
          expect(
            stateOf('5').displayLabel,
            const CalculatorDisplayLabel(isTyping: true),
          );
          expect(
            stateOf('2 + 1 2').displayLabel,
            const CalculatorDisplayLabel(operator: Operator.add),
          );
          expect(
            stateOf('2 × [Width] 1 8').displayLabel,
            const CalculatorDisplayLabel(
              keyId: 'Width',
              operator: Operator.multiply,
              isTyping: true,
            ),
          );
          expect(
            stateOf('2 × [Pitch] 3 0 .').displayLabel,
            const CalculatorDisplayLabel(
              keyId: 'Pitch',
              operator: Operator.multiply,
              reading: NumberReading.degrees,
              isTyping: true,
            ),
          );
          expect(
            stateOf('[Slope] 7').displayLabel,
            const CalculatorDisplayLabel(
              keyId: 'Slope',
              reading: NumberReading.grade,
              isTyping: true,
            ),
          );
          expect(
            stateOf('[Pitch] 8 in').displayLabel,
            const CalculatorDisplayLabel(
              keyId: 'Pitch',
              reading: NumberReading.risePerFoot,
            ),
          );
          expect(
            stateOf('[Pitch] 3 0').displayLabel,
            const CalculatorDisplayLabel(
              keyId: 'Pitch',
              reading: NumberReading.degrees,
              isTyping: true,
            ),
          );
          expect(
            stateOf('[Pitch] 6 / 1 2').displayLabel,
            const CalculatorDisplayLabel(
              keyId: 'Pitch',
              reading: NumberReading.risePerFoot,
              isTyping: true,
            ),
          );
          expect(
            stateOf('[SIN]').displayLabel,
            const CalculatorDisplayLabel(
              keyId: 'Sine',
              reading: NumberReading.degrees,
              isTyping: true,
            ),
          );
          expect(
            stateOf('[ACOS] 0 . 5').displayLabel,
            const CalculatorDisplayLabel(
              keyId: 'Arccosine',
              reading: NumberReading.ratio,
              isTyping: true,
            ),
          );
          expect(
            stateOf('3 8 [DMS] 3 0').displayLabel,
            const CalculatorDisplayLabel(
              reading: NumberReading.degreesMinutesSeconds,
              isTyping: true,
            ),
          );
          expect(
            stateOf('[Pitch] 3 8 [DMS] 3 0').displayLabel,
            const CalculatorDisplayLabel(
              keyId: 'Pitch',
              reading: NumberReading.degreesMinutesSeconds,
              isTyping: true,
            ),
          );
          expect(
            stateOf('[Width]').displayLabel,
            const CalculatorDisplayLabel(keyId: 'Width', isTyping: true),
          );
          expect(
            stateOf('2 ft × 3 =').displayLabel,
            const CalculatorDisplayLabel(keyId: Tape.calcKey),
          );
          expect(
            stateOf('7 8 lbs ÷ 1 2 ft =').displayLabel,
            CalculatorDisplayLabel(keyId: CalculationError.dimensionError.name),
          );
        },
      );

      test('a bracket\'s factor is the icon of the operator that leads it, '
          'and none when the bracket starts the chain', () {
        expect(
          stateOf('2 + ( 3 (').chipsList.last.factor,
          CoreIcons.addOperator,
        );
        expect(
          stateOf('2 − ( 3 (').chipsList.last.factor,
          CoreIcons.subtractOperator,
        );
        expect(
          stateOf('2 × ( 3 (').chipsList.last.factor,
          CoreIcons.multiplyOperator,
        );
        expect(stateOf('2 ÷ ( 3 (').chipsList.last.factor, CoreIcons.divide);
        expect(stateOf('( 3 (').chipsList.last.factor, isNull);
        expect(stateOf('2 + 3').chipsList.last.factor, isNull);
      });

      test('a closed bracket is named by its operator and its inside, and '
          'the value row shows what it is worth (Section 7)', () {
        final closed = stateOf('2 + ( 3 × 4 (');
        expect(
          closed.displayLabel,
          const CalculatorDisplayLabel(
            operator: Operator.add,
            bracketExpression: '3×4',
          ),
        );
        expect(closed.valueText, '12');
        expect([for (final chip in closed.chipsList) chip.value], ['2', '3×4']);

        final first = stateOf('( 3 × 4 (');
        expect(
          first.displayLabel,
          const CalculatorDisplayLabel(bracketExpression: '3×4'),
        );
        expect(first.valueText, '12');

        final open = stateOf('2 + ( 3 × 4');
        expect(
          open.displayLabel,
          const CalculatorDisplayLabel(operator: Operator.multiply),
        );
        expect(open.valueText, '4');

        final empty = stateOf('2 + (');
        expect(empty.displayLabel, isNull);
        expect(empty.valueText, '');
        expect(
          stateOf('2 + ( 3 ×').displayLabel,
          const CalculatorDisplayLabel(
            operator: Operator.multiply,
            isTyping: true,
          ),
        );
        expect([for (final chip in empty.chipsList) chip.value], ['2', '']);
        expect(empty.chipsList.last.type, CoreCalculatorChipType.bracketOpen);
        expect(empty.chipsList.last.factor, CoreIcons.addOperator);
      });

      test('the value row and the tape write a bare number\'s reading after '
          'it: degrees, a grade, a rise per 12in; a point still open, a '
          'D:M:S spelling and a ratio are left as typed', () {
        expect(stateOf('[Pitch] 3 0').valueText, '30°');
        expect(stateOf('[Pitch] 8 .').valueText, '8.');
        expect(stateOf('[Pitch] 8 . 4 5').valueText, '8.45°');
        expect(stateOf('[Pitch] 8 in').valueText, '8in/12in');
        expect(stateOf('[Pitch] 6 / 1 2').valueText, '6/12');
        expect(
          [
            for (final chip in stateOf('[Pitch] 6 / 1 2 +').chipsList)
              chip.value,
          ],
          ['6in/12in', '+'],
        );
        expect(stateOf('[Pitch] 1 / 4 in').valueText, '1/4in/12in');
        expect(
          [
            for (final chip in stateOf('[Pitch] 1 / 4 in +').chipsList)
              chip.value,
          ],
          ['1/4in/12in', '+'],
        );
        expect(stateOf('[Slope] 7').valueText, '7%');
        expect(stateOf('[SIN] 3 8 . 3 0').valueText, '38.30°');
        expect(stateOf('[ACOS] 0 . 5').valueText, '0.5');
        expect(stateOf('3 8 [DMS] 3 0').valueText, '38°30\'00"');
        expect(stateOf('[Width] 1 8 ft 8').valueText, '18ft 8');
        expect(stateOf('[Pitch]').valueText, '');
        expect(
          [for (final chip in stateOf('[Pitch] 8 in').chipsList) chip.value],
          ['8in/12in'],
        );
        expect(
          [
            for (final chip in stateOf('3 8 [SIN]').chipsList)
              '${chip.label}${chip.value}',
          ],
          ['Sine38°', 'Sine0.615661'],
        );
      });
    });

    group('S1b 5/6: the pills', () {
      CalculatorState stateOf(String keys) =>
          CalculatorState(tape: pressed(keys));

      test('the Read-as pill offers the other reading of the number on the '
          'display, as a sentence from its reading to the next (S86, S92, '
          'S115, S116)', () {
        CalculatorReadAsPill pillOf(String keys) =>
            stateOf(keys).dependentKeys.single as CalculatorReadAsPill;

        expect(pillOf('[Pitch] 8 . 4 5').sourceText, '8.45°');
        expect(pillOf('[Pitch] 8 . 4 5').targetText, '8.45in/12in');
        expect(pillOf('[Pitch] 8 . 4 5').rebuildsAnAnswer, isFalse);
        expect(pillOf('[Pitch] 8 in').sourceText, '8in/12in');
        expect(pillOf('[Pitch] 8 in').targetText, '8°');
        expect(
          stateOf('[Pitch] 8 .').dependentKeys,
          isEmpty,
          reason: 'D:M:S is no pitch reading (decision tree row 260)',
        );
        expect(pillOf('[Pitch] 8 . 4 5 .').sourceText, '8°45\'00"');
        expect(pillOf('[Pitch] 8 . 4 5 .').targetText, '8.45°');
        expect(pillOf('[Slope] 0 . 6 5').sourceText, '0.65%');
        expect(pillOf('[Slope] 0 . 6 5').targetText, '65%');
        expect(pillOf('[SIN] 3 8 . 3 0').sourceText, '38.30°');
        expect(pillOf('[SIN] 3 8 . 3 0').targetText, '38°30\'00"');
        expect(pillOf('3 8 . 3 0 [SIN]').sourceText, '38.30°');
        expect(pillOf('3 8 . 3 0 [SIN]').rebuildsAnAnswer, isTrue);
        expect(stateOf('[Pitch] 1 0 0').dependentKeys, isEmpty);
        expect(
          stateOf('[Rise] 6 ft [Run] 1 2 ft [Pitch]').dependentKeys,
          isEmpty,
          reason: 'a pitch answer carries no pill (Section 8)',
        );
        expect(stateOf('[Slope] 2 . 5').dependentKeys, isEmpty);
        expect(stateOf('[Length] 2 2 ft').dependentKeys, isEmpty);
        expect(stateOf('[ACOS] 0 . 5').dependentKeys, isEmpty);
      });

      blocTest<CalculatorBloc, CalculatorState>(
        'taking the Read-as pill re-reads the number from its digits, and a '
        'trig answer after it is rebuilt (S91)',
        build: () => bloc,
        act: (bloc) => bloc
          ..add(const CalculatorDigitPressed('3'))
          ..add(const CalculatorDigitPressed('8'))
          ..add(const CalculatorDigitPressed('.'))
          ..add(const CalculatorDigitPressed('3'))
          ..add(const CalculatorDigitPressed('0'))
          ..add(const CalculatorKeySelected('SIN'))
          ..add(const CalculatorReadAsAccepted()),
        skip: 6,
        expect: () => [
          tapeState(switch (pressed('3 8 . 3 0 [SIN]').reInput()) {
            TapeChanged(:final tape) => tape,
            final other => throw StateError('$other'),
          }),
        ],
        verify: (bloc) {
          expect(
            [for (final chip in bloc.state.chipsList) chip.value],
            ['38°30\'00"', '0.622515'],
          );
          expect(
            (bloc.state.dependentKeys.single as CalculatorReadAsPill)
                .targetText,
            '38.30°',
          );
        },
      );

      blocTest<CalculatorBloc, CalculatorState>(
        'the Read-as pill tapped with nothing to re-read is refused',
        build: () => bloc,
        act: (bloc) => bloc.add(const CalculatorReadAsAccepted()),
        expect: () => [
          const CalculatorState(
            refusal: TapeRefused(TapeRefusal.nothingToReInput),
          ),
        ],
      );
    });

    group('S1b 6/6: the strip notes', () {
      CalculatorState stateOf(String keys) =>
          CalculatorState(tape: pressed(keys));

      test('a pitch of 90° or more, a flat pitch with a Rise alone, and a '
          'slope of 0% say why the strip is empty, and keep saying it under '
          'a second value (S89); a flat pitch with a Run answers Rise 0ft', () {
        expect(
          stateOf('[Pitch] 8 9 9').stripNote,
          const CalculatorPitchOutOfRangeNote(isAtLeastARightAngle: true),
        );
        expect(stateOf('[Pitch] 8 9 9').suggestions, isEmpty);
        expect(
          stateOf('[Pitch] 9 0').stripNote,
          const CalculatorPitchOutOfRangeNote(isAtLeastARightAngle: true),
        );
        expect(stateOf('[Pitch] 0').stripNote, isNull);
        expect(
          [for (final s in stateOf('[Pitch] 0').suggestions) s.key],
          [
            DeterministicRules.pitchDegreesKey,
            DeterministicRules.pitchRiseKey,
            DeterministicRules.pitchGradeKey,
          ],
        );
        expect(stateOf('[Pitch] 0 [Run] 1 0 ft').stripNote, isNull);
        expect(
          [
            for (final s in stateOf('[Pitch] 0 [Run] 1 0 ft').suggestions)
              '${s.key}: ${s.text}',
          ],
          ['Rise: 0ft', 'Diagonal: 10ft'],
        );
        expect(
          stateOf('[Pitch] 0 [Rise] 1 0 ft').stripNote,
          const CalculatorFlatPitchHasNoRunNote(),
        );
        expect(stateOf('[Pitch] 0 [Rise] 1 0 ft').suggestions, isEmpty);
        expect(stateOf('[Pitch] 0 [Rise] 1 0 ft').conversions, isEmpty);
        expect(
          stateOf('[Pitch] 9 5 [Diag] 2 2 ft').stripNote,
          const CalculatorPitchOutOfRangeNote(isAtLeastARightAngle: true),
        );
        expect(stateOf('[Pitch] 9 5 [Diag] 2 2 ft').suggestions, isEmpty);
        expect(
          stateOf('[Slope] 0').stripNote,
          const CalculatorSlopeOutOfRangeNote(),
        );
        expect(stateOf('[Pitch] 0 in').stripNote, isNull);
        expect(
          stateOf('[Pitch] 9 5 [Run] 1 0 ft').conversions,
          isEmpty,
          reason: 'a note takes the place of both rows (Section 1.8)',
        );
        expect(stateOf('[Slope] 0 [Run] 1 0 ft').conversions, isEmpty);
        expect(stateOf('[Pitch] 9 5 [Diag] 2 2 ft').conversions, isEmpty);
        expect(stateOf('[Pitch] 8 in').stripNote, isNull);
        expect(stateOf('[Pitch] 8 9').stripNote, isNull);
        expect(stateOf('[Slope] 7').stripNote, isNull);
        expect(stateOf('').stripNote, isNull);
      });

      test('a prefix trig chip its function cannot answer says so while the '
          'operand stays (Section 5.4)', () {
        expect(
          stateOf('[ACOS] 4 5').stripNote,
          const CalculatorTrigCannotAnswerNote(TrigFunction.arccosine),
        );
        expect(
          stateOf('[TAN] 9 0').stripNote,
          const CalculatorTrigCannotAnswerNote(TrigFunction.tangent),
        );
        expect(stateOf('[ACOS] 0 . 5').stripNote, isNull);
        expect(stateOf('[ACOS] 4 5').suggestions, isEmpty);
      });

      blocTest<CalculatorBloc, CalculatorState>(
        'the D:M:S key on a pitch answer changes nothing and the note says '
        'so until the next key, which brings the other spellings back',
        build: () => bloc,
        act: (bloc) => bloc
          ..add(const CalculatorKeySelected('Rise'))
          ..add(const CalculatorDigitPressed('6'))
          ..add(const CalculatorUnitSelected(Unit.foot))
          ..add(const CalculatorKeySelected('Run'))
          ..add(const CalculatorDigitPressed('1'))
          ..add(const CalculatorDigitPressed('2'))
          ..add(const CalculatorUnitSelected(Unit.foot))
          ..add(const CalculatorKeySelected('Pitch'))
          ..add(const CalculatorKeySelected('DMS'))
          ..add(const CalculatorKeySelected('Pitch')),
        skip: 8,
        expect: () => [
          tapeState(pressed('[Rise] 6 ft [Run] 1 2 ft [Pitch]')).copyWith(
            refusal: () => const TapeRefused(TapeRefusal.pitchHasNoDms),
          ),
          tapeState(pressed('[Rise] 6 ft [Run] 1 2 ft [Pitch] [Pitch]')),
        ],
        verify: (bloc) {
          final refused = tapeState(pressed('[Rise] 6 ft [Run] 1 2 ft [Pitch]'))
              .copyWith(
                refusal: () => const TapeRefused(TapeRefusal.pitchHasNoDms),
              );
          expect(refused.stripNote, const CalculatorPitchHasNoDmsNote());
          expect(refused.suggestions, isEmpty);
          expect(bloc.state.stripNote, isNull);
          expect(bloc.state.suggestions, isNotEmpty);
        },
      );

      test('a note never shows after an error chip or inside a bracket, and '
          'a warning outranks a key that changed nothing', () {
        expect(
          CalculatorState(
            tape: pressed('7 8 lbs ÷ 1 2 ft ='),
            refusal: const TapeRefused(TapeRefusal.pitchHasNoDms),
          ).stripNote,
          isNull,
        );
        expect(
          CalculatorState(
            tape: pressed('[Pitch] 9 5'),
            refusal: const TapeRefused(TapeRefusal.pitchHasNoDms),
          ).stripNote,
          const CalculatorPitchOutOfRangeNote(isAtLeastARightAngle: true),
        );
        expect(stateOf('2 + ( 3').stripNote, isNull);
      });
    });

    group('T2a 1/2: the tiles of the detail panel (Section 1.4)', () {
      CalculatorState stateOf(String keys) =>
          CalculatorState(tape: pressed(keys));

      List<String> tiles(CalculatorState state) => [
        for (final dimension in state.dimensions)
          '${dimension.key}: ${dimension.text}',
      ];

      void type(CalculatorBloc bloc, String keys) {
        for (final key in keys.split(' ')) {
          bloc.add(switch (key) {
            'ft' => const CalculatorUnitSelected(Unit.foot),
            '=' => const CalculatorEqualsPressed(),
            _ when key.startsWith('[') => CalculatorKeySelected(
              key.substring(1, key.length - 1),
            ),
            _ => CalculatorDigitPressed(key),
          });
        }
      }

      blocTest<CalculatorBloc, CalculatorState>(
        'two named sides give a tile for every value they work out',
        build: () => bloc,
        act: (bloc) => type(bloc, '[Length] 2 0 ft [Height] 9 ft'),
        skip: 6,
        expect: () => [tapeState(pressed('[Length] 2 0 ft [Height] 9 ft'))],
        verify: (bloc) {
          expect(tiles(bloc.state), [
            'Area: 180ft²',
            'Diagonal: 21.93ft',
            'Perimeter: 58ft',
          ]);
          expect([
            for (final dimension in bloc.state.dimensions) dimension.kind,
          ], everyElement(CalculatorSuggestionKind.answer));
        },
      );

      blocTest<CalculatorBloc, CalculatorState>(
        'an accepted answer leaves the tiles: after Area 180ft² they read '
        'Diagonal 21.93ft and Perimeter 58ft (walkthrough 11.3, decision '
        'tree row 224)',
        build: () => bloc,
        act: (bloc) => type(bloc, '[Length] 2 0 ft [Height] 9 ft ='),
        verify: (bloc) {
          expect(bloc.state.labelKeyId, DeterministicRules.areaKey);
          expect(bloc.state.valueText, '180ft²');
          expect(tiles(bloc.state), ['Diagonal: 21.93ft', 'Perimeter: 58ft']);
        },
      );

      test('one named value gives the tiles of its shape (walkthrough '
          '18.1: Radius 6ft)', () {
        expect(tiles(stateOf('[Radius] 6 ft')), [
          'Diameter: 12ft',
          'Circle area: 113.1ft²',
          'Circumference: 37.7ft',
        ]);
      });

      test('the tiles are the tape\'s: they stay while Calc takes row 1 of '
          'the strip', () {
        final chained = stateOf('[Length] 2 0 ft [Height] 9 ft × 2');
        expect(
          [for (final suggestion in chained.suggestions) suggestion.kind],
          [CalculatorSuggestionKind.runningTotal],
        );
        expect(tiles(chained), [
          'Area: 180ft²',
          'Diagonal: 21.93ft',
          'Perimeter: 58ft',
        ]);
      });

      test('a tape with no named value has no tile', () {
        expect(CalculatorState.initial().dimensions, isEmpty);
        expect(stateOf('1 2 ft').dimensions, isEmpty);
        expect(stateOf('[Length] 2 0 ft').dimensions, isEmpty);
      });
    });

    group('S2a 1/2 (CA-1090): the sheet counts on the strip (rule 4.4; '
        'Section 9), with the store\'s answer in the state', () {
      /// Row 1 as the page writes it: the chip's name, its value and, for a
      /// count, the size it assumed.
      List<String> rowOne(CalculatorState state) => [
        for (final chip in state.suggestions)
          '${chip.key}: ${chip.text}'
              '${chip.basis == null ? '' : ' (${chip.basis})'}',
      ];

      const appendixB = [
        'Drywall: 5.63 (48in x 96in)',
        'Drywall: 5.00 (48in x 108in)',
        'Drywall: 4.50 (48in x 120in)',
      ];

      /// The state after [keys], with the store's answer for the area on
      /// the display, as the watch of 2/2 leaves it.
      CalculatorState withCounts(String keys, {Tape tape = const Tape()}) {
        final state = CalculatorState(tape: pressed(keys, tape: tape));
        return state.copyWith(stores: storesOf(state));
      }

      /// Length 20ft and Height 9ft with Area accepted from the strip.
      Tape areaAccepted() {
        final typed = pressed('[Length] 2 0 ft [Height] 9 ft');
        final area = CalculatorState(tape: typed).suggestions.first;
        return (typed.landAnswer(area.key!, area.value) as TapeChanged).tape;
      }

      test('after Area is accepted row 1 leads with the counts in the '
          'store\'s order, the rule answers behind them, and the equals key '
          'reads = (rule 4.4 rung 2a; walkthrough 11.1; rows 216, 218)', () {
        final state = withCounts('', tape: areaAccepted());
        expect(state.labelKeyId, DeterministicRules.areaKey);
        expect(rowOne(state), [
          ...appendixB,
          'Diagonal: 21.93ft',
          'Perimeter: 58ft',
        ]);
        expect([
          for (final chip in state.suggestions.take(3)) chip.kind,
        ], everyElement(CalculatorSuggestionKind.materialCount));
        expect([
          for (final chip in state.suggestions.take(3)) chip.count,
        ], sheetCountsOf(state));
        expect(state.equalsKeyId, isNull);
        expect(state.equalsLands, isNull);
      });

      test('a typed area is as good as a computed one: 180 ft ft leads with '
          'the counts, its conversions on row 2, and the equals key reads '
          'Drywall (rule 4.4 rung 5; walkthrough 15.2; row 218 case 2)', () {
        final state = withCounts('1 8 0 ft ft');
        expect(state.valueText, '180ft²');
        expect(rowOne(state), appendixB);
        expect(
          [for (final chip in state.conversions) chip.text],
          ['20yd²', '25,920in²', '16.72m²'],
        );
        expect(state.equalsKeyId, Trade.drywall.offerKey);
        expect(state.equalsLands, state.suggestions.first);
      });

      blocTest<CalculatorBloc, CalculatorState>(
        'accepting a count lands it under Number of sheets, and the other '
        'sizes stay on the strip (row 218; Section 9)',
        build: () => bloc,
        seed: () => withCounts('', tape: areaAccepted()),
        act: (bloc) => bloc.add(
          CalculatorSuggestionAccepted(bloc.state.suggestions.first),
        ),
        verify: (bloc) {
          final state = bloc.state;
          expect(state.labelKeyId, Trade.drywall.resultKey);
          expect(state.valueText, '5.63');
          expect(
            state.tape.chips.last,
            ResultChip(
              key: Trade.drywall.resultKey,
              value: state.materialCounts.first.value,
              size: state.materialCounts.first.size,
            ),
            reason: 'the count lands with the size it was made at (rule 4.7)',
          );
          expect(rowOne(state), [
            'Drywall: 5.00 (48in x 108in)',
            'Drywall: 4.50 (48in x 120in)',
          ]);
          expect(state.equalsKeyId, isNull);
        },
      );

      blocTest<CalculatorBloc, CalculatorState>(
        '= on a typed area lands the leading count, as it lands any leading '
        'suggestion (term 2.15)',
        build: () => bloc,
        seed: () => withCounts('1 8 0 ft ft'),
        act: (bloc) => bloc.add(const CalculatorEqualsPressed()),
        verify: (bloc) {
          expect(bloc.state.labelKeyId, Trade.drywall.resultKey);
          expect(bloc.state.valueText, '5.63');
          expect(rowOne(bloc.state), [
            'Drywall: 5.00 (48in x 108in)',
            'Drywall: 4.50 (48in x 120in)',
          ]);
        },
      );

      blocTest<CalculatorBloc, CalculatorState>(
        'a count chip with no count behind it changes nothing, as an answer '
        'with no key does',
        build: () => bloc,
        seed: () => withCounts('1 8 0 ft ft'),
        act: (bloc) => bloc.add(
          CalculatorSuggestionAccepted(
            CalculatorSuggestion(
              key: Trade.drywall.offerKey,
              value: bloc.state.suggestions.first.value,
              kind: CalculatorSuggestionKind.materialCount,
              text: '5.63',
            ),
          ),
        ),
        expect: () => <CalculatorState>[],
      );

      test('under Metric the counts follow the metric seeds, each size in '
          'millimetres (row 214; S24)', () {
        const metric = Tape(
          preferences: CalculatorPreferences(system: MeasurementSystem.metric),
        );
        // 180ft² ÷ (1.2m × 3m) is 4.6451; the seed keeps each side to the
        // tick (1200mm is 3024 ticks, 1200.15mm), so the stored piece is a
        // hair larger and the third count reads 4.64 — a question for the
        // seeds (CA-1083), pinned here as the store answers it today.
        expect(rowOne(withCounts('1 8 0 ft ft', tape: metric)), [
          'Drywall: 5.81 (1200mm x 2400mm)',
          'Drywall: 5.16 (1200mm x 2700mm)',
          'Drywall: 4.64 (1200mm x 3000mm)',
        ]);
      });

      test('the other sizes stay on offer while a chip before the count is '
          'reopened: the count on the tape names the area (row 219)', () {
        final landed = withCounts('', tape: areaAccepted());
        final count = landed.suggestions.first.count!;
        final counted =
            (landed.tape.landAnswer(
                      count.trade.resultKey,
                      count.value,
                      size: count.size,
                    )
                    as TapeChanged)
                .tape;
        final reopened = landed.copyWith(
          tape: (counted.tapChip(0) as TapeChanged).tape,
        );
        expect(reopened.tape.editing!.index, 0);
        expect(reopened.areaForCounts, landed.areaForCounts);
        expect(rowOne(reopened).take(2), [
          'Drywall: 5.00 (48in x 108in)',
          'Drywall: 4.50 (48in x 120in)',
        ]);
      });

      test('no area on the display, no counts: a length alone (rung 3), a '
          'Calc that is an area (rung 4: its cost and conversions), a '
          'function key after the Area (rung 6), and a number under an '
          'operator', () {
        for (final keys in [
          '[Length] 2 0 ft',
          '1 2 ft × 5 ft =',
          '[Length] 2 0 ft [Height] 9 ft = [Length]',
          '1 8 0 ft ft × 2',
          '',
        ]) {
          expect(
            CalculatorState(tape: pressed(keys)).areaForCounts,
            isNull,
            reason: keys,
          );
        }
        expect(
          countOffers(
            CalculatorState(
              tape: pressed('[Length] 2 0 ft [Height] 9 ft = [Length]'),
            ),
          ),
          isEmpty,
        );
      });

      test('a silent strip keeps the table under it: an area typed in an '
          'open bracket, or in a chain that cannot be computed, shows no '
          'chip on row 1 and every stored size in the table (Section 1.4)', () {
        for (final keys in ['( 1 8 0 ft ft', '5 lbs + 1 8 0 ft ft']) {
          final silent = withCounts(keys);

          expect(silent.suggestions, isEmpty, reason: keys);
          expect(silent.areaForCounts, isNotNull, reason: keys);
          expect(silent.sizeTable!.rows, hasLength(3), reason: keys);
        }
      });

      test('the counts are always those of the area on the display: the '
          'ladder counts it over the stores in the state, so another area '
          'is counted at once and no count of an area that left can show; '
          'with no stores yet there is nothing to offer', () {
        final onScreen = CalculatorState(tape: pressed('1 8 0 ft ft'));
        final another = CalculatorState(tape: pressed('4 1 0 ft ft'));

        expect(countOffers(onScreen), isEmpty);
        expect(
          rowOne(onScreen.copyWith(stores: storesOf(onScreen))),
          appendixB,
        );
        expect(rowOne(another.copyWith(stores: storesOf(onScreen))), [
          'Drywall: 12.81 (48in x 96in)',
          'Drywall: 11.39 (48in x 108in)',
          'Drywall: 10.25 (48in x 120in)',
        ]);
      });

      /// [state] with the count at [index] of row 1 accepted; the store's
      /// answer stays in the state, as it does until the watch brings the
      /// next one.
      CalculatorState accepting(CalculatorState state, int index) {
        final count = state.suggestions[index].count!;
        return state.copyWith(
          tape:
              (state.tape.landAnswer(
                        count.trade.resultKey,
                        count.value,
                        size: count.size,
                      )
                      as TapeChanged)
                  .tape,
        );
      }

      for (final keys in [
        '[Length] 3 ft',
        '× 2 =',
        '+ 3 =',
        '÷ 4 =',
        '× 2 = 7',
      ]) {
        test('a key after an accepted count takes the counts off the strip '
            'with the area: 180 ft ft, Drywall 5.63 accepted, then $keys '
            '(B1; rule 4.4)', () {
          final counted = accepting(withCounts('1 8 0 ft ft'), 0);
          expect(
            rowOne(counted),
            ['Drywall: 5.00 (48in x 108in)', 'Drywall: 4.50 (48in x 120in)'],
            reason: 'right after the count the other sizes stay (row 218)',
          );

          final after = counted.copyWith(
            tape: pressed(keys, tape: counted.tape),
          );
          expect(after.areaForCounts, isNull);
          expect(countOffers(after), isEmpty);
          expect(
            after.equalsLands,
            isNot(
              isA<CalculatorSuggestion>().having(
                (chip) => chip.kind,
                'kind',
                CalculatorSuggestionKind.materialCount,
              ),
            ),
            reason: '= never lands a sheet count of an area the user left',
          );
        });
      }

      test('every size not yet accepted stays on offer, after a second count '
          'and after the last, and no rule answer follows them: the ladder '
          'stops at the other sizes once a count is accepted (rule 4.4, rung '
          '2; Section 9, "the other sizes stay on the strip")', () {
        final area = withCounts('', tape: areaAccepted());
        expect(rowOne(area).skip(3), ['Diagonal: 21.93ft', 'Perimeter: 58ft']);
        final one = accepting(area, 0);
        expect(rowOne(one), [
          'Drywall: 5.00 (48in x 108in)',
          'Drywall: 4.50 (48in x 120in)',
        ]);
        final two = accepting(one, 0);
        expect(two.areaForCounts, one.areaForCounts);
        expect(rowOne(two), ['Drywall: 4.50 (48in x 120in)']);
        final three = accepting(two, 0);
        expect(three.areaForCounts, one.areaForCounts);
        expect(rowOne(three), isEmpty);
        expect(
          three.dimensions.map((tile) => tile.key),
          ['Diagonal', 'Perimeter'],
          reason: 'the detail panel keeps its tiles (Section 1.4)',
        );
      });

      test('a count accepted from an earlier area hides no count of the area '
          'now on the display, the same value included: 180ft² counted as '
          '5.00, then 160 ft ft (Section 9, "One chip per stored size")', () {
        final counted = accepting(withCounts('', tape: areaAccepted()), 1);
        final typed = CalculatorState(
          tape: pressed('1 6 0 ft ft', tape: counted.tape),
        );
        final next = typed.copyWith(stores: storesOf(typed));
        expect(rowOne(next).take(3), [
          'Drywall: 5.00 (48in x 96in)',
          'Drywall: 4.44 (48in x 108in)',
          'Drywall: 4.00 (48in x 120in)',
        ]);
      });

      test('two stored sizes that count the same do not leave together: with '
          '48in x 96in and 96in x 48in stored, accepting one 5.63 leaves the '
          'other on the strip (N2)', () {
        final sheets = appendixBSheets();
        final turned = PieceSize(
          width: sheets.first.height,
          height: sheets.first.width,
        );
        final area = CalculatorState(tape: areaAccepted());
        final stored = area.copyWith(
          stores: TradeStores(sheetSizes: [sheets.first, turned, sheets[1]]),
        );
        expect(rowOne(stored).take(3), [
          'Drywall: 5.63 (48in x 96in)',
          'Drywall: 5.63 (96in x 48in)',
          'Drywall: 5.00 (48in x 108in)',
        ]);
        expect(rowOne(accepting(stored, 0)), [
          'Drywall: 5.63 (96in x 48in)',
          'Drywall: 5.00 (48in x 108in)',
        ]);
      });

      test('Calc takes row 1 from the counts while an operator has values on '
          'both sides, as it does from the rule answers (term 2.15)', () {
        final chained = CalculatorState(tape: pressed('1 8 0 ft ft × 2'));
        final withStale = chained.copyWith(
          stores: storesOf(CalculatorState(tape: pressed('1 8 0 ft ft'))),
        );
        expect(
          withStale.suggestions.single.kind,
          CalculatorSuggestionKind.runningTotal,
        );
      });

      blocTest<CalculatorBloc, CalculatorState>(
        'C clears the counts with the tape',
        build: () => bloc,
        seed: () => withCounts('1 8 0 ft ft'),
        act: (bloc) =>
            bloc.add(const CalculatorControlActioned(ControlAction.clearAll)),
        verify: (bloc) {
          expect(bloc.state.materialCounts, isEmpty);
          expect(bloc.state.areaForCounts, isNull);
          expect(bloc.state.suggestions, isEmpty);
        },
      );
    });

    group('S2a 2/2 (CA-1090): the bloc watches the store for the area on the '
        'display (requirement R9)', () {
      void type(CalculatorBloc bloc, String keys) {
        for (final key in keys.split(' ')) {
          bloc.add(switch (key) {
            'ft' => const CalculatorUnitSelected(Unit.foot),
            '=' => const CalculatorEqualsPressed(),
            'C' => const CalculatorControlActioned(ControlAction.clearAll),
            _ when key.startsWith('[') => CalculatorKeySelected(
              key.substring(1, key.length - 1),
            ),
            _ => CalculatorDigitPressed(key),
          });
        }
      }

      List<String> rowOne(CalculatorState state) => [
        for (final chip in state.suggestions)
          '${chip.key}: ${chip.text}'
              '${chip.basis == null ? '' : ' (${chip.basis})'}',
      ];

      const appendixB = [
        'Drywall: 5.63 (48in x 96in)',
        'Drywall: 5.00 (48in x 108in)',
        'Drywall: 4.50 (48in x 120in)',
      ];

      StoredSize sheet(int widthInches, int heightInches) => StoredSize(
        store: SizeStore.sheet,
        width: Length(widthInches * Length.ticksPerInch, unit: Unit.inch),
        height: Length(heightInches * Length.ticksPerInch, unit: Unit.inch),
        position: 0,
      );

      /// Runs [act] and waits for the first state after it that [holds],
      /// listening before the act so that no state is missed.
      Future<void> until(
        CalculatorBloc bloc,
        bool Function(CalculatorState state) holds,
        FutureOr<void> Function() act,
      ) async {
        final arrived = bloc.stream.firstWhere(holds);
        await act();
        await arrived;
      }

      bool offersThreeCounts(CalculatorState state) =>
          countOffers(state).length == 3;

      blocTest<CalculatorBloc, CalculatorState>(
        'the store answers behind the key that puts an area on the display: '
        'Area accepted from the strip, and a typed 180 ft ft',
        build: () => bloc,
        act: (bloc) async {
          await until(
            bloc,
            offersThreeCounts,
            () => type(bloc, '[Length] 2 0 ft [Height] 9 ft ='),
          );
          expect(rowOne(bloc.state), [
            ...appendixB,
            'Diagonal: 21.93ft',
            'Perimeter: 58ft',
          ]);
          await until(
            bloc,
            offersThreeCounts,
            () => type(bloc, 'C 1 8 0 ft ft'),
          );
        },
        verify: (bloc) {
          expect(rowOne(bloc.state), appendixB);
          expect(bloc.state.materialCounts, sheetCountsOf(bloc.state));
        },
      );

      blocTest<CalculatorBloc, CalculatorState>(
        'a size added to the store shows as one more chip with no key '
        'pressed (requirement R9; row 224 case 2)',
        build: () => bloc,
        act: (bloc) async {
          await until(
            bloc,
            offersThreeCounts,
            () => type(bloc, '[Length] 2 0 ft [Height] 9 ft ='),
          );
          await until(
            bloc,
            (state) => countOffers(state).length == 4,
            () => stores.addSize(sheet(48, 100)),
          );
        },
        verify: (bloc) {
          expect(rowOne(bloc.state), [
            ...appendixB,
            'Drywall: 5.40 (48in x 100in)',
            'Diagonal: 21.93ft',
            'Perimeter: 58ft',
          ]);
        },
      );

      blocTest<CalculatorBloc, CalculatorState>(
        'the watch asks under the unit system in force: with Metric chosen '
        'on the empty tape the store answers with the metric seeds (row 214; '
        'S24)',
        build: () => bloc,
        act: (bloc) async {
          bloc.add(const CalculatorUnitSystemChanged(UnitSystem.metric));
          await until(
            bloc,
            offersThreeCounts,
            () => type(bloc, '[Length] 2 0 ft [Height] 9 ft ='),
          );
        },
        verify: (bloc) {
          expect(rowOne(bloc.state).take(3), [
            'Drywall: 5.81 (1200mm x 2400mm)',
            'Drywall: 5.16 (1200mm x 2700mm)',
            'Drywall: 4.64 (1200mm x 3000mm)',
          ]);
        },
      );

      blocTest<CalculatorBloc, CalculatorState>(
        'the watch follows the area: after C a new area is answered with its '
        'own counts',
        build: () => bloc,
        act: (bloc) async {
          await until(bloc, offersThreeCounts, () => type(bloc, '1 8 0 ft ft'));
          await until(
            bloc,
            offersThreeCounts,
            () => type(bloc, 'C 4 1 0 ft ft'),
          );
        },
        verify: (bloc) {
          expect(rowOne(bloc.state), [
            'Drywall: 12.81 (48in x 96in)',
            'Drywall: 11.39 (48in x 108in)',
            'Drywall: 10.25 (48in x 120in)',
          ]);
        },
      );

      blocTest<CalculatorBloc, CalculatorState>(
        'the other sizes stay on offer while a chip before the count is '
        'reopened: the count on the tape keeps the watch on its area (row '
        '219)',
        build: () => bloc,
        act: (bloc) async {
          await until(
            bloc,
            offersThreeCounts,
            () => type(bloc, '[Length] 2 0 ft [Height] 9 ft ='),
          );
          await until(
            bloc,
            (state) =>
                state.labelKeyId == Trade.drywall.resultKey &&
                countOffers(state).length == 2,
            () => bloc.add(
              CalculatorSuggestionAccepted(bloc.state.suggestions.first),
            ),
          );
          await until(
            bloc,
            (state) => state.tape.editing != null,
            () => bloc.add(const CalculatorChipTapped(0)),
          );
        },
        verify: (bloc) {
          expect(bloc.state.tape.editing!.index, 0);
          expect(rowOne(bloc.state).take(2), [
            'Drywall: 5.00 (48in x 108in)',
            'Drywall: 4.50 (48in x 120in)',
          ]);
        },
      );

      blocTest<CalculatorBloc, CalculatorState>(
        'a new value after an accepted count ends the watch: the counts '
        'leave the state and the strip, and a size added afterwards brings '
        'none back (F3; rule 4.4)',
        build: () => bloc,
        act: (bloc) async {
          await until(bloc, offersThreeCounts, () => type(bloc, '1 8 0 ft ft'));
          await until(
            bloc,
            (state) =>
                state.labelKeyId == Trade.drywall.resultKey &&
                countOffers(state).length == 2,
            () => bloc.add(
              CalculatorSuggestionAccepted(bloc.state.suggestions.first),
            ),
          );
          await until(
            bloc,
            (state) =>
                state.valueText == '3ft' && state.stores == const TradeStores(),
            () => type(bloc, '[Length] 3 ft'),
          );
          await stores.addSize(sheet(48, 100));
        },
        verify: (bloc) {
          expect(bloc.state.areaForCounts, isNull);
          expect(bloc.state.materialCounts, isEmpty);
          expect(
            bloc.state.stores,
            const TradeStores(),
            reason: 'the stores leave the state with the area',
          );
          expect(
            rowOne(bloc.state),
            isNot(contains(startsWith(Trade.drywall.offerKey))),
          );
        },
      );

      blocTest<CalculatorBloc, CalculatorState>(
        'stores that answer with no area on the display are not kept: an '
        'answer that arrives after its area left changes nothing',
        build: () => bloc,
        act: (bloc) async {
          await until(
            bloc,
            (state) => state.valueText == '3ft',
            () => type(bloc, '[Length] 3 ft'),
          );
          bloc.add(CalculatorTradeStoresArrived(storesOf(bloc.state)));
        },
        skip: 3,
        expect: () => const <CalculatorState>[],
        verify: (bloc) => expect(bloc.state.stores, const TradeStores()),
      );

      blocTest<CalculatorBloc, CalculatorState>(
        'a store error on the watch is not thrown, and the strip keeps the '
        'counts it showed (F2)',
        build: () => bloc,
        act: (bloc) async {
          await until(bloc, offersThreeCounts, () => type(bloc, '1 8 0 ft ft'));
          stores.failWatches(StateError('the store could not be read'));
          await until(
            bloc,
            (state) => countOffers(state).length == 4,
            () => stores.addSize(sheet(48, 100)),
          );
        },
        errors: () => isEmpty,
        verify: (bloc) {
          expect(rowOne(bloc.state), [
            ...appendixB,
            'Drywall: 5.40 (48in x 100in)',
          ]);
        },
      );

      blocTest<CalculatorBloc, CalculatorState>(
        'C ends the watch with the tape: a size added afterwards changes '
        'nothing',
        build: () => bloc,
        act: (bloc) async {
          await until(bloc, offersThreeCounts, () => type(bloc, '1 8 0 ft ft'));
          await until(
            bloc,
            (state) => state.areaForCounts == null,
            () => type(bloc, 'C'),
          );
          await stores.addSize(sheet(48, 100));
        },
        verify: (bloc) {
          expect(bloc.state.materialCounts, isEmpty);
          expect(bloc.state.suggestions, isEmpty);
        },
      );
    });

    group('T2a 2/3: the sheet table of the detail panel (Section 1.4, '
        '"sheet sizes with the count for each")', () {
      void type(CalculatorBloc bloc, String keys) {
        for (final key in keys.split(' ')) {
          bloc.add(switch (key) {
            'ft' => const CalculatorUnitSelected(Unit.foot),
            '=' => const CalculatorEqualsPressed(),
            _ when key.startsWith('[') => CalculatorKeySelected(
              key.substring(1, key.length - 1),
            ),
            _ => CalculatorDigitPressed(key),
          });
        }
      }

      List<String> rows(CalculatorState state) => [
        for (final row in state.sizeTable!.rows)
          '${row.sizeText} ${row.countText}',
      ];

      const appendixBRows = [
        '48in x 96in 5.63',
        '48in x 108in 5.00',
        '48in x 120in 4.50',
      ];

      late Tape landedTape;

      Future<List<StoredSize>> storedSheets() =>
          stores.watchSizes(SizeStore.sheet, MeasurementSystem.imperial).first;

      blocTest<CalculatorBloc, CalculatorState>(
        'after Area 180ft² the table counts the area at every stored size, '
        'the one accepted from the strip included (walkthrough 11.3)',
        build: () => bloc,
        act: (bloc) async {
          type(bloc, '[Length] 2 0 ft [Height] 9 ft =');
          await bloc.stream.firstWhere(
            (state) => state.materialCounts.isNotEmpty,
          );
          bloc.add(CalculatorSuggestionAccepted(bloc.state.suggestions.first));
        },
        verify: (bloc) {
          expect(bloc.state.sizeTable!.areaText, '180ft²');
          expect(rows(bloc.state), appendixBRows);
          expect(bloc.state.hasDetails, isTrue);
        },
      );

      blocTest<CalculatorBloc, CalculatorState>(
        'a typed 180ft² has no tiles but has the table, so the panel has '
        'details',
        build: () => bloc,
        act: (bloc) => type(bloc, '1 8 0 ft ft'),
        verify: (bloc) {
          expect(bloc.state.dimensions, isEmpty);
          expect(rows(bloc.state), appendixBRows);
          expect(bloc.state.hasDetails, isTrue);
        },
      );

      blocTest<CalculatorBloc, CalculatorState>(
        'Radius 6ft has tiles and no table, and the panel has details',
        build: () => bloc,
        act: (bloc) => type(bloc, '[Radius] 6 ft'),
        verify: (bloc) {
          expect(bloc.state.sizeTable, isNull);
          expect(bloc.state.dimensions, isNotEmpty);
          expect(bloc.state.hasDetails, isTrue);
        },
      );

      blocTest<CalculatorBloc, CalculatorState>(
        'a length is not an area: no table and nothing in the panel',
        build: () => bloc,
        act: (bloc) => type(bloc, '1 8 0 ft'),
        verify: (bloc) {
          expect(bloc.state.sizeTable, isNull);
          expect(bloc.state.hasDetails, isFalse);
        },
      );

      test('a count with no stored row behind it is named by its size and '
          'the rows before it that show the same size', () {
        final typed = tapeState(pressed('1 8 0 ft ft'));
        final sheet = appendixBSheets().first;
        final unnamed = PieceSize(width: sheet.width, height: sheet.height);
        final state = typed.copyWith(
          stores: TradeStores(sheetSizes: [unnamed, sheet, unnamed]),
        );
        expect(state.sizeTable!.rows.map((row) => row.id), [
          '48in x 96in#0',
          'sheet_48x96in',
          '48in x 96in#2',
        ]);
      });

      test('the rows are the counts of the area on the display: until the '
          'stores answer the table has its title and no row, and with them '
          'a new area is counted at once', () {
        final waiting = tapeState(pressed('4 1 0 ft ft'));
        expect(waiting.sizeTable!.areaText, '410ft²');
        expect(waiting.sizeTable!.rows, isEmpty);

        final answered = waiting.copyWith(stores: storesOf(waiting));
        expect(answered.sizeTable!.rows.map((row) => row.countText), [
          '12.81',
          '11.39',
          '10.25',
        ]);
      });

      blocTest<CalculatorBloc, CalculatorState>(
        'a size the store holds twice gets a row each, each named by its own '
        'stored row',
        build: () => bloc,
        act: (bloc) async {
          await stores.addSize((await storedSheets()).first);
          type(bloc, '1 8 0 ft ft');
          await bloc.stream.firstWhere(
            (state) => state.materialCounts.length == 4,
          );
        },
        verify: (bloc) async {
          expect(bloc.state.sizeTable!.rows.map((row) => row.id), [
            'sheet_48x96in',
            'sheet_48x108in',
            'sheet_48x120in',
            (await storedSheets()).last.id,
          ]);
          expect(rows(bloc.state), [...appendixBRows, '48in x 96in 5.63']);
        },
      );

      for (final (which, deletedRow, keptSeeds) in const [
        ('first', 0, ['sheet_48x108in', 'sheet_48x120in', null]),
        ('second', 3, ['sheet_48x96in', 'sheet_48x108in', 'sheet_48x120in']),
      ]) {
        blocTest<CalculatorBloc, CalculatorState>(
          'deleting the $which of two rows with one size removes that stored '
          'row alone, and the other keeps its name, so the table never hands '
          'a swiped row\'s place to the row that stays (B1)',
          build: () => bloc,
          act: (bloc) async {
            await stores.addSize((await storedSheets()).first);
            type(bloc, '1 8 0 ft ft');
            await bloc.stream.firstWhere(
              (state) => state.materialCounts.length == 4,
            );
            final before = bloc.state.sizeTable!.rows;
            final kept = before[3 - deletedRow].id;
            final shrunk = bloc.stream.firstWhere(
              (state) => state.materialCounts.length == 3,
            );
            bloc.add(CalculatorSizeRowDeleted(before[deletedRow].id));
            final after = await shrunk;
            expect(
              after.sizeTable!.rows.map((row) => row.id),
              contains(kept),
              reason: 'the row that stays is still named as it was',
            );
            expect(
              after.sizeTable!.rows.map((row) => row.id),
              isNot(contains(before[deletedRow].id)),
            );
            expect(
              after.stores.masonrySizes,
              hasLength(2),
              reason: 'a deleted sheet size leaves the other store alone',
            );
          },
          verify: (bloc) async {
            expect(
              rows(bloc.state).where((row) => row == '48in x 96in 5.63'),
              hasLength(1),
            );
            expect((await storedSheets()).map((size) => size.seed), keptSeeds);
          },
        );
      }

      blocTest<CalculatorBloc, CalculatorState>(
        'deleting a row takes it off the table and the strip at once and '
        'removes the size from the store; the tape stays',
        build: () => bloc,
        act: (bloc) async {
          type(bloc, '1 8 0 ft ft');
          await bloc.stream.firstWhere(
            (state) => state.materialCounts.isNotEmpty,
          );
          bloc.add(const CalculatorSizeRowDeleted('sheet_48x108in'));
        },
        verify: (bloc) async {
          expect(rows(bloc.state), ['48in x 96in 5.63', '48in x 120in 4.50']);
          expect(bloc.state.tape, pressed('1 8 0 ft ft'));
          expect((await storedSheets()).map((size) => size.seed), [
            'sheet_48x96in',
            'sheet_48x120in',
          ]);
        },
      );

      blocTest<CalculatorBloc, CalculatorState>(
        'a Drywall result already on the tape keeps its count when its size '
        'is deleted (Section 1.4)',
        build: () => bloc,
        act: (bloc) async {
          type(bloc, '1 8 0 ft ft');
          await bloc.stream.firstWhere(
            (state) => state.materialCounts.isNotEmpty,
          );
          bloc.add(CalculatorSuggestionAccepted(bloc.state.suggestions.first));
          await bloc.stream.firstWhere((state) => state.tape.endsWithResult);
          landedTape = bloc.state.tape;
          bloc.add(const CalculatorSizeRowDeleted('sheet_48x96in'));
        },
        verify: (bloc) {
          expect(bloc.state.tape, landedTape);
          expect(rows(bloc.state), ['48in x 108in 5.00', '48in x 120in 4.50']);
        },
      );

      blocTest<CalculatorBloc, CalculatorState>(
        'a delete the store refuses takes the row off at once, before the '
        'store answers, then puts it back',
        build: () => bloc,
        act: (bloc) async {
          type(bloc, '1 8 0 ft ft');
          await bloc.stream.firstWhere(
            (state) => state.materialCounts.isNotEmpty,
          );
          stores.writeFailure = const CalculatorFailure(
            errorType: CalculatorErrorType.storageError,
          );
          bloc.add(const CalculatorSizeRowDeleted('sheet_48x108in'));
        },
        expect: () => predicate<List<CalculatorState>>(
          (states) => equals([
            ['48in x 96in 5.63', '48in x 120in 4.50'],
            appendixBRows,
          ]).matches(states.skip(states.length - 2).map(rows).toList(), {}),
          'ends with the row taken off, then put back',
        ),
        verify: (bloc) async {
          expect(await storedSheets(), hasLength(3));
        },
      );

      blocTest<CalculatorBloc, CalculatorState>(
        'a row no longer on the table, deleted twice before the table '
        'redrew, changes nothing more',
        build: () => bloc,
        act: (bloc) async {
          type(bloc, '1 8 0 ft ft');
          await bloc.stream.firstWhere(
            (state) => state.materialCounts.isNotEmpty,
          );
          bloc
            ..add(const CalculatorSizeRowDeleted('sheet_48x108in'))
            ..add(const CalculatorSizeRowDeleted('sheet_48x108in'));
        },
        verify: (bloc) async {
          expect(rows(bloc.state), ['48in x 96in 5.63', '48in x 120in 4.50']);
          expect(await storedSheets(), hasLength(2));
        },
      );
    });

    group('T2a 3/3: "+ Add size" in the sheet table (Section 1.4; term '
        '2.18)', () {
      List<String> rows(CalculatorState state) => [
        for (final row in state.sizeTable!.rows)
          '${row.sizeText} ${row.countText}',
      ];

      List<String> stripSizes(CalculatorState state) => [
        for (final chip in countOffers(state)) chip.basis!,
      ];

      void type180SquareFeet(CalculatorBloc bloc) => bloc
        ..add(const CalculatorDigitPressed('1'))
        ..add(const CalculatorDigitPressed('8'))
        ..add(const CalculatorDigitPressed('0'))
        ..add(const CalculatorUnitSelected(Unit.foot))
        ..add(const CalculatorUnitSelected(Unit.foot));

      blocTest<CalculatorBloc, CalculatorState>(
        '4 [Feet] by 12 [Feet] adds 48in x 144in at 3.75 after the last row, '
        'with its chip at the end of the strip; the tape stays (walkthrough '
        '11.4)',
        build: () => bloc,
        act: (bloc) async {
          type180SquareFeet(bloc);
          await bloc.stream.firstWhere(
            (state) => state.materialCounts.isNotEmpty,
          );
          bloc.add(const CalculatorSizeEditorClosed(['4Feet', '12Feet']));
        },
        verify: (bloc) {
          expect(rows(bloc.state), [
            '48in x 96in 5.63',
            '48in x 108in 5.00',
            '48in x 120in 4.50',
            '48in x 144in 3.75',
          ]);
          expect(stripSizes(bloc.state).last, '48in x 144in');
          expect(bloc.state.tape, pressed('1 8 0 ft ft'));
        },
      );

      blocTest<CalculatorBloc, CalculatorState>(
        'a number with no unit adds no size, in either field: nothing says '
        'whether 8 is inches or feet (B3; term 2.16)',
        build: () => bloc,
        act: (bloc) async {
          type180SquareFeet(bloc);
          await bloc.stream.firstWhere(
            (state) => state.materialCounts.isNotEmpty,
          );
          final added = bloc.stream.firstWhere(
            (state) => state.materialCounts.length == 4,
          );
          bloc
            ..add(const CalculatorSizeEditorClosed(['4Feet', '8']))
            ..add(const CalculatorSizeEditorClosed(['48', '8Feet']))
            ..add(const CalculatorSizeEditorClosed(['4Feet', '12Feet']));
          await added;
        },
        verify: (bloc) {
          expect(bloc.state.materialCounts, hasLength(4));
          expect(rows(bloc.state).last, '48in x 144in 3.75');
        },
      );

      blocTest<CalculatorBloc, CalculatorState>(
        'Add is the equals key: 4 [Feet] 6 by 8 [Feet] adds 54in x 96in at '
        '5.00, and 48 [Inch] 1 / 2 by 96 [Inch] adds 48.5in x 96in (B1; rule '
        '4.5; Section 6)',
        build: () => bloc,
        act: (bloc) async {
          type180SquareFeet(bloc);
          await bloc.stream.firstWhere(
            (state) => state.materialCounts.isNotEmpty,
          );
          final four = bloc.stream.firstWhere(
            (state) => state.materialCounts.length == 4,
          );
          bloc.add(const CalculatorSizeEditorClosed(['4Feet6', '8Feet']));
          await four;
          final five = bloc.stream.firstWhere(
            (state) => state.materialCounts.length == 5,
          );
          bloc.add(const CalculatorSizeEditorClosed(['48Inch1/2', '96Inch']));
          await five;
        },
        verify: (bloc) {
          expect(rows(bloc.state).skip(3), [
            '54in x 96in 5.00',
            '48.5in x 96in 5.57',
          ]);
        },
      );

      for (final (length, width) in const [
        ('0Feet', '12Feet'),
        ('4Feet', '0'),
        ('4Feet', ''),
        ('4+2Feet', '12Feet'),
        ('4Feet4Feet', '8Feet'),
        ('4Feet20CM', '8Feet'),
        ('6Inch4Feet', '8Feet'),
        ('0.0001Inch', '96Inch'),
        ('99999999999999Inch', '96Inch'),
      ]) {
        blocTest<CalculatorBloc, CalculatorState>(
          'Length "$length" by Width "$width" spells no size and adds nothing',
          build: () => bloc,
          act: (bloc) async {
            type180SquareFeet(bloc);
            await bloc.stream.firstWhere(
              (state) => state.materialCounts.isNotEmpty,
            );
            bloc.add(CalculatorSizeEditorClosed([length, width]));
          },
          verify: (bloc) async {
            expect(rows(bloc.state), hasLength(3));
            expect(
              await stores
                  .watchSizes(SizeStore.sheet, MeasurementSystem.imperial)
                  .first,
              hasLength(3),
            );
          },
        );
      }

      blocTest<CalculatorBloc, CalculatorState>(
        'a size the store refuses is said so in a red Alert, "Size not '
        'added", which the next key clears, and no row is added (N2)',
        build: () => bloc,
        act: (bloc) async {
          type180SquareFeet(bloc);
          await bloc.stream.firstWhere(
            (state) => state.materialCounts.isNotEmpty,
          );
          stores.writeFailure = const CalculatorFailure(
            errorType: CalculatorErrorType.storageError,
          );
          final refused = bloc.stream.firstWhere((state) => state.sizeNotAdded);
          bloc.add(const CalculatorSizeEditorClosed(['4Feet', '12Feet']));
          final told = await refused;
          expect(told.toast, const CalculatorSizeNotAddedToast());
          expect(told.toastsRaised, 1);
          expect(rows(told), hasLength(3));
          final cleared = bloc.stream.firstWhere(
            (state) => !state.sizeNotAdded,
          );
          bloc.add(const CalculatorDigitPressed('7'));
          expect((await cleared).toast, isNull);
        },
        verify: (bloc) async {
          expect(
            await stores
                .watchSizes(SizeStore.sheet, MeasurementSystem.imperial)
                .first,
            hasLength(3),
          );
        },
      );

      blocTest<CalculatorBloc, CalculatorState>(
        'a key the tape refuses clears "Size not added" too, as any key '
        'clears the last one\'s message (N2)',
        build: () => bloc,
        act: (bloc) async {
          type180SquareFeet(bloc);
          await bloc.stream.firstWhere(
            (state) => state.materialCounts.isNotEmpty,
          );
          stores.writeFailure = const CalculatorFailure(
            errorType: CalculatorErrorType.storageError,
          );
          final refused = bloc.stream.firstWhere((state) => state.sizeNotAdded);
          bloc.add(const CalculatorSizeEditorClosed(['4Feet', '12Feet']));
          await refused;
          final cleared = bloc.stream.firstWhere(
            (state) => !state.sizeNotAdded,
          );
          bloc.add(const CalculatorFractionPressed());
          expect((await cleared).refusal, isNotNull);
        },
        verify: (bloc) async {
          expect(
            await stores
                .watchSizes(SizeStore.sheet, MeasurementSystem.imperial)
                .first,
            hasLength(3),
          );
        },
      );

      test('two states that differ only in "Size not added" are not equal, '
          'so the page draws the Alert and takes it down again', () {
        expect(
          const CalculatorState(sizeNotAdded: true),
          isNot(equals(const CalculatorState())),
        );
      });

      blocTest<CalculatorBloc, CalculatorState>(
        'with nobody signed in the add says nothing of its own: the app '
        'answers that with the sign-in screen (N2)',
        build: () => bloc,
        act: (bloc) async {
          type180SquareFeet(bloc);
          await bloc.stream.firstWhere(
            (state) => state.materialCounts.isNotEmpty,
          );
          stores.signedIn = false;
          bloc
            ..add(const CalculatorSizeEditorClosed(['4Feet', '12Feet']))
            ..add(const CalculatorGroupSelected(1));
          await bloc.stream.firstWhere((state) => state.currentGroupIndex == 1);
        },
        verify: (bloc) {
          expect(bloc.state.sizeNotAdded, isFalse);
          expect(bloc.state.toast, isNull);
        },
      );

      blocTest<CalculatorBloc, CalculatorState>(
        'the editor closed without Add adds nothing',
        build: () => bloc,
        act: (bloc) async {
          type180SquareFeet(bloc);
          await bloc.stream.firstWhere(
            (state) => state.materialCounts.isNotEmpty,
          );
          bloc.add(const CalculatorSizeEditorClosed([]));
        },
        verify: (bloc) async {
          expect(rows(bloc.state), hasLength(3));
          expect(
            await stores
                .watchSizes(SizeStore.sheet, MeasurementSystem.imperial)
                .first,
            hasLength(3),
          );
        },
      );

      test('the editor reads a field under the unit system in force: 0.4mm '
          'is a size under Imperial and rounds to 0mm under Metric, and a '
          'number with no unit is a size under neither', () {
        final imperial = CalculatorState.initial();
        final metric = tapeState(
          const Tape(
            preferences: CalculatorPreferences(
              system: MeasurementSystem.metric,
            ),
          ),
        );
        expect(imperial.sizeEntryLength('0.4MM'), isNotNull);
        expect(
          metric.sizeEntry('0.4MM'),
          const SizeEntryRefused(
            SizeEntryRefusal.roundsToZero,
            typed: '0.4mm',
            shownAs: '0mm',
          ),
        );
        for (final state in [imperial, metric]) {
          expect(state.sizeEntryLength('1200'), isNull);
          expect(
            state.sizeEntry('1200'),
            const SizeEntryRefused(SizeEntryRefusal.noUnit, typed: '1200'),
          );
        }
        expect(metric.sizeEntryLength('0'), isNull);
        expect(
          metric.sizeEntry('0'),
          const SizeEntryRefused(SizeEntryRefusal.zero),
        );
        expect(
          imperial.sizeEntry('4Feet20CM'),
          const SizeEntryRefused(SizeEntryRefusal.otherSystem),
        );
      });
    });

    test(
      'the initial state is an empty imperial tape with the first group',
      () {
        final state = CalculatorState.initial();
        expect(state.tape, const Tape());
        expect(state.currentGroupIndex, 0);
        expect(state.groupOrder, CalculatorGroupId.defaultOrder);
        expect(state.currentUnitSystem, UnitSystem.imperial);
        expect(state.tape.beingTyped, isNull);
        expect(state.labelKeyId, isNull);
        expect(state.valueText, '');
        expect(state.chipsList, isEmpty);
        expect(state.notice, isNull);
        expect(state.refusal, isNull);
      },
    );
  });
}
