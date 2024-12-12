class DailyChallenge {
  DailyChallenge({
    required this.id,
    required this.date,
    required this.seed,
    required this.boss,
  });

  factory DailyChallenge.fromJson(Map<String, dynamic> json) {
    return DailyChallenge(
      id: json['id'],
      date: json['date'],
      seed: json['seed'],
      boss: json['boss'],
    );
  }

  final int id;
  final String date;
  final String seed;
  final String boss;
}
