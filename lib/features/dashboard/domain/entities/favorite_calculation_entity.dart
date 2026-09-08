import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

/// Display model for a favorited calculation shown on the dashboard.
@immutable
class FavoriteCalculation extends Equatable {
  final String id;
  final DateTime date;
  final List<String> tags;

  const FavoriteCalculation({
    required this.id,
    required this.date,
    required this.tags,
  });

  @override
  List<Object?> get props => [id, date, tags];
}
