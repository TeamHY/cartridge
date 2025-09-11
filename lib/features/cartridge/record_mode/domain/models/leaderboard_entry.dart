class LeaderboardEntry {
  final int rank;
  final String nickname;
  final Duration? clearTime;
  final DateTime createdAt;
  const LeaderboardEntry({
    required this.rank,
    required this.nickname,
    this.clearTime,
    required this.createdAt
  });
}