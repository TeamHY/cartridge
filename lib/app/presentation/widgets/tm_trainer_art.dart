import 'dart:math' as math;
import 'package:flutter/widgets.dart';

class TmTrainerArt extends StatefulWidget {
  const TmTrainerArt({super.key});

  @override
  State<TmTrainerArt> createState() => _TmTrainerArtState();
}

class _TmTrainerArtState extends State<TmTrainerArt>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  )..repeat();

  // 🔹 추가: base 투명도 & 미세 떨림 크기
  static const double _baseOpacity = 0.85;
  static const double _baseJitter = 0.6;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final enableAnim = TickerMode.of(context); // 테스트/골든에선 false → 정지
    if (!enableAnim && _ctrl.isAnimating) _ctrl.stop();

    Widget base() => Image.asset(
      'assets/images/TMTRAINER_200_200.png',
      width: 200,
      height: 200,
      filterQuality: FilterQuality.none, // 픽셀아트 또렷하게
    );

    return SizedBox(
      width: 220,
      height: 220,
      child: enableAnim
          ? AnimatedBuilder(
        animation: _ctrl,
        builder: (context, _) {
          final t = _ctrl.value * 2 * math.pi;

          // 기존 값 유지 (수평/수직 글리치 이동량)
          final dx = math.sin(t) * 6.1;
          final dy = math.cos(t * 1.7) * 1.3;

          // 🔹 base의 미세 떨림 (아주 작게)
          var jx = math.sin(t * 2.1) * _baseJitter * 3.6;
          var jy = math.cos(t * 1.8) * _baseJitter;

          // (선택) 픽셀 스냅을 원하면 주석 해제 (정수 픽셀로 스냅)
          jx = jx.roundToDouble();
          jy = jy.roundToDouble();

          // 빨강, 파랑 레이어를 뒤에 배치하고,
          // 마지막에 base(투명도+미세 떨림)를 올립니다.
          return Stack(
            alignment: Alignment.center,
            children: [
              // 🔵 파랑
              Transform.translate(
                offset: Offset(-dx, dy),
                child: ColorFiltered(
                  colorFilter: const ColorFilter.matrix([
                    0, 0, 0, 0, 0,
                    0, 0, 0, 0, 0,
                    0, 0, 1, 0, 0,
                    0, 0, 0, _baseOpacity, 0,
                  ]),
                  child: base(),
                ),
              ),
              // 🔴 빨강
              Transform.translate(
                offset: Offset(dx, 0),
                child: ColorFiltered(
                  colorFilter: const ColorFilter.matrix([
                    1, 0, 0, 0, 0,
                    0, 0, 0, 0, 0,
                    0, 0, 0, 0, 0,
                    0, 0, 0, _baseOpacity, 0,
                  ]),
                  child: base(),
                ),
              ),
              Transform.translate(
                offset: Offset(jx, jy),
                child: Opacity(
                  opacity: _baseOpacity,
                  child: base(),
                ),
              ),
            ],
          );
        },
      )
          : Opacity(
        // 애니메이션 OFF 환경(테스트/골든): base만 고정 프레임으로
        opacity: _baseOpacity,
        child: base(),
      ),
    );
  }
}
