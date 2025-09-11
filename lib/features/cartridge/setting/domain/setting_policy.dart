import 'package:cartridge/core/validation.dart';
import 'package:cartridge/features/cartridge/setting/setting.dart';
import 'package:cartridge/theme/theme.dart';

/// Setting 도메인 정책:
/// - normalize: 언어/테마/경로 trim, rerunDelay clamp(AppSetting 상수 사용)
/// - validate : 자동탐지 OFF 시 경로 필수 등 정책 위반 검출
class SettingPolicy {
  /// 정규화
  static AppSetting normalize(AppSetting s) {
    final lang = (() {
      final v = s.languageCode.trim().toLowerCase();
      return (v == 'ko') ? 'ko' : 'en';
    })();

    final key = _parseThemeKeyOrDefault(s.themeName);
    final themeName = key.name;

    final delay = s.rerunDelay
        .clamp(AppSetting.rerunDelayMin, AppSetting.rerunDelayMax);

    return s.copyWith(
      languageCode: lang,
      themeName: themeName,
      rerunDelay: delay,
      isaacPath: s.isaacPath.trim(),
      optionsIniPath: s.optionsIniPath.trim(),
    );
  }

  /// 검증
  static ValidationResult validate(AppSetting s) {
    final v = <Violation>[];

    if (!s.useAutoDetectInstallPath && s.isaacPath.trim().isEmpty) {
      v.add(const Violation('setting.isaacPath.required'));
    }
    if (!s.useAutoDetectOptionsIni && s.optionsIniPath.trim().isEmpty) {
      v.add(const Violation('setting.optionsIniPath.required'));
    }

    return ValidationResult(v);
  }

  static AppThemeKey _parseThemeKeyOrDefault(String? name) {
    final v = (name ?? '').trim().toLowerCase();
    for (final k in AppThemeKey.values) {
      if (k.name == v) return k;
    }
    return AppThemeKey.system;
  }
}
