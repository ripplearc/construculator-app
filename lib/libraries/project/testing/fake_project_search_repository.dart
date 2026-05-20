import 'dart:async';

import 'package:construculator/libraries/either/either.dart';
import 'package:construculator/libraries/errors/failures.dart';
import 'package:construculator/libraries/global_search/domain/search_error_type.dart';
import 'package:construculator/libraries/project/domain/entities/project_entity.dart';
import 'package:construculator/libraries/project/domain/repositories/project_search_repository.dart';
import 'package:construculator/libraries/supabase/data/supabase_types.dart';

/// Fake implementation of [ProjectSearchRepository] for testing.
class FakeProjectSearchRepository implements ProjectSearchRepository {
  /// Tracks method calls for assertions.
  final List<Map<String, dynamic>> _methodCalls = [];

  /// Projects returned by [searchProjects] on success.
  final List<Project> _searchResults = [];

  /// Controls whether [searchProjects] throws an exception.
  bool shouldThrowOnSearchProjects = false;

  /// Used to specify the type of exception thrown by [searchProjects].
  SupabaseExceptionType? searchProjectsExceptionType;

  /// Error message for [searchProjects] thrown exceptions.
  String? searchProjectsErrorMessage;

  /// Used to specify the Postgres error code thrown by [searchProjects].
  PostgresErrorCode? postgrestErrorCode;

  /// Controls whether operations should be delayed.
  bool shouldDelayOperations = false;

  /// Controls when a delayed future is completed.
  Completer? completer;

  /// Creates a [FakeProjectSearchRepository].
  FakeProjectSearchRepository();

  @override
  Future<Either<Failure, List<Project>>> searchProjects({
    required String userId,
    required String query,
    DateTime? filterByDate,
    String? filterByTag,
    String? filterByOwner,
  }) async {
    if (shouldDelayOperations) {
      await completer?.future;
    }

    _methodCalls.add({
      'method': 'searchProjects',
      'userId': userId,
      'query': query,
      'filterByDate': filterByDate,
      'filterByTag': filterByTag,
      'filterByOwner': filterByOwner,
    });

    if (query.trim().isEmpty || userId.trim().isEmpty) {
      return Right([]);
    }

    if (shouldThrowOnSearchProjects) {
      return Left(_failureForConfiguredException());
    }

    return Right(List<Project>.from(_searchResults));
  }

  Failure _failureForConfiguredException() {
    switch (searchProjectsExceptionType) {
      case SupabaseExceptionType.timeout:
        return SearchFailure(errorType: SearchErrorType.timeoutError);
      case SupabaseExceptionType.socket:
        return SearchFailure(errorType: SearchErrorType.connectionError);
      case SupabaseExceptionType.type:
        return SearchFailure(errorType: SearchErrorType.parsingError);
      case SupabaseExceptionType.postgrest:
        if (postgrestErrorCode == PostgresErrorCode.noDataFound) {
          return SearchFailure(errorType: SearchErrorType.notFoundError);
        }
        if (postgrestErrorCode == PostgresErrorCode.connectionFailure ||
            postgrestErrorCode == PostgresErrorCode.unableToConnect ||
            postgrestErrorCode == PostgresErrorCode.connectionDoesNotExist) {
          return SearchFailure(errorType: SearchErrorType.connectionError);
        }
        return SearchFailure(errorType: SearchErrorType.unexpectedDatabaseError);
      default:
        return UnexpectedFailure();
    }
  }

  /// Sets the projects returned by [searchProjects] on success.
  void setSearchResults(List<Project> projects) {
    _searchResults
      ..clear()
      ..addAll(projects);
  }

  /// Returns a list of all method calls.
  List<Map<String, dynamic>> getMethodCalls() => List.from(_methodCalls);

  /// Returns the last method call, or null if none recorded.
  Map<String, dynamic>? getLastMethodCall() =>
      _methodCalls.isEmpty ? null : _methodCalls.last;

  /// Returns all method calls for the given method name.
  List<Map<String, dynamic>> getMethodCallsFor(String methodName) {
    return _methodCalls.where((call) => call['method'] == methodName).toList();
  }

  /// Clears recorded method calls.
  void clearMethodCalls() {
    _methodCalls.clear();
  }

  /// Resets all fake configurations and clears data.
  void reset() {
    shouldThrowOnSearchProjects = false;
    searchProjectsExceptionType = null;
    searchProjectsErrorMessage = null;
    postgrestErrorCode = null;
    shouldDelayOperations = false;
    completer = null;
    _searchResults.clear();
    _methodCalls.clear();
  }
}
