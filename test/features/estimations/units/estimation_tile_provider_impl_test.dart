// ignore_for_file: no_direct_instantiation

import 'package:construculator/features/estimation/data/estimation_tile_provider_impl.dart';
import 'package:construculator/features/estimation/presentation/widgets/shared_estimation_tile.dart';
import 'package:construculator/libraries/estimation/domain/estimation_tile_data.dart';
import 'package:construculator/libraries/estimation/domain/estimation_tile_provider.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('EstimationTileProviderImpl', () {
    setUpAll(() {
      Modular.init(_TestAppModule());
    });

    tearDownAll(() {
      Modular.destroy();
    });

    test('buildEstimationTile returns a SharedEstimationTile with the supplied data and callbacks', () {
      final provider = Modular.get<EstimationTileProvider>();
      final data = _FakeData();
      void onTap() {}
      void onMenuTap() {}

      final widget = provider.buildEstimationTile(
        data: data,
        onTap: onTap,
        onMenuTap: onMenuTap,
      );

      expect(widget, isA<SharedEstimationTile>());
      final tile = widget as SharedEstimationTile;
      expect(tile.data, same(data));
      expect(tile.onTap, same(onTap));
      expect(tile.onMenuTap, same(onMenuTap));
    });

    test('buildEstimationTile passes through a null onMenuTap', () {
      final provider = Modular.get<EstimationTileProvider>();

      final widget = provider.buildEstimationTile(
        data: _FakeData(),
        onTap: () {},
      );

      expect(widget, isA<SharedEstimationTile>());
      expect((widget as SharedEstimationTile).onMenuTap, isNull);
    });
  });
}

class _TestAppModule extends Module {
  @override
  void binds(Injector i) {
    i.addLazySingleton<EstimationTileProvider>(
      () => const EstimationTileProviderImpl(),
    );
  }
}

class _FakeData implements EstimationTileData {
  @override
  String get estimateName => 'Fake';

  @override
  double? get totalCost => 100.0;

  @override
  DateTime get displayDate => DateTime(2024, 1, 1);
}
