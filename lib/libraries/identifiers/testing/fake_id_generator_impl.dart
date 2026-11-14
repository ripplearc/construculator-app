import 'package:construculator/libraries/identifiers/interfaces/id_generator.dart';

/// [IdGenerator] for tests that returns the same ids in the same order on
/// every run: `00000000-0000-4000-8000-000000000001`, then `...0002`, and so
/// on.
class FakeIdGeneratorImpl implements IdGenerator {
  int _issued = 0;

  @override
  String newId() {
    _issued++;
    return '00000000-0000-4000-8000-${_issued.toString().padLeft(12, '0')}';
  }

  /// The id [newId] returned for the [position]th call, counting from 1.
  static String idAt(int position) =>
      '00000000-0000-4000-8000-${position.toString().padLeft(12, '0')}';
}
