import 'package:flutter_bloc/flutter_bloc.dart';

part 'labour_cost_form_event.dart';
part 'labour_cost_form_state.dart';

/// BLoC for managing labour cost item type input and validation.
class LabourCostFormBloc
    extends Bloc<LabourCostFormEvent, LabourCostFormState> {
  LabourCostFormBloc() : super(const LabourCostFormInitial()) {
    on<LabourCostItemTypeChanged>(_onItemTypeChanged);
    // TODO(CA-294): register LabourCostFormSubmitted and wire to CostItemRepository.createCostItem
  }

  void _onItemTypeChanged(
    LabourCostItemTypeChanged event,
    Emitter<LabourCostFormState> emit,
  ) {
    final current = state is LabourCostFormEditing
        ? state as LabourCostFormEditing
        : const LabourCostFormEditing();
    emit(
      current.copyWith(
        labourType: event.value,
        itemTypeError: event.value.trim().isEmpty ? 'itemTypeRequired' : null,
      ),
    );
  }
}
