import 'package:cartridge/models/option_preset.dart';
import 'package:cartridge/providers/store_provider.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class OptionPresetDialog extends ConsumerStatefulWidget {
  const OptionPresetDialog({
    super.key,
    this.id,
  });

  final String? id;

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _OptionPresetDialogState();
}

class _OptionPresetDialogState extends ConsumerState<OptionPresetDialog> {
  late OptionPreset _newPreset;
  late TextEditingController _nameController;
  late TextEditingController _windowWidthController;
  late TextEditingController _windowHeightController;
  late TextEditingController _windowPosXController;
  late TextEditingController _windowPosYController;

  @override
  void initState() {
    super.initState();

    _newPreset = ref.read(storeProvider).optionPresets.firstWhere(
          (preset) => preset.id == widget.id,
          orElse: () => OptionPreset(id: widget.id, name: '새 프리셋'),
        );

    _nameController = TextEditingController(text: _newPreset.name);
    _windowWidthController =
        TextEditingController(text: _newPreset.windowWidth.toString());
    _windowHeightController =
        TextEditingController(text: _newPreset.windowHeight.toString());
    _windowPosXController =
        TextEditingController(text: _newPreset.windowPosX.toString());
    _windowPosYController =
        TextEditingController(text: _newPreset.windowPosY.toString());
  }

  @override
  void dispose() {
    _nameController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ContentDialog(
      title: const Text('옵션 프리셋'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 328,
            child: InfoLabel(
              label: '이름',
              child: TextBox(
                controller: _nameController,
              ),
            ),
          ),
          const SizedBox(height: 16.0),
          Text(
            '창 크기',
            style: FluentTheme.of(context).typography.subtitle,
          ),
          const SizedBox(height: 8.0),
          Row(
            children: [
              SizedBox(
                width: 160,
                child: InfoLabel(
                  label: '너비',
                  child: TextBox(
                    controller: _windowWidthController,
                  ),
                ),
              ),
              const SizedBox(
                width: 8.0,
              ),
              SizedBox(
                width: 160,
                child: InfoLabel(
                  label: '높이',
                  child: TextBox(
                    controller: _windowHeightController,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16.0),
          Text(
            '창 위치',
            style: FluentTheme.of(context).typography.subtitle,
          ),
          const SizedBox(height: 8.0),
          Row(
            children: [
              SizedBox(
                width: 160,
                child: InfoLabel(
                  label: 'X',
                  child: TextBox(
                    controller: _windowPosXController,
                  ),
                ),
              ),
              const SizedBox(
                width: 8.0,
              ),
              SizedBox(
                width: 160,
                child: InfoLabel(
                  label: 'Y',
                  child: TextBox(
                    controller: _windowPosYController,
                  ),
                ),
              ),
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
          onPressed: () {
            ref.read(storeProvider).updateOptionPreset(
                  OptionPreset(
                    id: widget.id,
                    name: _nameController.text,
                    windowWidth: int.parse(_windowWidthController.text),
                    windowHeight: int.parse(_windowHeightController.text),
                    windowPosX: int.parse(_windowPosXController.text),
                    windowPosY: int.parse(_windowPosYController.text),
                  ),
                );

            Navigator.pop(context);
          },
          child: const Text('저장'),
        ),
      ],
    );
  }
}
