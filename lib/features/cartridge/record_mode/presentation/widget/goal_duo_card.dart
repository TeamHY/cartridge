import 'package:fluent_ui/fluent_ui.dart';

import 'package:cartridge/features/cartridge/record_mode/record_mode.dart';
import 'package:cartridge/l10n/app_localizations.dart';
import 'package:cartridge/theme/theme.dart';

class GoalDuoCard extends StatelessWidget {
  const GoalDuoCard({super.key, required this.snapshot, required this.gameId});
  final GoalSnapshot snapshot;
  final String? gameId;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = FluentTheme.of(context);

    final label = gameId == null ? '로딩 중...' : RecordId.formatGameLabel(gameId!);
    final weeklyRange = gameId == null ? null : RecordId.formatWeeklyRange(gameId!);

    // … (기존 듀오 이미지 영역은 그대로)
    // 칩 요약만 예시:
    Widget pill(String text, {IconData? icon}) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: theme.micaBackgroundColor.withAlpha(120),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: theme.resources.cardStrokeColorDefault, width: 0.8),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        if (icon != null) ...[Icon(icon, size: 14), const SizedBox(width: 6)],
        Text(text, style: const TextStyle(fontWeight: FontWeight.w600)),
      ]),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('현재 진행중인 목표', style: TextStyle(fontWeight: FontWeight.w600)),
        Gaps.h8,
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.asset(
                snapshot.goal.imageAsset,
                width: 148, height: 125, fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 10),
            Column(
              children: [
                const Icon(FluentIcons.link),
                Container(width: 2, height: 64, color: Colors.grey[80]),
              ],
            ),
            const SizedBox(width: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.asset(
                snapshot.character.imageAsset,
                width: 148, height: 125, fit: BoxFit.cover,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8, runSpacing: 8,
          children: [
            pill('목표: ${snapshot.goal.localizedTitle(loc)}', icon: FluentIcons.end_point_solid),
            if (snapshot.challengeType == ChallengeType.weekly)
              pill('기간: $label${weeklyRange != null ? ' ($weeklyRange)' : ''}', icon: FluentIcons.calendar_week),
            if (snapshot.challengeType == ChallengeType.daily)
              pill('기간: 일간', icon: FluentIcons.calendar_day),
            pill('게임 시드: ${snapshot.seed}', icon: FluentIcons.map_pin12),
            pill('시작 캐릭터: ${snapshot.character.localizedName(loc)}', icon: FluentIcons.contact),
          ],
        ),
      ],
    );
  }
}
