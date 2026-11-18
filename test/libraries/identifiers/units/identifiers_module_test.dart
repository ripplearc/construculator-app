import 'package:construculator/libraries/identifiers/identifiers_module.dart';
import 'package:construculator/libraries/identifiers/interfaces/id_generator.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_test/flutter_test.dart';

class _ConsumerModule extends Module {
  @override
  List<Module> get imports => [IdentifiersModule()];
}

void main() {
  late IdGenerator generator;

  setUp(() {
    Modular.init(_ConsumerModule());
    addTearDown(Modular.destroy);
    generator = Modular.get<IdGenerator>();
  });

  group('IdentifiersModule', () {
    test('provides version 4 UUIDs', () {
      expect(
        generator.newId(),
        matches(
          RegExp(
            r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
          ),
        ),
      );
    });

    test('provides a different id on every call', () {
      expect(generator.newId(), isNot(generator.newId()));
    });
  });
}
