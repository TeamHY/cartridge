import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:cartridge/app/presentation/widgets/badge.dart';
import 'package:cartridge/app/presentation/widgets/ui_feedback.dart';
import 'package:cartridge/app/presentation/widgets/ut/ut_header_refresh_button.dart';
import 'package:cartridge/features/cartridge/setting/presentation/controllers/app_setting_page_controller.dart';
import 'package:cartridge/features/isaac/runtime/application/install_path_result.dart';
import 'package:cartridge/features/isaac/runtime/application/isaac_runtime_service.dart';
import 'package:cartridge/features/isaac/runtime/domain/isaac_versions.dart';
import 'package:cartridge/l10n/app_localizations.dart';
import 'package:cartridge/theme/theme.dart';

class InstallDetectPanel extends ConsumerWidget {
  const InstallDetectPanel({
    super.key,
    required this.useAutoInstall,
    required this.manualInstallPath,
  });

  final bool useAutoInstall;
  final String manualInstallPath;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fTheme = FluentTheme.of(context);
    final sem = ref.watch(themeSemanticsProvider);
    final loc = AppLocalizations.of(context);
    final async = ref.watch(isaacAutoInfoProvider);

    // 상태→메시지 매핑
    String statusMessage(InstallPathStatus s, InstallPathSource src, String? path) {
      switch (s) {
        case InstallPathStatus.ok:
          return '정상 설치 경로입니다.';
        case InstallPathStatus.dirNotFound:
          return src == InstallPathSource.manual
              ? '사용자 지정 경로의 폴더가 존재하지 않습니다${path == null ? '' : ':\n$path'}.'
              : '자동 탐지된 경로의 폴더가 존재하지 않습니다${path == null ? '' : ':\n$path'}.';
        case InstallPathStatus.exeNotFound:
          return '$isaacExeFile 파일을 찾을 수 없습니다${path == null ? '' : ':\n$path'}.';
        case InstallPathStatus.autoDetectFailed:
          return '자동 탐지에 실패했습니다. Steam 설치/라이브러리 구성을 확인해 주세요.';
        case InstallPathStatus.notConfigured:
          return '설치 경로가 아직 설정되지 않았습니다.';
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: fTheme.resources.dividerStrokeColorDefault),
      ),
      child: async.when(
        loading: () => const SizedBox(
          height: 84,
          child: Align(alignment: Alignment.centerLeft, child: ProgressBar()),
        ),
        error: (e, _) => InfoBar(
          title: Text(loc.common_error),
          content: Text(e.toString()),
          severity: InfoBarSeverity.error,
        ),
        data: (info) {
          final editionLabel = info.editionName ?? loc.setting_detect_not_found;
          final image = info.editionAsset;

          var badges = <BadgeSpec>[];
          badges.add(
            BadgeSpec(
              info.installSource == InstallPathSource.manual ? '수동 경로' : '자동 탐지',
              info.installSource == InstallPathSource.manual ? sem.info : sem.warning,
            ),
          );
          if (info.needsRepentogon) {
            badges.add(info.repentogonInstalled
                ? BadgeSpec('Repentogon 사용 중', sem.danger)
                : BadgeSpec('Repentogon 미설치', sem.danger));
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // 썸네일
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: image != null
                        ? Image.asset(
                      image,
                      width: 72,
                      height: 72,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(FluentIcons.photo2, size: 32),
                    )
                        : Container(
                      width: 72,
                      height: 72,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        border: Border.all(color: fTheme.resources.dividerStrokeColorDefault),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(FluentIcons.photo2, size: 28),
                    ),
                  ),
                  Gaps.w12,

                  // 타이틀/경로/Repentogon 상태
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(editionLabel, style: AppTypography.sectionTitle),
                        Gaps.h2,
                        Text(
                          (info.installPath == null || info.installPath!.isEmpty)
                              ? '설치 경로를 찾을 수 없어요.'
                              : '경로: ${info.installPath}',
                          style: AppTypography.caption,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Gaps.h8,
                        BadgeStrip(badges: badges),
                      ],
                    ),
                  ),

                  // 액션
                  Wrap(
                    spacing: 8,
                    children: [
                      UTHeaderRefreshButton(
                        tooltip: loc.common_refresh,
                        onRefresh: () async {
                          // 1) 재계산 트리거
                          ref.invalidate(isaacAutoInfoProvider);

                          try {
                            // 2) 새 값 대기
                            final refreshed = await ref.read(isaacAutoInfoProvider.future);
                            if (!context.mounted) return;

                            // 3) 메시지/Severity 결정 후 UiFeedback
                            final msg = statusMessage(
                              refreshed.installStatus,
                              refreshed.installSource,
                              refreshed.installPath,
                            );

                            if (refreshed.installStatus == InstallPathStatus.ok) {
                              UiFeedback.success(context, loc.common_refresh, msg);
                            } else {
                              UiFeedback.warn(context, '설치 경로 점검 필요', msg);
                            }
                          } catch (e) {
                            if (!context.mounted) return;
                            UiFeedback.error(context, loc.common_error, e.toString());
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),

              // Repentogon 설치 안내: “필요 + 미설치” 조건에서만
              if (info.needsRepentogon && !info.repentogonInstalled) ...[
                Gaps.h8,
                Expander(
                  header: const Text('Repentogon 설치 안내'),
                  content: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (info.edition == IsaacEdition.repentance) ...[
                        const Text('· GitHub Releases에서 설치 EXE를 다운로드해 실행하세요.'),
                        Gaps.h6,
                        HyperlinkButton(
                          child: const Text('Releases 열기'),
                          onPressed: () => launchUrl(Uri.parse('https://github.com/TeamREPENTOGON/REPENTOGON/releases')),
                        ),
                      ] else ...[
                        const Text('· GitHub Actions에서 최신 ZIP을 받아 게임 폴더에 압축 해제하세요.'),
                        Gaps.h6,
                        HyperlinkButton(
                          child: const Text('GitHub Actions 열기'),
                          onPressed: () => launchUrl(Uri.parse(
                              'https://github.com/TeamREPENTOGON/REPENTOGON/actions?query=branch%3Amain+is%3Asuccess')),
                        ),
                      ],
                      Gaps.h8,
                      const Text('※ 설치 후 "폴더 열기"로 DLL 배치 여부를 확인하세요.'),
                    ],
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}
