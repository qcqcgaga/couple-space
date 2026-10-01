import 'package:couple_space/core/models/image.dart';
import 'package:couple_space/core/models/note.dart';
import 'package:couple_space/core/storage/daos.dart';
import 'package:couple_space/core/storage/database.dart';
import 'package:couple_space/core/storage/store.dart';
import 'package:drift/drift.dart' hide Column, isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  Note note({
    String id = 'n1',
    String? title,
    String content = '一起写下的正文',
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
      createdAt: DateTime.fromMillisecondsSinceEpoch(1000),
      createdBy: 'deviceA',
      fieldVersions: versions,
    );
  }

  group('NotesDao', () {
    test('保存并可读回完整笔记（含字段版本与时间）', () async {
      final dao = NotesDao(db);
      final original = note(
        title: '我们的旅行',
        content: '第一天去了海边',
        timeBind: TimeBind.range,
        startAt: DateTime.fromMillisecondsSinceEpoch(1700000000000),
        versions: {
          'title': const FieldVersion(100, 'deviceA'),
          'content': const FieldVersion(100, 'deviceA'),
        },
      );

      await dao.upsertNote(original);
      final loaded = await dao.noteById('n1');

      expect(loaded, isNotNull);
      expect(loaded!.title, '我们的旅行');
      expect(loaded.content, '第一天去了海边');
      expect(loaded.timeBind, TimeBind.range);
      expect(loaded.startAt, DateTime.fromMillisecondsSinceEpoch(1700000000000));
      expect(loaded.fieldVersions['title'], const FieldVersion(100, 'deviceA'));
    });

    test('整条覆盖写入会替换字段版本', () async {
      final dao = NotesDao(db);
      await dao.upsertNote(
        note(versions: {'title': const FieldVersion(100, 'deviceA')}),
      );
      await dao.upsertNote(
        note(
          content: '新版正文',
          versions: {'content': const FieldVersion(200, 'deviceB')},
        ),
      );

      final loaded = await dao.noteById('n1');
      expect(loaded!.fieldVersions.keys, ['content']);
      expect(loaded.content, '新版正文');
    });

    test('allNotes 排除已删除，可查询增量变化', () async {
      final dao = NotesDao(db);
      await dao.upsertNote(
        note(
          id: 'old',
          content: '旧',
          versions: {'content': const FieldVersion(100, 'deviceA')},
        ),
      );
      await dao.upsertNote(
        note(
          id: 'new',
          content: '新',
          versions: {'content': const FieldVersion(300, 'deviceB')},
        ),
      );
      await dao.upsertNote(
        note(
          id: 'deleted',
          content: '已删除',
          deleted: true,
          versions: {'deleted': const FieldVersion(500, 'deviceA')},
        ),
      );

      final visible = await dao.allNotes();
      expect(visible.map((n) => n.id), containsAll(['old', 'new']));
      expect(visible.map((n) => n.id), isNot(contains('deleted')));

      final changed = await dao.notesChangedSince(150);
      expect(changed.map((n) => n.id), containsAll(['new', 'deleted']));
    });
  });

  group('NoteStore LWW 合并', () {
    test('远端较新标题胜出，正文各自保留', () async {
      final store = NoteStore(db);
      await store.save(
        note(
          title: '本地标题',
          content: '本地正文',
          versions: {
            'title': const FieldVersion(100, 'deviceA'),
            'content': const FieldVersion(100, 'deviceA'),
          },
        ),
      );

      await store.applyRemoteNote(
        note(
          title: '远端标题',
          content: '远端正文',
          versions: {
            'title': const FieldVersion(200, 'deviceB'),
            'content': const FieldVersion(300, 'deviceB'),
          },
        ),
      );

      final merged = await store.noteById('n1');
      expect(merged!.title, '远端标题');
      expect(merged.content, '远端正文');
      expect(merged.fieldVersions['title'], const FieldVersion(200, 'deviceB'));
    });

    test('远端删除较新时删除胜出并写入墓碑', () async {
      final store = NoteStore(db);
      await store.save(
        note(
          versions: {'content': const FieldVersion(100, 'deviceA')},
        ),
      );

      final merged = await store.applyRemoteNote(
        note(
          deleted: true,
          deletedBy: 'deviceB',
          versions: {'deleted': const FieldVersion(400, 'deviceB')},
        ),
      );

      expect(merged.deleted, isTrue);
      final tombstones = await TombstonesDao(db).all();
      expect(tombstones.map((t) => t.recordId), contains('n1'));
    });

    test('本地删除后远端又有编辑则编辑胜出（防复活）', () async {
      final store = NoteStore(db);
      await store.save(
        note(
          deleted: true,
          deletedBy: 'deviceA',
          versions: {
            'deleted': const FieldVersion(500, 'deviceA'),
          },
        ),
      );

      final merged = await store.applyRemoteNote(
        note(
          content: 'B 重新编辑',
          versions: {
            'content': const FieldVersion(600, 'deviceB'),
            'deleted': const FieldVersion(600, 'deviceB'),
          },
        ),
      );

      expect(merged.deleted, isFalse);
      expect(merged.content, 'B 重新编辑');
    });

    test('本地删除走墓碑，allNotes 不可见', () async {
      final store = NoteStore(db);
      await store.save(
        note(
          versions: {'content': const FieldVersion(100, 'deviceA')},
        ),
      );
      await store.delete('n1', deviceId: 'deviceA', ts: 900);

      expect(await store.allNotes(), isEmpty);
      expect((await store.noteById('n1'))!.deleted, isTrue);
    });
  });

  group('ImagesDao', () {
    test('图片元数据 CRUD 与续传位图', () async {
      final dao = ImagesDao(db);
      await dao.upsertImage(
        ImageMeta(
          id: 'img1',
          noteId: 'n1',
          fileName: 'photo.jpg',
          sha256: 'abc',
          size: 1024,
          lwTs: 100,
          lwDevice: 'deviceA',
        ),
      );

      await dao.updateChunkProgress(
        'img1',
        status: 'partial',
        totalChunks: 5,
        chunkBitmap: '1,0,0,0,0',
      );

      final image = await dao.imageById('img1');
      expect(image, isNotNull);
      expect(image!.syncStatus, 'partial');
      expect(image.totalChunks, 5);
      expect(image.chunkBitmap, '1,0,0,0,0');
      expect(image.noteId, 'n1');

      final changed = await dao.imagesChangedSince(50);
      expect(changed.map((i) => i.id), contains('img1'));
    });
  });

  group('Peers / SyncState / LocalIdentity', () {
    test('白名单、同步状态与本地身份', () async {
      final peers = PeersDao(db);
      await peers.upsert(
        PeerRow(
          deviceId: 'deviceB',
          name: '对方的设备',
          identityPublicKey: 'base64pub',
          pairedAt: 1000,
        ),
      );
      expect(await peers.isPaired('deviceB'), isTrue);
      expect((await peers.find('deviceB'))!.name, '对方的设备');

      final state = SyncStateDao(db);
      await state.setInt('lastSyncVector', 42);
      await state.setBool('syncEnabled', true);
      expect(await state.getInt('lastSyncVector'), 42);
      expect(await state.getBool('syncEnabled'), isTrue);

      final identity = LocalIdentityDao(db);
      await identity.save(
        deviceId: 'deviceA',
        privateKey: 'priv',
        publicKey: 'pub',
      );
      final saved = await identity.get();
      expect(saved!.deviceId, 'deviceA');
      expect(saved.publicKey, 'pub');
    });
  });

  group('TombstonesDao', () {
    test('双方确认且超过 30 天后压缩清理', () async {
      final notes = NotesDao(db);
      await notes.upsertNote(
        note(
          deleted: true,
          deletedBy: 'deviceA',
          versions: {'deleted': const FieldVersion(100, 'deviceA')},
        ),
      );

      final dao = TombstonesDao(db);
      await dao.put('n1', deletedAt: 100, deletedBy: 'deviceA');

      // 未确认：不清理。
      expect(await dao.purgeExpired(), 0);

      await dao.confirm('n1');
      // 直接改写确认时间到 31 天前，模拟过期。
      final oldConfirmed = DateTime.now()
          .subtract(const Duration(days: 31))
          .millisecondsSinceEpoch;
      await (db.update(db.tombstones)..where((t) => t.recordId.equals('n1'))).write(
        TombstonesCompanion(confirmedAt: Value(oldConfirmed)),
      );

      expect(await dao.purgeExpired(), 1);
      expect(await notes.noteById('n1'), isNull);
      expect(await dao.all(), isEmpty);
    });
  });
}
