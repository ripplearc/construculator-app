import 'dart:async';
import 'package:construculator/features/estimation/domain/entities/cost_estimate_entity.dart';
import 'package:construculator/features/estimation/domain/entities/enums.dart';
import 'package:construculator/features/estimation/domain/entities/lock_status_entity.dart';
import 'package:construculator/features/estimation/domain/entities/markup_configuration_entity.dart';
import 'package:construculator/features/estimation/domain/repositories/cost_estimation_repository.dart';
import 'package:construculator/libraries/errors/exceptions.dart';
import 'package:construculator/libraries/supabase/data/supabase_types.dart';
import 'package:construculator/libraries/time/interfaces/clock.dart';
import 'package:stack_trace/stack_trace.dart';

/// A fake implementation of [CostEstimationRepository] for testing purposes.
///
/// This class allows you to control and inspect the behavior of cost estimation
/// repository operations in tests. You can configure it to simulate errors,
/// delays, and return specific data for assertions.
class FakeCostEstimationRepository implements CostEstimationRepository {
  /// Tracks method calls for assertions
  final List<Map<String, dynamic>> _methodCalls = [];

  /// Tracks cost estimation data for assertions during [getEstimations]
  final Map<String, List<CostEstimate>> _projectEstimations = {};

  /// Controls whether [getEstimations] throws an exception
  bool shouldThrowOnGetEstimations = false;

  /// Error message for get estimations.
  /// Used to specify the error message thrown when [getEstimations] is attempted
  String? getEstimationsErrorMessage;

  /// Used to specify the type of exception thrown when [getEstimations] is attempted
  SupabaseExceptionType? getEstimationsExceptionType;

  /// Controls whether [createEstimation] throws an exception
  bool shouldThrowOnCreateEstimation = false;

  /// Error message for create estimation.
  /// Used to specify the error message thrown when [createEstimation] is attempted
  String? createEstimationErrorMessage;

  /// Used to specify the type of exception thrown when [createEstimation] is attempted
  SupabaseExceptionType? createEstimationExceptionType;

  /// Used to specify the error code thrown during [getEstimations]
  PostgresErrorCode? postgrestErrorCode;

  /// Controls whether [getEstimations] returns an empty list
  bool shouldReturnEmptyList = false;

  /// Controls whether operations should be delayed
  bool shouldDelayOperations = false;

  /// Controls when a delayed future is completed
  Completer? completer;

  /// Clock dependency for time operations
  final Clock clock;

  /// Constructor for fake cost estimation repository
  FakeCostEstimationRepository({required this.clock});

  @override
  Future<List<CostEstimate>> getEstimations(String projectId) async {
    if (shouldDelayOperations) {
      await completer?.future;
    }

    _methodCalls.add({
      'method': 'getEstimations',
      'projectId': projectId,
    });

    if (shouldThrowOnGetEstimations) {
      _throwConfiguredException(
        getEstimationsExceptionType,
        getEstimationsErrorMessage ?? 'Get estimations failed',
      );
    }

    if (shouldReturnEmptyList) {
      return [];
    }

    return _projectEstimations[projectId] ?? [];
  }

  @override
  Future<CostEstimate> createEstimation(CostEstimate estimation) async {
    if (shouldDelayOperations) {
      await completer?.future;
    }

    _methodCalls.add({
      'method': 'createEstimation',
      'estimation': {
        'id': estimation.id,
        'projectId': estimation.projectId,
        'estimateName': estimation.estimateName,
        'estimateDescription': estimation.estimateDescription,
        'creatorUserId': estimation.creatorUserId,
        'totalCost': estimation.totalCost,
        'isLocked': estimation.lockStatus.isLocked,
        'lockedByUserID': estimation.lockStatus.isLocked ? (estimation.lockStatus as LockedStatus).lockedByUserId : null,
        'createdAt': estimation.createdAt.toIso8601String(),
        'updatedAt': estimation.updatedAt.toIso8601String(),
      },
    });

    if (shouldThrowOnCreateEstimation) {
      _throwConfiguredException(
        createEstimationExceptionType,
        createEstimationErrorMessage ?? 'Create estimation failed',
      );
    }

    // Add the estimation to the project's estimations
    final projectId = estimation.projectId;
    final estimations = _projectEstimations[projectId] ?? [];
    estimations.add(estimation);
    _projectEstimations[projectId] = estimations;

    return estimation;
  }

  void _throwConfiguredException(
    SupabaseExceptionType? exceptionType,
    String message,
  ) {
    switch (exceptionType) {
      case SupabaseExceptionType.timeout:
        throw TimeoutException(message);
      case SupabaseExceptionType.type:
        throw TypeError();
      default:
        throw ServerException(Trace.current(), Exception(message));
    }
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

  /// Resets all fake configurations, clears data
  void reset() {
    shouldThrowOnGetEstimations = false;
    getEstimationsErrorMessage = null;
    getEstimationsExceptionType = null;
    shouldThrowOnCreateEstimation = false;
    createEstimationErrorMessage = null;
    createEstimationExceptionType = null;
    postgrestErrorCode = null;
    shouldReturnEmptyList = false;
    shouldDelayOperations = false;
    completer = null;

    clearAllData();
    clearMethodCalls();
  }

  /// Creates a sample CostEstimate for testing
  static const String _defaultEstimationIdPrefix = 'test-estimation-';
  static const String _defaultProjectId = 'test-project-123';
  static const String _defaultEstimateName = 'Test Estimation';
  static const String _defaultEstimateDescription = 'Test estimation description';
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
    
    // Create markup configuration
    final markupConfig = MarkupConfiguration(
      overallType: markupType ?? MarkupType.overall,
      overallValue: const MarkupValue(
        type: MarkupValueType.percentage,
        value: _defaultOverallMarkupValue,
      ),
      materialValueType: markupType == MarkupType.granular ? MarkupType.granular : null,
      materialValue: markupType == MarkupType.granular 
          ? const MarkupValue(type: MarkupValueType.percentage, value: _defaultMaterialMarkupValue)
          : null,
      laborValueType: markupType == MarkupType.granular ? MarkupType.granular : null,
      laborValue: markupType == MarkupType.granular 
          ? const MarkupValue(type: MarkupValueType.percentage, value: _defaultLaborMarkupValue)
          : null,
      equipmentValueType: markupType == MarkupType.granular ? MarkupType.granular : null,
      equipmentValue: markupType == MarkupType.granular 
          ? const MarkupValue(type: MarkupValueType.percentage, value: _defaultEquipmentMarkupValue)
          : null,
    );

    // Create lock status
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
    
    // Create overall markup configuration
    final markupConfig = MarkupConfiguration(
      overallType: MarkupType.overall,
      overallValue: MarkupValue(
        type: MarkupValueType.percentage,
        value: overallMarkupValue ?? _defaultOverallMarkupValue,
      ),
    );

    // Create lock status
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
    
    // Create granular markup configuration
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

    // Create lock status
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
