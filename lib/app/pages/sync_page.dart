import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../core/pairing/qr_codec.dart';
import '../../core/storage/database.dart';
import '../../core/sync/engine.dart';
import '../../services/sync_service.dart';
import '../theme.dart';
import '../widgets/pairing_dialog.dart';

/// 同步与配对页（M3）：本机信息、二维码/配对码、设备发现与白名单、
/// 手动 IP 直连、蓝牙/热点入口与最近同步状态。
class SyncPage extends StatefulWidget {
  const SyncPage({super.key, required this.sync});

  final SyncService sync;

  @override
  State<SyncPage> createState() => _SyncPageState();
}

class _SyncPageState extends State<SyncPage> {
  final TextEditingController _ipController = TextEditingController();
  final TextEditingController _portController = TextEditingController();
  PairingChallenge? _scheduledChallenge;

  @override
  void dispose() {
    _ipController.dispose();
    _portController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('同步与配对')),
      body: ListenableBuilder(
        listenable: widget.sync,
        builder: (context, _) {
          final challenge = widget.sync.pendingChallenge;
          if (challenge != null && !identical(_scheduledChallenge, challenge)) {
            _scheduledChallenge = challenge;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) _showPairingDialog(challenge);
            });
          }
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            children: [
              _buildIdentityCard(),
              const SizedBox(height: 12),
              if (challenge != null) ...[
                _PendingPairBanner(
                  code: challenge.code,
                  onTap: () => _showPairingDialog(challenge),
                ),
                const SizedBox(height: 12),
              ],
              _buildQrCard(),
              const SizedBox(height: 12),
              _buildDevicesCard(),
              const SizedBox(height: 12),
              _buildManualCard(),
              const SizedBox(height: 12),
              _buildChannelCard(),
              const SizedBox(height: 12),
              _buildEventsCard(),
            ],
          );
        },
      ),
    );
  }

  // ---------- 本机信息 ----------

  Widget _buildIdentityCard() {
    final sync = widget.sync;
    return _SectionCard(
      title: '本机',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _InfoRow(
            label: '昵称',
            value: sync.deviceName.isEmpty ? '我的设备' : sync.deviceName,
            trailing: TextButton(
              onPressed: _editDeviceName,
              child: const Text('修改'),
            ),
          ),
          _InfoRow(
            label: '设备 ID',
            value: sync.identity.deviceId,
          ),
          if (sync.listenPort != null)
            _InfoRow(label: '本机端口', value: '${sync.listenPort}'),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(
                sync.running ? Icons.wifi : Icons.wifi_off,
                size: 18,
                color: sync.running
                    ? CoupleColors.secondary
                    : CoupleColors.textLight,
              ),
              const SizedBox(width: 8),
              Text(
                sync.running ? '局域网发现中（自动连接已配对设备）' : '同步服务未启动',
                style: const TextStyle(
                  color: CoupleColors.textDark,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text(
              '自动连接',
              style: TextStyle(fontSize: 14, color: CoupleColors.textDark),
            ),
            subtitle: const Text(
              '发现已配对设备时自动连接并同步',
              style: TextStyle(fontSize: 12, color: CoupleColors.textLight),
            ),
            value: sync.autoConnect,
            onChanged: (value) => sync.setAutoConnect(value),
          ),
        ],
      ),
    );
  }

  Future<void> _editDeviceName() async {
    final controller = TextEditingController(text: widget.sync.deviceName);
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('修改昵称'),
        content: TextField(
          controller: controller,
          maxLength: 24,
          decoration: const InputDecoration(hintText: '对方看到的名字'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('保存'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (name != null && name.trim().isNotEmpty) {
      await widget.sync.setDeviceName(name);
      if (mounted) _toast('昵称已更新，重新开始发现');
    }
  }

  // ---------- 二维码 ----------

  Widget _buildQrCard() {
    final sync = widget.sync;
    return _SectionCard(
      title: '二维码配对',
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: CoupleColors.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: CoupleColors.border),
            ),
            child: QrImageView(
              data: sync.qrPayload,
              size: 176,
              eyeStyle: const QrEyeStyle(
                eyeShape: QrEyeShape.square,
                color: CoupleColors.textDark,
              ),
              dataModuleStyle: const QrDataModuleStyle(
                dataModuleShape: QrDataModuleShape.square,
                color: CoupleColors.textDark,
              ),
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            '让另一半扫描或输入本机二维码，即可锁定身份开始配对',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: CoupleColors.textLight),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              OutlinedButton.icon(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: sync.qrPayload));
                  _toast('已复制二维码内容');
                },
                icon: const Icon(Icons.copy, size: 16),
                label: const Text('复制'),
              ),
              const SizedBox(width: 10),
              FilledButton.icon(
                onPressed: _inputQrContent,
                icon: const Icon(Icons.qr_code_scanner, size: 16),
                label: const Text('输入对方二维码'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _inputQrContent() async {
    final controller = TextEditingController();
    final raw = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('输入对方二维码内容'),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: '粘贴对方「复制」出的二维码内容，或扫码后粘贴结果',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('锁定并配对'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (raw == null || raw.trim().isEmpty) return;
    try {
      final data = PairQrCodec.decode(raw);
      await widget.sync.prepareQrPairing(data);
      final label = data.name.isEmpty ? data.deviceId : data.name;
      if (mounted) _toast('已锁定 $label 的身份，等待连接配对…');
    } on FormatException catch (e) {
      if (mounted) _toast('二维码内容无效：${e.message}');
    }
  }

  // ---------- 设备与白名单 ----------

  Widget _buildDevicesCard() {
    final sync = widget.sync;
    return _SectionCard(
      title: '设备',
      child: StreamBuilder<List<PeerRow>>(
        stream: sync.watchPeers(),
        builder: (context, snapshot) {
          final peers = snapshot.data ?? const <PeerRow>[];
          final pairedIds = {for (final row in peers) row.deviceId};
          final discovered = sync.discoveredPeers;
          final allIds = <String>{
            for (final peer in discovered) peer.peerId,
            ...pairedIds,
          };
          if (allIds.isEmpty) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text(
                '还没发现设备~ 两台手机连上同一个 WiFi（或热点）后，这里就会出现对方。',
                style: TextStyle(fontSize: 13, color: CoupleColors.textLight),
              ),
            );
          }
          final rows = allIds.map((id) {
            final discoveredPeer = discovered
                .where((p) => p.peerId == id)
                .firstOrNull;
            final row = peers.where((p) => p.deviceId == id).firstOrNull;
            final peerName = discoveredPeer?.name;
            return _DeviceRowData(
              deviceId: id,
              name: (peerName?.isNotEmpty ?? false) ? peerName! : row?.name,
              paired: pairedIds.contains(id),
              discovered: discoveredPeer != null,
            );
          }).toList()
            ..sort((a, b) {
              if (a.paired != b.paired) return a.paired ? -1 : 1;
              return a.deviceId.compareTo(b.deviceId);
            });

          return Column(
            children: [
              for (final data in rows)
                _DeviceRow(
                  data: data,
                  connecting: sync.isConnecting(data.deviceId),
                  connected: sync.isConnected(data.deviceId),
                  onAction: () =>
                      sync.connectToDiscovered(data.deviceId),
                  onUnpair: () => _confirmUnpair(data),
                ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _confirmUnpair(_DeviceRowData data) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('解除配对？'),
        content: Text('将 ${data.displayName} 从本机白名单移除，不再自动连接。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: CoupleColors.primaryDark,
            ),
            child: const Text('解除'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await widget.sync.unpair(data.deviceId);
      if (mounted) _toast('已解除配对');
    }
  }

  // ---------- 手动直连 ----------

  Widget _buildManualCard() {
    return _SectionCard(
      title: '手动连接',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            '自动发现不生效时，可输入对方 IP 与本机端口直连',
            style: TextStyle(fontSize: 12, color: CoupleColors.textLight),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                flex: 3,
                child: TextField(
                  controller: _ipController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(hintText: 'IP 地址，如 192.168.1.8'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 1,
                child: TextField(
                  controller: _portController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(hintText: '端口'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          FilledButton.icon(
            onPressed: _manualConnect,
            icon: const Icon(Icons.link, size: 16),
            label: const Text('连接'),
          ),
        ],
      ),
    );
  }

  Future<void> _manualConnect() async {
    final host = _ipController.text.trim();
    final port = int.tryParse(_portController.text.trim());
    if (host.isEmpty || port == null) {
      _toast('请输入 IP 与端口');
      return;
    }
    await widget.sync.connectToHost(host, port);
  }

  // ---------- 通道入口 ----------

  Widget _buildChannelCard() {
    final sync = widget.sync;
    return _SectionCard(
      title: '连接通道',
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.bluetooth, color: CoupleColors.secondary),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '蓝牙',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: CoupleColors.textDark,
                      ),
                    ),
                    Text(
                      '原生 BLE 已预留，待真机联调接入；大图请走 WiFi/热点',
                      style: TextStyle(
                        fontSize: 11,
                        color: CoupleColors.textLight,
                      ),
                    ),
                  ],
                ),
              ),
              if (sync.bluetoothScanning)
                OutlinedButton(
                  onPressed: sync.stopBluetoothScan,
                  child: const Text('停止扫描'),
                )
              else
                FilledButton(
                  onPressed: sync.startBluetoothScan,
                  child: const Text('开始扫描'),
                ),
            ],
          ),
          const Divider(height: 20),
          Row(
            children: [
              const Icon(Icons.wifi_tethering, color: CoupleColors.secondary),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  '热点：一方开热点、另一方加入后自动发现，或用手动连接直连',
                  style: TextStyle(fontSize: 12, color: CoupleColors.textLight),
                ),
              ),
              OutlinedButton(
                onPressed: _showHotspotHelp,
                child: const Text('说明'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showHotspotHelp() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('热点怎么连？'),
        content: const Text(
          '1. 一方（建议 Android）开启个人热点；\n'
          '2. 另一方加入该热点 WiFi；\n'
          '3. 双方回到本页：热点与同 WiFi 一样走局域网自动发现，'
          '已配对会自动连接；也可以直接输入对方 IP 和本机端口手动直连。',
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('知道了'),
          ),
        ],
      ),
    );
  }

  // ---------- 最近状态 ----------

  Widget _buildEventsCard() {
    final events = widget.sync.recentEvents;
    if (events.isEmpty) {
      return const _SectionCard(
        title: '最近同步',
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: Text(
            '还没有同步记录，连接后这里会展示进度~',
            style: TextStyle(fontSize: 13, color: CoupleColors.textLight),
          ),
        ),
      );
    }
    return _SectionCard(
      title: '最近同步',
      child: Column(
        children: [
          for (final event in events.reversed.take(5).toList())
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                children: [
                  Icon(
                    _eventIcon(event.kind),
                    size: 16,
                    color: event.kind == SyncEventKind.error
                        ? CoupleColors.primaryDark
                        : CoupleColors.secondary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _eventLabel(event),
                      style: const TextStyle(
                        fontSize: 12,
                        color: CoupleColors.textDark,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  IconData _eventIcon(SyncEventKind kind) {
    switch (kind) {
      case SyncEventKind.error:
      case SyncEventKind.imageTransferFailed:
        return Icons.error_outline;
      case SyncEventKind.imageTransferProgress:
        return Icons.image_outlined;
      case SyncEventKind.synced:
        return Icons.check_circle_outline;
      case SyncEventKind.closed:
        return Icons.link_off;
      default:
        return Icons.sync;
    }
  }

  String _eventLabel(SyncEvent event) {
    switch (event.kind) {
      case SyncEventKind.connecting:
        return '连接中…';
      case SyncEventKind.handshaking:
        return '身份校验中…';
      case SyncEventKind.paired:
        return '已配对：${_shortId(event.peerDeviceId)}';
      case SyncEventKind.syncing:
        return '同步中…';
      case SyncEventKind.noteSynced:
        return '笔记已同步';
      case SyncEventKind.imageMetaSynced:
        return '图片元数据已同步';
      case SyncEventKind.imageTransferProgress:
        return '图片传输 ${event.progress}/${event.total}';
      case SyncEventKind.imageTransferDone:
        return '图片传输完成';
      case SyncEventKind.imageTransferFailed:
        return '图片传输失败';
      case SyncEventKind.synced:
        return '本轮同步完成';
      case SyncEventKind.error:
        return '错误：${event.message ?? ''}';
      case SyncEventKind.closed:
        return '连接已关闭';
    }
  }

  String _shortId(String? id) =>
      id == null ? '' : (id.length <= 10 ? id : '${id.substring(0, 10)}…');

  // ---------- 配对码浮层 ----------

  Future<void> _showPairingDialog(PairingChallenge challenge) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => PairingConfirmDialog(
        challenge: challenge,
        onConfirm: widget.sync.confirmPairing,
        onDismiss: widget.sync.dismissPairingChallenge,
      ),
    );
  }

  void _toast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

// ---------- 小组件 ----------

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: CoupleColors.textDark,
              ),
            ),
            const SizedBox(height: 10),
            child,
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value, this.trailing});

  final String label;
  final String value;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 72,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: CoupleColors.textLight,
              ),
            ),
          ),
          Expanded(
            child: SelectableText(
              value,
              style: const TextStyle(
                fontSize: 13,
                color: CoupleColors.textDark,
              ),
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

class _PendingPairBanner extends StatelessWidget {
  const _PendingPairBanner({required this.code, required this.onTap});

  final String code;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: CoupleColors.blush,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              const Icon(Icons.favorite, size: 18, color: CoupleColors.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '等待配对确认 · 配对码 $code',
                  style: const TextStyle(
                    fontSize: 13,
                    color: CoupleColors.textDark,
                  ),
                ),
              ),
              const Icon(Icons.chevron_right, size: 18, color: CoupleColors.textLight),
            ],
          ),
        ),
      ),
    );
  }
}

