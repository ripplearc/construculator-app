import 'package:construculator/libraries/tag/data/models/tag_dto.dart';

/// Interface that abstracts remote tag data operations.
abstract class TagDataSource {
  /// Returns all available tags ordered alphabetically by name.
  Future<List<TagDto>> getTags();
}
