import 'package:cartridge/main.dart';
import 'package:cartridge/providers/setting_provider.dart';
import 'package:cartridge/theme/theme.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart' as material;
import 'package:cartridge/l10n/app_localizations.dart';

class SettingDialog extends ConsumerStatefulWidget {
  const SettingDialog({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _SettingDialogState();
}

class _SettingDialogState extends ConsumerState<SettingDialog> {
  bool _isChanged = false;

  late TextEditingController _pathController;
  late TextEditingController _rerunDelayController;
  late String _selectedLanguageCode;
  late AppThemeKey _selectedThemeKey;

  @override
  void initState() {
    super.initState();

    final settings = ref.read(settingProvider);
    _pathController = TextEditingController(text: settings.isaacPath);
    _rerunDelayController =
        TextEditingController(text: settings.rerunDelay.toString());
    _selectedLanguageCode = settings.languageCode ?? 'ko';
    _selectedThemeKey = settings.themeKey;
  }

  @override
  void dispose() {
    _pathController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    String themeLabel(AppThemeKey k) => localizedThemeName(loc, k);

    return ContentDialog(
      title: Text(loc.setting_dialog_title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InfoLabel(
            label: loc.setting_isaac_path_label,
            child: TextBox(
              controller: _pathController,
              onChanged: (_) => setState(() => _isChanged = true),
            ),
          ),
          const SizedBox(height: 16.0),
          InfoLabel(
            label: loc.setting_rerun_delay_label,
            child: TextBox(
              controller: _rerunDelayController,
              onChanged: (_) => setState(() => _isChanged = true),
            ),
          ),
          const SizedBox(height: 16.0),
          InfoLabel(
            label: loc.setting_language_label,
            child: ComboBox<String>(
              value: _selectedLanguageCode,
              items: [
                ComboBoxItem(value: 'ko', child: Text(loc.setting_language_ko)),
                ComboBoxItem(value: 'en', child: Text(loc.setting_language_en)),
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
          const SizedBox(height: 16.0),InfoLabel(
            label: loc.setting_theme_label,
            child: ComboBox<AppThemeKey>(
              value: _selectedThemeKey,
              items: AppThemeKey.values.map((k) =>
                  ComboBoxItem(value: k, child: Text(themeLabel(k)))).toList(),
              onChanged: (value) {
                if (value == null) return;
                setState(() {
                  _selectedThemeKey = value;
                  _isChanged = true;
                });
              },
            ),
          ),
          const SizedBox(height: 16.0),
          Row(
            children: [
              Button(
                onPressed: () => material.showLicensePage(context: context),
                child: Text(loc.setting_license_button),
              ),
              const SizedBox(width: 8.0),
              Text('v$currentVersion'),
            ],
          ),
        ],
      ),
      actions: [
        Button(
          onPressed: () {
            Navigator.pop(context);
          },
          child: Text(loc.common_cancel),
        ),
        FilledButton(
          onPressed: _isChanged
              ? () {
                  final setting = ref.read(settingProvider);

                  setting.setIsaacPath(_pathController.text);
                  setting.setRerunDelay(
                    int.parse(_rerunDelayController.text),
                  );
                  setting.setLanguageCode(_selectedLanguageCode);
                  setting.setThemeKey(_selectedThemeKey);
                  setting.saveSetting();

                  Navigator.pop(context);
                }
              : null,
          child: Text(loc.common_save),
        ),
      ],
    );
  }
}
