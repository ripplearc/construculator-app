import 'dart:async';
import 'dart:io';

import 'package:construculator/features/estimation/data/data_source/interfaces/cost_estimation_data_source.dart';
import 'package:construculator/features/estimation/data/models/cost_estimate_dto.dart';
import 'package:construculator/libraries/errors/exceptions.dart';
import 'package:construculator/libraries/supabase/data/supabase_types.dart';
import 'package:construculator/libraries/time/interfaces/clock.dart';
import 'package:stack_trace/stack_trace.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

/// A fake implementation of [CostEstimationDataSource] for testing purposes.
///
/// This class allows you to control and inspect the behavior of cost estimation
/// data source operations in tests. You can configure it to simulate errors,
/// delays, and return specific data for assertions.
class FakeCostEstimationDataSource implements CostEstimationDataSource {
  /// Tracks method calls for assertions
  final List<Map<String, dynamic>> _methodCalls = [];

  /// Tracks cost estimation data for assertions during [getEstimations]
  final Map<String, List<CostEstimateDto>> _projectEstimations = {};

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

  /// Controls whether [deleteEstimation] throws an exception
  bool shouldThrowOnDeleteEstimation = false;

  /// Error message for delete estimation.
  /// Used to specify the error message thrown when [deleteEstimation] is attempted
  String? deleteEstimationErrorMessage;

  /// Used to specify the type of exception thrown when [deleteEstimation] is attempted
  SupabaseExceptionType? deleteEstimationExceptionType;

  /// Used to specify the error code thrown during [getEstimations]
  PostgresErrorCode? postgrestErrorCode;

  /// Controls whether [getEstimations] returns an empty list
  bool shouldReturnEmptyList = false;

  /// Controls whether operations should wait for a completer
  bool shouldDelayOperations = false;

  /// Completer to control operation timing in tests
  Completer<void>? completer;

  /// Clock dependency for time operations
  final Clock clock;

  /// Constructor for fake cost estimation data source
  FakeCostEstimationDataSource({required this.clock});

