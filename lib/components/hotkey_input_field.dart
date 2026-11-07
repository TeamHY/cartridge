import 'package:cartridge/components/dialogs/hotkey_record_dialog.dart';
import 'package:cartridge/ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class HotkeyInputField extends StatelessWidget {
  final TextEditingController controller;
  final String placeholder;
  final VoidCallback onChanged;

  const HotkeyInputField({
    super.key,
    required this.controller,
    required this.placeholder,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: AppTextField(
            controller: controller,
            placeholder: placeholder,
            mono: true,
            onChanged: (_) => onChanged(),
          ),
        ),
        const SizedBox(width: 8),
        AppIconButton(
          icon: const PhosphorIcon(PhosphorIconsFill.record),
          iconSize: 20,
          onPressed: () async {
            final result = await showAppDialog<String>(
              context: context,
              builder: (context) => HotkeyRecordDialog(
                initialHotkey: controller.text,
              ),
            );
            if (result != null) {
              controller.text = result;
              onChanged();
            }
          },
        ),
      ],
    );
  }
}
