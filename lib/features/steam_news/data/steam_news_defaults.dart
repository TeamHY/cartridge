/// Steam News API defaults for Isaac (AppID 250900).
/// Only the defaults are provided here. Use SteamIds.isaac for appId.
class SteamNewsDefaults {
  /// How many news items to fetch.
  static const int count = 10;

  /// Max characters for the news contents returned by API (truncation is done by Steam).
  /// Minimum size 1. 0 is full content.
  static const int maxLength = 1;
}
