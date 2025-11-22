import 'package:cartridge/providers/store_provider.dart';
import 'package:cartridge/components/layout.dart';
import 'package:cartridge/pages/home/components/home_sidebar.dart';
import 'package:cartridge/pages/home/components/home_main_view.dart';
import 'package:cartridge/pages/home/components/preset_edit_view.dart';
import 'package:cartridge/services/version_checker.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:cartridge/models/preset.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:multi_split_view/multi_split_view.dart';

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
  bool _isPresetEditing = false;

  @override
  void initState() {
    super.initState();

    _presetNameController = TextEditingController();
    _searchController = TextEditingController();
    _editPresetNameController = TextEditingController();
    _searchController.addListener(() {
      setState(() {});
    });

    VersionChecker.checkAppVersion(context);
  }

  @override
  void dispose() {
    _presetNameController.dispose();
    _searchController.dispose();
    _editPresetNameController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = ref.watch(storeProvider);

    void onHomePressed() {
      setState(() {
        _selectedPreset = null;
        _isPresetEditing = false;
      });
    }

    return Layout(
      onHomePressed: onHomePressed,
      child: MultiSplitViewTheme(
        data: MultiSplitViewThemeData(
          dividerThickness: 4,
        ),
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
                  _isPresetEditing = true;
                }),
                onDeletePreset: (preset) {
                  setState(() {
                    store.presets.remove(preset);
                    store.savePresets();
                    if (_selectedPreset?.name == preset.name) {
                      _selectedPreset = null;
                      _isPresetEditing = false;
                    }
                  });
                },
                onDeselectPreset: onHomePressed,
              ),
              size: 300,
            ),
            Area(
              builder: (context, size) => Container(
                decoration: BoxDecoration(
                  color: FluentTheme.of(context).cardColor,
                  border: Border.all(
                      color: Colors.black.withValues(alpha: 0.1), width: 1),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(4.0),
                  ),
                ),
                child: _isPresetEditing && _selectedPreset != null
                    ? PresetEditView(
                        selectedPreset: _selectedPreset!,
                        editPresetNameController: _editPresetNameController,
                        searchController: _searchController,
                        onCancel: () => setState(() {
                          _isPresetEditing = false;
                          _selectedPreset = null;
                        }),
                        onSave: (mods) {
                          _selectedPreset!.mods = mods;
                          store.savePresets();
                          setState(() {
                            _isPresetEditing = false;
                          });
                        },
                      )
                    : const HomeMainView(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
