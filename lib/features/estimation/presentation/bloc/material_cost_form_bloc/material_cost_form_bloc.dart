import 'package:flutter_bloc/flutter_bloc.dart';

part 'material_cost_form_event.dart';
part 'material_cost_form_state.dart';

/// BLoC for managing material cost item type input and validation.
class MaterialCostFormBloc
    extends Bloc<MaterialCostFormEvent, MaterialCostFormState> {
  MaterialCostFormBloc() : super(const MaterialCostFormInitial()) {
    on<MaterialCostItemTypeChanged>(_onItemTypeChanged);
    // TODO(CA-294): register MaterialCostFormSubmitted and wire to CostItemRepository.createCostItem
  }

  void _onItemTypeChanged(
    MaterialCostItemTypeChanged event,
    Emitter<MaterialCostFormState> emit,
  ) {
    final current = state is MaterialCostFormEditing
        ? state as MaterialCostFormEditing
        : const MaterialCostFormEditing();
    emit(
      current.copyWith(
        materialType: event.value,
        itemTypeError: event.value.trim().isEmpty ? 'itemTypeRequired' : null,
      ),
    );
  }
}
