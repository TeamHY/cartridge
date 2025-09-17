import 'package:cartridge/core/result.dart';
import 'package:cartridge/features/cartridge/instances/domain/instance_pack_service.dart';
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

  return showDialog<String?>(
    context: context,
    builder: (ctx) {
      final fTheme = FluentTheme.of(ctx);
      final accent = fTheme.accentColor.normal;
      final stroke = fTheme.dividerColor;

      return Consumer(
        builder: (_, ref, __) {
          final pack = ref.read(instancePackServiceProvider);

          Future<void> pickFile() async {
            final type = const XTypeGroup(label: 'Cartridge Instance', extensions: ['zip']);
            final file = await openFile(acceptedTypeGroups: [type]);
            if (file != null) {
              filePath = file.path;
              (ctx as Element).markNeedsBuild();
            }
          }

          Future<void> doImport() async {
            if (busy) return;
            if (filePath == null || filePath!.isEmpty) {
              UiFeedback.warn(ctx, content: '가져올 파일을 선택하세요(.zip).');
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
                  UiFeedback.success(ctx, content: '가져오기 완료');
                },
                invalid: (_, __, ___) {
                  UiFeedback.error(ctx, content: '패키지 파일이 올바르지 않습니다.');
                },
                notFound: (_, __) {
                  UiFeedback.error(ctx, content: '가져오기 실패: 구성 누락');
                },
                conflict: (_, __) {
                  UiFeedback.error(ctx, content: '가져오기 실패: 구성 누락');
                },
                failure: (_, __, ___) {
                  UiFeedback.error(ctx, content: '가져오기 실패: 내부 오류');
                },
              );

              if (createdId != null) {
                Navigator.of(ctx).pop(createdId);
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
                const Text('인스턴스 가져오기'),
              ],
            ),
            content: ConstrainedBox(
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
                    // 파일 선택 필드형 버튼
                    const Text('가져올 파일(.zip)', style: TextStyle(fontWeight: FontWeight.w600)),
                    Gaps.h6,
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
                                filePath ?? '파일 선택...',
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
                    Gaps.h12,

                    const Text('옵션', style: TextStyle(fontWeight: FontWeight.w600)),
                    Gaps.h6,
                    ToggleSwitch(
                      checked: skipExistingLocal,
                      onChanged: busy ? null : (v) { skipExistingLocal = v; (ctx as Element).markNeedsBuild(); },
                      content: const Text('이미 있는 로컬 모드는 건너뛰기'),
                    ),
                    Gaps.h8,
                    InfoBar(
                      title: const Text('참고'),
                      content: const Text('동일한 프리셋은 자동으로 재사용하고, 없으면 새로 생성합니다. 인스턴스는 항상 새로 만들어집니다.'),
                      severity: InfoBarSeverity.info,
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              Button(
                onPressed: busy ? null : () => Navigator.of(ctx).pop(null),
                child: const Text('취소'),
              ),
              FilledButton(
                onPressed: busy ? null : doImport,
                child: busy ? const ProgressRing() : const Text('가져오기'),
              ),
            ],
          );
        },
      );
    },
  );
}
