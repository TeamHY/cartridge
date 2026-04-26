import 'package:cartridge/pages/home/components/sub_page_header.dart';
import 'package:cartridge/services/isaac_config_service.dart';
import 'package:cartridge/l10n/app_localizations.dart';
import 'package:fluent_ui/fluent_ui.dart';

class _OptionDef {
  final String key;
  final String label;
  final _OptionType type;
  final String? section;

  const _OptionDef(this.key, this.label, this.type, {this.section});
}

enum _OptionType { toggle, number, decimal }

const _options = [
  _OptionDef('EnableMods', 'Enable Mods', _OptionType.toggle,
      section: 'general'),
  _OptionDef('EnableDebugConsole', 'Debug Console', _OptionType.toggle,
      section: 'general'),
  _OptionDef('MouseControl', 'Mouse Control', _OptionType.toggle,
      section: 'general'),
  _OptionDef('Fullscreen', 'Fullscreen', _OptionType.toggle,
      section: 'display'),
  _OptionDef('Filter', 'Filter', _OptionType.toggle, section: 'display'),
  _OptionDef('VSync', 'VSync', _OptionType.toggle, section: 'display'),
  _OptionDef('MaxScale', 'Max Scale', _OptionType.number, section: 'display'),
  _OptionDef('MaxRenderScale', 'Max Render Scale', _OptionType.number,
      section: 'display'),
  _OptionDef('Exposure', 'Exposure', _OptionType.decimal, section: 'display'),
  _OptionDef('Gamma', 'Gamma', _OptionType.decimal, section: 'display'),
  _OptionDef('MusicEnabled', 'Music Enabled', _OptionType.toggle,
      section: 'audio'),
  _OptionDef('MusicVolume', 'Music Volume', _OptionType.decimal,
      section: 'audio'),
  _OptionDef('SFXVolume', 'SFX Volume', _OptionType.decimal, section: 'audio'),
  _OptionDef('PopUps', 'Pop-Ups', _OptionType.toggle, section: 'gameplay'),
  _OptionDef('CameraStyle', 'Camera Style', _OptionType.number,
      section: 'gameplay'),
  _OptionDef('ChargeBars', 'Charge Bars', _OptionType.toggle,
      section: 'gameplay'),
  _OptionDef('FoundHUD', 'Found HUD', _OptionType.toggle, section: 'gameplay'),
  _OptionDef('HudOffset', 'HUD Offset', _OptionType.decimal,
      section: 'gameplay'),
  _OptionDef('MapOpacity', 'Map Opacity', _OptionType.decimal,
      section: 'gameplay'),
  _OptionDef('BulletVisibility', 'Bullet Visibility', _OptionType.toggle,
      section: 'gameplay'),
  _OptionDef('ShowRecentItems', 'Show Recent Items', _OptionType.number,
      section: 'gameplay'),
  _OptionDef('BossHpOnBottom', 'Boss HP on Bottom', _OptionType.toggle,
      section: 'gameplay'),
  _OptionDef('ItemInfoDisplayEnabled', 'Item Info Display', _OptionType.toggle,
      section: 'gameplay'),
  _OptionDef('AimLock', 'Aim Lock', _OptionType.toggle, section: 'input'),
  _OptionDef('ControllerHotplug', 'Controller Hotplug', _OptionType.toggle,
      section: 'input'),
  _OptionDef('RumbleEnabled', 'Rumble', _OptionType.toggle, section: 'input'),
  _OptionDef('TouchMode', 'Touch Mode', _OptionType.toggle, section: 'input'),
  _OptionDef('JacobEsauControls', 'Jacob & Esau Controls', _OptionType.toggle,
      section: 'input'),
  _OptionDef('PauseOnFocusLost', 'Pause on Focus Lost', _OptionType.toggle,
      section: 'misc'),
  _OptionDef('SteamCloud', 'Steam Cloud', _OptionType.toggle, section: 'misc'),
  _OptionDef('AnnouncerVoiceMode', 'Announcer Voice Mode', _OptionType.number,
      section: 'misc'),
  _OptionDef('AscentVoiceOver', 'Ascent Voice Over', _OptionType.toggle,
      section: 'misc'),
  _OptionDef('ConsoleFont', 'Console Font', _OptionType.number,
      section: 'misc'),
  _OptionDef('FadedConsoleDisplay', 'Faded Console Display', _OptionType.toggle,
      section: 'misc'),
  _OptionDef('SaveCommandHistory', 'Save Command History', _OptionType.toggle,
      section: 'misc'),
  _OptionDef('StreamerMode', 'Streamer Mode', _OptionType.toggle,
      section: 'misc'),
];

