import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:cartridge/app/presentation/widgets/ui_feedback.dart';
import 'package:cartridge/core/service_providers.dart';
import 'package:cartridge/features/cartridge/instances/presentation/widgets/show_mod_preset_picker_dialog.dart';
import 'package:cartridge/features/isaac/mod/domain/models/seed_mode.dart';
import 'package:cartridge/l10n/app_localizations.dart';
import 'package:cartridge/theme/theme.dart';

/// 다이얼로그 결과 DTO.
/// - name: 인스턴스 이름
/// - seedMode: 초기 시드(SeedMode)
/// - presetIds: 선택된 모드 프리셋 ID 집합(0–N)
/// - optionPresetId: 선택된 옵션 프리셋 ID(0–1; 없으면 null)
class CreateInstanceResult {
  final String name;
  final SeedMode mode;
  final List<String> presetIds;
  final String? optionPresetId;

  CreateInstanceResult(
      this.name,
      this.mode,
      this.presetIds,
      this.optionPresetId,
      );

  SeedMode get seedMode => mode;
}

const String _kNoneOptionId = '__NONE__';

/// 편집 결과 DTO (seedMode 없음)
class EditInstanceResult {
  final String name;
  final List<String> presetIds;
  final String? optionPresetId;
  EditInstanceResult(this.name, this.presetIds, this.optionPresetId);
}

