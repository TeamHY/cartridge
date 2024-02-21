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

  late TextEditingController _pathController;
  late TextEditingController _rerunDelayController;

  @override
  void initState() {
    super.initState();

    _pathController =
        TextEditingController(text: ref.read(settingProvider).isaacPath);
    _rerunDelayController = TextEditingController(
        text: ref.read(settingProvider).rerunDelay.toString());
  }

  @override
  void dispose() {
    _pathController.dispose();

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
              controller: _pathController,
              onChanged: (_) => setState(() => _isChanged = true),
            ),
          ),
          const SizedBox(height: 16.0),
          InfoLabel(
            label: '재시작 지연시간 (1000 = 1초)',
            child: TextBox(
              controller: _rerunDelayController,
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
                  final setting = ref.read(settingProvider);

                  setting.setIsaacPath(_pathController.text);
                  setting.setRerunDelay(
                    int.parse(_rerunDelayController.text),
                  );
                  setting.saveSetting();

                  Navigator.pop(context);
                }
              : null,
          child: const Text('저장'),
        ),
      ],
    );
  }
}
