import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

@immutable
class CostFile extends Equatable {
  final String id;
  final String fileName;
  final int fileSizeInBytes;
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
