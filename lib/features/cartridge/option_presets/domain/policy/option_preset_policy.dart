library;

import 'package:cartridge/core/validation.dart';
import 'package:cartridge/features/cartridge/option_presets/domain/models/option_preset.dart';
import 'package:cartridge/features/isaac/options/domain/isaac_options_policy.dart';

abstract final class OptionPresetPolicy {
  static OptionPreset normalize(OptionPreset p) {
    final fixedName = p.name.trim().isEmpty ? '옵션 프리셋' : p.name.trim();
    return p.copyWith(
      name: fixedName,
      options: IsaacOptionsPolicy.normalize(p.options),
    );
  }

  static ValidationResult validate(OptionPreset p) {
    final meta = <Violation>[];
    if (p.id.isEmpty) meta.add(const Violation('opt.id.empty'));
    if (p.name.trim().isEmpty) meta.add(const Violation('opt.name.empty'));

    final iv = IsaacOptionsPolicy.validate(p.options);
    return ValidationResult([...meta, ...iv.violations]);
  }
}
