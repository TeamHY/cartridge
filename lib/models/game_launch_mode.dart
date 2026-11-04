/// How the game is started when a preset is applied.
enum GameLaunchMode {
  /// Start isaac-ng.exe directly.
  vanilla,

  /// Start the game through rgon-cli with REPENTOGON loaded.
  repentogon;

  static GameLaunchMode fromName(String? name) {
    return GameLaunchMode.values.firstWhere(
      (mode) => mode.name == name,
      orElse: () => GameLaunchMode.vanilla,
    );
  }
}
