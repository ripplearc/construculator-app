import 'package:construculator/features/estimation/domain/entities/cost_item_entity.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'labour_cost_form_event.dart';
part 'labour_cost_form_state.dart';

/// BLoC for managing labour cost item type input and validation.
class LabourCostFormBloc
    extends Bloc<LabourCostFormEvent, LabourCostFormState> {
  LabourCostFormBloc() : super(const LabourCostFormInitial()) {
    on<LabourCostItemTypeChanged>(_onItemTypeChanged);
    on<LabourCostCalculationMethodChanged>(_onCalculationMethodChanged);
    on<LabourCostLaborValueUpdated>(_onLaborValueUpdated);
    on<LabourCostCrewSizeUpdated>(_onCrewSizeUpdated);
    on<LabourCostHourlyRateUpdated>(_onHourlyRateUpdated);
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

  void _onCalculationMethodChanged(
    LabourCostCalculationMethodChanged event,
    Emitter<LabourCostFormState> emit,
  ) {
    final current = state is LabourCostFormEditing
        ? state as LabourCostFormEditing
        : const LabourCostFormEditing();
    emit(current.copyWith(calculationMethod: event.calculationMethod));
  }

  void _onLaborValueUpdated(
    LabourCostLaborValueUpdated event,
    Emitter<LabourCostFormState> emit,
  ) {
    final current = state is LabourCostFormEditing
        ? state as LabourCostFormEditing
        : const LabourCostFormEditing();
    emit(current.copyWith(laborValue: event.laborValue));
  }

  void _onCrewSizeUpdated(
    LabourCostCrewSizeUpdated event,
    Emitter<LabourCostFormState> emit,
  ) {
    final current = state is LabourCostFormEditing
        ? state as LabourCostFormEditing
        : const LabourCostFormEditing();
    final crewSize = event.crewSize;
    final isPositive = crewSize != null && crewSize > 0;
    emit(
      current.copyWith(
        crewSize: isPositive ? crewSize : null,
        crewSizeError: crewSize == null
            ? 'crewSizeRequiredError'
            : isPositive
                ? null
                : 'crewSizeInvalidError',
      ),
    );
  }

  void _onHourlyRateUpdated(
    LabourCostHourlyRateUpdated event,
    Emitter<LabourCostFormState> emit,
  ) {
    final current = state is LabourCostFormEditing
        ? state as LabourCostFormEditing
        : const LabourCostFormEditing();
    final parsed = double.tryParse(event.value);
    final isPositive = parsed != null && parsed > 0;
    emit(
      current.copyWith(
        hourlyRate: isPositive ? parsed : null,
        hourlyRateError: event.value.trim().isEmpty
            ? 'hourlyRateRequiredError'
            : isPositive
                ? null
                : 'hourlyRateInvalidError',
      ),
    );
  }
}
