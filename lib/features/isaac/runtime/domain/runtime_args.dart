import 'package:cartridge/features/cartridge/option_presets/domain/models/option_preset.dart';
import 'package:cartridge/features/isaac/runtime/domain/repentogon.dart';

/// 옵션 프리셋과 설치 경로를 받아 **추가 실행 인자**를 만든다.
/// - Repentogon 설치되어 있고, 프리셋에서 비활성(false)이면 '-repentogone'
Future<List<String>> buildIsaacExtraArgs({
  required String installPath,
  required OptionPreset preset,
  List<String> base = const [],
}) async {
  final args = <String>[...base];

  final repInstalled = await Repentogon.isInstalled(installPath);
  final useRep = preset.useRepentogon; // bool? (null이면 미지정 = 기본 동작)

  if (repInstalled && useRep == false) {
    args.add(kArgRepentogonOff);
  }

  return args;
}
