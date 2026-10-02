import 'dart:io';

import 'package:couple_space/core/sync/transports/lan/mdns_responder.dart';
import 'package:multicast_dns/multicast_dns.dart';

/// mDNS 单机栈能力探测。
///
/// mDNS 单机测试需要「应答器 + multicast_dns 客户端」在同一台机器上互通。
/// Windows 某些网络状态下（WLAN 掉到 link-local、5353 被其它应用占用、
/// 组播回环投递异常等），原始组播回环可能仍然可用，但完整 mDNS 栈
/// （服务宣告/查询应答）无法成立；此时相关测试自动跳过并给出原因
/// （ADR-02x）。真实局域网/真机各自绑定端口，不受影响。
Future<bool> supportsMdnsStack({int port = 55363}) async {
  final responder = MdnsResponder(
    serviceType: '_capability._tcp',
    instanceName: 'cap-device._capability._tcp.local.',
    hostName: 'cap-device.local.',
    port: 45678,
    txtEntries: const ['id=cap-device', 'name=能力探测'],
    listenPort: port,
    announceInterval: const Duration(seconds: 1),
  );
  await responder.start();
  final client = MDnsClient();
  try {
    await client.start(
      interfacesFactory: _multicastCapableInterfaces,
      mDnsPort: port,
      onError: (Object e) {},
    );
    final records = await client
        .lookup<PtrResourceRecord>(
          ResourceRecordQuery.serverPointer('_capability._tcp.local'),
          timeout: const Duration(seconds: 4),
        )
        .toList();
    return records.isNotEmpty;
  } catch (_) {
    return false;
  } finally {
    client.stop();
    await responder.stop();
  }
}

/// 与 lan_transport.dart 相同的「首选网卡」选择逻辑（镜像实现，避免改 M1 API）。
Future<Iterable<NetworkInterface>> _multicastCapableInterfaces(
  InternetAddressType type,
) async {
  final interfaces = await NetworkInterface.list(
    includeLinkLocal: true,
    type: type,
    includeLoopback: true,
  );
  final result = <NetworkInterface>[];
  final group = type == InternetAddressType.IPv6
      ? InternetAddress('FF02::FB')
      : InternetAddress('224.0.0.251');
  final preferred = interfaces.where((i) =>
      i.addresses.isNotEmpty &&
      !i.addresses.first.address.startsWith('127.') &&
      !i.addresses.first.address.startsWith('169.254.'));
  for (final iface in [...preferred, ...interfaces]) {
    final probe = await RawDatagramSocket.bind(
      type == InternetAddressType.IPv6
          ? InternetAddress.anyIPv6
          : InternetAddress.anyIPv4,
      0,
      reuseAddress: true,
      ttl: 255,
    );
    try {
      probe.joinMulticast(group, iface);
      result.add(iface);
      break;
    } catch (_) {
      // 该网卡不支持组播加入，跳过。
    } finally {
      probe.close();
    }
  }
  return result;
}
