import 'package:cartridge/models/daily_challenge.dart';
import 'package:cartridge/models/daily_record.dart';
import 'package:cartridge/utils/format_util.dart';
import 'package:cartridge/widgets/dialogs/error_dialog.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cartridge/l10n/app_localizations.dart';

class DailyChallengeRanking extends ConsumerStatefulWidget {
  const DailyChallengeRanking({super.key, this.isAdmin = false});

  final bool isAdmin;

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _DailyChallengeRankingState();
}

class _DailyChallengeRankingState extends ConsumerState<DailyChallengeRanking> {
  final _supabase = Supabase.instance.client;

  bool _isLoading = true;
  DateTime _date = DateTime.now();
  DailyChallenge? _challenge;
  List<DailyRecord> _records = [];

  Future<void> refreshChallenge(BuildContext context) async {
    try {
      final challengeData =
          await _supabase.from("daily_challenges").select().eq("date", _date);

      if (challengeData.isEmpty) {
        setState(() {
          _isLoading = false;
          _challenge = null;
          _records = [];
        });

        return;
      }

      final challenge = DailyChallenge.fromJson(challengeData.first);

      final res = await _supabase.functions
          .invoke('daily-record/${challenge.id}', method: HttpMethod.get);

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
                icon: const Icon(FluentIcons.back, size: 20),
                onPressed: () =>
                    setDate(_date.subtract(const Duration(days: 1))),
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    _date.toIso8601String().split('T')[0],
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
                onPressed: () => setDate(_date.add(const Duration(days: 1))),
              ),
            ],
          ),
        ),
        if (_challenge == null)
          Center(
            child: Text(
              _isLoading ? loc.ranking_loading : loc.ranking_no_data,
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
            ],
          ),
        const SizedBox(height: 8),
        Expanded(
          child: ListView.builder(
            itemCount: _records.length,
            itemBuilder: (context, index) {
              final record = _records[index];
              return DailyChallengeRankingItem(
                rank: index + 1,
                time: record.time,
                character: record.character,
                nickname: record.nickname,
                isAdmin: widget.isAdmin,
              );
            },
          ),
        ),
      ],
    );
  }
}

class DailyChallengeRankingItem extends StatelessWidget {
  const DailyChallengeRankingItem({
    super.key,
    required this.rank,
    required this.time,
    required this.character,
    required this.nickname,
    this.isAdmin = false,
  });

  final int rank;

  final int time;

  final int character;

  final String nickname;

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
              ),
            ),
        ],
      ),
    );
  }
}
