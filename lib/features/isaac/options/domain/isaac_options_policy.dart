library;

import 'package:cartridge/core/validation.dart';
import 'package:cartridge/features/isaac/options/domain/models/isaac_options.dart';
import 'package:cartridge/features/isaac/options/domain/models/isaac_options_schema.dart';

// ---- sane defaults (모델 내부에서만 사용) ----
const kDefaultWindowWidth = 960;
const kDefaultWindowHeight = 540;
const kDefaultWindowPosX = 100;
const kDefaultWindowPosY = 100;
const kDefaultFullscreen = IsaacOptionsSchema.fullscreenOff;
const kDefaultGamma = 1.0;
const kDefaultDebugConsole = IsaacOptionsSchema.debugOn;
const kDefaultPauseOnFocusLost = IsaacOptionsSchema.pauseOff;
const kDefaultMouseControl = IsaacOptionsSchema.mouseOn;

abstract final class IsaacOptionsPolicy {
  static IsaacOptions normalize(IsaacOptions v) {
    int? clampIntN(int? x, int lo, int hi) => x?.clamp(lo, hi);
    double? clampDoubleN(double? x, double lo, double hi)
    => x?.clamp(lo, hi).toDouble();

    return v.copyWith(
      gamma:        clampDoubleN(v.gamma,        IsaacOptionsSchema.gammaMin, IsaacOptionsSchema.gammaMax),
      windowWidth:  clampIntN   (v.windowWidth,  IsaacOptionsSchema.winMin,   IsaacOptionsSchema.winMax),
      windowHeight: clampIntN   (v.windowHeight, IsaacOptionsSchema.winMin,   IsaacOptionsSchema.winMax),
      windowPosX:   clampIntN   (v.windowPosX,   IsaacOptionsSchema.posMin,   IsaacOptionsSchema.posMax),
      windowPosY:   clampIntN   (v.windowPosY,   IsaacOptionsSchema.posMin,   IsaacOptionsSchema.posMax),
      // bool? 들은 nullable 유지
    );
  }

  static ValidationResult validate(IsaacOptions v) {
    final out = <Violation>[];
    bool okIntN(int? x, int lo, int hi)   => x == null || (x >= lo && x <= hi);
    bool okDblN(double? x, double lo, double hi)
    => x == null || (x >= lo && x <= hi);

    if (!okDblN(v.gamma, IsaacOptionsSchema.gammaMin, IsaacOptionsSchema.gammaMax)) {
      out.add(const Violation('opt.gamma.range'));
    }
    if (!okIntN(v.windowWidth, IsaacOptionsSchema.winMin, IsaacOptionsSchema.winMax)) {
      out.add(const Violation('opt.window.width.range'));
    }
    if (!okIntN(v.windowHeight, IsaacOptionsSchema.winMin, IsaacOptionsSchema.winMax)) {
      out.add(const Violation('opt.window.height.range'));
    }
    if (!okIntN(v.windowPosX, IsaacOptionsSchema.posMin, IsaacOptionsSchema.posMax)) {
      out.add(const Violation('opt.window.posx.range'));
    }
    if (!okIntN(v.windowPosY, IsaacOptionsSchema.posMin, IsaacOptionsSchema.posMax)) {
      out.add(const Violation('opt.window.posy.range'));
    }
    return ValidationResult(out);
  }
}

/// INI 업데이트용 인코더: null은 “키 미적용(유지)” → map에 넣지 않음
abstract final class IsaacOptionsEncoder {
  static Map<String, String> toIniMapSkippingNulls(IsaacOptions v) {
    int b(bool x) => x ? IsaacOptionsSchema.on : IsaacOptionsSchema.off;
    String n(num x) => x.toString();

    final out = <String, String>{};
    void putB(String key, bool? x) { if (x != null) out[key] = b(x).toString(); }
    void putN(String key, num?  x) { if (x != null) out[key] = n(x); }

    putB(IsaacOptionsSchema.keyFullscreen,        v.fullscreen);
    putN(IsaacOptionsSchema.keyGamma,             v.gamma);
    putB(IsaacOptionsSchema.keyEnableDebugConsole,v.enableDebugConsole);
    putB(IsaacOptionsSchema.keyPauseOnFocusLost,  v.pauseOnFocusLost);
    putB(IsaacOptionsSchema.keyMouseControl,      v.mouseControl);
    putN(IsaacOptionsSchema.keyWindowWidth,       v.windowWidth);
    putN(IsaacOptionsSchema.keyWindowHeight,      v.windowHeight);
    putN(IsaacOptionsSchema.keyWindowPosX,        v.windowPosX);
    putN(IsaacOptionsSchema.keyWindowPosY,        v.windowPosY);
    return out;
  }
}
