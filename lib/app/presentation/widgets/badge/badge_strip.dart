import 'package:fluent_ui/fluent_ui.dart';

import 'package:cartridge/app/presentation/widgets/badge/badge.dart';

/// 셀 폭에 맞춰 자동 접힘(+n) 처리하는 뱃지 스트립
class BadgeStrip extends StatelessWidget {
  const BadgeStrip({
    super.key,
    required this.badges,
    this.height = 18,
    this.gap = 6,
    this.reserveNameMinWidth = 60, // 이름이 최소 확보할 폭(셀에서 Row 조합 시 유용)
  });

  final List<BadgeSpec> badges;
  final double height;
  final double gap;
  final double reserveNameMinWidth;

  @override
  Widget build(BuildContext context) {
    if (badges.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: height,
      child: LayoutBuilder(
        builder: (ctx, box) {
          final fTheme = FluentTheme.of(ctx);
          final maxW = box.maxWidth - 4; // 셀에서 ConstrainedBox로 감싸면 유한값이 들어옴. 2px 추가 gap, 근사치 방어

          // 유효 폭이 없으면 그냥 한 줄로(최대한 안전하게) 다 보여주기
          if (!maxW.isFinite) {
            return _rowAll(fTheme);
          }

          // 극단적으로 좁은 경우: 오버플로우 방어 (툴바/체크박스 등과 겹칠 때)
          if (maxW <= 28) {
            return _onlyPlus(count: badges.length, tooltip: _tooltipText(), scaleDown: true);
          }

          // 각 배지의 예상 폭 측정
          final pillWidths = <double>[];
          for (final b in badges) {
            pillWidths.add(_pillWidth(fTheme, b));
          }

          // (+n) 알약의 폭은 숨겨질 개수에 따라 달라질 수 있으니
          // 일단 1개 숨겨질 때 기준으로 대략 측정하고, 이후 필요 시 갱신
          double plusW(int hidden) => _plusWidth(fTheme, hidden);

          // 배치를 시뮬레이션: 몇 개까지 보이고, 몇 개를 (+n)으로 접을지
          int visible = 0;
          double used = 0;

          // 최소한 이름이 차지할 폭(reserveNameMinWidth)은 남겨둬야 한다면
          final usable = (maxW - 0).clamp(0, double.infinity); // 이 위젯 자체 폭만 고려
          // (이 위젯 바깥에서 ConstrainedBox(maxWidth: availForBadges)로 이미 제한하고 있을 가능성 높음)

          // 전부 넣어보고 남는지 확인하며, 남지 않으면 (+n) 고려
          for (int i = 0; i < badges.length; i++) {
            final w = (i == 0 ? 0 : gap) + pillWidths[i];

            // 일단 이 배지를 넣는다고 가정
            final usedIfAdd = used + w;

            if (usedIfAdd <= usable) {
              // 아직 여유가 있으면 넣고 계속
              used = usedIfAdd;
              visible = i + 1;
              continue;
            } else {
              // 안 들어가면 (+n) 필요
              final hidden = badges.length - i; // i 번째부터 숨김
              // 지금까지 보이는 것(visible개) + (있다면 gap) + (+n) 폭이 들어가는지 확인
              double need = used + (visible > 0 ? gap : 0) + plusW(hidden);

              // 필요 폭이 넘치면, 뒤에서부터 하나씩 빼서 공간 만들기
              while (need > usable && visible > 0) {
                // 마지막으로 들어간 배지를 뺀다
                final lastW = pillWidths[visible - 1] + (visible - 1 > 0 ? gap : 0);
                used -= lastW;
                visible--;
                need = used + (visible > 0 ? gap : 0) + plusW(hidden);
              }

              // 그래도 안되면 배지를 전부 접고 (+n)만
              if (need > usable) {
                visible = 0;
              }
              break;
            }
          }

          final hidden = badges.length - visible;

          // 모두 들어가면 그냥 다 보여주기
          if (hidden <= 0) {
            return _rowVisible(fTheme, badges, gap);
          }

          // 일부는 보이고, 나머지는 (+n)
          if (visible > 0) {
            final shown = badges.take(visible).toList();
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ..._pills(shown, fTheme, gap),
                SizedBox(width: gap),
                Tooltip(
                  message: _tooltipText(),
                  style: const TooltipThemeData(waitDuration: Duration(milliseconds: 80)),
                  child: PlusPill(hidden),
                ),
              ],
            );
          }

          // 완전 좁아서 전부 접는 경우: (+n)만
          return _onlyPlus(count: hidden, tooltip: _tooltipText());
        },
      ),
    );
  }

  // 전부 표시 (폭 제약이 사실상 없을 때)
  Widget _rowAll(FluentThemeData theme) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: _pills(badges, theme, gap),
    );
  }

  // 일부 표시
  Widget _rowVisible(FluentThemeData theme, List<BadgeSpec> shown, double gap) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: _pills(shown, theme, gap),
    );
  }

  // (+n)만 표시 (아주 좁은 경우 대비로 scaleDown 옵션)
  Widget _onlyPlus({required int count, required String tooltip, bool scaleDown = false}) {
    final pill = Tooltip(
      message: tooltip,
      style: const TooltipThemeData(waitDuration: Duration(milliseconds: 80)),
      child: PlusPill(count),
    );
    return scaleDown
        ? FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft, child: pill)
        : pill;
  }

  // 배지 위젯 리스트
  List<Widget> _pills(List<BadgeSpec> list, FluentThemeData theme, double gap) {
    final children = <Widget>[];
    for (int i = 0; i < list.length; i++) {
      if (i > 0) children.add(SizedBox(width: gap));
      children.add(Pill(list[i]));
    }
    return children;
  }

  // 툴팁 텍스트(전체 목록)
  String _tooltipText() => badges.map((b) => b.text).join('\n');

  // 폭 추정 유틸들 -------------------------------------------------------------

  double _pillWidth(FluentThemeData theme, BadgeSpec b) {
    final textW = _textWidth(theme, b.text);
    final iconW = b.icon == null ? 0.0 : 12.0 + 4.0; // 아이콘 + 간격
    const hp = 6.0 + 6.0; // 좌우 패딩
    return textW + iconW + hp;
  }

  double _plusWidth(FluentThemeData theme, int hidden) {
    final label = '(+${hidden.toString()})';
    const hp = 6.0 + 6.0;
    return _textWidth(theme, label) + hp;
  }

  double _textWidth(FluentThemeData theme, String text) {
    final style = (theme.typography.caption ??
        const TextStyle(fontSize: 12, height: 1.0))
        .copyWith(fontWeight: FontWeight.w600);
    final tp = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout();
    return tp.size.width;
  }
}