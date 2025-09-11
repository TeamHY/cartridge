import 'package:fluent_ui/fluent_ui.dart';

import 'package:cartridge/features/cartridge/record_mode/record_mode.dart';
import 'package:cartridge/theme/theme.dart';

class RankTile extends StatelessWidget {
  const RankTile({super.key, required this.entry, required this.isAdmin});
  final LeaderboardEntry entry;
  final bool isAdmin;

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);

    // 상위 3위 강조 색상/아이콘
    Color? accent;
    IconData? emblem;
    switch (entry.rank) {
      case 1:
        accent = const Color(0xFFFACC15); // gold
        emblem = FluentIcons.crown;
        break;
      case 2:
        accent = const Color(0xFFD1D5DB); // silver
        emblem = FluentIcons.trophy;
        break;
      case 3:
        accent = const Color(0xFFB45309); // bronze
        emblem = FluentIcons.trophy2;
        break;
    }

    final baseBg = theme.cardColor;
    final bg = accent == null ? baseBg : baseBg.withAlpha(235);

    // 운영자에게만 보이는 서브타이틀(클리어 시간)
    final subtitle = (isAdmin && entry.clearTime != null)
        ? Text(
      getTimeString(entry.clearTime!),
      style: TextStyle(
        fontSize: 12,
        color: theme.resources.textFillColorSecondary,
      ),
    )
        : null;

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: theme.resources.cardStrokeColorDefault, width: 0.8),
      ),
      foregroundDecoration: accent == null
          ? null
          : BoxDecoration(
        border: Border(
          left: BorderSide(color: accent, width: 3),
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(10), bottomLeft: Radius.circular(10),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          // 랭크 엠블럼(숫자 + 상위는 아이콘)
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: accent == null ? theme.micaBackgroundColor.withAlpha(120) : accent.withAlpha(38),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: emblem == null
                  ? Text('${entry.rank}', style: const TextStyle(fontWeight: FontWeight.w700))
                  : Icon(emblem, size: 18),
            ),
          ),
          Gaps.w12,

          // 닉네임 + (운영자: 서브타이틀로 클리어시간)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.nickname,
                  maxLines: 1, overflow: TextOverflow.ellipsis, softWrap: false,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                if (subtitle != null) subtitle,
              ],
            ),
          ),
        ],
      ),
    );
  }
}