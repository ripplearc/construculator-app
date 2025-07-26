// coverage:ignore-file
import 'package:equatable/equatable.dart';

/// This is the domain entity for a professional role with a unique identifier and name.
class ProfessionalRole extends Equatable {
  /// The unique identifier for the professional role.
  final String id;

  /// The name of the professional role.
  final String name;

  const ProfessionalRole({required this.id, required this.name});

  @override
  List<Object?> get props => [id, name];
} 