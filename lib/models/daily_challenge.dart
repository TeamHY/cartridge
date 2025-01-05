class DailyChallenge {
  DailyChallenge({
    required this.id,
    required this.date,
    required this.seed,
    required this.boss,
    required this.character,
  });

  factory DailyChallenge.fromJson(Map<String, dynamic> json) {
    return DailyChallenge(
      id: json['id'],
      date: json['date'],
      seed: json['seed'],
      boss: json['boss'],
      character: json['character'],
    );
  }

  final int id;
  final String date;
  final String seed;
  final String boss;
  final int? character;
}
