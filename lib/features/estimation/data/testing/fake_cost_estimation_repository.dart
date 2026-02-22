import 'dart:async';

import 'package:construculator/features/estimation/domain/entities/cost_estimate_entity.dart';
import 'package:construculator/features/estimation/domain/entities/enums.dart';
import 'package:construculator/features/estimation/domain/entities/lock_status_entity.dart';
import 'package:construculator/features/estimation/domain/entities/markup_configuration_entity.dart';
import 'package:construculator/features/estimation/domain/repositories/cost_estimation_repository.dart';
import 'package:construculator/libraries/either/either.dart';
import 'package:construculator/libraries/estimation/domain/estimation_error_type.dart';
import 'package:construculator/libraries/errors/failures.dart';
import 'package:construculator/libraries/time/interfaces/clock.dart';

/// A fake implementation of [CostEstimationRepository] for testing purposes.
class FakeCostEstimationRepository implements CostEstimationRepository {
  /// Tracks method calls for assertions
  final List<Map<String, dynamic>> _methodCalls = [];

  /// Tracks cost estimation data for assertions during [fetchInitialEstimations]
  final Map<String, List<CostEstimate>> _projectEstimations = {};

  /// Stream controllers for each project
  final Map<String, StreamController<Either<Failure, List<CostEstimate>>>>
  _streamControllers = {};

  /// Controls whether [fetchInitialEstimations] should return a [Failure].s
  bool shouldReturnFailureOnFetchInitialEstimations = false;

  /// Specifies the [EstimationErrorType] for the [Failure] returned by
  /// [fetchInitialEstimations] when [shouldReturnFailureOnFetchInitialEstimations] is true.
  EstimationErrorType? fetchInitialEstimationsFailureType;

  /// Controls whether [fetchInitialEstimations] returns an empty list
  bool shouldReturnEmptyList = false;

  /// Controls whether [createEstimation] should return a [Failure].
  bool shouldReturnFailureOnCreateEstimation = false;

  /// Specifies the [EstimationErrorType] for the [Failure] returned by
  /// [createEstimation] when [shouldReturnFailureOnCreateEstimation] is true.
  EstimationErrorType? createEstimationFailureType;

  /// Controls whether [deleteEstimation] should return a [Failure].
  bool shouldReturnFailureOnDeleteEstimation = false;

  /// Specifies the [EstimationErrorType] for the [Failure] returned by
  /// [deleteEstimation] when [shouldReturnFailureOnDeleteEstimation] is true.
  EstimationErrorType? deleteEstimationFailureType;

  /// Controls whether [loadMoreEstimations] should return a [Failure].
  bool shouldReturnFailureOnLoadMore = false;

  /// Specifies the [EstimationErrorType] for the [Failure] returned by
  /// [loadMoreEstimations] when [shouldReturnFailureOnLoadMore] is true.
  EstimationErrorType? loadMoreFailureType;

  /// Tracks pagination state per project
  final Map<String, bool> _hasMoreEstimationsMap = {};

  /// Controls whether operations should be delayed
  bool shouldDelayOperations = false;

  /// Controls when a delayed future is completed
  Completer<void>? completer;

  /// Clock dependency for time operations
  final Clock clock;

  /// Constructor for fake cost estimation repository
  FakeCostEstimationRepository({required this.clock});

  @override
  Future<Either<Failure, List<CostEstimate>>> fetchInitialEstimations(
    String projectId,
  ) async {
    if (shouldDelayOperations) {
      await completer?.future;
    }

    _methodCalls.add({
      'method': 'fetchInitialEstimations',
      'projectId': projectId,
    });

    if (shouldReturnFailureOnFetchInitialEstimations) {
      final failure = EstimationFailure(
        errorType:
            fetchInitialEstimationsFailureType ??
            EstimationErrorType.unexpectedError,
      );
      _emitToStream(projectId, Left(failure));
      return Left(failure);
    }

    if (shouldReturnEmptyList) {
      _emitToStream(projectId, const Right([]));
      return const Right([]);
    }

    final estimations = _projectEstimations[projectId] ?? [];
    _emitToStream(projectId, Right(estimations));
    return Right(estimations);
  }

