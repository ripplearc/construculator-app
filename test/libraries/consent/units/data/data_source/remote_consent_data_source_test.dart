import 'package:construculator/libraries/consent/data/data_source/remote_consent_data_source.dart';
import 'package:construculator/libraries/consent/domain/types/consent_types.dart';
import 'package:construculator/libraries/supabase/data/supabase_types.dart';
import 'package:construculator/libraries/supabase/database_constants.dart';
import 'package:construculator/libraries/supabase/testing/fake_supabase_wrapper.dart';
import 'package:construculator/libraries/time/testing/fake_clock_impl.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

Map<String, dynamic> _versionRow({
  String id = 'version-1',
  String consentType = 'terms_and_privacy',
  int version = 1,
  String documentUrl = 'https://ripplearc.com/legal/terms-and-privacy',
  String publishedAt = '2026-08-14T00:00:00.000Z',
}) {
  return {
    DatabaseConstants.idColumn: id,
    DatabaseConstants.consentTypeColumn: consentType,
    DatabaseConstants.versionColumn: version,
    DatabaseConstants.documentUrlColumn: documentUrl,
    DatabaseConstants.publishedAtColumn: publishedAt,
  };
}

void main() {
  group('RemoteConsentDataSourceImpl', () {
    late FakeSupabaseWrapper supabaseWrapper;
    late RemoteConsentDataSourceImpl dataSource;

    setUp(() {
      supabaseWrapper = FakeSupabaseWrapper(clock: FakeClockImpl());
      dataSource = RemoteConsentDataSourceImpl(
        supabaseWrapper: supabaseWrapper,
      );
    });

    tearDown(() {
      supabaseWrapper.reset();
    });

    test('fetchPublishedVersions maps rows to ConsentVersionDtos', () async {
      supabaseWrapper.addTableData(
        DatabaseConstants.currentConsentVersionsView,
        [
          _versionRow(),
          _versionRow(
            id: 'version-2',
            consentType: 'analytics',
            version: 3,
            documentUrl: 'https://ripplearc.com/legal/analytics',
          ),
        ],
      );

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

    test('fetchPublishedVersions returns empty when nothing is published',
        () async {
      supabaseWrapper.addTableData(
        DatabaseConstants.currentConsentVersionsView,
        const [],
      );

      final result = await dataSource.fetchPublishedVersions();

      expect(result, isEmpty);
    });

    test('fetchPublishedVersions rethrows when the read fails', () async {
      supabaseWrapper.shouldThrowOnSelectMatch = true;
      supabaseWrapper.selectMatchExceptionType =
          SupabaseExceptionType.postgrest;

      await expectLater(
        () => dataSource.fetchPublishedVersions(),
        throwsA(isA<supabase.PostgrestException>()),
      );
    });

    // A blank document_url would leave the consent page with nothing to
    // present, so the DTO refuses the row rather than defaulting it. The
    // backend rejects it on write too; this covers the client half.
    test('fetchPublishedVersions drops a row with a blank document url',
        () async {
      supabaseWrapper.addTableData(
        DatabaseConstants.currentConsentVersionsView,
        [_versionRow(documentUrl: '')],
      );

      expect(await dataSource.fetchPublishedVersions(), isEmpty);
    });

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

    test('fetchPublishedVersions drops a row with a zero version', () async {
      // Zero would compare as satisfied against every acceptance on file.
      supabaseWrapper.addTableData(
        DatabaseConstants.currentConsentVersionsView,
        [_versionRow(version: 0), _versionRow(id: 'version-2')],
      );

      final versions = await dataSource.fetchPublishedVersions();

      expect(versions.single.id, 'version-2');
    });
  });
}
