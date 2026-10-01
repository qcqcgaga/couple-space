import 'package:drift_flutter/drift_flutter.dart';

import 'database.dart';

/// Flutter 运行时数据库入口。
///
/// drift_flutter 负责在各平台定位数据库文件，并加载随应用打包的 SQLite
/// （Android/iOS 由 sqlite3_flutter_libs 提供）。核心表定义放在
/// [AppDatabase]（纯 Dart，不依赖 drift_flutter），以便 Windows 上的
/// 单测与双进程探针在纯 Dart VM 中直接打开同一定义的数据库。
Future<AppDatabase> openFlutterDatabase({String dbName = 'couple_space'}) async {
  return AppDatabase(driftDatabase(name: dbName));
}
