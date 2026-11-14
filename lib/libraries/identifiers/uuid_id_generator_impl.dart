// coverage:ignore-file
import 'package:construculator/libraries/identifiers/interfaces/id_generator.dart';
import 'package:powersync/powersync.dart' show uuid;

/// [IdGenerator] that returns random version 4 UUIDs.
class UuidIdGeneratorImpl implements IdGenerator {
  @override
  String newId() => uuid.v4();
}
