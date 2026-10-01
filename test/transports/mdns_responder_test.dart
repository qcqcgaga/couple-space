import 'dart:typed_data';
import 'dart:convert';

import 'package:couple_space/core/sync/transports/lan/mdns_responder.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const serviceType = '_couple-space._tcp';
  const instanceName = 'deviceA._couple-space._tcp.local.';
  const hostName = 'deviceA.local.';
  const txtEntries = ['id=deviceA', 'name=小明手机', 'pv=1'];

  MdnsResponder responder({int port = 43123}) => MdnsResponder(
        serviceType: serviceType,
        instanceName: instanceName,
        hostName: hostName,
        port: port,
        txtEntries: txtEntries,
      );

  Uint8List localIp() => Uint8List.fromList([192, 168, 1, 50]);

  group('MdnsResponder.buildResponse', () {
    test('PTR 查询返回服务记录（含 SRV/TXT/A）', () {
      final query = _query('_couple-space._tcp.local.', type: 12);
      final response = responder().buildResponse(query, localAddress: localIp());

      expect(response, isNotNull);
      final records = _parseRecords(response!);
      expect(records.map((r) => r.type), containsAll([12, 33, 16, 1]));

      final ptr = records.firstWhere((r) => r.type == 12);
      expect(ptr.nameData, 'deviceA._couple-space._tcp.local');
      final srv = records.firstWhere((r) => r.type == 33);
      expect(srv.nameData, 'deviceA.local');
      expect(srv.port, 43123);
      final txt = records.firstWhere((r) => r.type == 16);
      expect(txt.txtEntries, containsAll(['id=deviceA', 'name=小明手机', 'pv=1']));
      final a = records.firstWhere((r) => r.type == 1);
      expect(a.ipAddress, '192.168.1.50');
    });

    test('SRV 查询返回 SRV 与 A', () {
      final response = responder().buildResponse(
        _query(instanceName, type: 33),
        localAddress: localIp(),
      );
      final records = _parseRecords(response!);
      expect(records.map((r) => r.type), containsAll([33, 1]));
    });

    test('TXT 查询返回 TXT', () {
      final response = responder().buildResponse(
        _query(instanceName, type: 16),
        localAddress: localIp(),
      );
      final records = _parseRecords(response!);
      expect(records.map((r) => r.type), [16]);
    });

    test('A 查询返回本机 IPv4', () {
      final response = responder().buildResponse(
        _query(hostName, type: 1),
        localAddress: localIp(),
      );
      final records = _parseRecords(response!);
      expect(records.map((r) => r.type), [1]);
      expect(records.single.ipAddress, '192.168.1.50');
    });

    test('无关服务的查询不响应', () {
      final query = _query('_other._tcp.local.', type: 12);
      expect(responder().buildResponse(query, localAddress: localIp()), isNull);
    });

    test('主动宣告包含全部服务记录', () {
      final response = responder().buildAnnouncement(localAddress: localIp());
      final records = _parseRecords(response);
      expect(records.map((r) => r.type), containsAll([12, 33, 16, 1]));
    });
  });
}

Uint8List _query(String name, {required int type}) {
  final nameBytes = _encodeName(name);
  final header = Uint8List(12);
  final view = ByteData.sublistView(header);
  view.setUint16(0, 0x1234);
  view.setUint16(2, 0);
  view.setUint16(4, 1); // QDCOUNT
  view.setUint16(6, 0);
  view.setUint16(8, 0);
  view.setUint16(10, 0);
  final question = Uint8List(4);
  final questionView = ByteData.sublistView(question);
  questionView.setUint16(0, type);
  questionView.setUint16(2, 1); // IN
  return Uint8List.fromList([...header, ...nameBytes, ...question]);
}

Uint8List _encodeName(String name) {
  final normalized = name.endsWith('.') ? name : '$name.';
  final builder = BytesBuilder(copy: false);
  for (final label in normalized.split('.')) {
    if (label.isEmpty) continue;
    final bytes = label.codeUnits;
    builder.addByte(bytes.length);
    builder.add(bytes);
  }
  builder.addByte(0);
  return builder.toBytes();
}

class _Record {
  const _Record({required this.type, required this.rdata, required this.name});

  final int type;
  final Uint8List rdata;
  final String name;

  int get port {
    if (type != 33 || rdata.length < 6) return -1;
    return ByteData.sublistView(rdata).getUint16(4);
  }

  /// 名称类 RDATA（PTR/SRV 目标）解析为点分域名。
  String get nameData {
    if (type == 12) return _readName(rdata, 0)!.$1;
    if (type == 33) return _readName(rdata, 6)!.$1;
    return '';
  }

  /// TXT 记录：长度前缀字符串列表。
  List<String> get txtEntries {
    if (type != 16) return const [];
    final out = <String>[];
    var i = 0;
    while (i < rdata.length) {
      final len = rdata[i];
      i++;
      if (len == 0) continue;
      out.add(utf8.decode(Uint8List.sublistView(rdata, i, i + len)));
      i += len;
    }
    return out;
  }

  String get ipAddress => rdata.join('.');
}

List<_Record> _parseRecords(Uint8List bytes) {
  final view = ByteData.sublistView(bytes);
  final qd = view.getUint16(4);
  final an = view.getUint16(6);
  var offset = 12;
  for (var i = 0; i < qd; i++) {
    final name = _readName(bytes, offset)!;
    offset = name.$2 + 4;
  }
  final records = <_Record>[];
  for (var i = 0; i < an; i++) {
    final name = _readName(bytes, offset)!;
    offset = name.$2;
    final type = ByteData.sublistView(bytes, offset).getUint16(0);
    final rdLength = ByteData.sublistView(bytes, offset).getUint16(8);
    offset += 10;
    final rdata = Uint8List.sublistView(bytes, offset, offset + rdLength);
    offset += rdLength;
    records.add(_Record(type: type, rdata: rdata, name: name.$1));
  }
  return records;
}

(String, int)? _readName(Uint8List bytes, int offset) {
  final labels = <String>[];
  var cursor = offset;
  var jumped = false;
  var jumpTarget = 0;
  while (true) {
    final len = bytes[cursor];
    if (len == 0) {
      cursor++;
      break;
    }
    if (len & 0xC0 == 0xC0) {
      final pointer = ((len & 0x3F) << 8) | bytes[cursor + 1];
      if (!jumped) {
        jumpTarget = cursor + 2;
        jumped = true;
      }
      cursor = pointer;
      continue;
    }
    labels.add(String.fromCharCodes(bytes, cursor + 1, cursor + 1 + len));
    cursor += 1 + len;
  }
  return (labels.join('.'), jumped ? jumpTarget : cursor);
}
