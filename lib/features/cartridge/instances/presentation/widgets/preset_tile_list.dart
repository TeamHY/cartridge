import 'dart:ui';

import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:cartridge/features/cartridge/instances/instances.dart';
import 'package:cartridge/features/cartridge/mod_presets/mod_presets.dart';
import 'package:cartridge/theme/theme.dart';

class PresetTileList extends ConsumerStatefulWidget {
  const PresetTileList({
    super.key,
    required this.presets,
    required this.selectedIds,
    required this.onToggleSelected,
    this.controller,
    this.ensurePresetOnlyMode,
  });

  final List<AppliedPresetLabelView> presets;
  final Set<String> selectedIds;
  final ValueChanged<String> onToggleSelected;
  final ScrollController? controller;
  final VoidCallback? ensurePresetOnlyMode;

  @override
  ConsumerState<PresetTileList> createState() => _PresetTileListState();
}

class _PresetTileListState extends ConsumerState<PresetTileList> {

  // ── 스윕 상태 ─────────────────────────────────────────────────────────
  bool _sweeping = false;        // 현재 스윕 중?
  bool? _sweepSelect;            // 스윕 목표 상태(true=선택, false=해제)
  Offset? _downPos;              // 타일 기준 첫 눌림 위치
  DateTime? _downAt;             // 첫 눌림 시각
  bool _downWasSelected = false; // 시작 타일의 기존 선택상태
  bool _downInSweepZone = false; // 체크박스 영역에서 시작했는가?

  static const double _kSweepDistance = 6.0;    // 이동 임계값(px)
  static const int    _kHoldToSweepMs = 160;    // 홀드 임계값(ms)
  static const double _kSweepStartWidthPx = 56; // 좌측 체크 시작 영역 폭

  void _resetSweep() {
    _sweeping = false;
    _sweepSelect = null;
    _downPos = null;
    _downAt = null;
    _downInSweepZone = false;
  }

  // 현재 타일의 체크 상태(checked)와 스윕 목표(_sweepSelect)를 비교해 필요 시만 토글
  void _applySweepToTile({required String id, required bool checked}) {
    if (_sweepSelect == null) return;

    // 프리셋만 보기 모드 보장
    widget.ensurePresetOnlyMode?.call();

    if (_sweepSelect! && !checked) {
      widget.onToggleSelected(id); // 선택으로 맞춤
    } else if (!_sweepSelect! && checked) {
      widget.onToggleSelected(id); // 해제로 맞춤
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = fluent.FluentTheme.of(context);

    if (widget.presets.isEmpty) {
      return Text('No presets', style: TextStyle(color: theme.inactiveColor));
    }

    final asyncList = ref.watch(modPresetsControllerProvider);
    final countsById = asyncList.maybeWhen<Map<String, int>>(
      data: (list) => { for (final v in list) v.key: v.enabledCount },
      orElse: () => const {},
    );

    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerUp: (_) => setState(_resetSweep),
      onPointerCancel: (_) => setState(_resetSweep),
      child: ListView.separated(
        controller: widget.controller,
        itemCount: widget.presets.length,
        separatorBuilder: (_, __) => Gaps.h6,
        itemBuilder: (context, index) {
          final p = widget.presets[index];
          final id = p.presetId;
          final title = (p.presetName.trim().isNotEmpty) ? p.presetName : id;
          final checked = widget.selectedIds.contains(id);
          final count = countsById[id];

          final tileCore = SidebarTile(
            leading: fluent.Checkbox(
              checked: checked,
              onChanged: (_) {
                widget.ensurePresetOnlyMode?.call();
                widget.onToggleSelected(id);
              },
            ),
            label: title,
            count: count,
            selected: checked,
            onTap: () {
              widget.ensurePresetOnlyMode?.call();
              widget.onToggleSelected(id);
            },
            tooltip: title,
          );

          return Listener(
            onPointerDown: (e) {
              if (e.kind == PointerDeviceKind.mouse && e.buttons == kPrimaryMouseButton) {
                _sweeping = false;
                _sweepSelect = null;
                _downPos = e.localPosition;
                _downAt = DateTime.now();
                _downWasSelected = checked;
                _downInSweepZone = _downPos!.dx <= _kSweepStartWidthPx;
              }
            },
            onPointerMove: (e) {
              if (_downPos == null || _downAt == null || _sweeping) return;
              final moved = (e.localPosition - _downPos!).distance;
              final heldMs = DateTime.now().difference(_downAt!).inMilliseconds;

              // 체크박스 영역에서 시작 + 임계 이동/홀드 초과 → 스윕 시작
              if (_downInSweepZone && (moved > _kSweepDistance || heldMs > _kHoldToSweepMs)) {
                setState(() {
                  _sweeping = true;
                  _sweepSelect = !_downWasSelected; // 시작 타일 상태의 반대로 쓸지 결정
                });
                // 시작 타일 즉시 적용
                _applySweepToTile(id: id, checked: checked);
              }
            },
            child: MouseRegion(
              onEnter: (_) {
                if (_sweeping) {
                  // 지나가는 타일들 적용
                  _applySweepToTile(id: id, checked: checked);
                }
              },
              child: tileCore,
            ),
          );
        },
      ),
    );
  }
}