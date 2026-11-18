import 'package:construculator/libraries/identifiers/interfaces/id_generator.dart';
import 'package:construculator/libraries/identifiers/uuid_id_generator_impl.dart';
import 'package:flutter_modular/flutter_modular.dart';

/// Provides the [IdGenerator] that creates the ids of new rows.
class IdentifiersModule extends Module {
  @override
  void exportedBinds(Injector i) {
    i.add<IdGenerator>(() => UuidIdGeneratorImpl());
  }
}
