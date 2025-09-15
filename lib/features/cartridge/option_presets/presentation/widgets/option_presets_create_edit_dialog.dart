import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:cartridge/app/presentation/widgets/ui_feedback.dart';
import 'package:cartridge/features/cartridge/option_presets/option_presets.dart';
import 'package:cartridge/l10n/app_localizations.dart';
import 'package:cartridge/theme/theme.dart';

Future<OptionPresetView?> showOptionPresetsCreateEditDialog(
    BuildContext context, {
      OptionPresetView? initial,
      bool repentogonInstalled = false,
    }) async {
  // ── 초기값/컨트롤러 ───────────────────────────────────────────────────────────
  var data = initial ?? OptionPresetView(id: '', name: '');
  final isEditing = data.id.trim().isNotEmpty;

  final nameCtl   = TextEditingController(text: data.name);
  final widthCtl  = TextEditingController(text: data.windowWidth?.toString() ?? '');
  final heightCtl = TextEditingController(text: data.windowHeight?.toString() ?? '');
  final xCtl      = TextEditingController(text: data.windowPosX?.toString() ?? '');
  final yCtl      = TextEditingController(text: data.windowPosY?.toString() ?? '');

  bool isFullscreen = data.fullscreen ?? false;

  double gamma = (data.gamma ?? 1.0).clamp(0.5, 3.5);
  final gammaCtl = TextEditingController(text: gamma.toStringAsFixed(2));
  bool syncingGammaText = false;

  bool enableDebugConsole = data.enableDebugConsole ?? false;
  bool pauseOnFocusLost   = data.pauseOnFocusLost ?? true;
  bool mouseControl       = data.mouseControl ?? true;
  bool useRepentogon      = repentogonInstalled ? (data.useRepentogon ?? true) : false;

  void applyQuickSize((int, int) s) {
    widthCtl.text = '${s.$1}';
    heightCtl.text = '${s.$2}';
  }

  final scrollCtl = ScrollController();
  final advancedAnchorKey = GlobalKey();
  bool advancedOpen = false;

  bool advancedTouched() {
    final gammaTouched = (gamma - 1.0).abs() > 1e-9;
    final debugTouched = enableDebugConsole;
    final pauseTouched = !pauseOnFocusLost;
    final mouseTouched = !mouseControl;
    final repenTouched = repentogonInstalled && useRepentogon;
    return gammaTouched || debugTouched || pauseTouched || mouseTouched || repenTouched;
  }
  advancedOpen = advancedTouched();

  int? parseInt(TextEditingController c) {
    final t = c.text.trim();
    if (t.isEmpty) return null;
    return int.tryParse(t);
  }

  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) {
      final loc = AppLocalizations.of(ctx);
      final fTheme = FluentTheme.of(ctx);
      final accent = fTheme.accentColor.normal;
      final dividerColor = fTheme.dividerColor;

      return Consumer(
        builder: (ctx, ref, _) {
          return StatefulBuilder(
            builder: (ctx, setState) {
              final previewW = parseInt(widthCtl)  ?? data.windowWidth;
              final previewH = parseInt(heightCtl) ?? data.windowHeight;
              final previewX = parseInt(xCtl)      ?? data.windowPosX;
              final previewY = parseInt(yCtl)      ?? data.windowPosY;

              void markDirty() => setState(() {});

              return ContentDialog(
                title: Row(
                  children: [
                    Icon(FluentIcons.single_column_edit, size: 18, color: accent),
                    Gaps.w4,
                    Text(isEditing ? loc.option_window_edit_title : loc.option_window_create_title),
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
                          // 상단 상태 칩
                          OptionPresetHeader(
                            previewW: previewW,
                            previewH: previewH,
                            previewX: previewX,
                            previewY: previewY,
                            isFullscreen: isFullscreen,
                            repentogonInstalled: repentogonInstalled,
                            useRepentogon: useRepentogon,
                          ),
                          Gaps.h8,

                          // 카드형 기본 옵션
                          Container(
                            decoration: BoxDecoration(
                              color: fTheme.cardColor,
                              borderRadius: AppShapes.panel,
                              border: Border.all(color: dividerColor),
                            ),
                            padding: const EdgeInsets.all(AppSpacing.md),
                            child: OptionPresetBasicSection(
                              nameCtl: nameCtl,
                              widthCtl: widthCtl,
                              heightCtl: heightCtl,
                              xCtl: xCtl,
                              yCtl: yCtl,
                              isFullscreen: isFullscreen,
                              onToggleFullscreen: (v) {
                                setState(() {
                                  isFullscreen = v;
                                  if (isFullscreen) {
                                    xCtl.text = '0';
                                    yCtl.text = '0';
                                  }
                                });
                              },
                              onApplyQuickSize: (s) {
                                applyQuickSize(s);
                                markDirty();
                              },
                              onAnyChanged: markDirty,
                            ),
                          ),

                          Gaps.h12,

                          // 고급 옵션
                          KeyedSubtree(
                            key: advancedAnchorKey,
                            child: OptionPresetAdvancedSection(
                              initiallyExpanded: advancedOpen,
                              onExpandedChanged: (v) => setState(() => advancedOpen = v),
                              gamma: gamma,
                              gammaCtl: gammaCtl,
                              syncingGammaText: syncingGammaText,
                              onGammaSliderChanged: (v) {
                                setState(() {
                                  gamma = double.parse(v.toStringAsFixed(2));
                                  syncingGammaText = true;
                                  gammaCtl.text = gamma.toStringAsFixed(2);
                                  syncingGammaText = false;
                                });
                              },
                              onGammaTextChanged: (t) {
                                if (syncingGammaText) return;
                                final v = double.tryParse(t);
                                if (v == null) return;
                                setState(() => gamma = v.clamp(0.5, 3.5));
                              },
                              enableDebugConsole: enableDebugConsole,
                              onToggleDebugConsole: (v) => setState(() => enableDebugConsole = v),
                              pauseOnFocusLost: pauseOnFocusLost,
                              onTogglePauseOnFocusLost: (v) => setState(() => pauseOnFocusLost = v),
                              mouseControl: mouseControl,
                              onToggleMouseControl: (v) => setState(() => mouseControl = v),
                              repentogonInstalled: repentogonInstalled,
                              useRepentogon: useRepentogon,
                              onToggleRepentogon: (v) => setState(() => useRepentogon = v),
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
                        // Advanced 스크롤 토글 (flex=3)
                        Expanded(
                          flex: 3,
                          child: HyperlinkButton(
                            onPressed: () {
                              if (!advancedOpen) {
                                setState(() => advancedOpen = true);
                              }
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
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Row(
                                mainAxisSize: MainAxisSize.max,
                                children: [
                                  Icon(
                                    advancedOpen ? FluentIcons.arrow_up_right8 : FluentIcons.arrow_down_right8,
                                    size: 14,
                                  ),
                                  Gaps.w6,
                                  Flexible(
                                    child: Text(
                                      loc.option_advanced_title,
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
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
                        Gaps.w8,
                        // 취소 (flex=2)
                        Expanded(
                          flex: 2,
                          child: Button(
                            onPressed: () => Navigator.pop(ctx, false),
                            style: ButtonStyle(
                              padding: WidgetStateProperty.all(
                                const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                              ),
                            ),
                            child: Center(child: Text(loc.common_cancel, overflow: TextOverflow.ellipsis)),
                          ),
                        ),
                        Gaps.w8,
                        // 저장 (flex=2)
                        Expanded(
                          flex: 2,
                          child: FilledButton(
                            onPressed: () {
                              final err = OptionPresetValidators.validate(
                                ctx: ctx,
                                name: nameCtl.text,
                                isFullscreen: isFullscreen,
                                widthText: widthCtl.text,
                                heightText: heightCtl.text,
                                xText: xCtl.text,
                                yText: yCtl.text,
                              );
                              if (err != null) {
                                UiFeedback.error(ctx, title: AppLocalizations.of(ctx).common_save_fail, content: loc.option_preset_save_failed);
                                Navigator.pop(ctx, false);
                                return;
                              }
                              Navigator.pop(ctx, true);
                            },
                            style: ButtonStyle(
                              padding: WidgetStateProperty.all(
                                const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                              ),
                            ),
                            child: Center(child: Text(loc.common_save, overflow: TextOverflow.ellipsis)),
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
    },
  );

  // ── 정리/반환 ───────────────────────────────────────────────────────────
  scrollCtl.dispose();
  nameCtl.dispose(); widthCtl.dispose(); heightCtl.dispose(); xCtl.dispose(); yCtl.dispose();
  gammaCtl.dispose();
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
