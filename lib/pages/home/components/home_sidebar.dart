import 'package:cartridge/models/preset.dart';
import 'package:cartridge/pages/home/components/music_player_controller.dart';
import 'package:cartridge/pages/home/components/preset_creation_bar.dart';
import 'package:cartridge/pages/home/components/preset_list.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class HomeSidebar extends ConsumerWidget {
  final TextEditingController presetNameController;
  final TextEditingController editPresetNameController;
  final Preset? selectedPreset;
  final bool isMusicPlayerSelected;
  final Function(Preset) onSelectPreset;
  final Function(Preset) onDeletePreset;
  final VoidCallback? onDeselectPreset;
  final VoidCallback? onMusicPlayerTap;

  const HomeSidebar({
    super.key,
    required this.presetNameController,
    required this.editPresetNameController,
    required this.selectedPreset,
    required this.isMusicPlayerSelected,
    required this.onSelectPreset,
    required this.onDeletePreset,
    required this.onDeselectPreset,
    required this.onMusicPlayerTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.all(8.0).copyWith(right: 4.0),
      child: Column(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: onDeselectPreset,
              child: PresetList(
                selectedPreset: selectedPreset,
                onSelect: onSelectPreset,
                onDelete: onDeletePreset,
              ),
            ),
          ),
          const SizedBox(height: 8),
          PresetCreationBar(controller: presetNameController),
          const SizedBox(height: 8),
          MusicPlayer(
              isSelected: isMusicPlayerSelected, onTap: onMusicPlayerTap),
        ],
      ),
    );
  }
}
