import 'package:cartridge/main.dart';
import 'package:cartridge/pages/home/components/sub_page_header.dart';
import 'package:cartridge/providers/setting_provider.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart' as material;
import 'package:cartridge/l10n/app_localizations.dart';

class SettingView extends ConsumerStatefulWidget {
  final VoidCallback? onBackPressed;

  const SettingView({super.key, this.onBackPressed});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _SettingViewState();
}

class _SettingViewState extends ConsumerState<SettingView> {
  bool _isChanged = false;

  late TextEditingController _pathController;
  late TextEditingController _rerunDelayController;
  late String _selectedLanguageCode;

  @override
  void initState() {
    super.initState();

    final settings = ref.read(settingProvider);
    _pathController = TextEditingController(text: settings.isaacPath);
    _rerunDelayController =
        TextEditingController(text: settings.rerunDelay.toString());
    _selectedLanguageCode = settings.languageCode ?? 'ko';
  }

  @override
  void dispose() {
    _pathController.dispose();
    _rerunDelayController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);

    return Column(
      children: [
        SubPageHeader(
          title: loc.setting_dialog_title,
          onBackPressed: widget.onBackPressed,
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
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
                      ComboBoxItem(
                          value: 'ko', child: Text(loc.setting_language_ko)),
                      ComboBoxItem(
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
                Row(
                  children: [
                    Button(
                      onPressed: () =>
                          material.showLicensePage(context: context),
                      child: Text(loc.setting_license_button),
                    ),
                    const SizedBox(width: 8.0),
                    Text('v$currentVersion'),
                  ],
                ),
              ],
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
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              spacing: 4,
              children: [
                FilledButton(
                  onPressed: _isChanged
                      ? () {
                          final setting = ref.read(settingProvider);

                          setting.isaacPath = _pathController.text;
                          setting.rerunDelay =
                              int.parse(_rerunDelayController.text);
                          setting.languageCode = _selectedLanguageCode;
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
