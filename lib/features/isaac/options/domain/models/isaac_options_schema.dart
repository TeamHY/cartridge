/// Isaac `options.ini`의 [Options] 섹션 **스키마(schema)**.
/// - 키 이름, 허용 값(0/1 등), 범위를 한 곳에 문서화/상수화합니다.
/// - 이 파일만 고치면 Service/Applier가 모두 최신 스펙을 따릅니다.
///
/// 참조:
/// - Fandom Options 페이지: Fullscreen/MouseControl/EnableDebugConsole/WindowWidth/Height/Pos 등, 0/1 토글과 픽셀 단위 설명.
///   (본문 주석의 레퍼런스를 유지하세요)
abstract final class IsaacOptionsSchema {
  // === 키 문자열 (오타 방지) ===
  static const keyFullscreen = 'Fullscreen';
  static const keyGamma = 'Gamma';
  static const keyEnableDebugConsole = 'EnableDebugConsole';
  static const keyPauseOnFocusLost = 'PauseOnFocusLost';
  static const keyMouseControl = 'MouseControl';
  static const keyWindowWidth = 'WindowWidth';
  static const keyWindowHeight = 'WindowHeight';
  static const keyWindowPosX = 'WindowPosX';
  static const keyWindowPosY = 'WindowPosY';

  // === 0/1 토글을 위한 enum 변환 도우미 ===
  static const int off = 0;
  static const int on = 1;

  /// Fullscreen: 0/1
  /// - 0: 창 모드(Windowed)
  /// - 1: 전체 화면(Fullscreen)
  static const int fullscreenOff = off;
  static const int fullscreenOn = on;

  /// EnableDebugConsole: 0/1
  /// - 0: 비활성
  /// - 1: 활성 (도전/일부 진척에 제약 발생)
  static const int debugOff = off;
  static const int debugOn = on;

  /// PauseOnFocusLost: 0/1
  /// - 0: 포커스 잃어도 계속 진행
  /// - 1: 포커스 잃으면 일시정지
  static const int pauseOff = off;
  static const int pauseOn = on;

  /// MouseControl: 0/1
  /// - 0: 마우스 비활성
  /// - 1: 마우스 활성
  static const int mouseOff = off;
  static const int mouseOn = on;

  /// Gamma: float, **0.5–1.5** (게임 내 변경 가능 범위)
  static const double gammaMin = 0.5;
  static const double gammaMax = 4.0;

  /// WindowWidth/Height: 픽셀 단위 정수.
  static const int winMin = 100;
  static const int winMax = 4096;

  /// WindowPosX/PosY: 픽셀 단위 정수(음수 가능 환경 존재).
  static const int posMin = -10000;
  static const int posMax = 10000;
}

/// Isaac의 0/1 값을 타입 안전하게 다루기 위한 enum.
enum IniBool {
  off(0),
  on(1);

  final int ini;
  const IniBool(this.ini);

  static IniBool fromIni(int v) => v == 1 ? IniBool.on : IniBool.off;
}
