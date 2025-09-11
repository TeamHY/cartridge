import 'package:cartridge/core/log.dart';
import 'package:cartridge/features/cartridge/record_mode/domain/id_util.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/interfaces.dart';
import '../domain/models/leaderboard_entry.dart';
import '../infra/supabase_leaderboard_repository.dart';

class LeaderboardServiceImpl implements LeaderboardService {
  final SupabaseLeaderboardRepository _repo;
  LeaderboardServiceImpl(SupabaseClient sp, {SupabaseLeaderboardRepository? repo})
      : _repo = repo ?? SupabaseLeaderboardRepository(sp);

  static const _tag = 'LeaderboardServiceImpl';

  DateTime _parseDate(dynamic v) {
    if (v is String) {
      try {
        return DateTime.parse(v);
      } catch (_) {}}
    return DateTime.now();
  }

  String _dashDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
          '${d.month.toString().padLeft(2, '0')}-'
          '${d.day.toString().padLeft(2, '0')}';

  @override
  Future<List<LeaderboardEntry>> fetchAll({required String gameId}) async {
    logI(_tag, 'fetchAll start | gameId=$gameId');

    try {
      if (RecordId.isWeekly(gameId)) {
        final (year, week) = RecordId.parseWeekly(gameId);
        logI(_tag, '[weekly] parsed year=$year week=$week');

        final cid = await _repo.findWeeklyChallengeId(year: year, week: week);
        if (cid == null) {
          logI(_tag, '[weekly] no challenge for $year/$week');
          return const [];
        }

        final raw = await _repo.fetchWeeklyRecords(challengeId: cid);
        raw.sort((a, b) => (a['time'] as int).compareTo(b['time'] as int));

        final out = List<LeaderboardEntry>.generate(raw.length, (i) {
          final r = raw[i];
          return LeaderboardEntry(
            rank: i + 1,
            nickname: r['nickname'] as String,
            clearTime: Duration(milliseconds: r['time'] as int),
            createdAt: _parseDate(r['created_at']),
          );
        });
        logI(_tag, '[weekly] parsed entries=${out.length}');
        return out;
      }

      if (RecordId.isDaily(gameId)) {
        final dt = RecordId.parseDailyDate(gameId);
        final dateDash = _dashDate(dt);
        logI(_tag, '[daily] parsed from "$gameId" -> ${dt.toIso8601String()} (dash=$dateDash)');

        final cid = await _repo.findDailyChallengeId(date: dateDash);
        if (cid == null) {
          logI(_tag, '[daily] no challenge for date=$dateDash');
          return const [];
        }

        final raw = await _repo.fetchDailyRecords(challengeId: cid);
        raw.sort((a, b) => (a['time'] as int).compareTo(b['time'] as int));

        final out = List<LeaderboardEntry>.generate(raw.length, (i) {
          final r = raw[i];
          return LeaderboardEntry(
            rank: i + 1,
            nickname: r['nickname'] as String,
            clearTime: Duration(milliseconds: r['time'] as int),
            createdAt: _parseDate(r['created_at']),
          );
        });
        logI(_tag, '[daily] parsed entries=${out.length}');
        return out;
      }

      logW(_tag, 'unsupported gameId format: $gameId');
      return const [];
    } catch (e, st) {
      logE(_tag, 'fetchAll error | gameId=$gameId', e, st);
      return const [];
    }
  }
}
