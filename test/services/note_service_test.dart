import 'package:couple_space/core/models/note.dart';
import 'package:couple_space/core/models/note_edit.dart';
import 'package:couple_space/core/storage/store.dart';
import 'package:couple_space/services/note_service.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_env.dart';

void main() {
  late TestEnv env;

  setUp(() async {
    env = await TestEnv.create(deviceId: 'deviceA');
  });

  tearDown(() async {
    await env.dispose();
  });

  NoteDraft draft({
    String? title,
    String content = '今天一起去了海边',
    TimeBind timeBind = TimeBind.none,
    DateTime? startAt,
    DateTime? endAt,
    String? color,
    String? location,
    int? reminderOffsetMin,
  }) {
    return NoteDraft(
      title: title,
      content: content,
      timeBind: timeBind,
      startAt: startAt,
      endAt: endAt,
      color: color,
      location: location,
      reminderOffsetMin: reminderOffsetMin,
    );
  }

  group('NoteService 笔记 CRUD', () {
    test('新建笔记：全部字段打上本机 LWW 版本，可读回', () async {
      final created = await env.service.createNote(
        draft(
          title: '我们的旅行',
          timeBind: TimeBind.range,
          startAt: DateTime(2026, 10, 1, 10),
          endAt: DateTime(2026, 10, 1, 12),
          color: 'F08CA4',
          location: '海边',
          reminderOffsetMin: 30,
        ),
      );

      final loaded = await env.service.noteById(created.id);
      expect(loaded, isNotNull);
      expect(loaded!.title, '我们的旅行');
      expect(loaded.content, '今天一起去了海边');
      expect(loaded.timeBind, TimeBind.range);
      expect(loaded.location, '海边');
      expect(loaded.reminderOffsetMin, 30);
      expect(loaded.createdBy, 'deviceA');

      final versions = loaded.fieldVersions;
      expect(versions.length, NoteVersions.editableFields.length);
      for (final field in NoteVersions.editableFields) {
        expect(versions[field]?.deviceId, 'deviceA', reason: field);
      }
      // 提醒时间 = 开始时间 - 30 分钟。
      expect(
        loaded.reminderAt,
        DateTime(2026, 10, 1, 10).subtract(const Duration(minutes: 30)),
      );
    });

    test('更新笔记：仅变更字段重新打时间戳，未动字段版本保留', () async {
      final created = await env.service.createNote(
        draft(title: '旧标题', content: '旧正文'),
      );
      final oldTs = NoteVersions.lastUpdatedAt(created);

      // 模拟远端设备 B 更新了标题：字段版本较新，经 LWW 合并后本地生效。
      final remote = created.copyWith(
        title: '对方的标题',
        fieldVersions: {
          ...created.fieldVersions,
          'title': FieldVersion(oldTs + 1000, 'deviceB'),
        },
      );
      await NoteStore(env.db).applyRemoteNote(remote);

      final afterRemote = await env.service.noteById(created.id);
      final remoteTitleTs = afterRemote!.fieldVersions['title']!.ts;

      // 本地这次只改正文；标题字段版本保持对方较新的值。
      await env.service.updateNote(
        created.id,
        draft(title: '对方的标题', content: '本地新正文'),
      );
      final updated = await env.service.noteById(created.id);

      expect(updated!.title, '对方的标题');
      expect(updated.content, '本地新正文');
      expect(updated.fieldVersions['content']!.deviceId, 'deviceA');
      expect(updated.fieldVersions['content']!.ts, greaterThan(oldTs));
      expect(updated.fieldVersions['title']!.ts, remoteTitleTs);
      // 标题未被本地改动：字段版本仍是远端设备 B 的。
      expect(updated.fieldVersions['title']!.deviceId, 'deviceB');
    });

    test('删除写入墓碑，列表不再可见', () async {
      final created = await env.service.createNote(draft());
      await env.service.deleteNote(created.id);

      expect(await env.service.listNotes(), isEmpty);
      final loaded = await env.service.noteById(created.id);
      expect(loaded!.deleted, isTrue);
      expect(loaded.deletedBy, 'deviceA');
    });

    test('列表按最后更新时间倒序', () async {
      final first = await env.service.createNote(draft(content: '第一条'));
      await Future<void>.delayed(const Duration(milliseconds: 2));
      final second = await env.service.createNote(draft(content: '第二条'));
      await Future<void>.delayed(const Duration(milliseconds: 2));
      final third = await env.service.createNote(draft(content: '第三条'));

      final notes = await env.service.listNotes();
      expect(notes.map((n) => n.id), [third.id, second.id, first.id]);

      // 编辑第一条后它应回到最前。
      await env.service.updateNote(first.id, draft(content: '第一条更新'));
      final refreshed = await env.service.listNotes();
      expect(refreshed.first.id, first.id);
    });

    test('watchNotes 在笔记与图片变化时发出新列表', () async {
      final emitted = <List<Note>>[];
      final sub = env.service.watchNotes().listen(emitted.add);
      addTearDown(sub.cancel);

      final created = await env.service.createNote(draft());
      final png = await env.writePng();
      await env.service.addImage(created.id, sourcePath: png.path);

      await Future<void>.delayed(const Duration(milliseconds: 100));
      expect(emitted, isNotEmpty);
      expect(emitted.last.map((n) => n.id), contains(created.id));
      await sub.cancel();
    });
  });

  group('NoteService 图片管理', () {
    test('添加图片：复制原图、生成缩略图、sha256/size 落库', () async {
      final created = await env.service.createNote(draft());
      final png = await env.writePng();

      final image = await env.service.addImage(
        created.id,
        sourcePath: png.path,
        fileName: '海边照片.png',
      );

      expect(image.sha256, hasLength(64));
      expect(image.size, greaterThan(0));
      expect(image.lwDevice, 'deviceA');
      expect(await env.service.files.exists(image), isTrue);
      final thumb = await env.service.thumbnailFor(image);
      expect(thumb, isNotNull);
      expect(thumb!.existsSync(), isTrue);

      final list = await env.service.imagesForNote(created.id);
      expect(list.map((i) => i.id), contains(image.id));
    });

    test('移除图片：写墓碑、删除原图与缩略图', () async {
      final created = await env.service.createNote(draft());
      final png = await env.writePng();
      final image = await env.service.addImage(
        created.id,
        sourcePath: png.path,
      );
      final thumb = await env.service.thumbnailFor(image);

      await env.service.removeImage(image);

      expect(await env.service.files.exists(image), isFalse);
      expect(thumb!.existsSync(), isFalse);
      final list = await env.service.imagesForNote(created.id);
      expect(list.map((i) => i.id), isNot(contains(image.id)));
    });
  });

  group('NoteService 时间与日历查询', () {
    test('coversDay：全天仅当天，时间段为闭区间，不绑定不出现', () async {
      final allDay = Note(
        id: 'a',
        timeBind: TimeBind.allDay,
        startAt: DateTime(2026, 10, 1),
      );
      final range = Note(
        id: 'r',
        timeBind: TimeBind.range,
        startAt: DateTime(2026, 10, 3, 8),
        endAt: DateTime(2026, 10, 5, 20),
      );
      final none = Note(id: 'n');

      expect(NoteService.coversDay(allDay, DateTime(2026, 10, 1)), isTrue);
      expect(NoteService.coversDay(allDay, DateTime(2026, 10, 2)), isFalse);
      expect(NoteService.coversDay(range, DateTime(2026, 10, 3)), isTrue);
      expect(NoteService.coversDay(range, DateTime(2026, 10, 4)), isTrue);
      expect(NoteService.coversDay(range, DateTime(2026, 10, 5)), isTrue);
      expect(NoteService.coversDay(range, DateTime(2026, 10, 6)), isFalse);
      expect(NoteService.coversDay(none, DateTime(2026, 10, 1)), isFalse);
    });

    test('notesForDay 与 daysWithNotesInMonth', () async {
      await env.service.createNote(
        draft(timeBind: TimeBind.allDay, startAt: DateTime(2026, 10, 8)),
      );
      await env.service.createNote(
        draft(
          timeBind: TimeBind.range,
          startAt: DateTime(2026, 10, 20, 9),
          endAt: DateTime(2026, 10, 22, 18),
        ),
      );
      await env.service.createNote(draft(content: '不绑定时间的随笔'));

      final dayNotes = await env.service.notesForDay(DateTime(2026, 10, 21));
      expect(dayNotes, hasLength(1));
      expect(dayNotes.single.timeBind, TimeBind.range);

      final markers = await env.service.daysWithNotesInMonth(2026, 10);
      expect(markers, {DateTime(2026, 10, 8), DateTime(2026, 10, 20), DateTime(2026, 10, 21), DateTime(2026, 10, 22)});
      final noneMonth = await env.service.daysWithNotesInMonth(2026, 11);
      expect(noneMonth, isEmpty);
    });

    test('reminderAtFor：全天 09:00 基准、时间段 startAt 基准、关闭返回 null', () {
      expect(
        NoteService.reminderAtFor(
          draft(
            timeBind: TimeBind.allDay,
            startAt: DateTime(2026, 10, 8),
            reminderOffsetMin: 15,
          ),
        ),
        DateTime(2026, 10, 8, 9).subtract(const Duration(minutes: 15)),
      );
      expect(
        NoteService.reminderAtFor(
          draft(
            timeBind: TimeBind.range,
            startAt: DateTime(2026, 10, 8, 10),
            endAt: DateTime(2026, 10, 8, 12),
            reminderOffsetMin: 30,
          ),
        ),
        DateTime(2026, 10, 8, 10).subtract(const Duration(minutes: 30)),
      );
      expect(NoteService.reminderAtFor(draft()), isNull);
      expect(
        NoteService.reminderAtFor(
          draft(timeBind: TimeBind.allDay, startAt: DateTime(2026, 10, 8)),
        ),
        isNull,
      );
    });
  });
}