  @override
  Future<Either<Failure, List<CostEstimate>>> loadMoreEstimations(
    String projectId,
  ) async {
    if (shouldDelayOperations) {
      await completer?.future;
    }

    _methodCalls.add({'method': 'loadMoreEstimations', 'projectId': projectId});

    if (shouldReturnFailureOnLoadMore) {
      return Left(
        EstimationFailure(
          errorType: loadMoreFailureType ?? EstimationErrorType.unexpectedError,
        ),
      );
    }

    final estimations = _projectEstimations[projectId] ?? [];
    _emitToStream(projectId, Right(estimations));
    return Right(estimations);
  }

  @override
  bool hasMoreEstimations(String projectId) {
    return _hasMoreEstimationsMap[projectId] ?? true;
  }

  @override
  Stream<Either<Failure, List<CostEstimate>>> watchEstimations(
    String projectId,
  ) {
    _methodCalls.add({'method': 'watchEstimations', 'projectId': projectId});

    if (!_streamControllers.containsKey(projectId)) {
      _streamControllers[projectId] =
          StreamController<Either<Failure, List<CostEstimate>>>.broadcast(
            onCancel: () {
              _streamControllers[projectId]?.close();
              _streamControllers.remove(projectId);
            },
          );
      Future.microtask(() => fetchInitialEstimations(projectId));
    }

    final controller = _streamControllers[projectId];
    if (controller == null) {
      throw StateError('Stream controller not found for project: $projectId');
    }
    return controller.stream;
  }

  void _emitToStream(
    String projectId,
    Either<Failure, List<CostEstimate>> result,
  ) {
    if (_streamControllers.containsKey(projectId) &&
        _streamControllers[projectId]?.isClosed == false) {
      _streamControllers[projectId]?.add(result);
    }
  }

  @override
  Future<Either<Failure, CostEstimate>> createEstimation(
    CostEstimate estimation,
  ) async {
    if (shouldDelayOperations) {
      await completer?.future;
    }

    _methodCalls.add({'method': 'createEstimation', 'estimation': estimation});

    if (shouldReturnFailureOnCreateEstimation) {
      return Left(
        EstimationFailure(
          errorType:
              createEstimationFailureType ??
              EstimationErrorType.unexpectedError,
        ),
      );
    }

    final projectId = estimation.projectId;
    final estimations = _projectEstimations[projectId] ?? [];
    estimations.add(estimation);
    _projectEstimations[projectId] = estimations;

    _emitToStream(projectId, Right(estimations));

    return Right(estimation);
  }

  @override
  Future<Either<Failure, void>> deleteEstimation(
    String estimationId,
    String projectId,
  ) async {
    if (shouldDelayOperations) {
      await completer?.future;
    }

    _methodCalls.add({
      'method': 'deleteEstimation',
      'estimationId': estimationId,
      'projectId': projectId,
    });

    if (shouldReturnFailureOnDeleteEstimation) {
      return Left(
        EstimationFailure(
          errorType:
              deleteEstimationFailureType ??
              EstimationErrorType.unexpectedError,
        ),
      );
    }

    final estimations = _projectEstimations[projectId] ?? [];
    final hadEstimation = estimations.any((est) => est.id == estimationId);
    if (!hadEstimation) {
      return const Left(
        EstimationFailure(errorType: EstimationErrorType.notFoundError),
      );
    }
    estimations.removeWhere((estimation) => estimation.id == estimationId);
    _projectEstimations[projectId] = estimations;

    if (hadEstimation) {
      _emitToStream(projectId, Right(estimations));
    }

    return const Right(null);
  }

  @override
  void dispose() {
    for (final controller in _streamControllers.values) {
      if (!controller.isClosed) {
        controller.close();
      }
    }
    _streamControllers.clear();
    _projectEstimations.clear();
  }

  /// Adds cost estimation data for a specific project
  void addProjectEstimations(String projectId, List<CostEstimate> estimations) {
    _projectEstimations[projectId] = estimations;
  }

  /// Adds a single cost estimation for a specific project
  void addProjectEstimation(String projectId, CostEstimate estimation) {
    final estimations = _projectEstimations[projectId] ?? [];
    estimations.add(estimation);
    _projectEstimations[projectId] = estimations;
  }

