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


  // ── 드래그 스윕 동작 파라미터 ───────────────────────────────────────────────────────────
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
      final theme = FluentTheme.of(dialogCtx);

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
                Text(loc.preset_tab_mod),
                Gaps.w8,
                Text('(${selected.length})',
                    style: TextStyle(color: theme.inactiveColor)),
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

                      // 목록
                      Expanded(
                        child: asyncList.when(
                          loading: () => const Center(child: ProgressRing()),
                          error: (e, st) =>
                              Center(child: Text('Error: $e')),
                          data: (List<ModPresetView> list) {
                            final filtered = query.isEmpty
                                ? list
                                : list
                                .where((p) => p.name
                                .toLowerCase()
                                .contains(query.toLowerCase()))
                                .toList(growable: false);

                            // 사이드바 스타일: 타일 간격 유지
                            if (filtered.isEmpty) {
                              return Center(
                                child: Text(
                                  'No presets',
                                  style: TextStyle(color: theme.inactiveColor),
                                ),
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
                                  primary: false, // PrimaryScrollController 사용 안함
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 4),
                                  itemCount: filtered.length,
                                  separatorBuilder: (_, __) =>
                                  Gaps.h6,
                                  itemBuilder: (context, index) {
                                    final p = filtered[index];
                                    final id = p.key; // presetId
                                    final isSelected =
                                    selected.contains(id);

                                    // 타일 본체 (사이드바 스타일)
                                    final tile = SidebarTile(
                                      leading: Checkbox(
                                        checked: isSelected,
                                        onChanged: (_) {
                                          // 단건 토글
                                          toggleSelection(id);
                                        },
                                      ),
                                      label: p.name,
                                      selected: isSelected,
                                      onTap: () {
                                        // 클릭(스윕 아니라면) 토글
                                        if (!sweeping) {
                                          toggleSelection(id);
                                        }
                                      },
                                      tooltip: p.name,
                                    );

                                    // 스윕 래핑: 좌측 체크영역에서만 시작
                                    return Listener(
                                      onPointerDown: (e) {
                                        if (e.buttons == kPrimaryMouseButton) {
                                          sweeping = false;      // 아직 아님
                                          sweepSelect = null;
                                          downPos = e.position;
                                          downAt = DateTime.now();
                                          downWasSelected = isSelected;
                                          // 좌측 체크영역 범위 안에서 내려갔는지(로컬X 사용)
                                          final localX = e.localPosition.dx;
                                          downInSweepZone =
                                              localX <= kSweepStartWidthPx;
                                        }
                                      },
                                      onPointerMove: (e) {
                                        if (downPos == null ||
                                            downAt == null ||
                                            sweeping ||
                                            !downInSweepZone) {
                                          return;
                                        }

                                        final moved =
                                            (e.position - downPos!).distance;
                                        final heldMs = DateTime
                                            .now()
                                            .difference(downAt!)
                                            .inMilliseconds;

                                        if (moved > kSweepDistance ||
                                            heldMs > kHoldToSweepMs) {
                                          // 스윕 시작: 첫 항목이 선택돼 있었다면 해제 모드
                                          sweeping = true;
                                          sweepSelect = !downWasSelected;
                                          applySelection(id, sweepSelect!);
                                        }
                                      },
                                      child: MouseRegion(
                                        onEnter: (_) {
                                          // 스윕 중이면 동일 상태로 적용
                                          if (sweeping &&
                                              sweepSelect != null) {
                                            applySelection(
                                                id, sweepSelect!);
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