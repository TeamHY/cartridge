/// lib/features/cartridge/option_presets/domain/models/option_preset_view.dart
library;

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:cartridge/features/cartridge/option_presets/domain/models/option_preset.dart';

part 'option_preset_view.freezed.dart';

/// 리스트/테이블 표시용 **View 모델**
/// - Domain(OptionPreset)의 주요 필드를 **nullable 그대로** 보유
/// - 화면 전용 파생 정보(size/pos 라벨)는 **getter** 로 제공
@freezed
sealed class OptionPresetView with _$OptionPresetView {
  const OptionPresetView._(); // 커스텀 getter/메서드용

    factory OptionPresetView({
    // ---- Domain 그대로 (nullable 허용) ----
    required String id,
    required String name,

    // window & display
    int? windowWidth,
    int? windowHeight,
    int? windowPosX,
    int? windowPosY,
    bool? fullscreen,

    // gameplay/system
    double? gamma,
    bool? enableDebugConsole,
    bool? pauseOnFocusLost,
    bool? mouseControl,

    // Repentogon
    bool? useRepentogon,

    // meta
    DateTime? updatedAt,
  }) = _OptionPresetView;

  /// Domain → View 변환
  factory OptionPresetView.fromModel(OptionPreset p) => OptionPresetView(
    id: p.id,
    name: p.name,
    windowWidth: p.options.windowWidth,
    windowHeight: p.options.windowHeight,
    windowPosX: p.options.windowPosX,
    windowPosY: p.options.windowPosY,
    fullscreen: p.options.fullscreen,
    gamma: p.options.gamma,
    enableDebugConsole: p.options.enableDebugConsole,
    pauseOnFocusLost: p.options.pauseOnFocusLost,
    mouseControl: p.options.mouseControl,
    useRepentogon: p.useRepentogon,
    updatedAt: p.updatedAt,
  );

  /// 표시용: 크기 라벨. 둘 중 하나라도 null이면 빈 문자열.
  String get sizeLabel =>
      (windowWidth != null && windowHeight != null)
          ? '$windowWidth × $windowHeight'
          : '';

  /// 표시용: 위치 라벨. 둘 중 하나라도 null이면 빈 문자열.
  String get posLabel =>
      (windowPosX != null && windowPosY != null)
          ? 'X:$windowPosX Y:$windowPosY'
          : '';

  /// 표시용: 전체화면 여부 라벨(필요 시 UI에서 i18n 처리)
  String get fullscreenLabel => (fullscreen == true) ? 'Fullscreen' : 'Windowed';

  /// 주요 라벨: 전체화면이면 fullscreenLabel, 아니면 size • pos
  String get primaryLabel =>
      (fullscreen == true) ? fullscreenLabel : '$sizeLabel • $posLabel';


}
