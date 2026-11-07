import 'package:cartridge/models/preset.dart';
import 'package:cartridge/pages/home/components/preset_item.dart';
import 'package:cartridge/providers/store_provider.dart';
import 'package:cartridge/l10n/app_localizations.dart';
import 'package:cartridge/ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class PresetList extends ConsumerWidget {
  final Preset? selectedPreset;
  final Function(Preset) onSelect;
  final Function(Preset) onDelete;

  const PresetList({
    super.key,
    required this.selectedPreset,
    required this.onSelect,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final store = ref.watch(storeProvider);
    final loc = AppLocalizations.of(context);
    final c = AppColors.of(context);

    if (store.presets.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              PhosphorIcon(
                PhosphorIconsRegular.playlist,
                size: 48,
                color: c.lineStrong,
              ),
              const SizedBox(height: 16),
              Text(
                loc.preset_edit_no_presets,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: c.ink3,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                loc.preset_edit_create_new,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: c.ink3,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ReorderableListView.builder(
      buildDefaultDragHandles: false,
      itemCount: store.presets.length,
      itemBuilder: (context, index) => ReorderableDragStartListener(
        key: ValueKey(store.presets[index]),
        index: index,
        child: PresetItem(
          preset: store.presets[index],
          isSelected: selectedPreset == store.presets[index],
          onTap: () => onSelect(store.presets[index]),
          onApply: (Preset preset) async {
            store.selectGameConfig(preset.gameConfigId);
            store.applyPreset(preset);
          },
          onDelete: onDelete,
          onEdit: onSelect,
        ),
      ),
      onReorder: store.movePreset,
    );
  }
}
