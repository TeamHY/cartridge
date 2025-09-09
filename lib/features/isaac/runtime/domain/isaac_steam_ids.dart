/// Isaac 전용 Steam App/DLC/Depot ID 모음.
/// - 출처: SteamDB (App: https://steamdb.info/app/250900/)
class IsaacSteamIds {
  /// The Binding of Isaac: Rebirth (Base App)
  /// Store: https://store.steampowered.com/app/250900/
  /// SteamDB: https://steamdb.info/app/250900/
  static const int appId = 250900;
}

/// DLC AppId (SteamDB 근거)
class IsaacSteamDlcIds {
  /// Afterbirth      https://steamdb.info/app/401920/
  static const int afterbirth = 401920;

  /// Afterbirth+     https://steamdb.info/app/570660/
  static const int afterbirthPlus = 570660;

  /// Repentance      https://steamdb.info/app/1426300/
  static const int repentance = 1426300;

  /// Repentance+     https://steamdb.info/app/3353470/
  static const int repentancePlus = 3353470;
}

/// DepotId (InstalledDepots 기준, SteamDB Depots 페이지 참고)
/// https://steamdb.info/app/250900/depots/
class IsaacSteamDepotIds {
  static const int rebirth        = 250902;
  static const int afterbirth     = 250905;
  static const int afterbirthPlus = 250908;
  static const int repentance     = 250911;
  static const int repentancePlus = 3353471;
}
