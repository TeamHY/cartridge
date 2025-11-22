import 'package:cartridge/models/daily_challenge.dart';
import 'package:cartridge/models/daily_record.dart';
import 'package:cartridge/pages/record/components/ranking/base_ranking.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DailyChallengeRanking extends BaseRanking {
  const DailyChallengeRanking({super.key, super.isAdmin});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _DailyChallengeRankingState();
}

class _DailyChallengeRankingState
    extends BaseRankingState<DailyChallengeRanking> {
  final _supabase = Supabase.instance.client;

  DateTime _date = DateTime.now();
  DailyChallenge? _challenge;

  @override
  Future<void> refreshChallenge(BuildContext context) async {
    try {
      final challengeData =
          await _supabase.from("daily_challenges").select().eq("date", _date);

      if (challengeData.isEmpty) {
        setState(() {
          isLoading = false;
          _challenge = null;
          records = [];
        });
        return;
      }

      final challenge = DailyChallenge.fromJson(challengeData.first);

      final res = await _supabase.functions
          .invoke('daily-record/${challenge.id}', method: HttpMethod.get);

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
    _date = _date.subtract(const Duration(days: 1));
    onDateChange();
  }

  @override
  void onNextPeriod() {
    _date = _date.add(const Duration(days: 1));
    onDateChange();
  }

  @override
  String getDateText() {
    return _date.toIso8601String().split('T')[0];
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
      ],
    );
  }
}
