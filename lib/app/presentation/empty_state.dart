import 'dart:math' as math;
import 'package:fluent_ui/fluent_ui.dart';
import 'package:cartridge/theme/theme.dart';

class EmptyState extends StatefulWidget {
  final String title;
  final String primaryLabel;
  final VoidCallback onPrimary;
  final List<String> assetCandidates;

  final double minImageSize;
  final double maxImageSize;
  final double maxContentWidth;
  final bool invertInDark;
  final int? seed;

  const EmptyState({
    super.key,
    required this.title,
    required this.primaryLabel,
    required this.onPrimary,
    required this.assetCandidates,
    this.minImageSize = 96,
    this.maxImageSize = 200,
    this.maxContentWidth = 520,
    this.invertInDark = true,
    this.seed,
  });

  /// 404 폴더 기본 묶음을 쓰고 싶을 때 편의 생성자
  factory EmptyState.withDefault404({
    Key? key,
    required String title,
    required String primaryLabel,
    required VoidCallback onPrimary,
    int? seed,
  }) {
    const defaults = <String>[
      'assets/images/404/404_basement_144_144.png',
      'assets/images/404/404_bluebaby_144_144.png',
      'assets/images/404/404_everythingisterrible_144_144.png',
      'assets/images/404/404_heart_144_144.png',
      'assets/images/404/404_megasatan_144_144.png',
      'assets/images/404/404_MotherRep_144_144.png',
    ];
    return EmptyState(
      key: key,
      title: title,
      primaryLabel: primaryLabel,
      onPrimary: onPrimary,
      assetCandidates: defaults,
      seed: seed,
    );
  }

  @override
  State<EmptyState> createState() => _EmptyStateState();
}

class _EmptyStateState extends State<EmptyState> {
  late final String _pickedAsset;

  @override
  void initState() {
    super.initState();
    // 위젯 생명주기 동안 1회만 선택 → 리빌드에도 고정
    final rnd = (widget.seed != null) ? math.Random(widget.seed) : math.Random();
    _pickedAsset = widget.assetCandidates[rnd.nextInt(widget.assetCandidates.length)];
  }

  @override
  Widget build(BuildContext context) {
    final fTheme = FluentTheme.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final hasBoundedH = constraints.hasBoundedHeight && constraints.maxHeight.isFinite;
        final viewportH = hasBoundedH
            ? constraints.maxHeight
            : MediaQuery.of(context).size.height;

        final double imgSize = math.max(
          widget.minImageSize,
          math.min(widget.maxImageSize, viewportH * 0.35),
        );

        return Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: widget.maxContentWidth),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _InvertingAssetImage(
                    assetPath: _pickedAsset,
                    size: imgSize,
                    enabled: widget.invertInDark,
                  ),
                  Gaps.h8,
                  Text(
                    widget.title,
                    style: fTheme.typography.subtitle,
                    textAlign: TextAlign.center,
                  ),
                  Gaps.h8,
                  SizedBox(
                    height: 36,
                    child: FilledButton(
                      onPressed: widget.onPrimary,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(FluentIcons.add, size: 14),
                            Gaps.w8,
                            Text(widget.primaryLabel),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Gaps.h16,
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// 다크 모드에서만 색 반전 적용
class _InvertingAssetImage extends StatelessWidget {
  final String assetPath;
  final double size;
  final bool enabled;

  const _InvertingAssetImage({
    required this.assetPath,
    required this.size,
    required this.enabled,
  });

  static const List<double> _invertMatrix = <double>[
    -1,  0,  0, 0, 255,
    0, -1,  0, 0, 255,
    0,  0, -1, 0, 255,
    0,  0,  0, 1,   0,
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = FluentTheme.of(context).brightness == Brightness.dark;
    final image = Image.asset(
      assetPath,
      width: size,
      height: size,
      filterQuality: FilterQuality.medium,
      fit: BoxFit.contain,
    );
    if (!(enabled && isDark)) return image;
    return ColorFiltered(
      colorFilter: const ColorFilter.matrix(_invertMatrix),
      child: image,
    );
  }
}
