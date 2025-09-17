import 'package:cartridge/features/cartridge/instances/presentation/widgets/sidebar_tile.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/gestures.dart' show kPrimaryMouseButton;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:cartridge/features/cartridge/mod_presets/application/mod_presets_controller.dart';
import 'package:cartridge/features/cartridge/mod_presets/domain/models/mod_preset_view.dart';
import 'package:cartridge/l10n/app_localizations.dart';
import 'package:cartridge/theme/theme.dart';

/// 모드 프리셋 멀티 선택용 픽커 다이얼로그
/// - 내부 검색 지원(간단 contains, case-insensitive)
/// - Drag-to-select: 이동거리/홀드시간 임계값을 넘기면 스윕 시작
Future<Set<String>?> showModPresetPickerDialog(
    BuildContext context, {
      required Set<String> initialSelected,
    }) {
  final loc = AppLocalizations.of(context);
  final selected = <String>{...initialSelected};
  String query = '';

  bool sweeping = false;
  bool? sweepSelect;
  Offset? downPos;
  DateTime? downAt;
  bool downWasSelected = false;
  bool downInSweepZone = false;

  // ── 드래그 스윕 동작 파라미터 ───────────────────────────────────────────
  const double kSweepDistance = 6.0;     // 임계 이동거리
  const int    kHoldToSweepMs = 160;     // 홀드 임계시간
  const double kSweepStartWidthPx = 56;

  void resetSweep() {
    sweeping = false;
    sweepSelect = null;
    downPos = null;
    downAt = null;
    downInSweepZone = false;
  }

  return showDialog<Set<String>>(
    context: context,
    builder: (dialogCtx) {
      final fTheme = FluentTheme.of(dialogCtx);

      return StatefulBuilder(
        builder: (ctx, setState) {
          void applySelection(String id, bool toSelect) {
            final changed = toSelect ? selected.add(id) : selected.remove(id);
            if (changed) setState(() {});
          }

          void toggleSelection(String id) {
            if (selected.contains(id)) {
              selected.remove(id);
            } else {
              selected.add(id);
            }
            setState(() {});
          }

          return ContentDialog(
            constraints: const BoxConstraints(maxWidth: 560, maxHeight: 620),
            title: Row(
              children: [
                const Icon(FluentIcons.check_list, size: 18),
                Gaps.w4,
                Text(loc.preset_picker_title),
                Gaps.w8,
                Text(
                  loc.mod_presets_selected(selected.length),
                  style: AppTypography.caption.copyWith(
                    color: fTheme.resources.textFillColorSecondary,
                  ),
                ),
              ],
            ),
            content: SizedBox(
              width: 520,
              child: Consumer(
                builder: (context, ref, _) {
                  final asyncList = ref.watch(modPresetsControllerProvider);

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 검색박스
                      TextBox(
                        placeholder: loc.mod_preset_search_placeholder,
                        onChanged: (v) {
                          query = v.trim();
                          setState(() {});
                        },
                        prefix: const Padding(
                          padding: EdgeInsets.only(left: AppSpacing.xs),
                          child: Icon(FluentIcons.search),
                        ),
                      ),
                      Gaps.h4,

                      // 목록 컨테이너: 로딩/에러/데이터 상태에서도 같은 카드 레이아웃 유지
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: fTheme.cardColor,
                            borderRadius: AppShapes.panel,
                            border: Border.all(color: fTheme.dividerColor),
                          ),
                          child: asyncList.when(
                            // 1) 로딩: 스켈레톤 스타일 리스트(고정 높이)로 레이아웃 유지
                            loading: () => _LoadingListSkeleton(),
                            // 2) 에러: 코드 노출 없이 친절 문구 + 다시 시도
                            error: (_, __) => _ErrorPanel(
                              title: loc.presets_error_title,
                              message: loc.presets_error_desc,
                              onRetry: () => ref.refresh(modPresetsControllerProvider),
                            ),
                            // 3) 데이터
                            data: (List<ModPresetView> list) {
                              final filtered = query.isEmpty
                                  ? list
                                  : list
                                  .where((p) => p.name
                                  .toLowerCase()
                                  .contains(query.toLowerCase()))
                                  .toList(growable: false);

                              if (filtered.isEmpty) {
                                return _EmptyPanel(
                                  icon: FluentIcons.fabric_user_folder,
                                  title: loc.presets_empty_title,
                                  message: query.isEmpty
                                      ? loc.presets_empty_desc
                                      : loc.presets_search_empty_desc,
                                );
                              }

                              final scrollCtrl = ScrollController();

                              // 리스트 레벨에서 마우스 버튼을 떼면 스윕 종료
                              return Listener(
                                behavior: HitTestBehavior.translucent,
                                onPointerUp: (_) => resetSweep(),
                                onPointerCancel: (_) => resetSweep(),
                                child: Scrollbar(
                                  controller: scrollCtrl,
                                  interactive: true,
                                  child: ListView.separated(
                                    controller: scrollCtrl,
                                    primary: false,
                                    padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                                    itemCount: filtered.length,
                                    separatorBuilder: (_, __) => Gaps.h6,
                                    itemBuilder: (context, index) {
                                      final p = filtered[index];
                                      final id = p.key; // presetId
                                      final isSelected = selected.contains(id);

                                      final tile = SidebarTile(
                                        leading: Checkbox(
                                          checked: isSelected,
                                          onChanged: (_) => toggleSelection(id),
                                        ),
                                        label: p.name,
                                        selected: isSelected,
                                        onTap: () {
                                          if (!sweeping) toggleSelection(id);
                                        },
                                        tooltip: p.name,
                                      );

                                      return Listener(
                                        onPointerDown: (e) {
                                          if (e.buttons == kPrimaryMouseButton) {
                                            sweeping = false;
                                            sweepSelect = null;
                                            downPos = e.position;
                                            downAt = DateTime.now();
                                            downWasSelected = isSelected;
                                            final localX = e.localPosition.dx;
                                            downInSweepZone = localX <= kSweepStartWidthPx;
                                          }
                                        },
                                        onPointerMove: (e) {
                                          if (downPos == null ||
                                              downAt == null ||
                                              sweeping ||
                                              !downInSweepZone) {
                                            return;
                                          }
                                          final moved = (e.position - downPos!).distance;
                                          final heldMs = DateTime.now().difference(downAt!).inMilliseconds;
                                          if (moved > kSweepDistance || heldMs > kHoldToSweepMs) {
                                            sweeping = true;
                                            sweepSelect = !downWasSelected;
                                            applySelection(id, sweepSelect!);
                                          }
                                        },
                                        child: MouseRegion(
                                          onEnter: (_) {
                                            if (sweeping && sweepSelect != null) {
                                              applySelection(id, sweepSelect!);
                                            }
                                          },
                                          child: tile,
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            actions: [
              Button(
                child: Text(loc.common_cancel),
                onPressed: () => Navigator.of(dialogCtx).pop(null),
              ),
              FilledButton(
                child: Text(loc.common_confirm),
                onPressed: () => Navigator.of(dialogCtx).pop(selected),
              ),
            ],
          );
        },
      );
    },
  );
}

/// 로딩 스켈레톤: 실제 리스트 높이/간격 유지(우리 테마 사용)
class _LoadingListSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final fTheme = FluentTheme.of(context);
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      itemBuilder: (_, __) => Container(
        height: 40,
        decoration: BoxDecoration(
          color: fTheme.resources.controlFillColorDefault,
          borderRadius: AppShapes.chip,
          border: Border.all(color: fTheme.resources.controlStrokeColorSecondary),
        ),
      ),
      separatorBuilder: (_, __) => Gaps.h6,
      itemCount: 8,
    );
  }
}

/// 에러 패널: 코드/내부 메시지 노출하지 않고 간결하게 + 다시 시도
class _ErrorPanel extends StatelessWidget {
  const _ErrorPanel({
    required this.title,
    required this.message,
    required this.onRetry,
  });

  final String title;
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final fTheme = FluentTheme.of(context);
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(FluentIcons.info_solid, size: 36, color: fTheme.accentColor.normal),
              Gaps.h8,
              Text(title, style: AppTypography.sectionTitle, textAlign: TextAlign.center),
              Gaps.h6,
              Text(
                message,
                style: AppTypography.body.copyWith(color: fTheme.resources.textFillColorSecondary),
                textAlign: TextAlign.center,
              ),
              Gaps.h12,
              FilledButton(onPressed: onRetry, child: Text(AppLocalizations.of(context).common_retry)),
            ],
          ),
        ),
      ),
    );
  }
}

/// 빈 패널: 검색 결과 없음/전체 없음 공용
class _EmptyPanel extends StatelessWidget {
  const _EmptyPanel({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final fTheme = FluentTheme.of(context);
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 36, color: fTheme.accentColor.normal),
              Gaps.h8,
              Text(title, style: AppTypography.sectionTitle, textAlign: TextAlign.center),
              Gaps.h6,
              Text(
                message,
                style: AppTypography.body.copyWith(color: fTheme.resources.textFillColorSecondary),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
