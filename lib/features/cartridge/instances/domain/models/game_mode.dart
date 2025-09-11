/// lib/core/models/game_mode.dart
enum GameMode {
  normal,
  battle,
  record,
  vanilla,
}


GameMode gameModeFromString(String v) {
  switch (v) {
    case 'battle':        return GameMode.battle;
    case 'record':        return GameMode.record;
    case 'vanilla':       return GameMode.vanilla;
    case 'normal':
    default:              return GameMode.normal;
  }
}