import 'package:flutter/material.dart';
import 'package:cartridge/features/cartridge/mod_presets/presentation/pages/mod_presets_list_page.dart';
import 'package:cartridge/features/cartridge/mod_presets/presentation/pages/mod_preset_detail_page.dart';

class ModPresetsTab extends StatefulWidget {
  const ModPresetsTab({super.key});

  @override
  State<ModPresetsTab> createState() => _ModPresetsTabState();
}

class _ModPresetsTabState extends State<ModPresetsTab> {
  String? selectedPresetId;
  String? selectedPresetName;

  void openDetail(String presetId, String presetName) {
    setState(() {
      selectedPresetId = presetId;
      selectedPresetName = presetName;
    });
  }

  void goBack() {
    setState(() {
      selectedPresetId = null;
      selectedPresetName = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (selectedPresetId != null) {
      return ModPresetDetailPage(
        presetId: selectedPresetId!,
        presetName: selectedPresetName!,
        onBack: goBack,
      );
    } else {
      return ModPresetsListPage(onSelect: openDetail);
    }
  }
}
