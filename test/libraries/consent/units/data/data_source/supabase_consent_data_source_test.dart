import 'package:construculator/libraries/consent/data/data_source/supabase_consent_data_source.dart';
import 'package:construculator/libraries/consent/domain/types/consent_types.dart';
import 'package:construculator/libraries/supabase/data/supabase_types.dart';
import 'package:construculator/libraries/supabase/database_constants.dart';
import 'package:construculator/libraries/supabase/testing/fake_supabase_wrapper.dart';
import 'package:construculator/libraries/time/testing/fake_clock_impl.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

Map<String, dynamic> _versionRow({
  Object? id = 'version-1',
  Object? consentType = 'terms_and_privacy',
  Object? version = 1,
  Object? documentUrl = 'https://ripplearc.com/legal/terms-and-privacy',
  Object? publishedAt = '2026-08-14T00:00:00.000Z',
}) {
  return {
    DatabaseConstants.idColumn: id,
    DatabaseConstants.consentTypeColumn: consentType,
    DatabaseConstants.versionColumn: version,
    DatabaseConstants.documentUrlColumn: documentUrl,
    DatabaseConstants.publishedAtColumn: publishedAt,
  };
}

/// Matches the [FormatException] the DTO throws for a named column, so a test
/// cannot pass on a row that failed for some other field.
Matcher _unreadable(String column) =>
    isA<FormatException>().having((e) => e.message, 'message', contains(column));

void main() {
  group('SupabaseConsentDataSource', () {
    late FakeSupabaseWrapper supabaseWrapper;
    late SupabaseConsentDataSource dataSource;

    setUp(() {
      supabaseWrapper = FakeSupabaseWrapper(clock: FakeClockImpl());
      dataSource = SupabaseConsentDataSource(supabaseWrapper: supabaseWrapper);
    });

    tearDown(() {
      supabaseWrapper.reset();
    });

    test('fetchPublishedVersions maps rows to ConsentVersionDtos', () async {
      supabaseWrapper
          .addTableData(DatabaseConstants.currentConsentVersionsView, [
            _versionRow(),
            _versionRow(
              id: 'version-2',
              consentType: 'analytics',
              version: 3,
              documentUrl: 'https://ripplearc.com/legal/analytics',
            ),
          ]);

      final result = await dataSource.fetchPublishedVersions();

      expect(result, hasLength(2));
      expect(result.first.consentType, ConsentType.termsAndPrivacy);
      expect(result.first.version, 1);
      expect(result.last.consentType, ConsentType.analytics);
      expect(result.last.version, 3);
    });

    // The view resolves which version is in force; reading the base table
    // would return every version ever published and leave the caller picking
    // one. Pinning the queried name here catches a revert to the table.
    test('fetchPublishedVersions reads the current versions view', () async {
      supabaseWrapper.addTableData(
        DatabaseConstants.currentConsentVersionsView,
        [_versionRow()],
      );

      await dataSource.fetchPublishedVersions();

      final calls = supabaseWrapper.getMethodCallsFor('selectMatch');
      expect(calls, hasLength(1));
      expect(
        calls.first['table'],
        DatabaseConstants.currentConsentVersionsView,
      );
      expect(calls.first['filters'], isEmpty);
    });

    test(
      'fetchPublishedVersions returns empty when nothing is published',
      () async {
        supabaseWrapper.addTableData(
          DatabaseConstants.currentConsentVersionsView,
          const [],
        );

        final result = await dataSource.fetchPublishedVersions();

        expect(result, isEmpty);
      },
    );

    test('fetchPublishedVersions rethrows when the read fails', () async {
      supabaseWrapper.shouldThrowOnSelectMatch = true;
      supabaseWrapper.selectMatchExceptionType =
          SupabaseExceptionType.postgrest;

      await expectLater(
        () => dataSource.fetchPublishedVersions(),
        throwsA(isA<supabase.PostgrestException>()),
      );
    });

    // A blank document_url is a corrupt row of a type this build DOES gate
    // on, not an unrecognised type — dropping it would silently satisfy a
    // requirement the user never met, so it must propagate instead.
    test(
      'fetchPublishedVersions rethrows a row with a blank document url',
      () async {
        supabaseWrapper.addTableData(
          DatabaseConstants.currentConsentVersionsView,
          [_versionRow(documentUrl: '')],
        );

        await expectLater(
          () => dataSource.fetchPublishedVersions(),
          throwsA(isA<FormatException>()),
        );
      },
    );

    test('fetchPublishedVersions drops an unrecognised consent type', () async {
      // A type this build does not know means a newer server, not a corrupt
      // row -- so it must not take the valid row beside it down with it.
      supabaseWrapper.addTableData(
        DatabaseConstants.currentConsentVersionsView,
        [_versionRow(consentType: 'marketing_emails'), _versionRow()],
      );

      final versions = await dataSource.fetchPublishedVersions();

      expect(versions, hasLength(1));
      expect(versions.single.consentType, ConsentType.termsAndPrivacy);
    });

    // A null consent_type reaches the same "unrecognised" predicate as a
    // newer server's type would, but it is a corrupt row: dropping it hands
    // the caller a list that reads as "nothing required" for a requirement
    // the user never satisfied.
    test(
      'fetchPublishedVersions rethrows a row with a null consent type',
      () async {
        supabaseWrapper.addTableData(
          DatabaseConstants.currentConsentVersionsView,
          [_versionRow(consentType: null)],
        );

        await expectLater(
          () => dataSource.fetchPublishedVersions(),
          throwsA(_unreadable(DatabaseConstants.consentTypeColumn)),
        );
      },
    );

    test(
      'fetchPublishedVersions rethrows a row with a non-string consent type',
      () async {
        supabaseWrapper.addTableData(
          DatabaseConstants.currentConsentVersionsView,
          [_versionRow(consentType: 7)],
        );

        await expectLater(
          () => dataSource.fetchPublishedVersions(),
          throwsA(_unreadable(DatabaseConstants.consentTypeColumn)),
        );
      },
    );

    // An empty string is textually well-formed but names no document, so it
    // is a corrupt row rather than a newer server's type.
    test(
      'fetchPublishedVersions rethrows a row with an empty consent type',
      () async {
        supabaseWrapper.addTableData(
          DatabaseConstants.currentConsentVersionsView,
          [_versionRow(consentType: '')],
        );

        await expectLater(
          () => dataSource.fetchPublishedVersions(),
          throwsA(_unreadable(DatabaseConstants.consentTypeColumn)),
        );
      },
    );

    test(
      'fetchPublishedVersions rethrows on a corrupt row of a known type',
      () async {
        // Zero would compare as satisfied against every acceptance on file —
        // this must propagate, not vanish as if nothing were published.
        supabaseWrapper.addTableData(
          DatabaseConstants.currentConsentVersionsView,
          [_versionRow(version: 0)],
        );

        await expectLater(
          () => dataSource.fetchPublishedVersions(),
          throwsA(isA<FormatException>()),
        );
      },
    );
  });
}
