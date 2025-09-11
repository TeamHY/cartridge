// features/cartridge/record_mode/infra/supabase_leaderboard_repository.dart
import 'package:cartridge/core/log.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseLeaderboardRepository {
  final SupabaseClient _sp;
  SupabaseLeaderboardRepository(this._sp);

  static const _tag = 'SupabaseLeaderboardRepository';

  Future<String?> findWeeklyChallengeId({required int year, required int week}) async {
    try {
      final row = await _sp.from('weekly_challenges')
          .select('id').eq('year', year).eq('week', week).maybeSingle();
      final cid = row?['id']?.toString();
      logI(_tag, '[weekly] findChallengeId(year=$year, week=$week) -> $cid');
      return cid;
    } catch (e, st) {
      logE(_tag, '[weekly] findChallengeId error', e, st);
      return null;
    }
  }

  Future<String?> findDailyChallengeId({required String date}) async {
    try {
      final row = await _sp.from('daily_challenges')
          .select('id').eq('date', date).maybeSingle();
      final cid = row?['id']?.toString();
      logI(_tag, '[daily] findChallengeId(date=$date) -> $cid');
      return cid;
    } catch (e, st) {
      logE(_tag, '[daily] findChallengeId error', e, st);
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> fetchWeeklyRecords({required String challengeId}) async {
    try {
      final res = await _sp.functions.invoke('weekly-record/$challengeId', method: HttpMethod.get);
      final data = (res.data is Map) ? (res.data as Map)['data'] : null;
      final list = (data is List) ? data.cast<Map<String, dynamic>>() : <Map<String, dynamic>>[];
      logI(_tag, '[weekly] fetchRecords(ch=$challengeId) status=${res.status} rows=${list.length}');
      return list;
    } catch (e, st) {
      logE(_tag, '[weekly] fetchRecords error (ch=$challengeId)', e, st);
      return const <Map<String, dynamic>>[];
    }
  }

  Future<List<Map<String, dynamic>>> fetchDailyRecords({required String challengeId}) async {
    try {
      final res = await _sp.functions.invoke('daily-record/$challengeId', method: HttpMethod.get);
      final data = (res.data is Map) ? (res.data as Map)['data'] : null;
      final list = (data is List) ? data.cast<Map<String, dynamic>>() : <Map<String, dynamic>>[];
      logI(_tag, '[daily] fetchRecords(ch=$challengeId) status=${res.status} rows=${list.length}');
      return list;
    } catch (e, st) {
      logE(_tag, '[daily] fetchRecords error (ch=$challengeId)', e, st);
      return const <Map<String, dynamic>>[];
    }
  }
}
