import 'package:construculator/libraries/logging/app_logger.dart';
import 'package:construculator/libraries/supabase/database_constants.dart';
import 'package:construculator/libraries/supabase/interfaces/supabase_wrapper.dart';
import 'package:construculator/libraries/tag/data/data_source/interfaces/tag_data_source.dart';
import 'package:construculator/libraries/tag/data/models/tag_dto.dart';

/// Supabase-backed implementation of [TagDataSource].
class RemoteTagDataSource implements TagDataSource {
  final SupabaseWrapper _supabaseWrapper;
  static final _logger = AppLogger().tag('RemoteTagDataSource');

  /// Creates a [RemoteTagDataSource].
  const RemoteTagDataSource({required SupabaseWrapper supabaseWrapper})
    : _supabaseWrapper = supabaseWrapper;

  @override
  Future<List<TagDto>> getTags() async {
    try {
      _logger.debug('Fetching all tags');

      final rows = await _supabaseWrapper.selectMatch(
        table: DatabaseConstants.tagsTable,
        filters: const {},
        orderBy: DatabaseConstants.nameColumn,
      );

      return rows.map(TagDto.fromJson).toList();
    } catch (error, stackTrace) {
      _logger.error('Error while fetching tags', error, stackTrace);
      rethrow;
    }
  }
}
