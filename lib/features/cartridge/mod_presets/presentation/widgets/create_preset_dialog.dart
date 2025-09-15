import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:flutter/widgets.dart';

import 'package:cartridge/app/presentation/widgets/ui_feedback.dart';
import 'package:cartridge/features/isaac/mod/isaac_mod.dart';
import 'package:cartridge/l10n/app_localizations.dart';
import 'package:cartridge/theme/theme.dart';

class CreatePresetResult {
  final String name;
  final SeedMode mode;
  CreatePresetResult(this.name, this.mode);
  SeedMode get seedMode => mode;
}

Future<CreatePresetResult?> showCreatePresetDialog(BuildContext context) {
  final nameController = TextEditingController();
  final scrollCtrl = ScrollController();
  var mode = SeedMode.allOff;
  final loc = AppLocalizations.of(context);

  return fluent.showDialog<CreatePresetResult>(
    context: context,
    builder: (ctx) {
      final theme = fluent.FluentTheme.of(ctx);
      final accent = theme.accentColor.normal;
      final dividerColor = theme.dividerColor;

      return fluent.ContentDialog(
        title: Row(
          children: [
            fluent.Icon(fluent.FluentIcons.add_medium, size: 18, color: accent),
            Gaps.w4,
            Text(loc.mod_preset_create_title),
          ],
        ),
        constraints: const BoxConstraints(maxWidth: 560, maxHeight: 460),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560, maxHeight: 460),
          child: fluent.Scrollbar(
            controller: scrollCtrl,
            interactive: true,
            child: SingleChildScrollView(
              controller: scrollCtrl,
              child: Container(
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(color: dividerColor),
                ),
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 이름
                    Text(
                      loc.mod_preset_create_name_label,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    Gaps.h4,
                    fluent.TextBox(
                      controller: nameController,
                      placeholder: loc.mod_preset_create_name_placeholder,
                    ),
                    Gaps.h12,

                    // 초기 모드
                    Text(
                      loc.mod_preset_create_initial_mode_label,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    Gaps.h4,
                    _RadioRow(
                      label: loc.mod_preset_create_all_off,
                      selected: mode == SeedMode.allOff,
                      onChanged: () {
                        mode = SeedMode.allOff;
                        (ctx as Element).markNeedsBuild();
                      },
                    ),
                    _RadioRow(
                      label: loc.mod_preset_create_current_enabled,
                      selected: mode == SeedMode.currentEnabled,
                      onChanged: () {
                        mode = SeedMode.currentEnabled;
                        (ctx as Element).markNeedsBuild();
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
          fluent.Button(
            child: Text(loc.common_cancel),
            onPressed: () => Navigator.of(ctx).pop(null),
          ),
          fluent.FilledButton(
            child: Text(loc.common_create),
            onPressed: () {
              final name = nameController.text.trim();
              if (name.isEmpty) {
                UiFeedback.error(ctx, content: loc.mod_preset_create_validate_required);
                return;
              }
              Navigator.of(ctx).pop(CreatePresetResult(name, mode));
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
        decoration: BoxDecoration(
          borderRadius: AppShapes.chip,
        ),
        child: Row(
          children: [
            fluent.RadioButton(
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

/// 이름만 수정하는 다이얼로그 (동일 톤/레이아웃)
Future<String?> showEditPresetNameDialog(
    BuildContext context, {
      required String initialName,
    }) {
  final nameController = TextEditingController(text: initialName);
  final scrollCtrl = ScrollController();
  final theme = fluent.FluentTheme.of(context);
  final loc = AppLocalizations.of(context);
  final accent = theme.accentColor.normal;
  final dividerColor = theme.dividerColor;

  return fluent.showDialog<String>(
    context: context,
    builder: (ctx) => fluent.ContentDialog(
      title: Row(
        children: [
          fluent.Icon(fluent.FluentIcons.edit, size: 18, color: accent),
          Gaps.w4,
          Text(loc.mod_preset_edit_title),
        ],
      ),
      constraints: const BoxConstraints(
        maxWidth: AppBreakpoints.sm - 1,
        maxHeight: AppBreakpoints.md,
      ),
      content: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: AppBreakpoints.sm - 1,
          maxHeight: AppBreakpoints.md,
        ),
        child: fluent.Scrollbar(
          controller: scrollCtrl,
          interactive: true,
          child: SingleChildScrollView(
            controller: scrollCtrl,
            child: Container(
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: dividerColor),
              ),
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    loc.mod_preset_edit_name_label,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  Gaps.h4,
                  fluent.TextBox(
                    controller: nameController,
                    placeholder: loc.mod_preset_edit_name_placeholder,
                    autofocus: true,
                    onSubmitted: (_) {
                      final name = nameController.text.trim();
                      if (name.isEmpty) {
                        UiFeedback.error(ctx, content: loc.mod_preset_create_validate_required);
                        return;
                      }
                      Navigator.of(ctx).pop(name);
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      actions: [
        fluent.Button(
          child: Text(loc.common_cancel),
          onPressed: () => Navigator.of(ctx).pop(null),
        ),
        fluent.FilledButton(
          child: Text(loc.common_save),
          onPressed: () {
            final name = nameController.text.trim();
            if (name.isEmpty) {
              UiFeedback.error(ctx, content: loc.mod_preset_create_validate_required);
              return;
            }
            Navigator.of(ctx).pop(name);
          },
        ),
      ],
    ),
  );
}