  @override
  Future<List<CostEstimateDto>> getEstimations(String projectId) async {
    _methodCalls.add({'method': 'getEstimations', 'projectId': projectId});

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
  Future<CostEstimateDto> createEstimation(CostEstimateDto estimation) async {
    if (shouldDelayOperations) {
      await completer?.future;
    }

    _methodCalls.add({
      'method': 'createEstimation',
      'estimation': estimation.toJson(),
    });

    if (shouldThrowOnCreateEstimation) {
      _throwConfiguredException(
        createEstimationExceptionType,
        createEstimationErrorMessage ?? 'Create estimation failed',
      );
    }

    final projectId = estimation.projectId;
    final estimations = _projectEstimations[projectId] ?? [];
    estimations.add(estimation);
    _projectEstimations[projectId] = estimations;

    return estimation;
  }

  @override
  Future<CostEstimateDto> deleteEstimation(String estimationId) async {
    if (shouldDelayOperations) {
      await completer?.future;
    }

    _methodCalls.add({
      'method': 'deleteEstimation',
      'estimationId': estimationId,
    });

    if (shouldThrowOnDeleteEstimation) {
      _throwConfiguredException(
        deleteEstimationExceptionType,
        deleteEstimationErrorMessage ?? 'Delete estimation failed',
      );
    }

    CostEstimateDto? deletedEstimation;
    for (final projectId in _projectEstimations.keys) {
      final estimations = _projectEstimations[projectId] ?? [];
      for (final estimation in estimations) {
        if (estimation.id == estimationId) {
          deletedEstimation = estimation;
          break;
        }
      }

      if (deletedEstimation != null) {
        estimations.removeWhere((estimation) => estimation.id == estimationId);
        _projectEstimations[projectId] = estimations;
        break;
      }
    }

    if (deletedEstimation == null) {
      throw ServerException(
        Trace.current(),
        Exception('Estimation not found for deletion'),
      );
    }

    return deletedEstimation;
  }

  void _throwConfiguredException(
    SupabaseExceptionType? exceptionType,
    String message,
  ) {
    switch (exceptionType) {
      case SupabaseExceptionType.timeout:
        throw TimeoutException(message);
      case SupabaseExceptionType.socket:
        throw SocketException(message);
      case SupabaseExceptionType.postgrest:
        throw supabase.PostgrestException(
          code: postgrestErrorCode?.toString() ?? 'unknown',
          message: message,
        );
      case SupabaseExceptionType.type:
        throw FormatException();
      default:
        throw ServerException(Trace.current(), Exception(message));
    }
  }

  /// Adds cost estimation data for a specific project
  void addProjectEstimations(
    String projectId,
    List<CostEstimateDto> estimations,
  ) {
    _projectEstimations[projectId] = estimations;
  }

  /// Adds a single cost estimation for a specific project
  void addProjectEstimation(String projectId, CostEstimateDto estimation) {
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
    shouldThrowOnDeleteEstimation = false;
    deleteEstimationErrorMessage = null;
    deleteEstimationExceptionType = null;
    postgrestErrorCode = null;
    shouldReturnEmptyList = false;
    shouldDelayOperations = false;
    completer = null;

    clearAllData();
    clearMethodCalls();
  }

  /// Creates a sample CostEstimateDto for testing
  static const String _defaultEstimationIdPrefix = 'test-estimation-';
  static const String _defaultProjectId = 'test-project-123';
  static const String _defaultEstimateName = 'Test Estimation';
  static const String _defaultEstimateDescription =
      'Test estimation description';
  static const String _defaultCreatorUserId = 'test-user-123';
  static const String _defaultMarkupType = 'overall';
  static const String _defaultMarkupValueType = 'percentage';
  static const double _defaultOverallMarkupValue = 15.0;
  static const double _defaultMaterialMarkupValue = 10.0;
  static const double _defaultLaborMarkupValue = 20.0;
  static const double _defaultEquipmentMarkupValue = 12.0;
  static const double _defaultTotalCost = 50000.0;
  static const bool _defaultIsLocked = false;

  /// Creates a sample CostEstimateDto for testing
  CostEstimateDto createSampleEstimation({
    String? id,
    String? projectId,
    String? estimateName,
    String? estimateDescription,
    String? creatorUserId,
    double? totalCost,
    bool? isLocked,
    String? lockedByUserID,
    DateTime? lockedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    final now = clock.now();
    final locked = isLocked ?? _defaultIsLocked;
    return CostEstimateDto(
      id: id ?? '$_defaultEstimationIdPrefix${now.millisecondsSinceEpoch}',
      projectId: projectId ?? _defaultProjectId,
      estimateName: estimateName ?? _defaultEstimateName,
      estimateDescription: estimateDescription ?? _defaultEstimateDescription,
      creatorUserId: creatorUserId ?? _defaultCreatorUserId,
      markupType: _defaultMarkupType,
      overallMarkupValueType: _defaultMarkupValueType,
      overallMarkupValue: _defaultOverallMarkupValue,
      materialMarkupValueType: _defaultMarkupValueType,
      materialMarkupValue: _defaultMaterialMarkupValue,
      laborMarkupValueType: _defaultMarkupValueType,
      laborMarkupValue: _defaultLaborMarkupValue,
      equipmentMarkupValueType: _defaultMarkupValueType,
      equipmentMarkupValue: _defaultEquipmentMarkupValue,
      totalCost: totalCost ?? _defaultTotalCost,
      isLocked: locked,
      lockedByUserID: locked ? lockedByUserID : null,
      lockedAt: locked ? (lockedAt ?? now).toIso8601String() : null,
      createdAt: (createdAt ?? now).toIso8601String(),
      updatedAt: (updatedAt ?? now).toIso8601String(),
    );
  }
}
