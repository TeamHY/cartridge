import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:cartridge/app/presentation/controllers/home_controller.dart';
import 'package:cartridge/app/presentation/widgets/home/ut_split_button.dart';
import 'package:cartridge/core/log.dart';
import 'package:cartridge/core/service_providers.dart';
import 'package:cartridge/features/cartridge/option_presets/option_presets.dart';
import 'package:cartridge/features/isaac/options/isaac_options.dart';
import 'package:cartridge/theme/theme.dart';

class VanillaPlaySplitButton extends ConsumerWidget {
  const VanillaPlaySplitButton({
    super.key,
    required this.optionPresets,
    required this.buttonColor,
  });

  final List<OptionPresetView> optionPresets;
  final Color buttonColor;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fTheme = FluentTheme.of(context);
    final repAsync = ref.watch(repentogonInstalledProvider);

    // 최근/기본 프리셋 선택
    final recentPresetId = ref.watch(vanillaPresetIdProvider);
    final OptionPresetView? selected = optionPresets.isNotEmpty
        ? (recentPresetId != null
        ? optionPresets.firstWhere(
          (p) => p.id == recentPresetId,
      orElse: () => optionPresets.first,
    )
        : optionPresets.first)
        : null;

    OptionPreset toDomain(OptionPresetView v, {bool? useRepOverride}) {
      return OptionPreset(
        id: v.id,
        name: v.name,
        useRepentogon: useRepOverride ?? v.useRepentogon,
        options: IsaacOptions(
          windowWidth: v.windowWidth,
          windowHeight: v.windowHeight,
          windowPosX: v.windowPosX,
          windowPosY: v.windowPosY,
          fullscreen: v.fullscreen,
          gamma: v.gamma,
          enableDebugConsole: v.enableDebugConsole,
          pauseOnFocusLost: v.pauseOnFocusLost,
          mouseControl: v.mouseControl,
        ),
        updatedAt: v.updatedAt,
      );
    }

    Future<void> launch(OptionPresetView v, {bool? useRepOverride}) async {
      try {
        final launcher = ref.read(isaacLauncherServiceProvider);
        await launcher.launchIsaac(
          optionPreset: toDomain(v, useRepOverride: useRepOverride),
          entries: const {},
        );
      } catch (e, st) {
        logE('VanillaPlaySplitButton', 'Run vanilla failed', e, st);
      }
    }

    // 프리셋이 없는 경우: 스킨 유지한 채 disabled/간단 액션
    if (selected == null) {
      return repAsync.when(
        loading: () => UtSplitButton.single(
          mainButtonText: '바닐라 플레이',
          secondaryText: '확인 중...',
          buttonColor: fTheme.accentColor,
          onPressed: _noop,
          enabled: false,
        ),
        error: (_, __) => UtSplitButton.single(
          mainButtonText: '바닐라 플레이',
          secondaryText: '확인 실패',
          buttonColor: fTheme.accentColor,
          onPressed: _noop,
          enabled: false,
        ),
        data: (installed) => UtSplitButton.single(
          mainButtonText: '바닐라 플레이',
          secondaryText: '프리셋 없음',
          buttonColor: fTheme.accentColor,
          onPressed: () {
            // 프리셋 없이 바로 실행 (Repentogon 설치시 -repentogonoff)
            if (installed) {
              ref.read(isaacLauncherServiceProvider).launchIsaac(
                extraArgs: const ['-repentogonoff'],
              );
            } else {
              ref.read(isaacLauncherServiceProvider).launchIsaac();
            }
          },
        ),
      );
    }

    // 프리셋이 있을 때: 메인 버튼은 선택 프리셋으로 실행, 오른쪽 화살표는 패널 오픈
    return repAsync.when(
      loading: () => UtSplitButton.single(
        mainButtonText: '바닐라 플레이',
        secondaryText: '확인 중...',
        buttonColor: fTheme.accentColor,
        onPressed: _noop,
        enabled: false,
      ),
      error: (_, __) => UtSplitButton.single(
        mainButtonText: '바닐라 플레이',
        secondaryText: '확인 실패',
        buttonColor: fTheme.accentColor,
        onPressed: _noop,
        enabled: false,
      ),
      data: (installed) => UtSplitButton(
        mainButtonText: '바닐라 플레이',
        secondaryText: selected.name,
        buttonColor: buttonColor,
        onMainButtonPressed: () => launch(selected),
        dropdownMenuItems: const [],
        hasDropdown: true,
        dropdownBuilder: (ctx) => _PresetPickerPanel(
          presets: optionPresets,
          selectedId: selected.id,
          repentogonInstalled: installed,
          onPick: (id) {
            ref.read(vanillaPresetIdProvider.notifier).state = id; // 선택만 갱신
            Flyout.of(ctx).close();
          },
          width: 340,
          maxHeight: 320,
        ),
      ),
    );
  }
}