class _DeviceRowData {
  const _DeviceRowData({
    required this.deviceId,
    required this.paired,
    required this.discovered,
    this.name,
  });

  final String deviceId;
  final String? name;
  final bool paired;
  final bool discovered;

  String get displayName => (name?.isNotEmpty ?? false) ? name! : deviceId;
}

class _DeviceRow extends StatelessWidget {
  const _DeviceRow({
    required this.data,
    required this.connecting,
    required this.connected,
    required this.onAction,
    required this.onUnpair,
  });

  final _DeviceRowData data;
  final bool connecting;
  final bool connected;
  final VoidCallback onAction;
  final VoidCallback onUnpair;

  @override
  Widget build(BuildContext context) {
    final Widget action;
    if (connected) {
      action = const _StatusChip(
        label: '已连接',
        icon: Icons.check_circle,
        color: CoupleColors.secondary,
      );
    } else if (connecting) {
      action = const _StatusChip(
        label: '连接中…',
        icon: Icons.sync,
        color: CoupleColors.textLight,
      );
    } else {
      action = FilledButton(
        onPressed: onAction,
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          textStyle: const TextStyle(fontSize: 13),
        ),
        child: Text(data.paired ? '连接' : '配对'),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(
            data.paired ? Icons.favorite : Icons.phone_iphone,
            size: 20,
            color: data.paired ? CoupleColors.primary : CoupleColors.textLight,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.displayName,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: CoupleColors.textDark,
                  ),
                ),
                Text(
                  '${data.paired ? '已配对' : '未配对'} · ${data.deviceId}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: CoupleColors.textLight,
                  ),
                ),
              ],
            ),
          ),
          if (data.paired && !connected)
            TextButton(
              onPressed: onUnpair,
              child: const Text(
                '解除',
                style: TextStyle(fontSize: 12, color: CoupleColors.textLight),
              ),
            ),
          const SizedBox(width: 6),
          action,
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.label,
    required this.icon,
    required this.color,
  });

  final String label;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: color),
        ),
      ],
    );
  }
}
