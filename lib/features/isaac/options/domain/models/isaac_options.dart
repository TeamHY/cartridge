import 'package:freezed_annotation/freezed_annotation.dart';

part 'isaac_options.freezed.dart';
part 'isaac_options.g.dart';

@freezed
sealed class IsaacOptions with _$IsaacOptions {
  const IsaacOptions._();

  factory IsaacOptions({
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
  }) = _IsaacOptions;

  factory IsaacOptions.fromJson(Map<String, dynamic> json) =>
      _$IsaacOptionsFromJson(json);
}