  /// Clears all cost estimation data for a specific project
  void clearProjectEstimations(String projectId) {
    _projectEstimations[projectId] = [];
  }

  /// Clears all cost estimation data and method calls
  void clearAllData() {
    _projectEstimations.clear();
    _methodCalls.clear();
  }

  /// Returns a list of all method calls
  List<Map<String, dynamic>> getMethodCalls() => List.from(_methodCalls);

  /// Returns the last method call
  Map<String, dynamic>? getLastMethodCall() =>
      _methodCalls.isEmpty ? null : _methodCalls.last;

  /// Returns a list of all method calls for a given method name
  List<Map<String, dynamic>> getMethodCallsFor(String methodName) {
    return _methodCalls.where((call) => call['method'] == methodName).toList();
  }

  /// Clears all method calls
  void clearMethodCalls() {
    _methodCalls.clear();
  }

  /// Sets whether there are more estimations to load for a project
  void setHasMoreEstimations(String projectId, bool hasMore) {
    _hasMoreEstimationsMap[projectId] = hasMore;
  }

  /// Resets all fake configurations, clears data
  void reset() {
    shouldReturnFailureOnFetchInitialEstimations = false;
    fetchInitialEstimationsFailureType = null;
    shouldReturnFailureOnCreateEstimation = false;
    createEstimationFailureType = null;
    shouldReturnFailureOnDeleteEstimation = false;
    deleteEstimationFailureType = null;
    shouldReturnFailureOnLoadMore = false;
    loadMoreFailureType = null;
    shouldReturnEmptyList = false;
    shouldDelayOperations = false;
    completer = null;

    for (final controller in _streamControllers.values) {
      controller.close();
    }
    _streamControllers.clear();
    _hasMoreEstimationsMap.clear();

    clearAllData();
    clearMethodCalls();
  }

  /// Creates a sample CostEstimate for testing
  static const String _defaultEstimationIdPrefix = 'test-estimation-';
  static const String _defaultProjectId = 'test-project-123';
  static const String _defaultEstimateName = 'Test Estimation';
  static const String _defaultEstimateDescription =
      'Test estimation description';
  static const String _defaultCreatorUserId = 'test-user-123';
  static const double _defaultTotalCost = 50000.0;
  static const double _defaultOverallMarkupValue = 15.0;
  static const double _defaultMaterialMarkupValue = 10.0;
  static const double _defaultLaborMarkupValue = 20.0;
  static const double _defaultEquipmentMarkupValue = 12.0;

  /// Creates a sample CostEstimate for testing
  CostEstimate createSampleEstimation({
    String? id,
    String? projectId,
    String? estimateName,
    String? estimateDescription,
    String? creatorUserId,
    double? totalCost,
    bool? isLocked,
    String? lockedByUserID,
    DateTime? createdAt,
    DateTime? updatedAt,
    MarkupType? markupType,
  }) {
    final now = clock.now();
    final created = createdAt ?? now;
    final updated = updatedAt ?? now;

    final markupConfig = MarkupConfiguration(
      overallType: markupType ?? MarkupType.overall,
      overallValue: const MarkupValue(
        type: MarkupValueType.percentage,
        value: _defaultOverallMarkupValue,
      ),
      materialValueType: markupType == MarkupType.granular
          ? MarkupType.granular
          : null,
      materialValue: markupType == MarkupType.granular
          ? const MarkupValue(
              type: MarkupValueType.percentage,
              value: _defaultMaterialMarkupValue,
            )
          : null,
      laborValueType: markupType == MarkupType.granular
          ? MarkupType.granular
          : null,
      laborValue: markupType == MarkupType.granular
          ? const MarkupValue(
              type: MarkupValueType.percentage,
              value: _defaultLaborMarkupValue,
            )
          : null,
      equipmentValueType: markupType == MarkupType.granular
          ? MarkupType.granular
          : null,
      equipmentValue: markupType == MarkupType.granular
          ? const MarkupValue(
              type: MarkupValueType.percentage,
              value: _defaultEquipmentMarkupValue,
            )
          : null,
    );

    final lockStatus = isLocked == true && lockedByUserID != null
        ? LockStatus.locked(lockedByUserID, now)
        : const LockStatus.unlocked();

    return CostEstimate(
      id: id ?? '$_defaultEstimationIdPrefix${now.millisecondsSinceEpoch}',
      projectId: projectId ?? _defaultProjectId,
      estimateName: estimateName ?? _defaultEstimateName,
      estimateDescription: estimateDescription ?? _defaultEstimateDescription,
      creatorUserId: creatorUserId ?? _defaultCreatorUserId,
      markupConfiguration: markupConfig,
      totalCost: totalCost ?? _defaultTotalCost,
      lockStatus: lockStatus,
      createdAt: created,
      updatedAt: updated,
    );
  }

