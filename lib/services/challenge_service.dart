import 'package:cartridge/models/daily_challenge.dart';
import 'package:cartridge/models/weekly_challenge.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:week_of_year/week_of_year.dart';

class ChallengeService {
  final SupabaseClient _supabase;

  ChallengeService(this._supabase);

  Future<DailyChallenge?> getDailyChallenge() async {
    final today = DateTime.now();

    final daily = await _supabase
        .from("daily_challenges")
        .select()
        .gte("date", today)
        .lte("date", today);

    if (daily.isEmpty) {
      return null;
    }

    return DailyChallenge.fromJson(daily.first);
  }

  Future<WeeklyChallenge?> getWeeklyChallenge() async {
    final today = DateTime.now();
    final week = today.weekOfYear;
    final year = today.day > 15 && week == 1 ? today.year + 1 : today.year;

    final weekly = await _supabase
        .from("weekly_challenges")
        .select()
        .eq("week", week)
        .eq("year", year);

    if (weekly.isEmpty) {
      return null;
    }

    return WeeklyChallenge.fromJson(weekly.first);
  }

  Future<void> submitDailyRecord({
    required int time,
    required String seed,
    required int character,
    required Map<String, dynamic> data,
  }) async {
    await _supabase.functions.invoke('daily-record', body: {
      'time': time,
      'seed': seed,
      'character': character,
      'data': data,
    });
  }

  Future<void> submitWeeklyRecord({
    required int time,
    required String seed,
    required int character,
    required Map<String, dynamic> data,
  }) async {
    await _supabase.functions.invoke('weekly-record', body: {
      'time': time,
      'seed': seed,
      'character': character,
      'data': data,
    });
  }
}
