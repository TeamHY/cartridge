class WeeklyChallenge {
  WeeklyChallenge({
    required this.id,
    required this.seed,
    required this.boss,
    required this.character,
    required this.year,
    required this.week,
  });

  factory WeeklyChallenge.fromJson(Map<String, dynamic> json) {
    return WeeklyChallenge(
      id: json['id'],
      seed: json['seed'],
      boss: json['boss'],
      character: json['character'],
      year: json['year'],
      week: json['week'],
    );
  }

  final int id;
  final String seed;
  final String boss;
  final int character;
  final int year;
  final int week;
}
