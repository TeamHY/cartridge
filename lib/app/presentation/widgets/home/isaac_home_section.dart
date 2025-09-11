import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:cartridge/app/presentation/controllers/home_controller.dart';
import 'package:cartridge/app/presentation/widgets/badge.dart';
import 'package:cartridge/app/presentation/widgets/home/home_card.dart';
import 'package:cartridge/app/presentation/widgets/ui_feedback.dart';
import 'package:cartridge/app/presentation/widgets/ut/ut_header_refresh_button.dart';
import 'package:cartridge/features/cartridge/setting/setting.dart';
import 'package:cartridge/features/isaac/runtime/isaac_runtime.dart';
import 'package:cartridge/features/isaac/save/isaac_save.dart';
import 'package:cartridge/l10n/app_localizations.dart';
import 'package:cartridge/theme/theme.dart';

const double horizontalSpacing = 8;
const double verticalSpacing = 8;

class IsaacHomeSection extends ConsumerWidget {
  const IsaacHomeSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = AppLocalizations.of(context);
    final theme = FluentTheme.of(context);
    final sem = ref.watch(themeSemanticsProvider);

    final autoInfo = ref.watch(isaacAutoInfoProvider);
    final IsaacEdition? detectedEdition =
    autoInfo.maybeWhen(data: (info) => info.edition, orElse: () => null);

    Future<void> openProps() async => ref.read(appSettingPageControllerProvider).openGameProperties();
    Future<void> verify() async => ref.read(appSettingPageControllerProvider).runIntegrityCheck();

    return HomeCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // (감지 썸네일/타이틀/리프레시) — 기존 컨테이너 그대로 사용
          Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: theme.resources.dividerStrokeColorDefault),
            ),
            child: autoInfo.when(
              loading: () => const SizedBox(
                height: 72,
                child: Align(alignment: Alignment.centerLeft, child: ProgressBar()),
              ),
              error: (e, _) => InfoBar(
                title: const Text('에러'),
                content: Text(e.toString()),
                severity: InfoBarSeverity.error,
              ),
              data: (info) {
                final editionLabel = info.editionName ?? '감지되지 않음';
                Widget thumb;
                if (info.editionAsset != null) {
                  thumb = ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.asset(
                      info.editionAsset!,
                      width: 72, height: 72, fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(FluentIcons.photo2, size: 32),
                    ),
                  );
                } else {
                  thumb = Container(
                    width: 72, height: 72,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      border: Border.all(color: theme.resources.dividerStrokeColorDefault),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(FluentIcons.photo2, size: 28),
                  );
                }

                // Build badges similar to Settings InstallDetectPanel
                final badges = <BadgeSpec>[
                  BadgeSpec(
                    info.installSource == InstallPathSource.manual ? '수동 경로' : '자동 탐지',
                    info.installSource == InstallPathSource.manual ? sem.info : sem.warning,
                  ),
                  if (info.needsRepentogon)
                    (info.repentogonInstalled
                        ? BadgeSpec('Repentogon 사용 중', sem.danger)
                        : BadgeSpec('Repentogon 미설치', sem.danger)),
                ];

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

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        thumb,
                        Gaps.w12,
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
                        UTHeaderRefreshButton(
                          tooltip: loc.common_refresh,
                          onRefresh: () async {
                            // 1) invalidate → 2) await new value → 3) show feedback
                            ref.invalidate(isaacAutoInfoProvider);
                            try {
                              final refreshed = await ref.read(isaacAutoInfoProvider.future);
                              if (!context.mounted) return;
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

                    if (info.needsRepentogon && !info.repentogonInstalled) ...[
                      Gaps.h8,
                      Expander(
                        header: const Text('Repentogon 설치 안내'),
                        content: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (info.edition == IsaacEdition.repentance) ...[
                              const Text('· GitHub Releases에서 설치 EXE를 다운로드해 실행하세요.'),
                            ] else ...[
                              const Text('· GitHub Actions에서 최신 ZIP을 받아 게임 폴더에 압축 해제하세요.'),
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
          ),
          Gaps.h12,
          Wrap(
            spacing: horizontalSpacing,
            runSpacing: verticalSpacing,
            children: [
              _buildActionTile(
                context,
                '게임 설치 폴더 열기',
                FluentIcons.fabric_folder_fill,
                    () => openInstallFolder(context, ref),
              ),
              _buildActionTile(
                context,
                '게임 옵션 폴더 열기',
                FluentIcons.open_file,
                    () => openOptionsFolder(context, ref),
              ),
              _buildActionTile(
                context,
                '세이브 폴더 열기',
                FluentIcons.folder_open,
                    () => openSaveFolder(context, ref),
              ),
              _buildActionTile(
                context,
                '스팀 게임 옵션',
                FluentIcons.settings,
                openProps,
              ),
              _buildActionTile(
                context,
                '스팀 무결성 검사',
                FluentIcons.shield,
                verify,
                primary: true,
              ),
              _buildActionTile(
                context,
                '에덴 토큰',
                FluentIcons.pro_hockey,
                    () => openEdenTokenEditor(context, ref, detectedEdition: detectedEdition),
              ),
            ],
          )
        ],
      ),
    );
  }
}


Widget _buildActionTile(
    BuildContext context,
    String label,
    IconData icon,
    VoidCallback? onPressed, {
      bool primary = false,
      String? tooltip,
    }) {
  return LayoutBuilder(
    builder: (context, constraints) {
      final itemWidth = (constraints.maxWidth - horizontalSpacing) / 2;
      return SizedBox(
        width: itemWidth,
        child: _ActionTile(
          label: label,
          icon: icon,
          onPressed: onPressed,
          primary: primary,
          tooltip: tooltip,
        ),
      );
    },
  );
}

class _ActionTile extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final bool primary;
  final String? tooltip; 

  const _ActionTile({
    required this.label,
    required this.icon,
    required this.onPressed,
    this.primary = false,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    final dividerColor = theme.dividerColor;

    final enabled = onPressed != null;

    final tile = HoverButton(
      onPressed: onPressed,
      builder: (context, states) {
        final hovered = states.isHovered && enabled;
        final bg = primary
            ? _primaryTint(theme)
            : theme.cardColor;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: dividerColor),
            boxShadow: hovered
                ? [
              BoxShadow(
                color: theme.shadowColor.withAlpha(60),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: enabled ? null : theme.inactiveColor),
              Gaps.w8,
              Expanded(
                child: Text(
                  label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: enabled ? null : TextStyle(color: theme.inactiveColor),
                ),
              ),
            ],
          ),
        );
      },
    );
    return tooltip == null ? tile : Tooltip(message: tooltip!, child: tile);
  }
}

Color _primaryTint(FluentThemeData theme) {
  final base = theme.cardColor; // 불투명 서피스
  final overlay = theme.accentColor.normal.withAlpha(
    theme.brightness == Brightness.dark ? 84 : 48, // 기존 alpha와 비슷한 느낌
  );
  return Color.alphaBlend(overlay, base); // 불투명 결과색
}