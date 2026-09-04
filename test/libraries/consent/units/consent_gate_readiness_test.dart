import 'package:construculator/libraries/config/env_constants.dart';
import 'package:construculator/libraries/config/testing/fake_env_loader.dart';
import 'package:construculator/libraries/consent/consent_gate_readiness.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  FakeEnvLoader envWith(String? flag) {
    final envLoader = FakeEnvLoader();
    if (flag != null) envLoader.setEnvVar(consentGateEnabledKey, flag);
    return envLoader;
  }

  group('consentPersistenceReady', () {
    // A canary, not a tautology: these three lines fail the build the moment
    // someone flips a readiness const without the work behind it, which is
    // the whole point of the block. CA-971 deletes this group in the same
    // PR that lands the durable store and the remote write path.
    test('is false, and so is each half it is built from', () {
      expect(
        durableLocalConsentStoreLanded,
        isFalse,
        reason: 'InMemoryLocalConsentDataSource is still the bound '
            'implementation -- see ConsentLibraryModule.',
      );
      expect(
        remoteConsentWritePathLanded,
        isFalse,
        reason: 'RemoteConsentDataSource still exposes only '
            'fetchPublishedVersions() -- there is no write to route to.',
      );
      expect(consentPersistenceReady, isFalse);
    });
  });

  group('consentGateEnabled', () {
    test('is false with the flag on, at the production default', () {
      // The finding this whole file exists for: a flag flip -- by a config
      // mistake, a future PR, or someone who skipped the doc comment --
      // must not be able to mount a gate that records nothing durable.
      expect(consentGateEnabled(envWith('true')), isFalse);
    });

    test('is true with the flag on once persistence is ready', () {
      expect(
        consentGateEnabled(envWith('true'), persistenceReady: true),
        isTrue,
      );
    });

    test('is false for every non-"true" flag value, ready or not', () {
      // Unset is the shipped default; 'false' is what .env.template carries;
      // 'TRUE' proves the comparison is not case-insensitive by accident.
      // Paired with the label the failure message needs, rather than deriving
      // one from a nullable at the call site: the custom linter forbids `??`
      // in tests and the analyzer forbids the `?:` that replaces it.
      const flagCases = <(String?, String)>[
        (null, '<unset>'),
        ('false', 'false'),
        ('TRUE', 'TRUE'),
        ('1', '1'),
        ('', '<empty>'),
      ];
      for (final (flag, label) in flagCases) {
        expect(
          consentGateEnabled(envWith(flag), persistenceReady: true),
          isFalse,
          reason: 'flag $label must not enable the gate',
        );
        expect(consentGateEnabled(envWith(flag)), isFalse);
      }
    });
  });
}
