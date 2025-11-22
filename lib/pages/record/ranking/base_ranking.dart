import 'package:cartridge/l10n/app_localizations.dart';
import 'package:cartridge/models/daily_record.dart';
import 'package:cartridge/components/dialogs/error_dialog.dart';
import 'package:cartridge/pages/record/components/ranking/ranking_item.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

abstract class BaseRanking extends ConsumerStatefulWidget {
  const BaseRanking({super.key, this.isAdmin = false});

  final bool isAdmin;
}

abstract class BaseRankingState<T extends BaseRanking>
    extends ConsumerState<T> {
  bool isLoading = true;
  List<DailyRecord> records = [];

  Future<void> refreshChallenge(BuildContext context);

  void onDateChange();

  void onPreviousPeriod();

  void onNextPeriod();

  String getDateText();

  Widget? buildChallengeInfo(BuildContext context);

  @override
  void initState() {
    super.initState();
    refreshChallenge(context);
  }

  Future<void> handleError(BuildContext context, dynamic error) async {
    if (context.mounted) {
      showErrorDialog(context, error.toString());
    }
  }

  void sortRecords() {
    records.sort((a, b) => a.time.compareTo(b.time));
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              IconButton(
                icon: const PhosphorIcon(PhosphorIconsBold.arrowLeft, size: 20),
                onPressed: onPreviousPeriod,
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    getDateText(),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Pretendard',
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                  IconButton(
                    icon: const PhosphorIcon(
                      PhosphorIconsBold.arrowClockwise,
                      size: 20,
                    ),
                    onPressed: () => refreshChallenge(context),
                  ),
                ],
              ),
              IconButton(
                icon:
                    const PhosphorIcon(PhosphorIconsBold.arrowRight, size: 20),
                onPressed: onNextPeriod,
              ),
            ],
          ),
        ),
        if (buildChallengeInfo(context) == null)
          Center(
            child: Text(
              isLoading ? loc.ranking_loading : loc.ranking_no_data,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                fontFamily: 'Pretendard',
              ),
              textAlign: TextAlign.center,
            ),
          )
        else
          buildChallengeInfo(context)!,
        const SizedBox(height: 8),
        Expanded(
          child: ListView.builder(
            itemCount: records.length,
            itemBuilder: (context, index) {
              final record = records[index];
              return RankingItem(
                rank: index + 1,
                nickname: record.nickname,
                time: record.time,
                isAdmin: widget.isAdmin,
              );
            },
          ),
        ),
      ],
    );
  }
}
