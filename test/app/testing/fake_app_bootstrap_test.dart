import 'package:construculator/app/app_bootstrap.dart';
import 'package:construculator/app/testing/fake_app_bootstrap.dart';
import 'package:construculator/libraries/config/interfaces/config.dart';
import 'package:construculator/libraries/config/interfaces/env_loader.dart';
import 'package:construculator/libraries/config/testing/fake_app_config.dart';
import 'package:construculator/libraries/config/testing/fake_env_loader.dart';
import 'package:construculator/libraries/supabase/interfaces/supabase_wrapper.dart';
import 'package:construculator/libraries/supabase/testing/fake_supabase_wrapper.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late FakeAppBootstrap fakeBootstrap;

  setUp(() {
    fakeBootstrap = FakeAppBootstrap();
  });

  group('FakeAppBootstrap', () {
    test('implements AppBootstrap interface', () {
      expect(fakeBootstrap, isA<AppBootstrap>());
    });

    group('envLoader', () {
      test('returns a FakeEnvLoader instance', () {
        final envLoader = fakeBootstrap.envLoader;

        expect(envLoader, isA<FakeEnvLoader>());
        expect(envLoader, isA<EnvLoader>());
      });

      test('returns a new instance on each call', () {
        final envLoader1 = fakeBootstrap.envLoader;
        final envLoader2 = fakeBootstrap.envLoader;

        expect(envLoader1, isNot(same(envLoader2)));
      });
    });

    group('config', () {
      test('returns a FakeAppConfig instance', () {
        final config = fakeBootstrap.config;

        expect(config, isA<FakeAppConfig>());
        expect(config, isA<Config>());
      });

      test('returns a new instance on each call', () {
        final config1 = fakeBootstrap.config;
        final config2 = fakeBootstrap.config;

        expect(config1, isNot(same(config2)));
      });
    });

    group('supabaseWrapper', () {
      test('returns a FakeSupabaseWrapper instance', () {
        final supabaseWrapper = fakeBootstrap.supabaseWrapper;

        expect(supabaseWrapper, isA<FakeSupabaseWrapper>());
        expect(supabaseWrapper, isA<SupabaseWrapper>());
      });

      test('returns a new instance on each call', () {
        final supabaseWrapper1 = fakeBootstrap.supabaseWrapper;
        final supabaseWrapper2 = fakeBootstrap.supabaseWrapper;

        expect(supabaseWrapper1, isNot(same(supabaseWrapper2)));
      });
    });

    group('integration', () {
      test('all getters return valid, functional fake implementations', () {
        final envLoader = fakeBootstrap.envLoader;
        final config = fakeBootstrap.config;
        final supabaseWrapper = fakeBootstrap.supabaseWrapper;

        expect(envLoader, isNotNull);
        expect(config, isNotNull);
        expect(supabaseWrapper, isNotNull);
        expect(envLoader, isA<EnvLoader>());
        expect(config, isA<Config>());
        expect(supabaseWrapper, isA<SupabaseWrapper>());
      });
    });
  });
}
