import 'package:cartridge/models/preset.dart';
import 'package:cartridge/pages/home/components/preset_item.dart';
import 'package:cartridge/providers/store_provider.dart';
import 'package:cartridge/l10n/app_localizations.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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

    if (store.presets.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                FluentIcons.playlist_music,
                size: 48,
                color: Colors.grey.withValues(alpha: 0.5),
              ),
              const SizedBox(height: 16),
              Text(
                loc.preset_edit_no_presets,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                loc.preset_edit_create_new,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.withValues(alpha: 0.6),
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
      onReorder: (oldIndex, newIndex) {
        if (oldIndex < newIndex) {
          newIndex -= 1;
        }
        final item = store.presets.removeAt(oldIndex);
        store.presets.insert(newIndex, item);
      },
    );
  }
}
