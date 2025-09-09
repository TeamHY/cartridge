abstract class SteamInstallPort {
  /// `steam.exe`가 들어있는 스팀 "설치 폴더" (예: C:\Program Files (x86)\Steam)
  /// 를 자동 탐지한다. 실패하면 null.
  Future<String?> autoDetectBaseDir();

  /// 사용자 지정 경로가 있으면 우선 검증 후 사용하고,
  /// 없으면 `autoDetectBaseDir()`으로 폴백한다.
  /// 검증 기준: 디렉터리 존재 && `<dir>\steam.exe` 존재.
  Future<String?> resolveBaseDir({String? override});
}
