import 'package:cartridge/models/preset.dart';
import 'package:cartridge/models/mod.dart';
import 'package:cartridge/providers/store_provider.dart';
import 'package:cartridge/l10n/app_localizations.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Flexible(
            child: TextBox(
              controller: controller,
              placeholder: loc.home_preset_placeholder,
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(FluentIcons.add),
            onPressed: () {
              store.presets.add(
                Preset(
                  name: controller.value.text != ''
                      ? controller.value.text
                      : loc.home_preset_placeholder,
                  mods: store.currentMods
                      .map((mod) => Mod.fromJson(mod.toJson()))
                      .toList(),
                ),
              );
              store.savePresets();
            },
          ),
        ],
      ),
    );
  }
}
