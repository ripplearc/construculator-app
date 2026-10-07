import 'package:flutter_bloc/flutter_bloc.dart';

/// Which cost line, if any, was just added and should stand out on the
/// estimate screen. The state is that line's id, or null when none is marked.
///
/// The mark is never timed out and is never saved: it lives as long as the
/// screen that owns this cubit, so leaving the screen clears it and reopening
/// never brings it back.
class AddedLineHighlightCubit extends Cubit<String?> {
  AddedLineHighlightCubit() : super(null);

  /// Marks [costItemId] as the line just added. Any earlier mark is replaced,
  /// so only the newest added line stands out.
  void highlight(String costItemId) => emit(costItemId);

  /// Removes the mark, as when the user taps the highlighted line.
  void clear() {
    if (state != null) emit(null);
  }
}
