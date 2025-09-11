import 'package:cartridge/features/isaac/options/domain/models/isaac_options.dart';
import 'package:cartridge/features/isaac/options/domain/models/isaac_options_schema.dart';

/// [Options] 섹션을 스키마에 맞춰 IsaacOptions로 디코딩
abstract final class IsaacOptionsDecoder {
  static IsaacOptions fromIniMap(Map<String, String> m) {
    int? i(String k) => int.tryParse(m[k]?.trim() ?? '');
    double? d(String k) => double.tryParse(m[k]?.trim() ?? '');

    bool? b(String k) {
      final raw = (m[k] ?? '').trim();
      if (raw.isEmpty) return null;

      final asInt = int.tryParse(raw);
      return asInt != null ? IniBool.fromIni(asInt) == IniBool.on : null;
    }

    return IsaacOptions(
      // window & display
      windowWidth:  i(IsaacOptionsSchema.keyWindowWidth),
      windowHeight: i(IsaacOptionsSchema.keyWindowHeight),
      windowPosX:   i(IsaacOptionsSchema.keyWindowPosX),
      windowPosY:   i(IsaacOptionsSchema.keyWindowPosY),

      fullscreen:   b(IsaacOptionsSchema.keyFullscreen),

      // gameplay/system
      gamma:              d(IsaacOptionsSchema.keyGamma),
      enableDebugConsole: b(IsaacOptionsSchema.keyEnableDebugConsole),
      pauseOnFocusLost:   b(IsaacOptionsSchema.keyPauseOnFocusLost),
      mouseControl:       b(IsaacOptionsSchema.keyMouseControl),
    );
  }
}
