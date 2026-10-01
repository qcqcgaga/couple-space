import 'package:couple_space/core/models/note.dart';
import 'package:couple_space/core/sync/lww.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const resolver = LwwResolver();

  Note note({
    String id = 'n1',
    String? title,
    String content = 'hello',
    TimeBind timeBind = TimeBind.none,
    DateTime? startAt,
    bool deleted = false,
    String? deletedBy,
    Map<String, FieldVersion>? versions,
  }) {
    return Note(
      id: id,
      title: title,
      content: content,
      timeBind: timeBind,
      startAt: startAt,
      deleted: deleted,
      deletedBy: deletedBy,
      fieldVersions: versions,
    );
  }

  group('LwwResolver', () {
    test('时间戳较新的一方在同一字段胜出', () {
      final local = note(
        title: '旧标题',
        versions: {'title': const FieldVersion(100, 'deviceA')},
      );
      final remote = note(
        title: '新标题',
        versions: {'title': const FieldVersion(200, 'deviceB')},
      );

      final merged = resolver.merge(local, remote);

      expect(merged.title, '新标题');
      expect(merged.fieldVersions['title'], const FieldVersion(200, 'deviceB'));
    });

    test('时间戳相同则设备 ID 大者胜，且与合并顺序无关', () {
      final a = note(
        title: 'A 的标题',
        versions: {'title': const FieldVersion(100, 'deviceA')},
      );
      final b = note(
        title: 'B 的标题',
        versions: {'title': const FieldVersion(100, 'deviceB')},
      );

      expect(resolver.merge(a, b).title, 'B 的标题');
      expect(resolver.merge(b, a).title, 'B 的标题');
    });

    test('不同字段各自保留较新版本', () {
      final local = note(
        title: 'A 改的标题',
        versions: {
          'title': const FieldVersion(300, 'deviceA'),
          'content': const FieldVersion(100, 'deviceA'),
        },
      );
      final remote = note(
        title: '旧标题',
        content: 'B 改的正文',
        versions: {
          'title': const FieldVersion(100, 'deviceB'),
          'content': const FieldVersion(400, 'deviceB'),
        },
      );

      final merged = resolver.merge(local, remote);

      expect(merged.title, 'A 改的标题');
      expect(merged.content, 'B 改的正文');
    });

    test('删除时间较新时删除胜出', () {
      final local = note(
        title: '旧标题',
        deleted: true,
        deletedBy: 'deviceA',
        versions: {'deleted': const FieldVersion(500, 'deviceA')},
      );
      final remote = note(
        title: 'B 后来改的标题',
        versions: {
          'title': const FieldVersion(200, 'deviceB'),
          'deleted': const FieldVersion(300, 'deviceB'),
        },
      );

      final merged = resolver.merge(local, remote);

      expect(merged.deleted, isTrue);
      expect(merged.deletedBy, 'deviceA');
    });

    test('删除之后又有编辑，则编辑胜出，笔记保留', () {
      final local = note(
        title: 'A 删除了',
        deleted: true,
        deletedBy: 'deviceA',
        versions: {
          'title': const FieldVersion(100, 'deviceA'),
          'deleted': const FieldVersion(100, 'deviceA'),
        },
      );
      final remote = note(
        title: 'B 重新编辑',
        deleted: false,
        versions: {
          'title': const FieldVersion(200, 'deviceB'),
          'deleted': const FieldVersion(200, 'deviceB'),
        },
      );

      final merged = resolver.merge(local, remote);

      expect(merged.deleted, isFalse);
      expect(merged.title, 'B 重新编辑');
    });
  });
}
