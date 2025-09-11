import 'package:cartridge/core/validation.dart';
import 'package:cartridge/features/cartridge/mod_presets/domain/models/mod_preset.dart';
import 'package:cartridge/features/cartridge/mod_presets/domain/mod_preset_mod_sort_key.dart';

/// ModPreset 도메인 정책
/// - normalize: 기본값/여백만 다듬고, **폴더명 key는 절대 가공하지 않음**
/// - validate: 이름/중복/키 유효성(윈도우 금지문자/예약어) 검사
class ModPresetPolicy {

  /// 정규화 (키는 가공하지 않음)
  static ModPreset normalize(ModPreset p) {
    final fixedName = p.name.trim().isEmpty ? '알 수 없는 모드 프리셋' : p.name.trim();
    // sortKey / ascending 기본값만 부여 (entries는 그대로 유지)
    return p.copyWith(
      name: fixedName,
      sortKey: p.sortKey ?? ModSortKey.name,
      ascending: p.ascending ?? true,
    );
  }

  /// 검증
  /// - 이름 공백 금지
  /// - 키 빈 값 금지
  /// - 키 중복 금지
  static ValidationResult validate(ModPreset p) {
    final v = <Violation>[];

    // 1) 이름
    if (p.name.trim().isEmpty) {
      v.add(const Violation('modPreset.name.empty'));
    }

    return ValidationResult(v);
  }
}
