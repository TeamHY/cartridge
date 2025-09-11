import 'dart:io';
import 'package:file_selector/file_selector.dart';
import 'package:fluent_ui/fluent_ui.dart';

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

  // ---------------------------
  // 유틸
  // ---------------------------

  // 스프라이트 셀 렌더
  Widget spriteTile(BuildContext ctx, int index,
      {double size = 80, BorderRadius? br}) {
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
    required BuildContext ctx,
    required BoxFit value,
    required ValueChanged<BoxFit> onChanged,
  }) {
    final options = <(BoxFit, String)>[
      (BoxFit.cover, '가득 채우기'),
      (BoxFit.contain, '전체 보이기'),
      (BoxFit.fill, '늘리기(왜곡 가능)'),
      (BoxFit.fitWidth, '너비 맞춤'),
      (BoxFit.fitHeight, '높이 맞춤'),
      (BoxFit.none, '원본 크기'),
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
            // 라벨 + 보조설명
            content: Text(o.$2, style: const TextStyle(fontWeight: FontWeight.w600)),
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

        // ---------------------------
        // 스프라이트 탭
        // ---------------------------
        Widget spriteGrid() {
          return Container(
            decoration: BoxDecoration(
              color: fTheme.cardColor,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: dividerColor,
              ),
            ),
            child: GridView.builder(
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
                final bg =
                isSelected ? fTheme.acrylicBackgroundColor.withAlpha(200) : fTheme.cardColor;

                Widget cell = Container(
                  decoration: BoxDecoration(
                    color: bg,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: baseBorder,
                      width: isSelected ? 2 : 1,
                    ),
                    boxShadow: isHovered
                        ? [
                      BoxShadow(
                        color: accent.withAlpha(50),
                        blurRadius: 10,
                        spreadRadius: 1,
                        offset: const Offset(0, 2),
                      ),
                    ]
                        : const [],
                  ),
                  foregroundDecoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: baseBorder,
                      width: isSelected ? 5 : 1,
                    ),
                  ),
                  child: Center(child: spriteTile(ctx, i, size: 80)),
                );

                final scale = isPressed ? 0.940 : (isHovered ? 0.970 : 1.0);

                return MouseRegion(
                  onEnter: (_) => setState(() => hoveredSprite = i),
                  onExit: (_) => setState(() => hoveredSprite = -1),
                  child: GestureDetector(
                    onTapDown: (_) => setState(() => pressedSprite = i),
                    onTapCancel: () => setState(() => pressedSprite = -1),
                    onTapUp: (_) => setState(() => pressedSprite = -1),
                    onTap: () => setState(() => selectedSprite = i),
                    child: AnimatedScale(
                      scale: scale,
                      duration: const Duration(milliseconds: 100),
                      curve: Curves.easeOut,
                      child: cell,
                    ),
                  ),
                );
              },
            ),
          );
        }

        // ---------------------------
        // 이미지 탭 (옵션 A: 2-Column)
        // ---------------------------
        Widget userFilePane() {
          const previewSize = 220.0; // 80x80 미리보기
          final br = BorderRadius.circular(12);

          Widget previewCard() {
            // 1) 아무 것도 없을 때
            if (pickedPath == null) {
              return Container(
                width: previewSize,
                height: previewSize,
                decoration: BoxDecoration(
                  color: fTheme.cardColor,
                  borderRadius: br,
                  border: Border.all(color: dividerColor),
                  boxShadow: const [
                    BoxShadow(
                      blurRadius: 14,
                      spreadRadius: 1,
                      offset: Offset(0, 4),
                      color: Color(0x22000000),
                    )
                  ],
                ),
                child: Center(
                  child: Icon(
                    FluentIcons.photo2,
                    size: 48,
                    color: fTheme.inactiveColor,
                  ),
                ),
              );
            }

            // 2) 파일 없음/손상 등 → 아이콘 플레이스홀더
            if (!userFileExists || previewDecodeError) {
              return Container(
                width: previewSize,
                height: previewSize,
                decoration: BoxDecoration(
                  color: fTheme.cardColor,
                  borderRadius: br,
                  border: Border.all(color: dividerColor),
                  boxShadow: const [
                    BoxShadow(
                      blurRadius: 14,
                      spreadRadius: 1,
                      offset: Offset(0, 4),
                      color: Color(0x22000000),
                    )
                  ],
                ),
                child: Center(
                  child: Icon(
                    FluentIcons.photo2,
                    size: 48,
                    color: fTheme.inactiveColor,
                  ),
                ),
              );
            }

            // 3) 정상 미리보기
            return Container(
              width: previewSize,
              height: previewSize,
              decoration: BoxDecoration(
                borderRadius: br,
                border: Border.all(color: dividerColor),
                boxShadow: const [
                  BoxShadow(
                    blurRadius: 14,
                    spreadRadius: 1,
                    offset: Offset(0, 4),
                    color: Color(0x22000000),
                  )
                ],
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
                // 디코딩 실패 시 상태 반영 + 아이콘 플레이스홀더로 전환
                errorBuilder: (context, error, stack) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (!previewDecodeError) {
                      setState(() => previewDecodeError = true);
                    }
                  });
                  return Center(
                    child: Icon(
                      FluentIcons.photo2,
                      size: 48,
                      color: fTheme.inactiveColor,
                    ),
                  );
                },
              ),
            );
          }

          // 좌측: "미리보기" 그룹 + (조건부) InfoBar(카드 아래)
          Widget leftPanel() {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(bottom: 6),
                  child: Text(
                    '미리보기',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                previewCard(),
                if (pickedPath != null && (!userFileExists || previewDecodeError)) ...[
                  Gaps.h8,
                  SizedBox(
                    width: 300, // InfoBar 가독성 확보
                    child: InfoBar(
                      title: const Text('파일을 찾을 수 없거나 손상되었습니다.'),
                      content: const Text('다시 선택하거나 스프라이트 탭을 사용하세요.'),
                      severity: InfoBarSeverity.error,
                      isLong: true,
                      action: Button(
                        onPressed: () {
                          pickUserFile(setState);
                        },
                        child: const Text('다시 선택…'),
                      ),
                    ),
                  ),
                ],
              ],
            );
          }

          // 우측: 섹션 4개(이미지/현재 선택/보기 방식/안내)
          Widget rightPanel() {
            return Expanded(
              child: Scrollbar( // fluent_ui의 Scrollbar
                child: SingleChildScrollView(
                  padding: const EdgeInsets.only(right: 8), // 스크롤바와 내용 간격 확보
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ① 이미지
                      InfoLabel(
                        label: '이미지',
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            Button(
                              onPressed: () {
                                pickUserFile(setState);
                              },
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(FluentIcons.folder_open),
                                  SizedBox(width: 6),
                                  Text('이미지 파일 선택…'),
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
                                child: const Text('선택 해제'),
                              ),
                          ],
                        ),
                      ),

                      Gaps.h12,

                      // ② 현재 선택
                      InfoLabel(
                        label: '현재 선택',
                        child: Text(
                          pickedPath ?? '선택된 파일이 없습니다.',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight: pickedPath == null ? FontWeight.normal : FontWeight.w500,
                            color: (pickedPath != null && (!userFileExists || previewDecodeError))
                                ? Colors.red
                                : (pickedPath == null ? fTheme.inactiveColor : null),
                          ),
                        ),
                      ),

                      Gaps.h12,

                      // ③ 보기 방식 (라디오 버튼)
                      InfoLabel(
                        label: '보기 방식',
                        child: boxFitRadios(
                          ctx: ctx,
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
              border: Border.all(
                color: dividerColor,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                leftPanel(),
                const SizedBox(width: AppSpacing.md),
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
              const SizedBox(width: AppSpacing.xs),
              const Text('인스턴스 이미지 선택'),
            ],
          ),
          constraints: const BoxConstraints(maxWidth: 720, maxHeight: 560),
          content: SizedBox(
            width: 680,
            height: 420,
            child: TabView(
              currentIndex: tabIndex,
              onChanged: (i) => setState(() => tabIndex = i),
              tabs: [
                Tab(
                  text: const Text('스프라이트'),
                  icon: const Icon(FluentIcons.grid_view_small),
                  body: spriteGrid(),
                  selectedForegroundColor: WidgetStateProperty.all(fTheme.selectionColor),
                  selectedBackgroundColor: WidgetStateProperty.all(fTheme.acrylicBackgroundColor),
                ),
                Tab(
                  text: const Text('이미지'),
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
              child: const Text('취소'),
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
              child: const Text('적용'),
            ),
          ],
        );
      },
    ),
  );
}
