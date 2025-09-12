/// lib/features/cartridge/setting/domain/models/app_setting.dart
library;

import 'package:freezed_annotation/freezed_annotation.dart';

part 'app_setting.freezed.dart';
part 'app_setting.g.dart';

/// 앱 전역 **Setting** 모델 (freezed + json_serializable).
///
/// - 이 객체는 UI와 Service 사이의 **불변(immutable)** 데이터 컨테이너입니다.
/// - 직렬화/역직렬화(JSON) 스키마는 `setting.json` 파일과 일치해야 합니다.
/// - 값 보정(예: rerunDelay clamp)은 **계산용 getter**로 제공하고,
///   원본 필드는 입력 그대로 유지해 round-trip 직렬화 안전성을 보장합니다.
@freezed
sealed class AppSetting with _$AppSetting {
  /// rerunDelay 허용 범위(ms)
  static const int rerunDelayMin = 0;
  static const int rerunDelayMax = 10000;

  const AppSetting._();

  /// 기본값을 @Default 로 선언하여 생성/역직렬화 모두 동일한 초기값을 갖습니다.
  factory AppSetting({
    /// 스팀 설치 경로
    @Default('') String steamPath,

    /// The Binding of Isaac 설치 경로
    @Default('') String isaacPath,

    /// 인스턴스 전환 시 재실행 대기(ms)
    /// - 입력값은 그대로 저장되며, 실제 사용 시 [effectiveRerunDelay]를 참조하세요.
    @Default(1000) int rerunDelay,

    /// 언어 코드: 'en' | 'ko'
    @Default('ko') String languageCode,

    /// 테마 키: 'system' | 'light' | 'dark' | 'oled' | 'tangerine' | 'claude' ...
    @Default('system') String themeName,

    /// 사용자 지정 options.ini 절대 경로(자동탐지 미사용 시 사용)
    @Default('') String optionsIniPath,

    /// 게임 설치 경로 자동탐지 사용 여부
    @Default(true) bool useAutoDetectSteamPath,

    /// 게임 설치 경로 자동탐지 사용 여부
    @Default(true) bool useAutoDetectInstallPath,

    /// options.ini 자동탐지 사용 여부
    @Default(true) bool useAutoDetectOptionsIni,
  }) = _AppSetting;

  /// JSON 역직렬화
  factory AppSetting.fromJson(Map<String, dynamic> json) =>
      _$AppSettingFromJson(json);

  /// 실제 사용에 적합한 rerunDelay (0..10000로 clamp)
  int get effectiveRerunDelay {
    final v = rerunDelay;
    if (v < rerunDelayMin) return rerunDelayMin;
    if (v > rerunDelayMax) return rerunDelayMax;
    return v;
  }

  /// 편의: 기본값 인스턴스
  static final AppSetting defaults = AppSetting();


  /// 동치 비교(정규화 여부 판단에 사용)
  bool equals(AppSetting b) =>
      steamPath == b.steamPath &&
          isaacPath == b.isaacPath &&
          optionsIniPath == b.optionsIniPath &&
          rerunDelay == b.rerunDelay &&
          languageCode == b.languageCode &&
          themeName == b.themeName &&
          useAutoDetectSteamPath == b.useAutoDetectSteamPath &&
          useAutoDetectInstallPath == b.useAutoDetectInstallPath &&
          useAutoDetectOptionsIni == b.useAutoDetectOptionsIni;
}
