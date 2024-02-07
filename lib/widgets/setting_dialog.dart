import 'package:cartridge/main.dart';
import 'package:cartridge/providers/setting_provider.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart' as material;

class SettingDialog extends ConsumerStatefulWidget {
  const SettingDialog({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _SettingDialogState();
}

class _SettingDialogState extends ConsumerState<SettingDialog> {
  bool _isChanged = false;

  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();

    _controller =
        TextEditingController(text: ref.read(settingProvider).isaacPath);
  }

  @override
  void dispose() {
    _controller.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ContentDialog(
      title: const Text('설정'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InfoLabel(
            label: '아이작 설치 경로',
            child: TextBox(
              controller: _controller,
              onChanged: (_) => setState(() => _isChanged = true),
            ),
          ),
          const SizedBox(height: 16.0),
          Row(
            children: [
              Button(
                onPressed: () => material.showLicensePage(context: context),
                child: const Text('라이센스'),
              ),
              const SizedBox(width: 8.0),
              Text('v$currentVersion'),
            ],
          ),
        ],
      ),
      actions: [
        Button(
          onPressed: () {
            Navigator.pop(context);
          },
          child: const Text('취소'),
        ),
        FilledButton(
          onPressed: _isChanged
              ? () {
                  ref.read(settingProvider).setIsaacPath(_controller.text);
                  Navigator.pop(context);
                }
              : null,
          child: const Text('저장'),
        ),
      ],
    );
  }
}
