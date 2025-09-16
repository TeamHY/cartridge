import 'package:cartridge/core/log.dart';
import 'package:cartridge/features/cartridge/record_mode/domain/id_util.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:week_of_year/week_of_year.dart';
import 'interfaces.dart';
import 'models/challenge_type.dart';
import 'models/game_character.dart';
import 'models/goal_snapshot.dart';
import 'models/record_goal.dart';


class SupabaseGoalReadService implements GoalReadService {
  static const _tag = 'SupabaseGoalReadService';

  final SupabaseClient _sp;
  SupabaseGoalReadService(this._sp);

  @override
  Stream<GoalSnapshot?> current(ChallengeType challengeType) async* {
    logI(_tag, 'current() start | challengeType=$challengeType');

    if (challengeType == ChallengeType.daily) {
      final today = DateTime.now();
      final res = await _sp
          .from('daily_challenges')
          .select('date,seed,boss,character')
          .gte('date', today)
          .lte('date', today);

      if (res.isEmpty) {
        logW(_tag, '[daily] no row for today=$today');
        yield null;
        return;
      }
      final d = res.first;
      final boss = (d['boss'] ?? '').toString();
      logI(_tag, '[daily] row date=${d['date']} boss=$boss char=${d['character']} seed=${d['seed']}');

      yield GoalSnapshot(
        challengeType: ChallengeType.daily,
        goal: RecordGoal(boss),
        seed: d['seed'] ?? '',
        character: GameCharacter(d['character'] ?? IsaacCharacter.eden.index),
      );
    } else {
      final now = DateTime.now();
      final week = now.weekOfYear;
      final year = RecordId.compatYear(now, week);
      final res = await _sp
          .from('weekly_challenges')
          .select('year,week,seed,boss,character')
          .eq('week', week)
          .eq('year', year);

      if (res.isEmpty) {
        logW(_tag, '[weekly] no row for year=$year week=$week');
        yield null;
        return;
      }
      final w = res.first;
      final boss = (w['boss'] ?? '').toString();
      logI(_tag, '[weekly] row year=${w['year']} week=${w['week']} boss=$boss char=${w['character']} seed=${w['seed']}');
      yield GoalSnapshot(
        challengeType: ChallengeType.weekly,
        goal: RecordGoal(boss),
        seed: w['seed'] ?? '',
        character: GameCharacter(w['character'] ?? 0),
      );
    }
    logI(_tag, 'current() end | challengeType=$challengeType');
  }

  @override
  Future<GoalSnapshot?> byGameId(String gameId) async {
    if (RecordId.isDaily(gameId)) {
      final date = RecordId.parseDailyDate(gameId); // YYYY-MM-DD
      final d = await _sp
          .from('daily_challenges')
          .select('seed,boss,character')
          .eq('date', _pgDate(date))
          .maybeSingle();
      if (d == null) return null;

      return GoalSnapshot(
        challengeType: ChallengeType.daily,
        seed: d['seed'] as String,
        goal: RecordGoal(d['boss'] as String),
        character: GameCharacter(d['character'] ?? IsaacCharacter.eden.index),
      );
    }

    if (RecordId.isWeekly(gameId)) {
      final (year, week) = RecordId.parseWeekly(gameId);

      final w = await _sp
          .from('weekly_challenges')
          .select('seed,boss,character')
          .eq('year', year)
          .eq('week', week)
          .maybeSingle();
      if (w == null) return null;
      return GoalSnapshot(
        challengeType: ChallengeType.weekly,
        seed: w['seed'] as String,
        goal: RecordGoal(w['boss'] as String),
        character: GameCharacter(w['character'] as int),
      );
    }

    return null;
  }

  String _pgDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
          '${d.month.toString().padLeft(2, '0')}-'
          '${d.day.toString().padLeft(2, '0')}';

}