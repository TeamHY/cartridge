import 'package:cartridge/core/result.dart';
import 'package:cartridge/features/cartridge/instances/domain/instance_pack_service.dart';
import 'package:cartridge/l10n/app_localizations.dart';
import 'package:file_selector/file_selector.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:cartridge/app/presentation/widgets/ui_feedback.dart';
import 'package:cartridge/core/service_providers.dart';
import 'package:cartridge/theme/theme.dart';

/// 인스턴스 Import 다이얼로그
/// - .zip 파일 선택
/// - 로컬 모드가 이미 있으면 건너뛰기 옵션
/// - Import 진행
///
/// 반환: 생성된 인스턴스 id (성공 시), 그 외 null
Future<String?> showImportInstanceDialog(BuildContext context) {
  String? filePath;
  bool skipExistingLocal = true;
  bool busy = false;

  final formKey = GlobalKey<FormState>();

  return showDialog<String?>(
    context: context,
    builder: (ctx) {
      final fTheme = FluentTheme.of(ctx);
      final accent = fTheme.accentColor.normal;
      final stroke = fTheme.dividerColor;
      final loc = AppLocalizations.of(ctx);
      final sem = ProviderScope.containerOf(ctx).read(themeSemanticsProvider);

      return Consumer(
        builder: (_, ref, __) {
          final pack = ref.read(instancePackServiceProvider);

          Future<void> pickFile() async {
            final type = const XTypeGroup(label: 'Cartridge Instance', extensions: ['zip']);
            final file = await openFile(acceptedTypeGroups: [type]);
            if (file != null) {
              filePath = file.path;
              (ctx as Element).markNeedsBuild();
              formKey.currentState?.validate();
            }
          }

          Future<void> doImport() async {
            if (busy) return;

            if (!(formKey.currentState?.validate() ?? false)) {
              return;
            }

            busy = true;
            (ctx as Element).markNeedsBuild();

            try {
              final res = await pack.importPack(
                zipPath: filePath!,
                options: InstanceImportOptions(skipExistingLocalMods: skipExistingLocal),
              );

              String? createdId;
              res.when(
                ok: (newId, _, __) {
                  createdId = newId;
                  UiFeedback.success(ctx, content: loc.import_complete_message);
                },
                invalid: (_, __, ___) {
                  UiFeedback.error(ctx, content: loc.import_error_invalid_package);
                },
                notFound: (_, __) {
                  UiFeedback.error(ctx, content: loc.import_error_missing_config);
                },
                conflict: (_, __) {
                  UiFeedback.error(ctx, content: loc.import_error_conflict);
                },
                failure: (_, __, ___) {
                  UiFeedback.error(ctx, content: loc.import_error_internal);
                },
              );

              if (createdId != null) {
                if (context.mounted) Navigator.of(ctx).pop(createdId);
              }
            } finally {
              busy = false;
              if (ctx.mounted) ctx.markNeedsBuild();
            }
          }

          return ContentDialog(
            constraints: const BoxConstraints(maxWidth: 560, maxHeight: 480),
            title: Row(
              children: [
                Icon(FluentIcons.download, size: 18, color: accent),
                Gaps.w4,
                Text(loc.import_title),
                if (busy) ...[
                  Gaps.w8,
                  const ProgressRing(),
                ]
              ],
            ),
            content: Form(
              key: formKey,
              autovalidateMode: AutovalidateMode.disabled, // 자동검증 off
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
                      // 파일 선택 필드 (FormField로 검증/에러 표시)
                      Text(loc.import_file_label, style: const TextStyle(fontWeight: FontWeight.w600)),
                      Gaps.h6,
                      FormField<String>(
                        validator: (_) {
                          if (filePath == null || filePath!.isEmpty) {
                            return loc.import_error_no_file_selected;
                          }
                          // 필요 시 확장:
                          // if (!filePath!.toLowerCase().endsWith('.zip')) {
                          //   return loc.import_error_file_must_be_zip;
                          // }
                          return null;
                        },
                        builder: (state) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                height: 36,
                                child: Button(
                                  onPressed: busy ? null : pickFile,
                                  child: Row(
                                    children: [
                                      const Icon(FluentIcons.open_file, size: 16),
                                      Gaps.w8,
                                      Expanded(
                                        child: Text(
                                          filePath ?? loc.import_file_button_default,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            color: filePath == null ? fTheme.inactiveColor : null,
                                            fontWeight: filePath == null ? FontWeight.w400 : FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              if (state.hasError) ...[
                                Gaps.h4,
                                Text(
                                  state.errorText!,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: sem.danger.fg,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ],
                          );
                        },
                      ),
                      Gaps.h12,

                      Text(loc.import_options, style: const TextStyle(fontWeight: FontWeight.w600)),
                      Gaps.h6,
                      ToggleSwitch(
                        checked: skipExistingLocal,
                        onChanged: busy ? null : (v) { skipExistingLocal = v; (ctx as Element).markNeedsBuild(); },
                        content: Text(loc.import_skip_existing_local),
                      ),
                      Gaps.h16,

                      // 정보성 안내(검증 아님)
                      InfoBar(
                        title: Text(loc.import_note),
                        content: Text(loc.import_note_content),
                        severity: InfoBarSeverity.info,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              Button(
                onPressed: busy ? null : () => Navigator.of(ctx).pop(null),
                child: Text(loc.common_cancel),
              ),
              FilledButton(
                onPressed: busy ? null : doImport,
                child: Text(loc.common_import),
              ),
            ],
          );
        },
      );
    },
  );
}
