import 'dart:io';
import 'package:cartridge/l10n/app_localizations.dart';
import 'package:file_selector/file_selector.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:cartridge/features/cartridge/instances/presentation/widgets/instance_image/sprite_sheet.dart';
import 'package:cartridge/features/cartridge/instances/domain/instance_policy.dart';
import 'package:cartridge/theme/theme.dart';

sealed class InstanceImagePickResult {
  const InstanceImagePickResult();
}

class PickSprite extends InstanceImagePickResult {
  final int index;
  const PickSprite(this.index);
}

class PickUserFile extends InstanceImagePickResult {
  final String path;
  final BoxFit fit;
  const PickUserFile(this.path, {this.fit = BoxFit.cover});
}

class PickClear extends InstanceImagePickResult {
  const PickClear();
}

/// 파일 존재 여부 가드(try/catch 포함)
bool _isUsableUserFile(String? path) {
  if (path == null || path.isEmpty) return false;
  try {
    return File(path).existsSync();
  } catch (_) {
    return false;
  }
}

Future<InstanceImagePickResult?> showInstanceImagePickerDialog(
    BuildContext context, {
      required String seedForDefault, // API 호환을 위해 유지 (현재 미사용)
      int? initialSpriteIndex,
      String? initialUserFilePath,
    }) async {
  int tabIndex = (initialUserFilePath != null) ? 1 : 0;
  int selectedSprite =
      initialSpriteIndex ?? (0.clamp(0, InstanceImageRules.spriteFilledCount - 1));
  String? pickedPath = initialUserFilePath;
  BoxFit fit = BoxFit.cover;

  bool userFileExists = _isUsableUserFile(pickedPath);
  bool previewDecodeError = false;

  int hoveredSprite = -1;
  int pressedSprite = -1;

  final GlobalKey selectedSpriteKey = GlobalKey();
  final GlobalKey gridKey = GlobalKey();
  final ScrollController spriteScrollController = ScrollController();
  final ScrollController detailsScrollController = ScrollController();
  bool didEnsureSpriteVisible = false;

  // ---------------------------
  // 유틸
  // ---------------------------

  // 스프라이트 셀 렌더
  Widget spriteTile(BuildContext ctx, int index, {double size = 80, BorderRadius? br}) {
    return SpriteTile(
      asset: InstanceImageRules.assetPath,
      grid: grid,
      index: index,
      width: size,
      height: size,
      borderRadius: br ?? BorderRadius.circular(8),
    );
  }

  // 파일 선택 후 상태 갱신
  Future<void> pickUserFile(StateSetter setState) async {
    const typeGroup = XTypeGroup(
      label: 'images',
      extensions: ['png', 'jpg', 'jpeg', 'webp', 'bmp'],
    );
    final file = await openFile(acceptedTypeGroups: [typeGroup]);
    if (file != null) {
      setState(() {
        pickedPath = file.path;
        userFileExists = _isUsableUserFile(pickedPath);
        previewDecodeError = false; // 새 파일 선택 시 초기화
      });
    }
  }

  // 보기 방식 라디오(Fluent RadioButton)
  Widget boxFitRadios({
    required AppLocalizations loc,
    required BoxFit value,
    required ValueChanged<BoxFit> onChanged,
  }) {
    final options = <(BoxFit, String)>[
      (BoxFit.cover,     loc.instance_image_boxfit_cover),
      (BoxFit.contain,   loc.instance_image_boxfit_contain),
      (BoxFit.fill,      loc.instance_image_boxfit_fill),
      (BoxFit.fitWidth,  loc.instance_image_boxfit_fitWidth),
      (BoxFit.fitHeight, loc.instance_image_boxfit_fitHeight),
      (BoxFit.none,      loc.instance_image_boxfit_none),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(options.length, (i) {
        final o = options[i];
        final selected = value == o.$1;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: RadioButton(
            checked: selected,
            onChanged: (checked) {
              if (checked) onChanged(o.$1);
            },
            content: Text(o.$2, style: AppTypography.body),
          ),
        );
      }),
    );
  }

  return await showDialog<InstanceImagePickResult?>(
    context: context,
    barrierDismissible: true,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) {
        final fTheme = FluentTheme.of(ctx);
        final dividerColor = fTheme.dividerColor;
        final accent = fTheme.accentColor.normal;
        final loc = AppLocalizations.of(ctx);
        final sem = ProviderScope.containerOf(ctx).read(themeSemanticsProvider);

        WidgetsBinding.instance.addPostFrameCallback((_) async {
          if (!didEnsureSpriteVisible && tabIndex == 0 && spriteScrollController.hasClients) {
            didEnsureSpriteVisible = true;

            // 1) 대략적 오프셋으로 먼저 점프(셀을 빌드시키기 위함)
            final gridBox = gridKey.currentContext?.findRenderObject() as RenderBox?;
            if (gridBox != null) {
              const spacing = 8.0; // gridDelegate와 동일
              final pad = AppSpacing.md; // GridView.padding (좌우)
              final cols = InstanceImageRules.spriteCols;
              final gridWidth = gridBox.size.width;
              final tileWidth = (gridWidth - pad * 2 - spacing * (cols - 1)) / cols;
              final row = selectedSprite ~/ cols;
              final rowExtent = tileWidth + spacing; // aspectRatio=1 → 높이=tileWidth
              final approxOffset = (rowExtent * row).clamp(
                0.0,
                spriteScrollController.position.maxScrollExtent,
              );
              // 점프(애니메이션 없이 빠르게)
              spriteScrollController.jumpTo(approxOffset);
            }

            // 2) 한 프레임 양보 후 정확히 맞추기
            await Future<void>.delayed(const Duration(milliseconds: 16));
            final c = selectedSpriteKey.currentContext;
            if (c != null && c.mounted) {
              Scrollable.ensureVisible(
                c,
                alignment: 0.3,
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOut,
              );
            }
          }
        });

        // ---------------------------
        // 스프라이트 탭
        // ---------------------------
        Widget spriteGrid() {
          return Container(
            decoration: BoxDecoration(
              color: fTheme.cardColor,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: dividerColor),
            ),
            child: GridView.builder(
              key: gridKey,
              controller: spriteScrollController,
              padding: const EdgeInsets.all(AppSpacing.md),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: InstanceImageRules.spriteCols,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: 1,
              ),
              itemCount: InstanceImageRules.spriteFilledCount,
              itemBuilder: (_, i) {
                final isSelected = (i == selectedSprite);
                final isHovered = (i == hoveredSprite);
                final isPressed = (i == pressedSprite);

                final baseBorder = isSelected ? accent : dividerColor;
                final bg = isSelected
                    ? fTheme.acrylicBackgroundColor.withAlpha(200)
                    : fTheme.cardColor;

                final scale = isPressed ? 0.940 : (isHovered ? 0.970 : 1.0);

                final cell = AnimatedScale(
                  scale: scale,
                  duration: const Duration(milliseconds: 100),
                  curve: Curves.easeOut,
                  child: Container(
                    decoration: BoxDecoration(
                      color: bg,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: baseBorder, width: isSelected ? 2 : 1),
                    ),
                    foregroundDecoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: baseBorder, width: isSelected ? 5 : 1),
                    ),
                    child: Stack(
                      clipBehavior: Clip.hardEdge,
                      children: [
                        Center(child: spriteTile(ctx, i, size: 80)),

                        if (isSelected)
                          Positioned(
                            left: 6,
                            top: 6,
                            child: IgnorePointer(
                              ignoring: true, // 배지가 터치를 가로채지 않도록
                              child: Container(
                                padding: const EdgeInsets.all(2),
                                child: Icon(
                                  FluentIcons.skype_circle_check,
                                  size: 16,
                                  color: accent, // 배지 테두리와 톤 맞춤
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                );

                return MouseRegion(
                  onEnter: (_) => setState(() => hoveredSprite = i),
                  onExit: (_) => setState(() => hoveredSprite = -1),
                  child: GestureDetector(
                    onTapDown: (_) => setState(() => pressedSprite = i),
                    onTapCancel: () => setState(() => pressedSprite = -1),
                    onTapUp: (_) => setState(() => pressedSprite = -1),
                    onTap: () => setState(() => selectedSprite = i),
                    child: isSelected
                        ? KeyedSubtree(key: selectedSpriteKey, child: cell)
                        : cell,
                  ),
                );
              },
            ),
          );
        }

        // ---------------------------
        // 이미지 탭
        // ---------------------------
        Widget userFilePane() {
          const previewSize = 220.0;
          final br = BorderRadius.circular(12);

          // 에러 카드 UI (프리뷰 내부에 표시)
          Widget errorPreviewCard() {
            // 카드 배경을 danger.bg와 카드 배경을 살짝 블렌딩해 “붉은 기”만
            final blended = Color.alphaBlend(sem.danger.bg.withAlpha(40), fTheme.cardColor);
            return Container(
              width: previewSize,
              height: previewSize,
              decoration: BoxDecoration(
                color: blended,
                borderRadius: br,
                border: Border.all(color: sem.danger.fg.withAlpha(140)),
              ),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(FluentIcons.photo_error, size: 40, color: sem.danger.fg),
                      const SizedBox(height: 8),
                      ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: previewSize - 24),
                        child: Text(
                          loc.instance_image_error_not_found_body,
                          textAlign: TextAlign.center,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis, // overflow 방어
                          style: TextStyle(
                            color: sem.danger.fg,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }

          Widget previewCard() {
            // 1) 아무 것도 없을 때
            if (pickedPath == null) {
              return Container(
                width: previewSize,
                height: previewSize,
                decoration: BoxDecoration(
                  color: fTheme.resources.controlFillColorSecondary,
                  borderRadius: br,
                  border: Border.all(color: dividerColor),
                ),
                child: Center(
                  child: Icon(FluentIcons.photo2, size: 48, color: fTheme.inactiveColor),
                ),
              );
            }

            // 2) 파일 없음/손상/디코딩 실패 → 에러 카드로
            if (!userFileExists || previewDecodeError) {
              return errorPreviewCard();
            }

            // 3) 정상 미리보기
            return Container(
              width: previewSize,
              height: previewSize,
              decoration: BoxDecoration(
                borderRadius: br,
                border: Border.all(color: dividerColor),
              ),
              clipBehavior: Clip.antiAlias,
              child: Image.file(
                File(pickedPath!),
                width: previewSize,
                height: previewSize,
                fit: fit,
                filterQuality: FilterQuality.medium,
                gaplessPlayback: true,
                isAntiAlias: false,
                errorBuilder: (context, error, stack) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (!previewDecodeError) {
                      setState(() => previewDecodeError = true);
                    }
                  });
                  return Center(
                    child: Icon(FluentIcons.photo_error, size: 40, color: sem.danger.fg),
                  );
                },
              ),
            );
          }

          // 좌측: "미리보기" 그룹 (InfoBar는 제거, 미리보기 카드에서 바로 알림)
          Widget leftPanel() {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(
                    loc.instance_image_preview_title,
                    style: AppTypography.bodyStrong,
                  ),
                ),
                previewCard(),
              ],
            );
          }

          // 우측: 이미지 선택/현재 선택/보기 방식
          Widget rightPanel() {
            return Expanded(
              child: Scrollbar(
                controller: detailsScrollController,
                child: SingleChildScrollView(
                  controller: detailsScrollController,
                  padding: const EdgeInsets.only(right: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ① 이미지
                      InfoLabel(
                        label: loc.common_image,
                        labelStyle: AppTypography.bodyStrong,
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            Button(
                              onPressed: () => pickUserFile(setState),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(FluentIcons.folder_open),
                                  Gaps.w6,
                                  Text(loc.instance_image_pick_file),
                                ],
                              ),
                            ),
                            if (pickedPath != null)
                              Button(
                                onPressed: () {
                                  setState(() {
                                    pickedPath = null;
                                    userFileExists = false;
                                    previewDecodeError = false;
                                  });
                                },
                                child: Text(loc.common_clear_selection),
                              ),
                          ],
                        ),
                      ),

                      Gaps.h12,

                      // ② 현재 선택
                      InfoLabel(
                        label: loc.instance_image_current_selection,
                        labelStyle: AppTypography.bodyStrong,
                        child: Text(
                          pickedPath ?? loc.instance_image_no_file_selected,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight: pickedPath == null ? FontWeight.normal : FontWeight.w500,
                            color: pickedPath == null ? fTheme.inactiveColor : null,
                          ),
                        ),
                      ),

                      Gaps.h12,

                      // ③ 보기 방식 (라디오)
                      InfoLabel(
                        label: loc.instance_image_boxfit_label,
                        labelStyle: AppTypography.bodyStrong,
                        child: boxFitRadios(
                          loc: loc,
                          value: fit,
                          onChanged: (v) => setState(() => fit = v),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }

          return Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: fTheme.cardColor,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: dividerColor),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                leftPanel(),
                Gaps.w12,
                rightPanel(),
              ],
            ),
          );
        }

        // 적용 버튼 활성화 규칙
        final canApply =
            tabIndex == 0 || (pickedPath != null && userFileExists && !previewDecodeError);

        return ContentDialog(
          title: Row(
            children: [
              Icon(FluentIcons.image_search, size: 18, color: accent),
              Gaps.w4,
              Text(loc.instance_image_picker_title),
            ],
          ),
          constraints: const BoxConstraints(maxWidth: 720, maxHeight: 560),
          content: SizedBox(
            width: 680,
            height: 420,
            child: TabView(
              currentIndex: tabIndex,
              onChanged: (i) {
                didEnsureSpriteVisible = false;
                setState(() => tabIndex = i);
              },
              tabs: [
                Tab(
                  text: Text(loc.instance_image_picker_tab_sprite),
                  icon: const Icon(FluentIcons.grid_view_small),
                  body: spriteGrid(),
                  selectedForegroundColor: WidgetStateProperty.all(fTheme.selectionColor),
                  selectedBackgroundColor: WidgetStateProperty.all(fTheme.acrylicBackgroundColor),
                ),
                Tab(
                  text: Text(loc.instance_image_picker_tab_image),
                  icon: const Icon(FluentIcons.image_pixel),
                  body: userFilePane(),
                  selectedForegroundColor: WidgetStateProperty.all(fTheme.selectionColor),
                  selectedBackgroundColor: WidgetStateProperty.all(fTheme.acrylicBackgroundColor),
                ),
              ],
            ),
          ),
          actions: [
            Button(
              onPressed: () => Navigator.pop(ctx, null),
              child: Text(loc.common_cancel),
            ),
            FilledButton(
              onPressed: canApply
                  ? () {
                if (tabIndex == 0) {
                  Navigator.pop(ctx, PickSprite(selectedSprite));
                } else {
                  if (pickedPath != null && userFileExists && !previewDecodeError) {
                    Navigator.pop(ctx, PickUserFile(pickedPath!, fit: fit));
                  }
                }
              }
                  : null,
              child: Text(loc.common_apply),
            ),
          ],
        );
      },
    ),
  );
}
