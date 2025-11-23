class MusicTrack {
  final String title;
  final String filePath;

  MusicTrack({
    required this.title,
    required this.filePath,
  });

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'filePath': filePath,
    };
  }

  factory MusicTrack.fromJson(Map<String, dynamic> json) {
    return MusicTrack(
      title: json['title'] as String,
      filePath: json['filePath'] as String,
    );
  }
}
