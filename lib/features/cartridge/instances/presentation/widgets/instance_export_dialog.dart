import 'package:cartridge/core/result.dart';
import 'package:cartridge/l10n/app_localizations.dart';
import 'package:file_selector/file_selector.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:cartridge/app/presentation/widgets/ui_feedback.dart';
import 'package:cartridge/core/service_providers.dart';
import 'package:cartridge/features/cartridge/instances/instances.dart';
import 'package:cartridge/theme/theme.dart';

/// 인스턴스 Export 다이얼로그
/// - 파일명 입력(검증: 비어있음 금지)
/// - 로컬 모드 포함 여부
/// - 이미지 포함 여부
/// - Export 버튼 클릭 시 폴더 선택 → 즉시 내보내기
Future<void> showExportInstanceDialog(
    BuildContext context, {
      required InstanceView instanceView,
    }) {
  final fileNameCtrl = TextEditingController(text: instanceView.name);
  final nameFocus = FocusNode();
  final formKey = GlobalKey<FormState>();

  bool includeLocal = true;
  bool includeImage = true;
  bool busy = false;

  return showDialog<void>(
    context: context,
    builder: (ctx) {
      final fTheme = FluentTheme.of(ctx);
      final accent = fTheme.accentColor.normal;
      final stroke = fTheme.dividerColor;
      final loc = AppLocalizations.of(ctx);

      return Consumer(
        builder: (_, ref, __) {
          final pack = ref.read(instancePackServiceProvider);

          Future<void> doExport() async {
            if (busy) return;

            if (!(formKey.currentState?.validate() ?? false)) {
              // 포커스 이동(UX)
              nameFocus.requestFocus();
              return;
            }

            final name = fileNameCtrl.text.trim();

            busy = true;
            (ctx as Element).markNeedsBuild();

            try {
              // 폴더 선택
              final dir = await getDirectoryPath(
                confirmButtonText: loc.export_directory_select_button,
              );
              if (dir == null) {
                busy = false;
                ctx.markNeedsBuild();
                return;
              }

              final res = await pack.exportFromView(
                view: instanceView,
                targetDir: dir,
                options: InstanceExportOptions(
                  includeLocalMods: includeLocal,
                  includeImage: includeImage,
                ),
                nameHint: name,
              );

              res.when(
                ok: (zipPath, _, __) {
                  UiFeedback.success(ctx, content: loc.export_complete_message(zipPath!));
                  Navigator.of(ctx).pop();
                },
                notFound: (_, __) {
                  UiFeedback.error(ctx, content: loc.export_error_instance_not_found);
                },
                invalid: (_, __, ___) {
                  UiFeedback.error(ctx, content: loc.export_error_package_creation_failed);
                },
                conflict: (_, __) {
                  UiFeedback.error(ctx, content: loc.export_error_package_creation_failed);
                },
                failure: (_, __, ___) {
                  UiFeedback.error(ctx, content: loc.export_error_unexpected);
                },
              );
            } finally {
              busy = false;
              if (ctx.mounted) ctx.markNeedsBuild();
            }
          }

          return ContentDialog(
            constraints: const BoxConstraints(maxWidth: 560, maxHeight: 480),
            title: Row(
              children: [
                Icon(FluentIcons.upload, size: 18, color: accent),
                Gaps.w4,
                Text(loc.export_title),
              ],
            ),
            content: Form(
              key: formKey,
              autovalidateMode: AutovalidateMode.disabled,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560, maxHeight: 480),
                child: Container(
                  decoration: BoxDecoration(
                    color: fTheme.cardColor,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(color: stroke),
                  ),
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 파일명
                      Text(loc.export_file_name, style: const TextStyle(fontWeight: FontWeight.w600)),
                      Gaps.h4,
                      TextFormBox(
                        focusNode: nameFocus,
                        controller: fileNameCtrl,
                        placeholder: loc.export_file_name_placeholder(instanceView.name),
                        validator: (v) {
                          final t = v?.trim() ?? '';
                          if (t.isEmpty) return loc.export_error_file_name_empty;
                          // 필요시 추가 규칙(윈도우 금지 문자 등) 확장 가능:
                          // final invalid = RegExp(r'[\\/:*?"<>|]');
                          // if (invalid.hasMatch(t)) return loc.export_error_file_name_invalid;
                          return null;
                        },
                        onFieldSubmitted: (_) {
                          if (!busy) doExport();
                        },
                      ),
                      Gaps.h12,

                      // 옵션들
                      Text(loc.export_options, style: const TextStyle(fontWeight: FontWeight.w600)),
                      Gaps.h6,
                      ToggleSwitch(
                        checked: includeLocal,
                        onChanged: busy
                            ? null
                            : (v) {
                          includeLocal = v;
                          (ctx as Element).markNeedsBuild();
                        },
                        content: Text(loc.export_include_local_mods),
                      ),
                      Gaps.h8,
                      ToggleSwitch(
                        checked: includeImage,
                        onChanged: busy
                            ? null
                            : (v) {
                          includeImage = v;
                          (ctx as Element).markNeedsBuild();
                        },
                        content: Text(loc.export_include_image),
                      ),
                      Gaps.h16,

                      // 안내(정보성) – 검증용이 아님
                      InfoBar(
                        title: Text(loc.export_note),
                        content: Text(loc.export_note_content),
                        severity: InfoBarSeverity.info,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              Button(
                onPressed: busy ? null : () => Navigator.of(ctx).pop(),
                child: Text(loc.common_cancel),
              ),
              FilledButton(
                onPressed: busy ? null : doExport,
                child: busy ? const ProgressRing() : Text(loc.common_export),
              ),
            ],
          );
        },
      );
    },
  );
}
