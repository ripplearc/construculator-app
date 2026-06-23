import 'package:construculator/libraries/supabase/database_constants.dart';
import 'package:construculator/libraries/tag/data/models/tag_dto.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TagDto', () {
    test('fromJson maps id and name columns', () {
      final dto = TagDto.fromJson({
        DatabaseConstants.idColumn: 'tag-1',
        DatabaseConstants.nameColumn: 'Roofing',
      });

      expect(dto.id, 'tag-1');
      expect(dto.name, 'Roofing');
    });

    test('toDomain maps to a Tag entity', () {
      const dto = TagDto(id: 'tag-1', name: 'Roofing');

      final tag = dto.toDomain();

      expect(tag.id, 'tag-1');
      expect(tag.name, 'Roofing');
    });

    test('equality is based on id and name', () {
      const a = TagDto(id: 'tag-1', name: 'Roofing');
      const b = TagDto(id: 'tag-1', name: 'Roofing');
      const c = TagDto(id: 'tag-2', name: 'Roofing');

      expect(a, b);
      expect(a == c, isFalse);
    });
  });
}
