import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:cartridge/app/presentation/widgets/ui_feedback.dart';
import 'package:cartridge/core/service_providers.dart';
import 'package:cartridge/features/cartridge/instances/instances.dart';
import 'package:cartridge/features/isaac/mod/isaac_mod.dart';
import 'package:cartridge/l10n/app_localizations.dart';
import 'package:cartridge/theme/theme.dart';

class CreateInstanceResult {
  final String name;
  final SeedMode mode;
  final List<String> presetIds;
  final String? optionPresetId;
  CreateInstanceResult(this.name, this.mode, this.presetIds, this.optionPresetId);
  SeedMode get seedMode => mode;
}

const String _kNoneOptionId = '__NONE__';
const double _kFieldWidth = 360;
const double _kFieldHeight = 36;

class EditInstanceResult {
  final String name;
  final List<String> presetIds;
  final String? optionPresetId;
  EditInstanceResult(this.name, this.presetIds, this.optionPresetId);
}

/// 인스턴스 생성
Future<CreateInstanceResult?> showCreateInstanceDialog(BuildContext context) {
  final nameController = TextEditingController();
  final scrollCtrl = ScrollController();
  var mode = SeedMode.allOff;
  final loc = AppLocalizations.of(context);

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
            Gaps.w4,
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
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(color: dividerColor),
                ),
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 이름
                    Text(loc.instance_create_name_label, style: const TextStyle(fontWeight: FontWeight.w600)),
                    Gaps.h4,
                    TextBox(
                      controller: nameController,
                      placeholder: loc.instance_create_name_placeholder,
                    ),
                    Gaps.h12,

                    // 초기 모드
                    Text(loc.instance_create_initial_mode_label, style: const TextStyle(fontWeight: FontWeight.w600)),
                    Gaps.h4,
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
                    Gaps.h12,

                    // 옵션 프리셋(단일)
                    Text(loc.instance_option_preset_label, style: const TextStyle(fontWeight: FontWeight.w600)),
                    Gaps.h4,
                    _OptionPresetComboField(
                      selectedOptionId: selectedOptionId,
                      onChanged: (v) {
                        selectedOptionId = v;
                        (ctx as Element).markNeedsBuild();
                      },
                    ),
                    Gaps.h12,

                    // 모드 프리셋(멀티)
                    Text(loc.preset_tab_mod, style: const TextStyle(fontWeight: FontWeight.w600)),
                    Gaps.h4,
                    _ModPresetPickerField(
                      selectedCount: selectedPresetIds.length,
                      onPressed: () async {
                        final picked = await showModPresetPickerDialog(ctx, initialSelected: selectedPresetIds);
                        if (picked != null) {
                          selectedPresetIds..clear()..addAll(picked);
                          (ctx as Element).markNeedsBuild();
                        }
                      },
                    ),
                    Gaps.h8,
                  ],
                ),
              ),
            ),
          ),
        ),
        actions: [
          Button(child: Text(loc.common_cancel), onPressed: () => Navigator.of(ctx).pop(null)),
          FilledButton(
            child: Text(loc.common_create),
            onPressed: () {
              final name = nameController.text.trim();
              if (name.isEmpty) {
                UiFeedback.error(ctx, content: loc.instance_create_validate_required);
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

/// 인스턴스 편집
Future<EditInstanceResult?> showEditInstanceDialog(
    BuildContext context, {
      required String initialName,
      required Set<String> initialPresetIds,
      required String? initialOptionPresetId,
    }) {
  final nameController = TextEditingController(text: initialName);
  final scrollCtrl = ScrollController();
  final loc = AppLocalizations.of(context);

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
            Gaps.w4,
            Text(loc.instance_edit_title),
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
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(color: dividerColor),
                ),
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 이름
                    Text(loc.instance_create_name_label, style: const TextStyle(fontWeight: FontWeight.w600)),
                    Gaps.h4,
                    TextBox(
                      controller: nameController,
                      placeholder: loc.instance_create_name_placeholder,
                    ),
                    Gaps.h12,

                    // 옵션 프리셋(단일)
                    Text(loc.instance_option_preset_label, style: const TextStyle(fontWeight: FontWeight.w600)),
                    Gaps.h4,
                    _OptionPresetComboField(
                      selectedOptionId: selectedOptionId,
                      onChanged: (v) {
                        selectedOptionId = v;
                        (ctx as Element).markNeedsBuild();
                      },
                    ),
                    Gaps.h12,

                    // 모드 프리셋(멀티)
                    Text(loc.preset_tab_mod, style: const TextStyle(fontWeight: FontWeight.w600)),
                    Gaps.h4,
                    _ModPresetPickerField(
                      selectedCount: selectedPresetIds.length,
                      onPressed: () async {
                        final picked = await showModPresetPickerDialog(ctx, initialSelected: selectedPresetIds);
                        if (picked != null) {
                          selectedPresetIds..clear()..addAll(picked);
                          (ctx as Element).markNeedsBuild();
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        actions: [
          Button(child: Text(loc.common_cancel), onPressed: () => Navigator.of(ctx).pop(null)),
          FilledButton(
            child: Text(loc.common_save),
            onPressed: () {
              final name = nameController.text.trim();
              if (name.isEmpty) {
                UiFeedback.error(ctx, content: loc.instance_create_validate_required);
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

/// 옵션 프리셋 콤보: loading/에러도 동일 레이아웃 유지
class _OptionPresetComboField extends ConsumerWidget {
  final String? selectedOptionId;
  final ValueChanged<String?> onChanged;
  const _OptionPresetComboField({
    required this.selectedOptionId,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = AppLocalizations.of(context);
    final asyncOptions = ref.watch(optionPresetsControllerProvider);

    // 항상 같은 너비/모양 유지
    return SizedBox(
      width: _kFieldWidth,
      child: asyncOptions.when(
        loading: () {
          return ComboBox<String>(
            isExpanded: true,
            value: _kNoneOptionId,
            items: [
              ComboBoxItem<String>(
                value: _kNoneOptionId,
                child: Text(loc.instance_option_loading),
              ),
            ],
            onChanged: null, // disabled
          );
        },
        error: (_, __) {
          return ComboBox<String>(
            isExpanded: true,
            value: _kNoneOptionId,
            items: [
              ComboBoxItem<String>(
                value: _kNoneOptionId,
                child: Text(loc.instance_option_error),
              ),
            ],
            onChanged: null, // disabled
          );
        },
        data: (options) {
          final exists = options.any((o) => o.id == selectedOptionId);
          final value = exists ? (selectedOptionId ?? _kNoneOptionId) : _kNoneOptionId;

          return ComboBox<String>(
            isExpanded: true,
            value: value,
            items: [
              ComboBoxItem<String>(
                value: _kNoneOptionId,
                child: Text(loc.instance_option_none),
              ),
              ...options.map(
                    (o) => ComboBoxItem<String>(value: o.id, child: Text(o.name)),
              ),
            ],
            onChanged: (v) => onChanged(v == _kNoneOptionId ? null : v),
          );
        },
      ),
    );
  }
}

/// 모드 프리셋: ComboBox처럼 보이는 '필드형 버튼'
class _ModPresetPickerField extends StatelessWidget {
  final int selectedCount;
  final VoidCallback onPressed;
  const _ModPresetPickerField({required this.selectedCount, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    final stroke = theme.resources.controlStrokeColorSecondary;
    final textColor = theme.typography.body?.color ?? theme.resources.textFillColorPrimary;
    final hintColor = theme.inactiveColor;
    final hasSelection = selectedCount > 0;
    final label = hasSelection
        ? AppLocalizations.of(context).mod_presets_selected(selectedCount)
        : AppLocalizations.of(context).mod_presets_none;

    return SizedBox(
      width: _kFieldWidth,
      height: _kFieldHeight,
      child: HoverButton(
        onPressed: onPressed,
        builder: (ctx, states) {
          final hovered = states.isHovered;
          final pressed = states.isPressed;
          final base = theme.resources.controlFillColorDefault;
          final overlay = _tileOverlay(
            brightness: theme.brightness,
            hovered: hovered,
            pressed: pressed,
          );
          final bg = Color.alphaBlend(overlay, base);
          final baseTextColor = hasSelection ? textColor : hintColor;
          final textButtonColor = hovered ? theme.resources.textFillColorSecondary : baseTextColor;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: AppShapes.chip,
              border: Border.all(color: pressed ? theme.resources.controlStrokeColorDefault : stroke),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: textButtonColor,
                      fontWeight: hasSelection ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsetsDirectional.only(start: 8.0),
                  child: IconTheme.merge(
                    data: IconThemeData(
                      color: theme.resources.textFillColorSecondary,
                      size: 8,
                    ),
                    child: Icon(FluentIcons.chevron_down),
                  ),
                ),
                Gaps.w4
              ],
            ),
          );
        },
      ),
    );
  }
}

/// 라디오 + 라벨
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
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs, horizontal: AppSpacing.sm),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(8)),
        child: Row(
          children: [
            RadioButton(checked: selected, onChanged: (_) => onChanged(), content: Text(label)),
          ],
        ),
      ),
    );
  }
}

Color _tileOverlay({
  required Brightness brightness,
  required bool hovered,
  required bool pressed,
}) {
  if (pressed) {
    return brightness == Brightness.dark
        ? Colors.white.withAlpha(1)
        : Colors.black.withAlpha(5);
  }
  if (hovered) {
    return brightness == Brightness.dark
        ? Colors.white.withAlpha(4)
        : Colors.black.withAlpha(5);
  }
  return Colors.transparent;
}