  /// Creates a sample CostEstimate with overall markup for testing
  CostEstimate createSampleOverallMarkupEstimation({
    String? id,
    String? projectId,
    String? estimateName,
    String? estimateDescription,
    String? creatorUserId,
    double? totalCost,
    bool? isLocked,
    String? lockedByUserID,
    DateTime? createdAt,
    DateTime? updatedAt,
    double? overallMarkupValue,
  }) {
    final now = clock.now();
    final created = createdAt ?? now;
    final updated = updatedAt ?? now;

    final markupConfig = MarkupConfiguration(
      overallType: MarkupType.overall,
      overallValue: MarkupValue(
        type: MarkupValueType.percentage,
        value: overallMarkupValue ?? _defaultOverallMarkupValue,
      ),
    );

    final lockStatus = isLocked == true && lockedByUserID != null
        ? LockStatus.locked(lockedByUserID, now)
        : const LockStatus.unlocked();

    return CostEstimate(
      id: id ?? '$_defaultEstimationIdPrefix${now.millisecondsSinceEpoch}',
      projectId: projectId ?? _defaultProjectId,
      estimateName: estimateName ?? _defaultEstimateName,
      estimateDescription: estimateDescription ?? _defaultEstimateDescription,
      creatorUserId: creatorUserId ?? _defaultCreatorUserId,
      markupConfiguration: markupConfig,
      totalCost: totalCost ?? _defaultTotalCost,
      lockStatus: lockStatus,
      createdAt: created,
      updatedAt: updated,
    );
  }

  /// Creates a sample CostEstimate with granular markup for testing
  CostEstimate createSampleGranularMarkupEstimation({
    String? id,
    String? projectId,
    String? estimateName,
    String? estimateDescription,
    String? creatorUserId,
    double? totalCost,
    bool? isLocked,
    String? lockedByUserID,
    DateTime? createdAt,
    DateTime? updatedAt,
    double? materialMarkupValue,
    double? laborMarkupValue,
    double? equipmentMarkupValue,
  }) {
    final now = clock.now();
    final created = createdAt ?? now;
    final updated = updatedAt ?? now;

    final markupConfig = MarkupConfiguration(
      overallType: MarkupType.granular,
      overallValue: const MarkupValue(
        type: MarkupValueType.percentage,
        value: _defaultOverallMarkupValue,
      ),
      materialValueType: MarkupType.granular,
      materialValue: MarkupValue(
        type: MarkupValueType.percentage,
        value: materialMarkupValue ?? _defaultMaterialMarkupValue,
      ),
      laborValueType: MarkupType.granular,
      laborValue: MarkupValue(
        type: MarkupValueType.percentage,
        value: laborMarkupValue ?? _defaultLaborMarkupValue,
      ),
      equipmentValueType: MarkupType.granular,
      equipmentValue: MarkupValue(
        type: MarkupValueType.percentage,
        value: equipmentMarkupValue ?? _defaultEquipmentMarkupValue,
      ),
    );

    final lockStatus = isLocked == true && lockedByUserID != null
        ? LockStatus.locked(lockedByUserID, now)
        : const LockStatus.unlocked();

    return CostEstimate(
      id: id ?? '$_defaultEstimationIdPrefix${now.millisecondsSinceEpoch}',
      projectId: projectId ?? _defaultProjectId,
      estimateName: estimateName ?? _defaultEstimateName,
      estimateDescription: estimateDescription ?? _defaultEstimateDescription,
      creatorUserId: creatorUserId ?? _defaultCreatorUserId,
      markupConfiguration: markupConfig,
      totalCost: totalCost ?? _defaultTotalCost,
      lockStatus: lockStatus,
      createdAt: created,
      updatedAt: updated,
    );
  }
}
