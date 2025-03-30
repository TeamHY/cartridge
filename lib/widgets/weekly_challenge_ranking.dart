import 'package:cartridge/models/daily_challenge.dart';
import 'package:cartridge/models/daily_record.dart';
import 'package:cartridge/models/weekly_challenge.dart';
import 'package:cartridge/utils/format_util.dart';
import 'package:cartridge/widgets/dialogs/error_dialog.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:week_of_year/week_of_year.dart';

class WeeklyChallengeRanking extends ConsumerStatefulWidget {
  const WeeklyChallengeRanking({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _WeeklyChallengeRankingState();
}

class _WeeklyChallengeRankingState
    extends ConsumerState<WeeklyChallengeRanking> {
  final _supabase = Supabase.instance.client;

  bool _isLoading = true;
  DateTime _date = DateTime.now();
  WeeklyChallenge? _challenge;
  List<DailyRecord> _records = [];

  int get _week => _date.weekOfYear;
  int get _year => _date.day > 15 && _week == 1 ? _date.year + 1 : _date.year;

  Future<void> refreshChallenge(BuildContext context) async {
    try {
      final challengeData = await _supabase
          .from("weekly_challenges")
          .select()
          .eq("week", _week)
          .eq("year", _year);

      if (challengeData.isEmpty) {
        setState(() {
          _isLoading = false;
          _challenge = null;
          _records = [];
        });

        return;
      }

      final challenge = WeeklyChallenge.fromJson(challengeData.first);

      final res = await _supabase.functions
          .invoke('weekly-record/${challenge.id}', method: HttpMethod.get);

      final records = (res.data['data'] as List<dynamic>)
          .map<DailyRecord>((e) => DailyRecord.fromJson(e))
          .toList();
      records.sort((a, b) => a.time.compareTo(b.time));

      setState(() {
        _isLoading = false;
        _challenge = challenge;
        _records = records;
      });
    } catch (e) {
      if (context.mounted) {
        showErrorDialog(context, e.toString());
      }
    }
  }

  void setDate(DateTime date) {
    setState(() {
      _isLoading = true;
      _date = date;
      _challenge = null;
      _records = [];
    });

    refreshChallenge(context);
  }

  @override
  void initState() {
    super.initState();

    refreshChallenge(context);
  }

  @override
  Widget build(BuildContext context) {
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
                icon: const Icon(FluentIcons.back, size: 20),
                onPressed: () =>
                    setDate(_date.subtract(const Duration(days: 7))),
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    '$_year년 $_week주차',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Pretendard',
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(FluentIcons.refresh, size: 20),
                    onPressed: () => refreshChallenge(context),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(FluentIcons.forward, size: 20),
                onPressed: () => setDate(_date.add(const Duration(days: 7))),
              ),
            ],
          ),
        ),
        if (_challenge == null)
          Center(
            child: Text(
              _isLoading ? '불러오는 중...' : '데이터 없음',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                fontFamily: 'Pretendard',
              ),
              textAlign: TextAlign.center,
            ),
          )
        else
          Row(
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
                FormatUtil.getCharacterName(_challenge!.character),
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Pretendard',
                ),
              ),
            ],
          ),
        const SizedBox(height: 8),
        Expanded(
          child: ListView.builder(
            itemCount: _records.length,
            itemBuilder: (context, index) {
              final record = _records[index];
              return WeeklyChallengeRankingItem(
                rank: index + 1,
                time: record.time,
                character: record.character,
                nickname: record.nickname,
              );
            },
          ),
        ),
      ],
    );
  }
}

class WeeklyChallengeRankingItem extends StatelessWidget {
  const WeeklyChallengeRankingItem({
    super.key,
    required this.rank,
    required this.time,
    required this.character,
    required this.nickname,
  });

  final int rank;

  final int time;

  final int character;

  final String nickname;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '${rank.toString()}위',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.normal,
                fontFamily: 'Pretendard',
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              nickname,
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
