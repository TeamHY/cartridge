class SteamNewsItem {
  final String title;
  final String url;
  final String contents;
  final int? epochSec; // Unix seconds

  const SteamNewsItem({
    required this.title,
    required this.url,
    required this.contents,
    this.epochSec,
  });

  DateTime? get date =>
      (epochSec == null) ? null : DateTime.fromMillisecondsSinceEpoch(epochSec! * 1000);

  Map<String, dynamic> toJson() => {
    'title': title,
    'url': url,
    'contents': contents,
    'epochSec': epochSec,
  };

  factory SteamNewsItem.fromJson(Map<String, dynamic> m) => SteamNewsItem(
    title: (m['title'] as String?) ?? '',
    url: (m['url'] as String?) ?? '',
    contents: (m['contents'] as String?) ?? '',
    epochSec: (m['epochSec'] is int) ? m['epochSec'] as int : null,
  );
}
