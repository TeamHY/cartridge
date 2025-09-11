import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:cartridge/app/presentation/widgets/ui_feedback.dart';
import 'package:cartridge/features/cartridge/option_presets/option_presets.dart';
import 'package:cartridge/features/isaac/options/isaac_options.dart';
import 'package:cartridge/l10n/app_localizations.dart';
import 'package:cartridge/theme/theme.dart';

/// 추천 해상도(16:9)
const _quickSizes = <(int, int)>[
  (960, 540),
  (1280, 720),
  (1600, 900),
  (1920, 1080),
];

Future<OptionPresetView?> showOptionPresetsCreateEditDialog(
    BuildContext context, {
      OptionPresetView? initial,
      bool repentogonInstalled = false,
    }) async {
  var data = initial ?? OptionPresetView(id: '', name: '');
  final bool isEditing = (data.id.trim().isNotEmpty);

  // ── 기본 필드 컨트롤러 ───────────────────────────────────────────
  final nameCtl   = TextEditingController(text: data.name);
  final widthCtl  = TextEditingController(text: data.windowWidth?.toString() ?? '');
  final heightCtl = TextEditingController(text: data.windowHeight?.toString() ?? '');
  final xCtl      = TextEditingController(text: data.windowPosX?.toString() ?? '');
  final yCtl      = TextEditingController(text: data.windowPosY?.toString() ?? '');
  bool isFullscreen = data.fullscreen ?? false;

  // ── 고급 옵션 상태(OptionPresetView/IsaacOptions에 매핑될 필드) ──
  double gamma = (data.gamma ?? 1.0).clamp(0.5, 2.0);
  bool enableDebugConsole   = data.enableDebugConsole ?? false;
  bool pauseOnFocusLost     = data.pauseOnFocusLost   ?? true;
  bool mouseControl         = data.mouseControl       ?? true;

  // 리펜토곤(설치된 사용자에게만 노출)
  bool useRepentogon = repentogonInstalled ? (data.useRepentogon ?? true) : false;

  void applyQuickSize((int, int) s) {
    widthCtl.text = '${s.$1}';
    heightCtl.text = '${s.$2}';
  }

  // ── 스크롤 & 고급옵션 앵커 ─────────────────────────────────────────
  final scrollCtl   = ScrollController();
  final advancedAnchorKey = GlobalKey(); // ensureVisible용 앵커

  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) {
      final fTheme = FluentTheme.of(ctx);
      final loc = AppLocalizations.of(ctx);
      final accent = fTheme.accentColor.normal;
      final dividerColor = fTheme.dividerColor;
      final sem = ProviderScope.containerOf(ctx, listen: false)
          .read(themeSemanticsProvider);

      // 자동 펼침용, 라벨만 안 써먹음
      bool advancedTouched() {
        final gammaTouched = (gamma - 1.0).abs() > 1e-9;
        final debugTouched = enableDebugConsole;      // default: false
        final pauseTouched = !pauseOnFocusLost;       // default: true
        final mouseTouched = !mouseControl;           // default: true
        final repenTouched = repentogonInstalled && useRepentogon; // default: false
        return gammaTouched || debugTouched || pauseTouched || mouseTouched || repenTouched;
      }
      bool advancedOpen = advancedTouched(); // 처음 열 때 자동으로 펼침

      Widget sectionLabel(String text) => Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.xs),
        child: Text(
          text,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
      );

      Widget chipButton(String label, VoidCallback onPressed) {
        return Button(
          onPressed: onPressed,
          style: ButtonStyle(
            padding: WidgetStateProperty.all(
              const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            ),
            backgroundColor: WidgetStateProperty.all(
              fTheme.accentColor.withAlpha(
                fTheme.brightness == Brightness.dark ? 128 : 80,
              ),
            ),
            shape: WidgetStateProperty.all(
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
          ),
          child: Text(label, style: const TextStyle(fontSize: 12)),
        );
      }

      return StatefulBuilder(
        builder: (ctx, setState) {
          int? parseInt(TextEditingController c) {
            final t = c.text.trim();
            if (t.isEmpty) return null;
            return int.tryParse(t);
          }

          final previewW = parseInt(widthCtl)  ?? data.windowWidth;
          final previewH = parseInt(heightCtl) ?? data.windowHeight;
          final previewX = parseInt(xCtl)      ?? data.windowPosX;
          final previewY = parseInt(yCtl)      ?? data.windowPosY;

          void bindPreview() => setState(() {});

          void toggleFullscreen(bool v) {
            setState(() {
              isFullscreen = v;
              if (isFullscreen) {
                xCtl.text = '0';
                yCtl.text = '0';
              }
            });
          }

          Widget disableIfFullscreen(Widget child) {
            if (!isFullscreen) return child;
            return Opacity(
              opacity: 0.5,
              child: IgnorePointer(ignoring: true, child: child),
            );
          }

          return ContentDialog(
            title: Row(
              children: [
                Icon(FluentIcons.single_column_edit, size: 18, color: accent),
                Gaps.w4,
                Text(isEditing
                    ? loc.option_window_edit_title
                    : loc.option_window_create_title),
              ],
            ),
            constraints: const BoxConstraints(maxWidth: 600, maxHeight: 560),
            content: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600, maxHeight: 560),
              child: Scrollbar(
                controller: scrollCtl,
                interactive: true,
                child: SingleChildScrollView(
                  controller: scrollCtl,
                  child: Column(
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Row(
                          children: [
                            Container(
                              margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: fTheme.accentColor.withAlpha(
                                  fTheme.brightness == Brightness.dark ? 128 : 80,
                                ),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                isFullscreen
                                    ? loc.option_window_fullscreen
                                    : '${previewW ?? '-'} × ${previewH ?? '-'} • X:${previewX ?? '-'} Y:${previewY ?? '-'}',
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                            if (useRepentogon == true) ...[
                              Gaps.w8,
                              Container(
                                margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: sem.danger.fg.withAlpha(
                                    fTheme.brightness == Brightness.dark ? 128 : 80,
                                  ),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  loc.option_use_repentogon_label,
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ),
                            ]
                          ],
                        ),
                      ),

                      // 카드형 컨텐트
                      Container(
                        decoration: BoxDecoration(
                          color: fTheme.cardColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: dividerColor),
                        ),
                        padding: const EdgeInsets.all(AppSpacing.md),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 프리셋 이름
                            sectionLabel(loc.option_name_label),
                            TextBox(
                              controller: nameCtl,
                              placeholder: loc.option_preset_fallback_name,
                              onChanged: (_) => bindPreview(),
                            ),
                            Gaps.h12,
                            // 전체화면 토글
                            sectionLabel(loc.option_window_fullscreen),
                            ToggleSwitch(
                              checked: isFullscreen,
                              onChanged: toggleFullscreen,
                              content: Text(isFullscreen ? 'ON' : 'OFF'),
                            ),
                            Gaps.h12,
                            // 추천 해상도
                            sectionLabel(loc.option_window_resolution_recommend),
                            disableIfFullscreen(
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: _quickSizes
                                    .map((s) => chipButton('${s.$1} × ${s.$2}', () {
                                  applyQuickSize(s);
                                  bindPreview();
                                }))
                                    .toList(),
                              ),
                            ),
                            Gaps.h12,

                            // 가로 × 세로
                            sectionLabel(loc.option_window_size_title),
                            disableIfFullscreen(
                              Row(
                                children: [
                                  Expanded(
                                    child: TextFormBox(
                                      controller: widthCtl,
                                      placeholder: loc.option_window_width_label,
                                      keyboardType: TextInputType.number,
                                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                      onChanged: (_) => bindPreview(),
                                    ),
                                  ),
                                  Gaps.w8,
                                  Expanded(
                                    child: TextFormBox(
                                      controller: heightCtl,
                                      placeholder: loc.option_window_height_label,
                                      keyboardType: TextInputType.number,
                                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                      onChanged: (_) => bindPreview(),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Gaps.h12,

                            // X, Y
                            sectionLabel(loc.option_window_position_title),
                            disableIfFullscreen(
                              Row(
                                children: [
                                  Expanded(
                                    child: TextFormBox(
                                      controller: xCtl,
                                      placeholder: loc.option_window_pos_x_label,
                                      keyboardType: TextInputType.number,
                                      inputFormatters: [
                                        FilteringTextInputFormatter.allow(RegExp(r'-?\d+'))
                                      ],
                                      onChanged: (_) => bindPreview(),
                                    ),
                                  ),
                                  Gaps.w8,
                                  Expanded(
                                    child: TextFormBox(
                                      controller: yCtl,
                                      placeholder: loc.option_window_pos_y_label,
                                      keyboardType: TextInputType.number,
                                      inputFormatters: [
                                        FilteringTextInputFormatter.allow(RegExp(r'-?\d+'))
                                      ],
                                      onChanged: (_) => bindPreview(),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      Gaps.h12,

                      // ── 고급 옵션(접이식) ──────────────────────────────────
                      // KeyedSubtree로 앵커 키를 감싸서 ensureVisible 타겟을 안정화
                      KeyedSubtree(
                        key: advancedAnchorKey,
                        child: Expander(
                          // advancedOpen 변경 시 key를 바꿔서 내부 상태 재초기화
                          key: ValueKey<bool>(advancedOpen),
                          initiallyExpanded: advancedOpen,
                          onStateChanged: (v) => setState(() => advancedOpen = v),
                          headerBackgroundColor: WidgetStateProperty.all(fTheme.cardColor),
                          contentBackgroundColor: fTheme.cardColor,

                          header: Text(loc.option_advanced_title),
                          content: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Display: Gamma
                              sectionLabel(loc.option_gamma_label),
                              Row(
                                children: [
                                  Expanded(
                                    child: Slider(
                                      value: gamma,
                                      min: 0.5,
                                      max: 3.5,
                                      onChanged: (v) => setState(() =>
                                      gamma = double.parse(v.toStringAsFixed(2))),
                                    ),
                                  ),
                                  Gaps.w8,
                                  SizedBox(
                                    width: 56,
                                    child: TextBox(
                                      placeholder: '1.0',
                                      inputFormatters: [
                                        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                                      ],
                                      onChanged: (t) {
                                        final v = double.tryParse(t);
                                        if (v == null) return;
                                        setState(() => gamma = v.clamp(0.5, 3.5));
                                      },
                                      controller:
                                      TextEditingController(text: gamma.toStringAsFixed(2)),
                                    ),
                                  ),
                                ],
                              ),
                              Gaps.h12,

                              // Gameplay/System
                              sectionLabel(loc.option_gameplay_title),
                              Wrap(
                                spacing: 12,
                                runSpacing: 8,
                                children: [
                                  ToggleSwitch(
                                    checked: enableDebugConsole,
                                    onChanged: (v) => setState(() => enableDebugConsole = v),
                                    content: Text(loc.option_debug_console_label),
                                  ),
                                  ToggleSwitch(
                                    checked: pauseOnFocusLost,
                                    onChanged: (v) => setState(() => pauseOnFocusLost = v),
                                    content: Text(loc.option_pause_on_focus_lost_label),
                                  ),
                                  ToggleSwitch(
                                    checked: mouseControl,
                                    onChanged: (v) => setState(() => mouseControl = v),
                                    content: Text(loc.option_mouse_control_label),
                                  ),
                                ],
                              ),
                              Gaps.h12,

                              // Repentogon (설치된 사용자만 노출)
                              if (repentogonInstalled) ...[
                                const Divider(),
                                sectionLabel('Repentogon'),
                                ToggleSwitch(
                                  checked: useRepentogon,
                                  onChanged: (v) => setState(() => useRepentogon = v),
                                  content: Text(loc.option_use_repentogon_label),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
              actions: [
                SizedBox(
                  width: double.infinity,
                  child: Row(
                    children: [
                      // 1) Advanced options (flex=3)
                      Expanded(
                        flex: 3,
                        child: SizedBox(
                          width: double.infinity, // 셀 폭 가득
                          child: HyperlinkButton(
                            onPressed: () {
                              if (!advancedOpen) setState(() => advancedOpen = true);
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                if (!ctx.mounted) return;
                                final anchorCtx = advancedAnchorKey.currentContext;
                                if (anchorCtx == null || !anchorCtx.mounted) return;
                                Scrollable.ensureVisible(
                                  anchorCtx,
                                  alignment: 0.05,
                                  duration: const Duration(milliseconds: 240),
                                );
                              });
                            },
                            style: ButtonStyle(
                              padding: WidgetStateProperty.all(
                                const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                              ),
                            ),
                            // 버튼 내용은 왼쪽 정렬 + 말줄임
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Row(
                                mainAxisSize: MainAxisSize.max,
                                children: [
                                  Icon(
                                    advancedOpen
                                        ? FluentIcons.arrow_up_right8
                                        : FluentIcons.arrow_down_right8,
                                    size: 14,
                                  ),
                                  Gaps.w6,
                                  Flexible(
                                    child: Text(
                                      loc.option_advanced_title,
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                      softWrap: false,
                                    ),
                                  ),
                                  if (advancedTouched()) ...[
                                    Gaps.w6,
                                    const Icon(FluentIcons.brightness, size: 8),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      Gaps.w8,

                      // 2) Cancel (flex=2)
                      Expanded(
                        flex: 2,
                        child: SizedBox(
                          width: double.infinity,
                          child: Button(
                            onPressed: () => Navigator.pop(ctx, false),
                            style: ButtonStyle(
                              padding: WidgetStateProperty.all(
                                const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                              ),
                            ),
                            // 버튼 내용은 오른쪽 정렬 + 말줄임
                            child: Align(
                              alignment: Alignment.center,
                              child: Text(
                                loc.common_cancel,
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                                softWrap: false,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Gaps.w8,

                      // 3) Save (flex=2)
                      Expanded(
                        flex: 2,
                        child: SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: () {
                              final name = nameCtl.text.trim();
                              String? err;
                              if (name.isEmpty) {
                                err = loc.option_window_error_name_required;
                              } else if (!isFullscreen) {
                                final width = int.tryParse(widthCtl.text.trim());
                                final height = int.tryParse(heightCtl.text.trim());
                                final posX = int.tryParse(xCtl.text.trim());
                                final posY = int.tryParse(yCtl.text.trim());
                                if (width == null ||
                                    width < IsaacOptionsSchema.winMin ||
                                    width > IsaacOptionsSchema.winMax) {
                                  err = loc.option_window_error_width_range;
                                } else if (height == null ||
                                    height < IsaacOptionsSchema.winMin ||
                                    height > IsaacOptionsSchema.winMax) {
                                  err = loc.option_window_error_height_range;
                                } else if (posX == null ||
                                    posX < IsaacOptionsSchema.posMin ||
                                    posX > IsaacOptionsSchema.posMax) {
                                  err = loc.option_window_error_posx_range;
                                } else if (posY == null ||
                                    posY < IsaacOptionsSchema.posMin ||
                                    posY > IsaacOptionsSchema.posMax) {
                                  err = loc.option_window_error_posy_range;
                                }
                              }
                              if (err != null) {
                                UiFeedback.error(ctx, loc.common_error, err);
                                return;
                              }
                              Navigator.pop(ctx, true);
                            },
                            style: ButtonStyle(
                              padding: WidgetStateProperty.all(
                                const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                              ),
                            ),
                            // 버튼 내용은 오른쪽 정렬 + 말줄임
                            child: Align(
                              alignment: Alignment.center,
                              child: Text(
                                loc.common_save,
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                                softWrap: false,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
          );
        },
      );
    },
  );

  scrollCtl.dispose();
  if (ok != true) return null;

  final name   = nameCtl.text.trim();
  final width  = int.tryParse(widthCtl.text.trim());
  final height = int.tryParse(heightCtl.text.trim());
  final posX   = int.tryParse(xCtl.text.trim());
  final posY   = int.tryParse(yCtl.text.trim());

  return data.copyWith(
    name: name,
    windowWidth : isFullscreen ? null : width,
    windowHeight: isFullscreen ? null : height,
    windowPosX  : isFullscreen ? 0    : posX,
    windowPosY  : isFullscreen ? 0    : posY,
    fullscreen  : isFullscreen,
    gamma: gamma,
    enableDebugConsole: enableDebugConsole,
    pauseOnFocusLost: pauseOnFocusLost,
    mouseControl: mouseControl,
    useRepentogon: repentogonInstalled ? useRepentogon : false,
  );
}
