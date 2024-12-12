class DailyRecord {
  DailyRecord({
    required this.id,
    required this.time,
    required this.character,
    required this.nickname,
    required this.data,
  });

  factory DailyRecord.fromJson(Map<String, dynamic> json) {
    return DailyRecord(
      id: json['id'],
      time: json['time'],
      character: json['character'],
      nickname: json['nickname'],
      data: json['data'],
    );
  }

  final int id;
  final int time;
  final int character;
  final String nickname;
  final Map<String, dynamic> data;
}
