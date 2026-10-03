import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/sync/engine.dart';
import '../theme.dart';

/// 配对码确认对话框（首次配对 SAS 比对，docs/02 §5）。
///
/// 展示本端计算的 6 位配对码，用户与对方核对后输入并确认；
/// 通过二维码锁定过身份时额外提示（[PairingChallenge.verifiedByQr]）。
class PairingConfirmDialog extends StatefulWidget {
  const PairingConfirmDialog({
    super.key,
    required this.challenge,
    required this.onConfirm,
    this.onDismiss,
  });

  final PairingChallenge challenge;

  /// 用户确认配对码后回调（输入错误由调用方抛出异常）。
  final Future<void> Function(String code) onConfirm;

  /// 「稍后再说」回调（默认仅关闭对话框）。
  final VoidCallback? onDismiss;

  @override
  State<PairingConfirmDialog> createState() => _PairingConfirmDialogState();
}

class _PairingConfirmDialogState extends State<PairingConfirmDialog> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final challenge = widget.challenge;
    return AlertDialog(
      title: const Text('配对确认'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (challenge.verifiedByQr) ...[
              const Chip(
                avatar: Icon(Icons.qr_code, size: 16),
                label: Text('已通过二维码锁定对方身份'),
              ),
              const SizedBox(height: 10),
            ],
            const Text(
              '两台设备应显示同一组 6 位配对码。请与对方核对后输入：',
              style: TextStyle(fontSize: 13, color: CoupleColors.textDark),
            ),
            const SizedBox(height: 12),
            Center(
              child: SelectableText(
                challenge.code,
                style: const TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 6,
                  color: CoupleColors.primaryDark,
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _controller,
              keyboardType: TextInputType.number,
              maxLength: 6,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                hintText: '输入对方设备显示的配对码',
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {
                  setState(() => _controller.text = challenge.code);
                },
                child: const Text('两边一致，自动填入'),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            widget.onDismiss?.call();
            Navigator.of(context).pop();
          },
          child: const Text('稍后再说'),
        ),
        FilledButton(
          onPressed: _confirm,
          child: const Text('确认配对'),
        ),
      ],
    );
  }

  Future<void> _confirm() async {
    final entered = _controller.text.trim();
    if (!RegExp(r'^\d{6}$').hasMatch(entered)) {
      _toast('请输入 6 位配对码');
      return;
    }
    try {
      await widget.onConfirm(entered);
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) _toast('配对失败：$e');
    }
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}
