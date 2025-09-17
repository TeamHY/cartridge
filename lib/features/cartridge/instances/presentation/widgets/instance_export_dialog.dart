import 'package:cartridge/core/result.dart';
import 'package:file_selector/file_selector.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:cartridge/app/presentation/widgets/ui_feedback.dart';
import 'package:cartridge/core/service_providers.dart';
import 'package:cartridge/features/cartridge/instances/instances.dart';
import 'package:cartridge/theme/theme.dart';

/// 인스턴스 Export 다이얼로그
/// - 파일명 입력
/// - 로컬 모드 포함 여부
/// - 이미지 포함 여부
/// - Export 버튼 클릭 시 폴더 선택 → 즉시 내보내기
Future<void> showExportInstanceDialog(
    BuildContext context, {
      required InstanceView instanceView,
    }) {
  final fileNameCtrl = TextEditingController(text: instanceView.name);
  bool includeLocal = true;
  bool includeImage = true;
  bool busy = false;

  return showDialog<void>(
    context: context,
    builder: (ctx) {
      final fTheme = FluentTheme.of(ctx);
      final accent = fTheme.accentColor.normal;
      final stroke = fTheme.dividerColor;

      return Consumer(
        builder: (_, ref, __) {
          final pack = ref.read(instancePackServiceProvider);

          Future<void> doExport() async {
            if (busy) return;
            final name = fileNameCtrl.text.trim();
            if (name.isEmpty) {
              UiFeedback.error(ctx, content: '파일명을 입력하세요.');
              return;
            }

            busy = true;
            (ctx as Element).markNeedsBuild();

            try {
              // 폴더 선택
              final dir = await getDirectoryPath(
                confirmButtonText: '폴더 선택',
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
                  UiFeedback.success(ctx, content: '내보내기 완료: $zipPath');
                  Navigator.of(ctx).pop();
                },
                notFound: (_, __) {
                  UiFeedback.error(ctx, content: '인스턴스를 찾을 수 없습니다.');
                },
                invalid: (_, __, ___) {
                  UiFeedback.error(ctx, content: '패키지 생성에 실패했습니다.');
                },
                conflict: (_, __) {
                  UiFeedback.error(ctx, content: '패키지 생성에 실패했습니다.');
                },
                failure: (_, __, ___) {
                  UiFeedback.error(ctx, content: '예상치 못한 오류가 발생했습니다.');
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
                const Text('인스턴스 내보내기'),
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
                    // 파일명
                    const Text('파일명', style: TextStyle(fontWeight: FontWeight.w600)),
                    Gaps.h4,
                    TextBox(
                      controller: fileNameCtrl,
                      placeholder: '예) ${instanceView.name}.zip (확장자는 자동)',
                    ),
                    Gaps.h12,

                    // 옵션들
                    const Text('옵션', style: TextStyle(fontWeight: FontWeight.w600)),
                    Gaps.h6,
                    ToggleSwitch(
                      checked: includeLocal,
                      onChanged: busy ? null : (v) { includeLocal = v; (ctx as Element).markNeedsBuild(); },
                      content: const Text('로컬 모드 포함(폴더 복사)'),
                    ),
                    Gaps.h6,
                    ToggleSwitch(
                      checked: includeImage,
                      onChanged: busy ? null : (v) { includeImage = v; (ctx as Element).markNeedsBuild(); },
                      content: const Text('인스턴스 이미지 포함'),
                    ),
                    Gaps.h8,
                    InfoBar(
                      title: const Text('참고'),
                      content: const Text('워크샵 모드는 활성화 정보만 포함됩니다. 로컬 모드/이미지 포함은 옵션으로 제어합니다.'),
                      severity: InfoBarSeverity.info,
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              Button(
                onPressed: busy ? null : () => Navigator.of(ctx).pop(),
                child: const Text('취소'),
              ),
              FilledButton(
                onPressed: busy ? null : doExport,
                child: busy ? const ProgressRing() : const Text('내보내기'),
              ),
            ],
          );
        },
      );
    },
  );
}
