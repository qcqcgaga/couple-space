import '../models/note.dart';
import '../sync/lww.dart';
import 'daos.dart';
import 'database.dart';

/// 笔记用例层（存储 + LWW 合并）。
///
/// 同步收到远端笔记时调用 [applyRemoteNote]：与本地当前版本做字段级
/// LWW 合并后落库；合并结果是删除的写入墓碑，防止旧数据复活。
class NoteStore {
  NoteStore(this.db) : notes = NotesDao(db);

  final AppDatabase db;
  final NotesDao notes;

  static const LwwResolver resolver = LwwResolver();

  Future<Note?> noteById(String id) => notes.noteById(id);

  Future<List<Note>> allNotes({bool includeDeleted = false}) =>
      notes.allNotes(includeDeleted: includeDeleted);

  /// 本地保存（含新建）：调用方用 NoteVersions.stamped 生成版本即可。
  Future<void> save(Note note) => notes.upsertNote(note);

  /// 合并并写入一条远端笔记。
  Future<Note> applyRemoteNote(Note remote) async {
    final local = await notes.noteById(remote.id);
    final merged = resolver.merge(local ?? Note(id: remote.id), remote);
    await notes.upsertNote(merged);
    if (merged.deleted) {
      await TombstonesDao(db).put(
        merged.id,
        deletedAt: merged.deletedAt?.millisecondsSinceEpoch ??
            merged.fieldVersions['deleted']?.ts ??
            DateTime.now().millisecondsSinceEpoch,
        deletedBy: merged.deletedBy ?? merged.fieldVersions['deleted']?.deviceId ?? '',
      );
    }
    return merged;
  }

  /// 本地删除：按 LWW 规则写入 deleted 字段并落墓碑。
  Future<void> delete(String id, {required String deviceId, required int ts}) async {
    final current = await notes.noteById(id);
    final note = (current ?? Note(id: id)).copyWith(
      deleted: true,
      deletedAt: DateTime.fromMillisecondsSinceEpoch(ts),
      deletedBy: deviceId,
      fieldVersions: {
        ...?current?.fieldVersions,
        'deleted': FieldVersion(ts, deviceId),
      },
    );
    await notes.upsertNote(note);
    await TombstonesDao(db).put(
      id,
      deletedAt: ts,
      deletedBy: deviceId,
    );
  }
}