/// 인스턴스 생성 다이얼로그.
/// - 이름 입력
/// - SeedMode 선택(allOff / currentEnabled)
/// - 모드 프리셋 멀티 선택(0–N)
/// - 옵션 프리셋 단일 선택(0–1)
Future<CreateInstanceResult?> showCreateInstanceDialog(BuildContext context) {
  final nameController = TextEditingController();
  final scrollCtrl = ScrollController();
  var mode = SeedMode.allOff;
  final loc = AppLocalizations.of(context);

  // 선택 상태(다이얼로그 생명주기 동안 유지)
  final selectedPresetIds = <String>{};
  String? selectedOptionId;

  return showDialog<CreateInstanceResult>(
    context: context,
    builder: (ctx) {
      final fTheme = FluentTheme.of(ctx);
      final accent = fTheme.accentColor.normal;
      final dividerColor = fTheme.dividerColor;

      return ContentDialog(
        title: Row(
          children: [
            Icon(FluentIcons.add_medium, size: 18, color: accent),
            const SizedBox(width: AppSpacing.xs),
            Text(loc.instance_create_title),
          ],
        ),
        constraints: const BoxConstraints(maxWidth: 560, maxHeight: 560),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560, maxHeight: 560),
          child: Scrollbar(
            controller: scrollCtrl,
            interactive: true,
            child: SingleChildScrollView(
              controller: scrollCtrl,
              child: Container(
                decoration: BoxDecoration(
                  color: fTheme.cardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: dividerColor),
                ),
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 이름 섹션
                    Text(
                      loc.instance_create_name_label,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    TextBox(
                      controller: nameController,
                      placeholder: loc.instance_create_name_placeholder,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    // 초기 모드 구성 섹션
                    Text(
                      loc.instance_create_initial_mode_label,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: AppSpacing.xs),

                    _RadioRow(
                      label: loc.instance_create_all_off,
                      selected: mode == SeedMode.allOff,
                      onChanged: () {
                        mode = SeedMode.allOff;
                        (ctx as Element).markNeedsBuild();
                      },
                    ),
                    _RadioRow(
                      label: loc.instance_create_current_enabled,
                      selected: mode == SeedMode.currentEnabled,
                      onChanged: () {
                        mode = SeedMode.currentEnabled;
                        (ctx as Element).markNeedsBuild();
                      },
                    ),

                    const SizedBox(height: AppSpacing.md),

                    // ── 모드 프리셋(0–N 멀티 선택)
                    Text(
                      loc.preset_tab_mod,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Row(
                      children: [
                        Button(
                          onPressed: () async {
                            final picked = await showModPresetPickerDialog(
                              ctx,
                              initialSelected: selectedPresetIds,
                            );
                            if (picked != null) {
                              selectedPresetIds
                                ..clear()
                                ..addAll(picked);
                              (ctx as Element).markNeedsBuild();
                            }
                          },
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(FluentIcons.check_list),
                              const SizedBox(width: AppSpacing.xs),
                              Text(
                                '${loc.preset_tab_mod} (${selectedPresetIds.length})',
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: AppSpacing.md),

                    // ── 옵션 프리셋(0–1 단일 선택)
                    Text(
                      loc.instance_option_preset_label,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Consumer(
                      builder: (context, ref, _) {
                        final asyncOptions = ref.watch(optionPresetsControllerProvider);
                        return SizedBox(
                          width: 360,
                          child: asyncOptions.when(
                            loading: () => const Center(child: ProgressRing()),
                            error  : (e, st) => Text('Error: $e'),
                            data   : (options) {
                              // 현재 선택된 id가 목록에 없으면 "(None)" sentinel로 폴백
                              final currentValue = options.any((o) => o.id == selectedOptionId)
                                  ? (selectedOptionId ?? _kNoneOptionId)
                                  : _kNoneOptionId;

                              return ComboBox<String>(
                                isExpanded: true,
                                value: currentValue,
                                items: [
                                  const ComboBoxItem<String>(
                                    value: _kNoneOptionId,
                                    child: Text('(None)'),
                                  ),
                                  ...options.map((o) => ComboBoxItem<String>(
                                    value: o.id,            // OptionPresetView.id 사용
                                    child: Text(o.name),
                                  )),
                                ],
                                onChanged: (v) {
                                  selectedOptionId = (v == _kNoneOptionId) ? null : v;
                                  (ctx as Element).markNeedsBuild();
                                },
                              );
                            },
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: AppSpacing.sm),

                    // ── 힌트
                    Text(
                      loc.instance_create_hint,
                      style: TextStyle(
                        fontSize: 12,
                        color: fTheme.inactiveColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        actions: [
          Button(
            child: Text(loc.common_cancel),
            onPressed: () => Navigator.of(ctx).pop(null),
          ),
          FilledButton(
            child: Text(loc.common_create),
            onPressed: () {
              final name = nameController.text.trim();
              if (name.isEmpty) {
                UiFeedback.error(
                  ctx,
                  loc.common_error,
                  loc.instance_create_validate_required,
                );
                return;
              }
              Navigator.of(ctx).pop(
                CreateInstanceResult(
                  name,
                  mode,
                  selectedPresetIds.toList(growable: false),
                  selectedOptionId,
                ),
              );
            },
          ),
        ],
      );
    },
  );
}

/// 인스턴스 편집 다이얼로그 (이름 + 프리셋 + 옵션 프리셋)
Future<EditInstanceResult?> showEditInstanceDialog(
  BuildContext context, {
  required String initialName,
  required Set<String> initialPresetIds,
  required String? initialOptionPresetId,
}) {
  final nameController = TextEditingController(text: initialName);
  final scrollCtrl = ScrollController();
  final loc = AppLocalizations.of(context);

  // 선택 상태(다이얼로그 생명주기 동안 유지)
  final selectedPresetIds = <String>{...initialPresetIds};
  String? selectedOptionId = initialOptionPresetId;

  return showDialog<EditInstanceResult>(
    context: context,
    builder: (ctx) {
      final fTheme = FluentTheme.of(ctx);
      final accent = fTheme.accentColor.normal;
      final dividerColor = fTheme.dividerColor;

      return ContentDialog(
        title: Row(
          children: [
            Icon(FluentIcons.edit, size: 18, color: accent),
            const SizedBox(width: AppSpacing.xs),
            const Text('인스턴스 편집'),
          ],
        ),
        constraints: const BoxConstraints(maxWidth: 560, maxHeight: 560),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560, maxHeight: 560),
          child: Scrollbar(
            controller: scrollCtrl,
            interactive: true,
            child: SingleChildScrollView(
              controller: scrollCtrl,
              child: Container(
                decoration: BoxDecoration(
                  color: fTheme.cardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: dividerColor),
                ),
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 이름 섹션
                    Text(
                      loc.instance_create_name_label,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    TextBox(
                      controller: nameController,
                      placeholder: loc.instance_create_name_placeholder,
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // ── 모드 프리셋(0–N 멀티 선택)
                    Text(
                      loc.preset_tab_mod,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Row(
                      children: [
                        Button(
                          onPressed: () async {
                            final picked = await showModPresetPickerDialog(
                              ctx,
                              initialSelected: selectedPresetIds,
                            );
                            if (picked != null) {
                              selectedPresetIds
                                ..clear()
                                ..addAll(picked);
                              (ctx as Element).markNeedsBuild();
                            }
                          },
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(FluentIcons.check_list),
                              const SizedBox(width: AppSpacing.xs),
                              Text(
                                '${loc.preset_tab_mod} (${selectedPresetIds.length})',
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: AppSpacing.md),

                    // ── 옵션 프리셋(0–1 단일 선택)
                    Text(
                      loc.instance_option_preset_label,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Consumer(
                      builder: (context, ref, _) {
                        final asyncOptions = ref.watch(optionPresetsControllerProvider);
                        return SizedBox(
                          width: 360,
                          child: asyncOptions.when(
                            loading: () => const Center(child: ProgressRing()),
                            error  : (e, st) => Text('Error: $e'),
                            data   : (options) {
                              // 현재 선택된 id가 목록에 없으면 "(None)" sentinel로 폴백
                              final currentValue = options.any((o) => o.id == selectedOptionId)
                                  ? (selectedOptionId ?? _kNoneOptionId)
                                  : _kNoneOptionId;

                              return ComboBox<String>(
                                isExpanded: true,
                                value: currentValue,
                                items: [
                                  const ComboBoxItem<String>(
                                    value: _kNoneOptionId,
                                    child: Text('(None)'),
                                  ),
                                  ...options.map((o) => ComboBoxItem<String>(
                                    value: o.id,
                                    child: Text(o.name),
                                  )),
                                ],
                                onChanged: (v) {
                                  selectedOptionId = (v == _kNoneOptionId) ? null : v;
                                  (ctx as Element).markNeedsBuild();
                                },
                              );
                            },
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        actions: [
          Button(
            child: Text(loc.common_cancel),
            onPressed: () => Navigator.of(ctx).pop(null),
          ),
          FilledButton(
            child: Text(loc.common_save),
            onPressed: () {
              final name = nameController.text.trim();
              if (name.isEmpty) {
                UiFeedback.error(
                  ctx,
                  loc.common_error,
                  loc.instance_create_validate_required,
                );
                return;
              }
              Navigator.of(ctx).pop(
                EditInstanceResult(
                  name,
                  selectedPresetIds.toList(growable: false),
                  selectedOptionId,
                ),
              );
            },
          ),
        ],
      );
    },
  );
}

/// Fluent 라디오 + 라벨 한 줄
class _RadioRow extends StatelessWidget {
  const _RadioRow({
    required this.label,
    required this.selected,
    required this.onChanged,
  });

  final String label;
  final bool selected;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Container(
        padding: const EdgeInsets.symmetric(
          vertical: AppSpacing.xs,
          horizontal: AppSpacing.sm,
        ),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(8)),
        child: Row(
          children: [
            RadioButton(
              checked: selected,
              onChanged: (_) => onChanged(),
              content: Text(label),
            ),
          ],
        ),
      ),
    );
  }
}

