
abstract class LeaderboardRepository {
  Future<String?> findWeeklyChallengeId({required int year, required int week});
  Future<String?> findDailyChallengeId({required String date}); // 'YYYY-MM-DD'

  /// Edge Function 호출 결과를 Raw Map 리스트로 반환 (ex: [{nickname,time,created_at}, ...])
  Future<List<Map<String, dynamic>>> fetchWeeklyRecords({required String challengeId});
  Future<List<Map<String, dynamic>>> fetchDailyRecords({required String challengeId});
}