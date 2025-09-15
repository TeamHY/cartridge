import 'package:fluent_ui/fluent_ui.dart';

import 'package:cartridge/features/cartridge/record_mode/record_mode.dart';
import 'package:cartridge/theme/theme.dart';

class RankTile extends StatelessWidget {
  const RankTile({
    super.key,
    required this.entry,
    required this.isAdmin,
    this.loading = false,
  });

  const RankTile.loading({super.key})
      : entry = null,
        isAdmin = false,
        loading = true;

  final LeaderboardEntry? entry;
  final bool isAdmin;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    final barBg = theme.resources.cardBackgroundFillColorSecondary;

    // 운영자에게만 보이는 서브타이틀(클리어 시간)
    final subtitle = (!loading && (showClearTime | isAdmin) && entry?.clearTime != null)
        ? Text(
      getTimeString(entry!.clearTime!),
      style: TextStyle(fontSize: 12, color: theme.resources.textFillColorSecondary),
    )
        : null;

    return Container(
      decoration: BoxDecoration(
        color: theme.resources.cardBackgroundFillColorDefault,
        borderRadius: AppShapes.chip,
        border: Border.all(color: theme.dividerColor),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          // 랭크 엠블럼(숫자 + 상위는 아이콘)
          Container(
            width: 28, height: 28,
            decoration: BoxDecoration(
              color: theme.micaBackgroundColor.withAlpha(220),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: loading
                  ? const SizedBox.shrink()
                  : Text('${entry!.rank}', style: const TextStyle(fontWeight: FontWeight.w700)),
            ),
          ),
          Gaps.w32,
          // 닉네임 + (운영자: 서브타이틀로 클리어시간)
          Expanded(
            child: loading
                ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(height: 14, width: double.infinity,
                  decoration: BoxDecoration(color: barBg, borderRadius: BorderRadius.circular(6)),
                ),
                Gaps.h6,
                Container(height: 10, width: 80,
                  decoration: BoxDecoration(color: barBg, borderRadius: BorderRadius.circular(6)),
                ),
              ],
            )
                : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry!.nickname,
                  maxLines: 1, overflow: TextOverflow.ellipsis, softWrap: false,
                  style: const TextStyle(fontWeight: FontWeight.w500),
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