import 'package:cartridge/components/save_button.dart';
import 'package:cartridge/main.dart';
import 'package:cartridge/pages/home/components/repentogon_settings_section.dart';
import 'package:cartridge/pages/home/components/sub_page_header.dart';
import 'package:cartridge/providers/repentogon_provider.dart';
import 'package:cartridge/providers/setting_provider.dart';
import 'package:cartridge/components/hotkey_input_field.dart';
import 'package:cartridge/ui/ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:cartridge/l10n/app_localizations.dart';

class SettingView extends ConsumerStatefulWidget {
  const SettingView({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _SettingViewState();
}

class _SettingViewState extends ConsumerState<SettingView> {
  bool _isChanged = false;

  late TextEditingController _pathController;
  late TextEditingController _rerunDelayController;
  late TextEditingController _musicTrackDelayController;
  late TextEditingController _playPauseHotkeyController;
  late TextEditingController _nextTrackHotkeyController;
  late TextEditingController _volumeUpHotkeyController;
  late TextEditingController _volumeDownHotkeyController;
  late TextEditingController _volumeStepController;
  late String _selectedLanguageCode;

  @override
  void initState() {
    super.initState();

    final settings = ref.read(settingProvider);
    _pathController = TextEditingController(text: settings.isaacPath);
    _rerunDelayController =
        TextEditingController(text: settings.rerunDelay.toString());
    _musicTrackDelayController =
        TextEditingController(text: settings.musicTrackDelay.toString());
    _playPauseHotkeyController =
        TextEditingController(text: settings.playPauseHotkey);
    _nextTrackHotkeyController =
        TextEditingController(text: settings.nextTrackHotkey);
    _volumeUpHotkeyController =
        TextEditingController(text: settings.volumeUpHotkey);
    _volumeDownHotkeyController =
        TextEditingController(text: settings.volumeDownHotkey);
    _volumeStepController = TextEditingController(
        text: (settings.volumeStepSize * 100).toStringAsFixed(0));
    _selectedLanguageCode = settings.languageCode ?? 'ko';
  }

  @override
  void dispose() {
    _pathController.dispose();
    _rerunDelayController.dispose();
    _musicTrackDelayController.dispose();
    _playPauseHotkeyController.dispose();
    _nextTrackHotkeyController.dispose();
    _volumeUpHotkeyController.dispose();
    _volumeDownHotkeyController.dispose();
    _volumeStepController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final c = AppColors.of(context);
    final musicTrackDelay = int.tryParse(_musicTrackDelayController.text);

    return Column(
      children: [
        SubPageHeader(
          title: loc.setting_dialog_title,
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppLabeled(
                  label: loc.setting_isaac_path_label,
                  child: AppTextField(
                    controller: _pathController,
                    mono: true,
                    onChanged: (_) => setState(() => _isChanged = true),
                  ),
                ),
                const SizedBox(height: 16.0),
                if (RepentogonNotifier.isSupported) ...[
                  const RepentogonSettingsSection(),
                  const SizedBox(height: 16.0),
                ],
                AppLabeled(
                  label: loc.setting_rerun_delay_label,
                  child: AppTextField(
                    controller: _rerunDelayController,
                    onChanged: (_) => setState(() => _isChanged = true),
                  ),
                ),
                const SizedBox(height: 16.0),
                AppLabeled(
                  label: loc.setting_music_track_delay_label,
                  child: AppTextField(
                    controller: _musicTrackDelayController,
                    placeholder: loc.setting_music_track_delay_hint,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    onChanged: (_) => setState(() => _isChanged = true),
                  ),
                ),
                if (musicTrackDelay == null)
                  Text(
                    loc.setting_music_track_delay_error,
                    style: TextStyle(color: c.danger),
                  ),
                const SizedBox(height: 16.0),
                AppLabeled(
                  label: loc.setting_language_label,
                  child: AppSelect<String>(
                    value: _selectedLanguageCode,
                    items: [
                      AppSelectItem(
                          value: 'ko', child: Text(loc.setting_language_ko)),
                      AppSelectItem(
                          value: 'en', child: Text(loc.setting_language_en)),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _selectedLanguageCode = value;
                          _isChanged = true;
                        });
                      }
                    },
                  ),
                ),
                const SizedBox(height: 16.0),
                AppLabeled(
                  label: loc.setting_theme_label,
                  child: AppSegmented<ThemeMode>(
                    value: ref.watch(settingProvider).themeMode,
                    segments: [
                      AppSegment(
                          value: ThemeMode.light,
                          label: loc.setting_theme_light),
                      AppSegment(
                          value: ThemeMode.dark, label: loc.setting_theme_dark),
                      AppSegment(
                          value: ThemeMode.system,
                          label: loc.setting_theme_system),
                    ],
                    onChanged: (mode) {
                      final setting = ref.read(settingProvider);
                      setting.themeMode = mode;
                      setting.saveSetting();
                    },
                  ),
                ),
                const SizedBox(height: 24.0),
                Text(
                  loc.setting_hotkey_section,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8.0),
                AppLabeled(
                  label: loc.setting_hotkey_play_pause_label,
                  child: HotkeyInputField(
                    controller: _playPauseHotkeyController,
                    placeholder: loc.setting_hotkey_hint,
                    onChanged: () => setState(() => _isChanged = true),
                  ),
                ),
                const SizedBox(height: 16.0),
                AppLabeled(
                  label: loc.setting_hotkey_next_track_label,
                  child: HotkeyInputField(
                    controller: _nextTrackHotkeyController,
                    placeholder: loc.setting_hotkey_hint,
                    onChanged: () => setState(() => _isChanged = true),
                  ),
                ),
                const SizedBox(height: 16.0),
                AppLabeled(
                  label: loc.setting_hotkey_volume_up_label,
                  child: HotkeyInputField(
                    controller: _volumeUpHotkeyController,
                    placeholder: loc.setting_hotkey_hint,
                    onChanged: () => setState(() => _isChanged = true),
                  ),
                ),
                const SizedBox(height: 16.0),
                AppLabeled(
                  label: loc.setting_hotkey_volume_down_label,
                  child: HotkeyInputField(
                    controller: _volumeDownHotkeyController,
                    placeholder: loc.setting_hotkey_hint,
                    onChanged: () => setState(() => _isChanged = true),
                  ),
                ),
                const SizedBox(height: 16.0),
                AppLabeled(
                  label: loc.setting_hotkey_volume_step_label,
                  child: AppTextField(
                    controller: _volumeStepController,
                    placeholder: loc.setting_hotkey_volume_step_hint,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    onChanged: (_) => setState(() => _isChanged = true),
                  ),
                ),
                const SizedBox(height: 16.0),
                Row(
                  children: [
                    AppButton(
                      onPressed: () => showLicensePage(context: context),
                      child: Text(loc.setting_license_button),
                    ),
                    const SizedBox(width: 8.0),
                    Text('v${packageInfo.version}'),
                  ],
                ),
              ],
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: c.surface1,
            boxShadow: [
              BoxShadow(
                color: c.line,
                blurRadius: 2,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              spacing: 4,
              children: [
                SaveButton(
                  onPressed: _isChanged && musicTrackDelay != null
                      ? () {
                          final musicTrackDelay =
                              int.tryParse(_musicTrackDelayController.text);
                          if (!_isChanged || musicTrackDelay == null) return;
                          final setting = ref.read(settingProvider);

                          setting.updateSettings(
                            isaacPath: _pathController.text,
                            rerunDelay: int.parse(_rerunDelayController.text),
                            musicTrackDelay: musicTrackDelay,
                            languageCode: _selectedLanguageCode,
                            playPauseHotkey: _playPauseHotkeyController.text,
                            nextTrackHotkey: _nextTrackHotkeyController.text,
                            volumeUpHotkey: _volumeUpHotkeyController.text,
                            volumeDownHotkey: _volumeDownHotkeyController.text,
                            volumeStepSize:
                                double.parse(_volumeStepController.text) / 100,
                          );
                          setting.saveSetting();

                          setState(() => _isChanged = false);
                        }
                      : null,
                  child: Text(loc.common_save),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
