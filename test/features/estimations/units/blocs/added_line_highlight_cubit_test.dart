import 'package:bloc_test/bloc_test.dart';
import 'package:construculator/features/estimation/presentation/bloc/added_line_highlight_cubit/added_line_highlight_cubit.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AddedLineHighlightCubit', () {
    blocTest<AddedLineHighlightCubit, String?>(
      'marks no line to begin with',
      build: AddedLineHighlightCubit.new,
      verify: (cubit) => expect(cubit.state, isNull),
    );

    blocTest<AddedLineHighlightCubit, String?>(
      'marks the line just added',
      build: AddedLineHighlightCubit.new,
      act: (cubit) => cubit.highlight('line-1'),
      expect: () => ['line-1'],
    );

    blocTest<AddedLineHighlightCubit, String?>(
      'moves the mark to the next line added',
      build: AddedLineHighlightCubit.new,
      act: (cubit) => cubit
        ..highlight('line-1')
        ..highlight('line-2'),
      expect: () => ['line-1', 'line-2'],
    );

    blocTest<AddedLineHighlightCubit, String?>(
      'moves the mark to a duplicate of the same material, as a new line',
      build: AddedLineHighlightCubit.new,
      act: (cubit) => cubit
        ..highlight('line-1')
        ..highlight('line-2'),
      verify: (cubit) => expect(cubit.state, 'line-2'),
    );

    blocTest<AddedLineHighlightCubit, String?>(
      'removes the mark when the user taps the line',
      build: AddedLineHighlightCubit.new,
      act: (cubit) => cubit
        ..highlight('line-1')
        ..clear(),
      expect: () => ['line-1', null],
    );

    blocTest<AddedLineHighlightCubit, String?>(
      'does nothing when there is no mark to remove',
      build: AddedLineHighlightCubit.new,
      act: (cubit) => cubit.clear(),
      expect: () => <String?>[],
    );
  });
}
