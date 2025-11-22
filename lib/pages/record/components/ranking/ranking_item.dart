import 'package:cartridge/l10n/app_localizations.dart';
import 'package:cartridge/utils/format_util.dart';
import 'package:fluent_ui/fluent_ui.dart';

class RankingItem extends StatelessWidget {
  const RankingItem({
    super.key,
    required this.rank,
    required this.nickname,
    required this.time,
    this.isAdmin = false,
  });

  final int rank;
  final String nickname;
  final int time;
  final bool isAdmin;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        spacing: 8,
        children: [
          Expanded(
            flex: 1,
            child: Text(
              loc.ranking_rank(rank.toString()),
              style: TextStyle(
                fontSize: 14,
                fontWeight: rank <= 3 ? FontWeight.bold : FontWeight.normal,
                fontFamily: 'Pretendard',
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              nickname,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.normal,
                fontFamily: 'Pretendard',
              ),
            ),
          ),
          if (isAdmin)
            Expanded(
              flex: 3,
              child: Text(
                FormatUtil.getTimeString(Duration(milliseconds: time)),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.normal,
                  fontFamily: 'Pretendard',
                ),
              ),
            ),
        ],
      ),
    );
  }
}
