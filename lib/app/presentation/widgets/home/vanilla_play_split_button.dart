import 'dart:async';

import 'package:cartridge/features/cartridge/runtime/application/game_launch_ux.dart';
import 'package:cartridge/l10n/app_localizations.dart';
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
    final loc = AppLocalizations.of(context);
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
        await ref.read(gameLaunchUxProvider).beforeLaunch(
          origin: LaunchOrigin.instancePage,
        );
        final launcher = ref.read(isaacLauncherServiceProvider);
        await launcher.launchIsaac(
          optionPreset: toDomain(v, useRepOverride: useRepOverride),
          entries: const {},
        );
      } catch (e, st) {
        logE('VanillaPlaySplitButton', 'Run vanilla failed', e, st);
      }
    }

    // 프리셋 없음 → 스킨 유지하되 상태 텍스트만
    if (selected == null) {
      return repAsync.when(
        loading: () => UtSplitButton.single(
          mainButtonText: loc.vanilla_play_button_title,
          secondaryText: loc.vanilla_play_checking,
          buttonColor: buttonColor,
          onPressed: _noop,
          enabled: false,
        ),
        error: (_, __) => UtSplitButton.single(
          mainButtonText: loc.vanilla_play_button_title,
          secondaryText: loc.vanilla_play_check_failed,
          buttonColor: buttonColor,
          onPressed: _noop,
          enabled: false,
        ),
        data: (installed) => UtSplitButton.single(
          mainButtonText: loc.vanilla_play_button_title,
          secondaryText: loc.vanilla_play_no_preset,
          buttonColor: buttonColor,
          onPressed: () {
            unawaited(ref.read(gameLaunchUxProvider).beforeLaunch(
              origin: LaunchOrigin.instancePage,
            ));
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

    // 프리셋 있음 → 메인 실행 + 우측 패널
    return repAsync.when(
      loading: () => UtSplitButton.single(
        mainButtonText: loc.vanilla_play_button_title,
        secondaryText: loc.vanilla_play_checking,
        buttonColor: buttonColor,
        onPressed: _noop,
        enabled: false,
      ),
      error: (_, __) => UtSplitButton.single(
        mainButtonText: loc.vanilla_play_button_title,
        secondaryText: loc.vanilla_play_check_failed,
        buttonColor: buttonColor,
        onPressed: _noop,
        enabled: false,
      ),
      data: (installed) => UtSplitButton(
        mainButtonText: loc.vanilla_play_button_title,
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
            ref.read(vanillaPresetIdProvider.notifier).state = id;
            Flyout.of(ctx).close();
          },
          width: 360,
          maxHeight: 360,
        ),
      ),
    );
  }
}

void _noop() {}

// === 패널 ===

class _PresetPickerPanel extends StatefulWidget {
  const _PresetPickerPanel({
    required this.presets,
    required this.selectedId,
    required this.repentogonInstalled,
    required this.onPick,
    this.width = 360,
    this.maxHeight = 360,
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
    final theme = FluentTheme.of(context);
    final loc = AppLocalizations.of(context);

    final stroke = theme.resources.controlStrokeColorDefault;
    final panelBg = theme.cardColor;
    final shadow = theme.shadowColor.withAlpha(28);

    final list = (_q.trim().isEmpty)
        ? widget.presets
        : widget.presets
        .where((v) => v.name.toLowerCase().contains(_q.toLowerCase()))
        .toList(growable: false);

    return Container(
      width: widget.width,
      constraints: BoxConstraints(maxHeight: widget.maxHeight),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.sm,
        AppSpacing.sm,
        AppSpacing.sm,
        AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: panelBg,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: stroke),
        boxShadow: [
          BoxShadow(color: shadow, blurRadius: 14, offset: const Offset(0, 8)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 헤더
          Row(
            children: [
              const Icon(FluentIcons.toolbox, size: 14),
              Gaps.w6,
              Text(
                loc.option_preset_picker_title,
                style: theme.typography.bodyStrong?.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          Gaps.h8,

          // 검색
          TextBox(
            controller: _searchCtrl,
            onChanged: (s) => setState(() => _q = s),
            placeholder: loc.common_search_placeholder,
          ),
          Gaps.h8,

          // 목록
          Expanded(
            child: list.isEmpty
                ? Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                child: Text(
                  loc.option_preset_picker_empty,
                  style: theme.typography.body,
                  textAlign: TextAlign.center,
                ),
              ),
            )
                : Scrollbar(
              controller: _scrollCtrl,
              interactive: true,
              child: ListView.separated(
                controller: _scrollCtrl,
                primary: false,
                itemCount: list.length,
                separatorBuilder: (_, __) => Gaps.h4,
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

  String _dimLabel(AppLocalizations loc, OptionPresetView v) {
    if (v.fullscreen == true) return loc.option_window_fullscreen;
    if (v.windowWidth != null && v.windowHeight != null) {
      return '${v.windowWidth}×${v.windowHeight}';
    }
    return '-';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = FluentTheme.of(context);
    final loc = AppLocalizations.of(context);

    final selStroke = theme.resources.controlStrokeColorSecondary;
    final hoverFill = theme.resources.subtleFillColorSecondary;
    final checkColor = theme.accentColor;

    return HoverButton(
      onPressed: onTap,
      builder: (ctx, states) {
        final hovered = states.isHovered;
        return ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: Stack(
            children: [
              Positioned.fill(
                child: IgnorePointer(
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 120),
                    curve: Curves.easeOut,
                    opacity: hovered ? 1.0 : 0.0,
                    child: Container(color: hoverFill),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.sm,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(
                    color: selected ? selStroke : Colors.transparent,
                    width: selected ? 1.2 : 1.0,
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            view.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.typography.bodyStrong?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          Gaps.h2,
                          Row(
                            children: [
                              Text(
                                _dimLabel(loc, view),
                                style: theme.typography.caption?.copyWith(
                                  fontSize: 11,
                                  color: theme.inactiveColor,
                                ),
                              ),
                              Gaps.w8,
                              if (view.useRepentogon == true)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: AppSpacing.xs,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: repentogonStatusOf(context, ref).bg,
                                    borderRadius: BorderRadius.circular(AppRadius.xs),
                                  ),
                                  child: Text(
                                    loc.option_use_repentogon_label,
                                    style: theme.typography.caption?.copyWith(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: repentogonStatusOf(context, ref).fg,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Gaps.w8,
                    if (selected) Icon(FluentIcons.check_mark, size: 14, color: checkColor),
                  ],
                ),
              ),
            ],
          ),
        );      },
    );
  }
}
