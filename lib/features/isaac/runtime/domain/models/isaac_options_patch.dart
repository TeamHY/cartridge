import 'package:freezed_annotation/freezed_annotation.dart';

part 'isaac_options_patch.freezed.dart';

/// Isaac options.ini의 [Options] 섹션에 적용할 **부분 패치**.
/// - null이 아닌 필드만 적용
@freezed
sealed class IsaacOptionsPatch with _$IsaacOptionsPatch {
  const IsaacOptionsPatch._();

  const factory IsaacOptionsPatch({
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
  }) = _IsaacOptionsPatch;

  static const empty = IsaacOptionsPatch();
}
