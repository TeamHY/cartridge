class SteamAccountProfile {
  final int accountId; // userdata 하위 폴더명(=32-bit account_id)
  final String steamId64; // 17자리
  final String? personaName;
  final String? avatarPngPath; // 존재하는 파일만
  final String savePath; // .../userdata/<accountId>/250900/remote
  final bool mostRecent;

  const SteamAccountProfile({
    required this.accountId,
    required this.steamId64,
    required this.savePath,
    this.personaName,
    this.avatarPngPath,
    this.mostRecent = false,
  });
}
