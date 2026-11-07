import 'package:cartridge/providers/store_provider.dart';
import 'package:cartridge/providers/hotkey_provider.dart';
import 'package:cartridge/providers/repentogon_provider.dart';
import 'package:cartridge/components/app_icon.dart';
import 'package:cartridge/components/layout.dart';
import 'package:cartridge/components/nav_rail.dart';
import 'package:cartridge/components/theme_rail_button.dart';
import 'package:cartridge/l10n/app_localizations.dart';
import 'package:cartridge/pages/quiz/quiz_page.dart';
import 'package:cartridge/pages/record/record_page.dart';
import 'package:cartridge/pages/slot_machine/slot_machine_page.dart';
import 'package:cartridge/pages/home/components/home_sidebar.dart';
import 'package:cartridge/pages/home/views/home_main_view.dart';
import 'package:cartridge/pages/home/views/preset_edit_view.dart';
import 'package:cartridge/pages/home/views/music_view.dart';
import 'package:cartridge/pages/home/views/isaac_options_view.dart';
import 'package:cartridge/pages/home/views/save_apply_view.dart';
import 'package:cartridge/pages/home/views/setting_view.dart';
import 'package:cartridge/services/auto_updater.dart';
import 'package:cartridge/ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:cartridge/models/preset.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:multi_split_view/multi_split_view.dart';

enum HomeView {
  main,
  presetEdit,
  music,
  saveApply,
  isaacOptions,
  setting,
  record,
  slotMachine,
  quiz,
}

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  late TextEditingController _presetNameController;
  late TextEditingController _searchController;
  late TextEditingController _editPresetNameController;
  Preset? _selectedPreset;
  HomeView _currentView = HomeView.main;

  @override
  void initState() {
    super.initState();

    _presetNameController = TextEditingController();
    _searchController = TextEditingController();
    _editPresetNameController = TextEditingController();
    _searchController.addListener(() {
      setState(() {});
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(hotkeyProvider);
      ref.read(repentogonProvider).refreshIfInstalled(checkUpdates: true);
    });

    AutoUpdater.checkAndUpdate(context);
  }

  @override
  void dispose() {
    _presetNameController.dispose();
    _searchController.dispose();
    _editPresetNameController.dispose();

    super.dispose();
  }

  void _goHome() => setState(() {
        _selectedPreset = null;
        _currentView = HomeView.main;
      });

  void _showView(HomeView view) => setState(() {
        _selectedPreset = null;
        _currentView = view;
      });

  Widget _buildContent() {
    final store = ref.read(storeProvider);

    return switch (_currentView) {
      HomeView.main => HomeMainView(
          onRecordPressed: () => _showView(HomeView.record),
          onSlotMachinePressed: () => _showView(HomeView.slotMachine),
          onQuizPressed: () => _showView(HomeView.quiz),
          onSaveApplyPressed: () => _showView(HomeView.saveApply),
          onIsaacOptionsPressed: () => _showView(HomeView.isaacOptions),
        ),
      HomeView.music => const MusicView(),
      HomeView.saveApply => const SaveApplyView(),
      HomeView.isaacOptions => const IsaacOptionsView(),
      HomeView.setting => const SettingView(),
      HomeView.record => const RecordPage(),
      HomeView.slotMachine => const SlotMachinePage(),
      HomeView.quiz => const QuizPage(),
      HomeView.presetEdit => _selectedPreset != null
          ? PresetEditView(
              selectedPreset: _selectedPreset!,
              editPresetNameController: _editPresetNameController,
              searchController: _searchController,
              onBackPressed: _goHome,
              onCancel: _goHome,
              onSave: (selectedGameConfigId, launchMode, mods) {
                _selectedPreset!.gameConfigId = selectedGameConfigId;
                _selectedPreset!.launchMode = launchMode;
                _selectedPreset!.mods = mods;
                store.savePresets();
                setState(() => _currentView = HomeView.main);
              },
            )
          : const HomeMainView(),
    };
  }

  Widget _buildPresetSplit() {
    return MultiSplitViewTheme(
      data: MultiSplitViewThemeData(dividerThickness: 4),
      child: MultiSplitView(
        initialAreas: [
          Area(
            builder: (context, size) => HomeSidebar(
              presetNameController: _presetNameController,
              editPresetNameController: _editPresetNameController,
              selectedPreset: _selectedPreset,
              onSelectPreset: (preset) => setState(() {
                _selectedPreset = preset;
                _editPresetNameController.text = preset.name;
                _currentView = HomeView.presetEdit;
              }),
              onDeletePreset: (preset) => setState(() {
                ref.read(storeProvider).removePreset(preset);
                if (_selectedPreset?.name == preset.name) {
                  _selectedPreset = null;
                  _currentView = HomeView.main;
                }
              }),
              onDeselectPreset: _goHome,
            ),
            size: 300,
          ),
          Area(
            builder: (context, size) => DecoratedBox(
              decoration: BoxDecoration(
                border: Border(
                  left: BorderSide(color: AppColors.of(context).line),
                ),
              ),
              child: _buildContent(),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(storeProvider);
    final loc = AppLocalizations.of(context);
    final showPresetList =
        _currentView == HomeView.main || _currentView == HomeView.presetEdit;

    NavRailItem item(AppIcons icon, String label, HomeView view) => NavRailItem(
          icon: icon,
          label: label,
          selected: _currentView == view,
          onPressed: () => _showView(view),
        );

    return Layout(
      onHomePressed: _goHome,
      onSettingPressed: () => setState(() => _currentView = HomeView.setting),
      onMusicPressed: () => _showView(HomeView.music),
      navigation: NavRail(
        footer: const ThemeRailButton(),
        items: [
          NavRailItem(
            icon: AppIcons.cartridge,
            label: loc.nav_presets,
            selected: showPresetList,
            onPressed: _goHome,
          ),
          item(AppIcons.music, loc.nav_music, HomeView.music),
          item(AppIcons.trophy, loc.home_button_record.replaceAll('\n', ' '),
              HomeView.record),
          item(AppIcons.slot, loc.home_button_slot_machine,
              HomeView.slotMachine),
          item(AppIcons.quiz, loc.home_button_quiz, HomeView.quiz),
          item(AppIcons.memoryCard, loc.nav_all_clear_save, HomeView.saveApply),
          item(AppIcons.sliders, loc.setting_isaac_options_section,
              HomeView.isaacOptions),
        ],
      ),
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: AppColors.of(context).surface2,
          border: Border.all(color: AppColors.of(context).line),
          borderRadius: const BorderRadius.only(topLeft: Radius.circular(8)),
        ),
        child: showPresetList ? _buildPresetSplit() : _buildContent(),
      ),
    );
  }
}
