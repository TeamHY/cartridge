import 'dart:ui' as ui;
import 'package:flutter/foundation.dart'; // SynchronousFuture
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

const grid = SpriteSheetGrid(
  cols: 8,
  rows: 38,
  cellSize: 64,
  gap: 1,
  outerLeftTop: 1,
  hasBottomOuter: false,
);

/// 스프라이트 시트의 격자 메타 정보
class SpriteSheetGrid {
  final int cols;
  final int rows;
  final double cellSize;
  final double gap;
  final double outerLeftTop;
  final bool hasBottomOuter;

  const SpriteSheetGrid({
    required this.cols,
    required this.rows,
    this.cellSize = 64,
    this.gap = 1,
    this.outerLeftTop = 1,
    this.hasBottomOuter = false,
  });

  Rect srcRect(int col, int row) {
    assert(col >= 0 && col < cols);
    assert(row >= 0 && row < rows);
    final dx = outerLeftTop + col * (cellSize + gap);
    final dy = outerLeftTop + row * (cellSize + gap);
    return Rect.fromLTWH(dx, dy, cellSize, cellSize);
  }

  (int col, int row) colRowOfIndex(int index) {
    assert(index >= 0 && index < cols * rows);
    final row = index ~/ cols;
    final col = index % cols;
    return (col, row);
  }

  Size expectedSheetSize() {
    final w = cellSize * cols + gap * (cols + 1);
    final h = cellSize * rows + gap * rows;
    return Size(w, h);
  }
}

/// 시트를 로드/캐싱 (+ 동기 접근 지원)
class SpriteSheetLoader {
  static final Map<String, Future<ui.Image>> _futures = {};
  static final Map<String, ui.Image> _images = {};

  /// 이미 디코드된 이미지가 있으면 즉시 반환(깜박임 방지의 핵심)
  static ui.Image? getSync(String asset) => _images[asset];

  static Future<ui.Image> load(String asset) {
    final img = _images[asset];
    if (img != null) {
      return SynchronousFuture<ui.Image>(img);
    }
    return _futures.putIfAbsent(asset, () async {
      final data = await rootBundle.load(asset);
      final bytes = data.buffer.asUint8List();
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      final decoded = frame.image;
      _images[asset] = decoded; // 동기 조회용 저장
      return decoded;
    });
  }
}

/// 단일 스프라이트를 그려주는 위젯
class SpriteTile extends StatelessWidget {
  final String asset;
  final SpriteSheetGrid grid;

  final int? col;
  final int? row;
  final int? index;

  final double? width;
  final double? height;
  final double scale; // width/height가 없으면 cellSize*scale

  /// 출력 영역 둥근 모서리. null이면 클리핑 생략(성능 ↑)
  final BorderRadius? borderRadius;

  const SpriteTile({
    super.key,
    required this.asset,
    required this.grid,
    this.col,
    this.row,
    this.index,
    this.width,
    this.height,
    this.scale = 1.0,
    this.borderRadius,
  }) : assert(
  ((col != null && row != null) ^ (index != null)),
  'Use either (col,row) OR index.',
  );

  @override
  Widget build(BuildContext context) {
    final dstW = width ?? (grid.cellSize * scale);
    final dstH = height ?? (grid.cellSize * scale);
    final (c, r) = index != null ? grid.colRowOfIndex(index!) : (col!, row!);
    final src = grid.srcRect(c, r);

    // 1) 먼저 동기 캐시 조회 → 있으면 즉시 그려서 첫 프레임 공백 방지
    final syncImage = SpriteSheetLoader.getSync(asset);
    if (syncImage != null) {
      return RepaintBoundary(
        child: CustomPaint(
          size: Size(dstW, dstH),
          painter: _SpritePainter(
            image: syncImage,
            src: src,
            borderRadius: borderRadius,
          ),
        ),
      );
    }

    // 2) 최초 로드만 비동기, 이후부터는 위의 동기 경로로 바로 그림
    return FutureBuilder<ui.Image>(
      future: SpriteSheetLoader.load(asset),
      builder: (context, snap) {
        final image = snap.data;
        if (image == null) {
          // loading 중에도 사이즈는 유지해 레이아웃 점프/깜박임 방지
          return SizedBox(width: dstW, height: dstH);
        }
        return RepaintBoundary(
          child: CustomPaint(
            size: Size(dstW, dstH),
            painter: _SpritePainter(
              image: image,
              src: src,
              borderRadius: borderRadius,
            ),
          ),
        );
      },
    );
  }
}

class _SpritePainter extends CustomPainter {
  final ui.Image image;
  final Rect src;
  final BorderRadius? borderRadius;

  _SpritePainter({
    required this.image,
    required this.src,
    this.borderRadius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final dst = Offset.zero & size;
    final paint = Paint()..filterQuality = FilterQuality.medium;

    if (borderRadius == null) {
      canvas.drawImageRect(image, src, dst, paint);
      return;
    }

    final rrect = borderRadius!.toRRect(dst);
    canvas.save();
    canvas.clipRRect(rrect);
    canvas.drawImageRect(image, src, dst, paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_SpritePainter old) {
    return image != old.image || src != old.src || borderRadius != old.borderRadius;
  }
}
