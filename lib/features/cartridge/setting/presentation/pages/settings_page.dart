import 'package:file_selector/file_selector.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/material.dart' as material;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

import 'package:cartridge/app/presentation/content_scaffold.dart';
import 'package:cartridge/app/presentation/desktop_grid.dart';
import 'package:cartridge/app/presentation/widgets/ui_feedback.dart';
import 'package:cartridge/core/service_providers.dart';
import 'package:cartridge/features/cartridge/setting/setting.dart';
import 'package:cartridge/features/isaac/runtime/isaac_runtime.dart';
import 'package:cartridge/l10n/app_localizations.dart';
import 'package:cartridge/main.dart';
import 'package:cartridge/theme/theme.dart';


class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _pathController;
  late final TextEditingController _optionIniController;
  late final TextEditingController _rerunDelayController;

  bool _isChanged = false; // 사용자가 편집 중일 때는 외부(state) 변경으로 폼 덮어쓰지 않음
  String _selectedLanguageCode = 'ko';
  AppThemeKey _selectedTheme = AppThemeKey.system;
  int _rerunDelay = 1000;
  bool _autoInstall = true;
  bool _autoOptionsIni = true;

  @override
  void initState() {
    super.initState();
    _pathController = TextEditingController();
    _optionIniController = TextEditingController();
    _rerunDelayController = TextEditingController();
    ref.read(appSettingControllerProvider).whenData(_applyFrom);
  }

  @override
  void dispose() {
    _pathController.dispose();
    _optionIniController.dispose();
    _rerunDelayController.dispose();
    super.dispose();
  }

  // 모델 → 폼
  void _applyFrom(AppSetting s) {
    _pathController.text = s.isaacPath;
    _optionIniController.text = s.optionsIniPath;
    _selectedLanguageCode = s.languageCode;
    _selectedTheme = _parseThemeKey(s.themeName);
    _rerunDelay = s.rerunDelay;
    _rerunDelayController.text = _rerunDelay.toString();
    _autoInstall = s.useAutoDetectInstallPath;
    _autoOptionsIni = s.useAutoDetectOptionsIni;
  }

  AppThemeKey _parseThemeKey(String? name) {
    if (name == null) return AppThemeKey.system;
    for (final k in AppThemeKey.values) {
      if (k.name == name) return k;
    }
    return AppThemeKey.system;
  }

  void _markDirty() {
    if (!_isChanged && mounted) setState(() => _isChanged = true);
  }

  Future<void> _openGameProperties() =>
      ref.read(appSettingPageControllerProvider).openGameProperties();

  Future<void> _runIntegrityCheck() =>
      ref.read(appSettingPageControllerProvider).runIntegrityCheck();

  // 설치 경로 자동 탐지
  Future<void> _detectIsaacPathFromSteam() async {
    final found = await ref.read(appSettingPageControllerProvider).detectInstallPath();
    if (!mounted) return;
    final loc = AppLocalizations.of(context);
    if (found == null) {
      UiFeedback.warn(context, loc.setting_detect_path_fail_title, loc.setting_detect_path_fail_desc);
      return;
    }
    setState(() { _pathController.text = found; _isChanged = true; });
    UiFeedback.success(context, loc.setting_detect_path_success_title, found);
    FocusScope.of(context).unfocus();
  }

  // options.ini 자동 탐지
  Future<void> _detectOptionsIniPathFromSteam() async {
    final found = await ref.read(appSettingPageControllerProvider).detectOptionsIniPath();
    if (!mounted) return;
    final loc = AppLocalizations.of(context);
    if (found == null) {
      UiFeedback.warn(
        context,
        loc.setting_detect_options_ini_fail_title,
        loc.setting_detect_options_ini_fail_desc,
      );
      return;
    }
    setState(() { _optionIniController.text = found; _isChanged = true; });
    UiFeedback.success(context, loc.setting_detect_path_success_title, found);
  }

  // 되돌리기(현재 보유 상태로)
  void _revert() {
    final st = ref.read(appSettingControllerProvider);
    st.whenData((s) {
      if (!mounted) return;
      setState(() { _applyFrom(s); _isChanged = false; });
      FocusScope.of(context).unfocus();
    });
  }

  Future<void> _browseIsaacPath() async {
    final loc = AppLocalizations.of(context);
    final picked = await getDirectoryPath(
      initialDirectory: _pathController.text.isNotEmpty ? _pathController.text : null,
      confirmButtonText: loc.common_select,
    );
    if (!mounted) return;
    if (picked != null && picked.trim().isNotEmpty) {
      setState(() { _pathController.text = picked; _isChanged = true; });
    }
  }

  Future<void> _browseOptionsIniPath() async {
    final loc = AppLocalizations.of(context);
    final current = _optionIniController.text.trim();
    final String? initialDirectory = current.isEmpty ? null : p.normalize(
      p.extension(current).toLowerCase() == '.ini' ? p.dirname(current) : current,
    );
    final XFile? file = await openFile(
      acceptedTypeGroups: const [ XTypeGroup(label: 'INI', extensions: ['ini']) ],
      initialDirectory: initialDirectory,
      confirmButtonText: loc.common_select,
    );

    if (!mounted || file == null) return;
    setState(() { _optionIniController.text = file.path; _isChanged = true; });
  }

  // 저장
  Future<void> _saveSettings() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    // 이전 언어코드 보관(알림 텍스트 갱신용)
    String prevLang = 'ko';
    ref.read(appSettingControllerProvider).whenData((s) => prevLang = s.languageCode);

    await ref.read(appSettingControllerProvider.notifier).patch(
      isaacPath: _pathController.text.trim(),
      optionsIniPath: _optionIniController.text.trim(),
      rerunDelay: _rerunDelay,
      languageCode: _selectedLanguageCode,
      themeName: _selectedTheme.name,
      useAutoDetectInstallPath: _autoInstall,
      useAutoDetectOptionsIni: _autoOptionsIni,
    );

    ref.invalidate(repentogonInstalledProvider);
    ref.invalidate(isaacAutoInfoProvider);

    if (!mounted) return;
    setState(() => _isChanged = false);

    final loc = AppLocalizations.of(context);
    final changedLang = prevLang != _selectedLanguageCode;
    if (changedLang) {
      await Future<void>.delayed(const Duration(milliseconds: 1));
      if (!mounted) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        UiFeedback.success(context, loc.common_saved, loc.setting_saved_desc);
      });
    } else {
      UiFeedback.success(context, loc.common_saved, loc.setting_saved_desc);
    }
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<AppSetting>>(appSettingControllerProvider, (prev, next) {
      next.whenData((s) { if (!_isChanged) _applyFrom(s); });
    });

    final loc = AppLocalizations.of(context);
    final fTheme = FluentTheme.of(context);

    final actions = <Widget>[
      Button(onPressed: _isChanged ? _saveSettings : null,
          child: Row(children: [const Icon(FluentIcons.save), Gaps.w6, Text(loc.common_save)])),
      Gaps.w8,
      Button(onPressed: _isChanged ? _revert : null,
          child: Row(children: [const Icon(FluentIcons.undo), Gaps.w6, Text(loc.common_reset)])),
    ];

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () => FocusScope.of(context).unfocus(),
      child: ScaffoldPage(
        header: ContentHeaderBar.text(
          title: loc.setting_page_title,
          actions: [
            if (_isChanged) ...[
              Icon(FluentIcons.circle_shape_solid, size: 10, color: fTheme.accentColor),
              Gaps.w8,
            ],
            ...actions,
          ],
        ),
        content: ContentShell(
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                // ── 기본 설정
                SettingsSection(
                  title: loc.setting_section_basic_title,
                  description: loc.setting_section_basic_desc,
                  leftAligned: true,
                  maxWidth: AppBreakpoints.lg + 1,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      DesktopGrid(
                        maxContentWidth: AppBreakpoints.lg + 1, colsLg: 3, colsMd: 2,
                        items: [
                          GridItem(child:
                            InfoLabel(
                              label: loc.setting_language_label,
                              labelStyle: AppTypography.sectionTitle,
                              child: ComboBox<String>(
                                value: _selectedLanguageCode,
                                items: [
                                  ComboBoxItem(value: 'ko', child: Text(loc.setting_language_ko)),
                                  ComboBoxItem(value: 'en', child: Text(loc.setting_language_en)),
                                ],
                                onChanged: (v) { if (v == null) return; setState(() { _selectedLanguageCode = v; _markDirty(); }); },
                              ),
                            ),
                          ),
                        ],
                      ),
                      Gaps.h16,
                      LabeledBlock(
                        label: loc.setting_theme_label,
                        child: ThemePaletteScroller(
                          selectedKey: _selectedTheme,
                          onSelect: (key) {
                            setState(() { _selectedTheme = key; _markDirty(); });
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                Gaps.h16,

                // ── 게임: 감지 + 경로 + 도구 + 지연
                SettingsSection(
                  title: loc.setting_section_game_title,
                  description: loc.setting_section_game_desc,
                  leftAligned: true,
                  maxWidth: AppBreakpoints.lg + 1,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 설치 감지 패널 (분리)
                      const IsaacInstallDetectCard(),
                      Gaps.h16,

                      // 아이작 설치 폴더
                      Text(loc.setting_isaac_path_label, style: AppTypography.sectionTitle),
                      Gaps.h4,
                      Text('설치 위치를 자동으로 사용하거나, 직접 지정할 수 있어요.', style: AppTypography.caption),
                      Gaps.h8,
                      PathInputGroup(
                        isFile: false,
                        auto: _autoInstall,
                        controller: _pathController,
                        placeholder: r'C:\...\Steam\steamapps\common\The Binding of Isaac Rebirth',
                        onModeChanged: (useAuto) => setState(() { _autoInstall = useAuto; _isChanged = true; }),
                        onPick: _browseIsaacPath,
                        onDetect: _detectIsaacPathFromSteam,
                        pickLabel: '폴더 선택',
                      ),

                      Gaps.h16,
                      const Divider(), Gaps.h16,

                      // options.ini 파일
                      Text(loc.setting_options_ini_path_label, style: AppTypography.sectionTitle),
                      Gaps.h4,
                      Text('자동으로 찾거나, 직접 파일을 선택할 수 있어요.', style: fTheme.typography.caption),
                      Gaps.h8,
                      PathInputGroup(
                        isFile: true,
                        auto: _autoOptionsIni,
                        controller: _optionIniController,
                        placeholder: r'C:\Users\(User)\Documents\My Games\Binding of Isaac Repentance+\options.ini',
                        onModeChanged: (useAuto) => setState(() { _autoOptionsIni = useAuto; _isChanged = true; }),
                        onPick: _browseOptionsIniPath,
                        onDetect: _detectOptionsIniPathFromSteam,
                        pickLabel: '파일 선택',
                      ),

                      Gaps.h16,
                      const Divider(style: DividerThemeData(horizontalMargin: EdgeInsets.zero)),
                      Gaps.h16,

                      // Steam 도구
                      Text('Steam 속성', style: AppTypography.sectionTitle),
                      Gaps.h4,
                      Text('Steam 게임 속성 창을 엽니다. 실행 인자 등을 설정할 수 있어요.', style: AppTypography.caption),
                      Gaps.h8,
                      Button(onPressed: _openGameProperties, child: Text(loc.setting_open_properties)),

                      Gaps.h12,
                      Text('무결성 검사', style: AppTypography.sectionTitle),
                      Gaps.h4,
                      Text('설치 파일 손상 여부를 확인하고, 문제가 있으면 복구합니다.', style: AppTypography.caption),
                      Gaps.h8,
                      FilledButton(onPressed: _runIntegrityCheck, child: Text(loc.setting_verify_integrity)),

                      Gaps.h16,
                      const Divider(), Gaps.h16,

                      // 자동 재시작 지연
                      Text(loc.setting_rerun_delay_label, style: AppTypography.sectionTitle),
                      Gaps.h4,
                      Text('기본 1000ms, 권장 500–3000ms', style: AppTypography.caption),
                      Gaps.h8,
                      SizedBox(
                        width: 220,
                        child: TextFormBox(
                          controller: _rerunDelayController,
                          placeholder: '1000',
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          suffix: const Padding(padding: EdgeInsets.symmetric(horizontal: 6), child: Text('ms')),
                          onChanged: (value) {
                            final parsed = int.tryParse(value) ?? 0;
                            setState(() { _rerunDelay = parsed; _markDirty(); });
                          },
                          validator: (value) {
                            final v = int.tryParse(value ?? '');
                            if (v == null) return loc.setting_validate_number_required;
                            if (v < 0) return loc.setting_validate_min_zero;
                            if (v > 60000) return loc.setting_validate_max_60s;
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                ),

                Gaps.h16,

                // ── 정보
                SettingsSection(
                  title: loc.setting_section_about_title,
                  description: loc.setting_section_about_desc,
                  leftAligned: true,
                  maxWidth: AppBreakpoints.lg + 1,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('v$currentVersion', style: AppTypography.body),
                      Gaps.h8,
                      Button(
                        onPressed: () {
                          Navigator.of(context).push(
                            material.MaterialPageRoute<void>(
                              builder: (context) => material.Theme(
                                data: material.Theme.of(context).copyWith(
                                  scaffoldBackgroundColor: fTheme.scaffoldBackgroundColor,
                                  cardColor: fTheme.scaffoldBackgroundColor,
                                ),
                                child: material.LicensePage(
                                  applicationName: 'Cartridge',
                                  applicationVersion: currentVersion.toString(),
                                ),
                              ),
                            ),
                          );
                        },
                        child: Text(loc.setting_license_button),
                      ),
                    ],
                  ),
                ),
                Gaps.h16,
              ],
            ),
          ),
        ),
      ),
    );
  }
}