const _sectionOrder = [
  'general',
  'display',
  'audio',
  'gameplay',
  'input',
  'misc'
];

Map<String, String> _getSectionLabels(AppLocalizations loc) => {
      'general': loc.setting_isaac_options_section_general,
      'display': loc.setting_isaac_options_section_display,
      'audio': loc.setting_isaac_options_section_audio,
      'gameplay': loc.setting_isaac_options_section_gameplay,
      'input': loc.setting_isaac_options_section_input,
      'misc': loc.setting_isaac_options_section_misc,
    };

class IsaacOptionsView extends StatefulWidget {
  final VoidCallback? onBackPressed;

  const IsaacOptionsView({super.key, this.onBackPressed});

  @override
  State<IsaacOptionsView> createState() => _IsaacOptionsViewState();
}

class _IsaacOptionsViewState extends State<IsaacOptionsView> {
  List<IsaacEdition> _editions = [];
  IsaacEdition? _selectedEdition;
  Map<String, String> _values = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadEditions();
  }

  Future<void> _loadEditions() async {
    final editions = await IsaacConfigService.getAvailableEditions();
    setState(() {
      _editions = editions;
      _selectedEdition = editions.isNotEmpty ? editions.last : null;
      _loading = false;
    });
    if (_selectedEdition != null) {
      _loadValues(_selectedEdition!);
    }
  }

  Future<void> _loadValues(IsaacEdition edition) async {
    final values = await IsaacConfigService.getAllOptions(edition);
    setState(() {
      _values = values;
    });
  }

  Future<void> _setOption(String key, String value) async {
    if (_selectedEdition == null) return;
    await IsaacConfigService.setOption(_selectedEdition!, key, value);
    setState(() {
      _values[key] = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final sectionLabels = _getSectionLabels(loc);

    return Container(
      color: Colors.white,
      child: Column(
        children: [
          SubPageHeader(
            title: loc.setting_isaac_options_section,
            onBackPressed: widget.onBackPressed,
          ),
          if (_loading)
            const Expanded(child: Center(child: ProgressRing()))
          else if (_editions.isEmpty)
            Expanded(
              child: Center(child: Text(loc.setting_isaac_options_not_found)),
            )
          else ...[
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
              child: Row(
                children: _editions.map((edition) {
                  final isSelected = edition == _selectedEdition;
                  final label = edition == IsaacEdition.repentancePlus
                      ? loc.setting_isaac_options_repentance_plus
                      : loc.setting_isaac_options_repentance;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ToggleButton(
                      checked: isSelected,
                      onChanged: (_) {
                        setState(() => _selectedEdition = edition);
                        _loadValues(edition);
                      },
                      child: Text(label),
                    ),
                  );
                }).toList(),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16.0),
                children: _buildSections(sectionLabels),
              ),
            ),
          ],
        ],
      ),
    );
  }

  List<Widget> _buildSections(Map<String, String> sectionLabels) {
    final widgets = <Widget>[];
    for (final section in _sectionOrder) {
      final sectionOptions =
          _options.where((o) => o.section == section).toList();
      if (sectionOptions.isEmpty) continue;

      final visibleOptions =
          sectionOptions.where((o) => _values.containsKey(o.key)).toList();
      if (visibleOptions.isEmpty) continue;

      widgets.add(Padding(
        padding: const EdgeInsets.only(top: 12.0, bottom: 6.0),
        child: Text(
          sectionLabels[section] ?? section,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ));

      for (final opt in visibleOptions) {
        widgets.add(_buildOptionRow(opt, _values[opt.key]!));
      }
    }
    return widgets;
  }

  Widget _buildOptionRow(_OptionDef opt, String value) {
    switch (opt.type) {
      case _OptionType.toggle:
        final boolValue = value.trim() == '1';
        return SizedBox(
          height: 40,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(opt.label),
                ToggleSwitch(
                  checked: boolValue,
                  onChanged: (v) => _setOption(opt.key, v ? '1' : '0'),
                ),
              ],
            ),
          ),
        );
      case _OptionType.number:
      case _OptionType.decimal:
        return SizedBox(
          height: 40,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(opt.label),
                SizedBox(
                  width: 80,
                  child: TextBox(
                    controller: TextEditingController(text: value.trim()),
                    keyboardType: opt.type == _OptionType.decimal
                        ? const TextInputType.numberWithOptions(decimal: true)
                        : TextInputType.number,
                    onSubmitted: (v) => _setOption(opt.key, v),
                  ),
                ),
              ],
            ),
          ),
        );
    }
  }
}
