import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

/// Display model for a favorited cost estimation shown on the dashboard.
@immutable
class FavoriteEstimation extends Equatable {
  final String id;
  final String title;
  final DateTime date;
  final double totalCost;

  const FavoriteEstimation({
    required this.id,
    required this.title,
    required this.date,
    required this.totalCost,
  });

  @override
  List<Object?> get props => [id, title, date, totalCost];
}
