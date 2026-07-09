import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

/// Represents a cost-related file attached to a project.
@immutable
class CostFile extends Equatable {
  /// Unique identifier for the file.
  final String id;

  /// Display name of the file including extension.
  final String fileName;

  /// Raw file size in bytes; use [DisplayFormatter.formatFileSize] for display.
  final int fileSizeInBytes;

  /// When the file was uploaded.
  final DateTime uploadedAt;

  const CostFile({
    required this.id,
    required this.fileName,
    required this.fileSizeInBytes,
    required this.uploadedAt,
  });

  @override
  List<Object?> get props => [id, fileName, fileSizeInBytes, uploadedAt];
}