void _noop() {}

// 같은 파일 하단에 같이 둬도 됩니다.

class _PresetPickerPanel extends StatefulWidget {
  const _PresetPickerPanel({
    required this.presets,
    required this.selectedId,
    required this.repentogonInstalled,
    required this.onPick,
    this.width = 340,
    this.maxHeight = 320,
  });

  final List<OptionPresetView> presets;
  final String selectedId;
  final bool repentogonInstalled;

  final ValueChanged<String> onPick;

  final double width;
  final double maxHeight;

  @override
  State<_PresetPickerPanel> createState() => _PresetPickerPanelState();
}

class _PresetPickerPanelState extends State<_PresetPickerPanel> {
  late final ScrollController _scrollCtrl;
  late final TextEditingController _searchCtrl;
  String _q = '';

  @override
  void initState() {
    super.initState();
    _scrollCtrl = ScrollController();
    _searchCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fTheme = FluentTheme.of(context);
    final divider = fTheme.dividerColor;

    final list = (_q.trim().isEmpty)
        ? widget.presets
        : widget.presets.where((v) {
      final q = _q.toLowerCase();
      return v.name.toLowerCase().contains(q);
    }).toList(growable: false);

    return Container(
      width: widget.width,
      constraints: BoxConstraints(maxHeight: widget.maxHeight),
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
      decoration: BoxDecoration(
        color: fTheme.scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: divider),
        boxShadow: [
          BoxShadow(
            color: fTheme.shadowColor.withAlpha(30),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 헤더 + 퀵 액션
          Row(
            children: [
              const Icon(FluentIcons.toolbox, size: 14),
              const SizedBox(width: 6),
              const Text('옵션 프리셋 선택', style: TextStyle(fontWeight: FontWeight.w600)),
            ],
          ),
          Gaps.h8,
          // 검색
          TextBox(
            controller: _searchCtrl,
            onChanged: (s) => setState(() => _q = s),
            placeholder: '검색',
          ),
          Gaps.h8,
          // 목록
          Expanded(
            child: Scrollbar(
              controller: _scrollCtrl,
              interactive: true,
              child: ListView.separated(
                controller: _scrollCtrl,
                primary: false, // ★ PrimaryScrollController 사용 안 함 (스크롤바 에러 방지)
                itemCount: list.length,
                separatorBuilder: (_, __) => const SizedBox(height: 6),
                itemBuilder: (ctx, i) {
                  final v = list[i];
                  final selected = v.id == widget.selectedId;
                  return _PresetTile(
                    view: v,
                    selected: selected,
                    onTap: () => widget.onPick(v.id),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PresetTile extends ConsumerWidget {
  const _PresetTile({
    required this.view,
    required this.selected,
    required this.onTap,
  });

  final OptionPresetView view;
  final bool selected;
  final VoidCallback onTap;

  String _dimLabel(OptionPresetView v) {
    if (v.fullscreen == true) return 'Fullscreen';
    if (v.windowWidth != null && v.windowHeight != null) {
      return '${v.windowWidth}×${v.windowHeight}';
    }
    return '-';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fTheme = FluentTheme.of(context);
    final selColor = fTheme.accentColor;
    final sem = ref.watch(themeSemanticsProvider);

    return HoverButton(
      onPressed: onTap,
      builder: (ctx, states) {
        final hovered = states.isHovered;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          decoration: BoxDecoration(
            color: hovered ? fTheme.cardColor : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: selected ? selColor : Colors.transparent,
              width: selected ? 1.2 : 1.0,
            ),
          ),
          child: Row(
            children: [
              // 텍스트
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(view.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text(_dimLabel(view),
                            style: TextStyle(
                                fontSize: 11, color: fTheme.inactiveColor)),
                        Gaps.w8,
                        if (view.useRepentogon == true)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: sem.danger.bg,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'Repentogon',
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              Gaps.w8,
              if (selected) Icon(FluentIcons.check_mark, size: 14, color: selColor),
            ],
          ),
        );
      },
    );
  }
}
