import 'package:cartridge/models/preset.dart';
import 'package:cartridge/models/mod.dart';
import 'package:cartridge/providers/store_provider.dart';
import 'package:cartridge/l10n/app_localizations.dart';
import 'package:cartridge/ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class PresetCreationBar extends ConsumerWidget {
  final TextEditingController controller;

  const PresetCreationBar({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final store = ref.watch(storeProvider);
    final loc = AppLocalizations.of(context);

    void onSubmit(String value) {
      store.addPreset(
        Preset(
          name: controller.value.text != ''
              ? controller.value.text
              : loc.home_preset_placeholder,
          mods: store.currentMods
              .map((mod) => Mod.fromJson(mod.toJson()))
              .toList(),
        ),
      );

      controller.clear();
    }

    return Row(
      children: [
        Flexible(
          child: AppTextField(
            controller: controller,
            onSubmitted: (value) => onSubmit(value),
            placeholder: loc.home_preset_placeholder,
          ),
        ),
        const SizedBox(width: 4),
        AppIconButton(
          icon: const PhosphorIcon(PhosphorIconsRegular.plus),
          onPressed: () => onSubmit(controller.value.text),
        ),
      ],
    );
  }
}
