import 'package:cartridge/providers/store_provider.dart';
import 'package:cartridge/components/layout.dart';
import 'package:cartridge/pages/home/components/preset_list.dart';
import 'package:cartridge/pages/home/components/preset_creation_bar.dart';
import 'package:cartridge/pages/home/components/home_navigation_bar.dart';
import 'package:cartridge/pages/home/components/preset_edit_view.dart';
import 'package:cartridge/services/version_checker.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:cartridge/models/preset.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cartridge/l10n/app_localizations.dart';

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

    return Layout(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 300,
            child: Column(
              children: [
                Expanded(
                  child: PresetList(
                    selectedPreset: _selectedPreset,
                    onSelect: (preset) => setState(() {
                      _selectedPreset = preset;
                      _editPresetNameController.text = preset.name;
                      _isPresetEditing = true;
                    }),
                    onDelete: (preset) {
                      setState(() {
                        store.presets.remove(preset);
                        store.savePresets();
                        if (_selectedPreset?.name == preset.name) {
                          _selectedPreset = null;
                          _isPresetEditing = false;
                        }
                      });
                    },
                  ),
                ),
                PresetCreationBar(controller: _presetNameController),
                const HomeNavigationBar(),
              ],
            ),
          ),
          Expanded(
            child: Container(
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
                  : _buildNormalView(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNormalView() {
    final loc = AppLocalizations.of(context);

    return Column(
      children: [
        Expanded(
          child: Center(
            child: Text(
              loc.preset_edit_select_message,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.grey.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 2,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: const SizedBox(
            width: double.infinity,
            height: 60,
          ),
        )
      ],
    );
  }
}
