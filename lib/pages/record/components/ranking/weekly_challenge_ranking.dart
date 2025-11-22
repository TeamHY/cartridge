import 'package:cartridge/models/daily_record.dart';
import 'package:cartridge/models/weekly_challenge.dart';
import 'package:cartridge/utils/format_util.dart';
import 'package:cartridge/pages/record/components/ranking/base_ranking.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:week_of_year/week_of_year.dart';
import 'package:cartridge/l10n/app_localizations.dart';

class WeeklyChallengeRanking extends BaseRanking {
  const WeeklyChallengeRanking({super.key, super.isAdmin});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _WeeklyChallengeRankingState();
}

class _WeeklyChallengeRankingState
    extends BaseRankingState<WeeklyChallengeRanking> {
  final _supabase = Supabase.instance.client;

  DateTime _date = DateTime.now();
  WeeklyChallenge? _challenge;

  int get _week => _date.weekOfYear;
  int get _year => _date.day > 15 && _week == 1 ? _date.year + 1 : _date.year;

  @override
  Future<void> refreshChallenge(BuildContext context) async {
    try {
      final challengeData = await _supabase
          .from("weekly_challenges")
          .select()
          .eq("week", _week)
          .eq("year", _year);

      if (challengeData.isEmpty) {
        setState(() {
          isLoading = false;
          _challenge = null;
          records = [];
        });
        return;
      }

      final challenge = WeeklyChallenge.fromJson(challengeData.first);

      final res = await _supabase.functions
          .invoke('weekly-record/${challenge.id}', method: HttpMethod.get);

      final fetchedRecords = (res.data['data'] as List<dynamic>)
          .map<DailyRecord>((e) => DailyRecord.fromJson(e))
          .toList();

      setState(() {
        isLoading = false;
        _challenge = challenge;
        records = fetchedRecords;
        sortRecords();
      });
    } catch (e) {
      await handleError(context, e);
    }
  }

  @override
  void onDateChange() {
    setState(() {
      isLoading = true;
      _challenge = null;
      records = [];
    });
    refreshChallenge(context);
  }

  @override
  void onPreviousPeriod() {
    _date = _date.subtract(const Duration(days: 7));
    onDateChange();
  }

  @override
  void onNextPeriod() {
    _date = _date.add(const Duration(days: 7));
    onDateChange();
  }

  @override
  String getDateText() {
    final loc = AppLocalizations.of(context);
    return loc.ranking_date_format(_year, _week);
  }

  @override
  Widget? buildChallengeInfo(BuildContext context) {
    if (_challenge == null) return null;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          _challenge!.boss,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            fontFamily: 'Pretendard',
          ),
        ),
        const SizedBox(width: 8),
        Text(
          _challenge!.seed,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            fontFamily: 'Pretendard',
          ),
        ),
        const SizedBox(width: 8),
        Text(
          FormatUtil.getCharacterName(context, _challenge!.character),
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            fontFamily: 'Pretendard',
          ),
        ),
      ],
    );
  }
}
