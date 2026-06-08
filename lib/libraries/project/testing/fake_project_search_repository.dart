import 'dart:async';

import 'package:construculator/libraries/either/either.dart';
import 'package:construculator/libraries/errors/failures.dart';
import 'package:construculator/libraries/global_search/domain/search_error_type.dart';
import 'package:construculator/libraries/project/domain/entities/project_entity.dart';
import 'package:construculator/libraries/project/domain/repositories/project_search_repository.dart';
import 'package:construculator/libraries/supabase/data/supabase_types.dart';

/// Fake implementation of [ProjectSearchRepository] for testing.
class FakeProjectSearchRepository implements ProjectSearchRepository {
  final List<Map<String, dynamic>> _methodCalls = [];

  final List<Project> _searchResults = [];

  /// Recent search terms returned by [getRecentProjectSearches] on success.
  final List<String> _recentSearches = [];

  /// Suggestion terms returned by [getProjectSearchSuggestions] on success.
  final List<String> _suggestions = [];

  /// Controls whether [searchProjects] throws an exception.
  bool shouldThrowOnSearchProjects = false;

  /// Used to specify the type of exception thrown by [searchProjects].
  SupabaseExceptionType? searchProjectsExceptionType;

  /// Controls whether [saveRecentProjectSearch] throws an exception.
  bool shouldThrowOnSaveRecent = false;

  /// Used to specify the type of exception thrown by
  /// [saveRecentProjectSearch].
  SupabaseExceptionType? saveRecentExceptionType;

  /// Controls whether [getRecentProjectSearches] throws an exception.
  bool shouldThrowOnGetRecent = false;

  /// Used to specify the type of exception thrown by
  /// [getRecentProjectSearches].
  SupabaseExceptionType? getRecentExceptionType;

  /// Controls whether [deleteRecentProjectSearch] throws an exception.
  bool shouldThrowOnDeleteRecent = false;

  /// Used to specify the type of exception thrown by
  /// [deleteRecentProjectSearch].
  SupabaseExceptionType? deleteRecentExceptionType;

  /// Controls whether [getProjectSearchSuggestions] throws an exception.
  bool shouldThrowOnGetSuggestions = false;

  /// Used to specify the type of exception thrown by
  /// [getProjectSearchSuggestions].
  SupabaseExceptionType? getSuggestionsExceptionType;

  /// Used to specify the Postgres error code shared across all configured
  /// PostgrestException paths.
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
      return Left(_failureForConfiguredException(searchProjectsExceptionType));
    }

    return Right(List<Project>.from(_searchResults));
  }

  @override
  Future<Either<Failure, void>> saveRecentProjectSearch({
    required String userId,
    required String searchTerm,
    bool hasResults = false,
  }) async {
    if (shouldDelayOperations) {
      await completer?.future;
    }

    _methodCalls.add({
      'method': 'saveRecentProjectSearch',
      'userId': userId,
      'searchTerm': searchTerm,
      'hasResults': hasResults,
    });

    if (userId.trim().isEmpty || searchTerm.trim().isEmpty) {
      return Right(null);
    }

    if (shouldThrowOnSaveRecent) {
      return Left(_failureForConfiguredException(saveRecentExceptionType));
    }

    return Right(null);
  }

  @override
  Future<Either<Failure, List<String>>> getRecentProjectSearches({
    required String userId,
  }) async {
    if (shouldDelayOperations) {
      await completer?.future;
    }

    _methodCalls.add({
      'method': 'getRecentProjectSearches',
      'userId': userId,
    });

    if (userId.trim().isEmpty) {
      return Right([]);
    }

    if (shouldThrowOnGetRecent) {
      return Left(_failureForConfiguredException(getRecentExceptionType));
    }

    return Right(List<String>.from(_recentSearches));
  }

  @override
  Future<Either<Failure, void>> deleteRecentProjectSearch({
    required String userId,
    required String searchTerm,
  }) async {
    if (shouldDelayOperations) {
      await completer?.future;
    }

    _methodCalls.add({
      'method': 'deleteRecentProjectSearch',
      'userId': userId,
      'searchTerm': searchTerm,
    });

    if (userId.trim().isEmpty || searchTerm.trim().isEmpty) {
      return Right(null);
    }

    if (shouldThrowOnDeleteRecent) {
      return Left(_failureForConfiguredException(deleteRecentExceptionType));
    }

    return Right(null);
  }

  @override
  Future<Either<Failure, List<String>>> getProjectSearchSuggestions({
    required String userId,
  }) async {
    if (shouldDelayOperations) {
      await completer?.future;
    }

    _methodCalls.add({
      'method': 'getProjectSearchSuggestions',
      'userId': userId,
    });

    if (userId.trim().isEmpty) {
      return Right([]);
    }

    if (shouldThrowOnGetSuggestions) {
      return Left(_failureForConfiguredException(getSuggestionsExceptionType));
    }

    return Right(List<String>.from(_suggestions));
  }

  Failure _failureForConfiguredException(SupabaseExceptionType? type) {
    switch (type) {
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

  /// Sets the terms returned by [getRecentProjectSearches] on success.
  void setRecentSearches(List<String> terms) {
    _recentSearches
      ..clear()
      ..addAll(terms);
  }

  /// Sets the terms returned by [getProjectSearchSuggestions] on success.
  void setSuggestions(List<String> terms) {
    _suggestions
      ..clear()
      ..addAll(terms);
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
    shouldThrowOnSaveRecent = false;
    saveRecentExceptionType = null;
    shouldThrowOnGetRecent = false;
    getRecentExceptionType = null;
    shouldThrowOnDeleteRecent = false;
    deleteRecentExceptionType = null;
    shouldThrowOnGetSuggestions = false;
    getSuggestionsExceptionType = null;
    postgrestErrorCode = null;
    shouldDelayOperations = false;
    completer = null;
    _searchResults.clear();
    _recentSearches.clear();
    _suggestions.clear();
    _methodCalls.clear();
  }
}
