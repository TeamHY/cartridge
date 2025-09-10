// test/helpers/load_test_fonts.dart
import 'package:flutter/services.dart' show FontLoader, rootBundle;
import 'package:flutter_test/flutter_test.dart';

bool _fontsLoaded = false;

/// Golden/위젯 테스트에서 한글 렌더링을 위해 Pretendard 폰트를 로드한다.
/// 여러 번 호출해도 1회만 동작.
Future<void> loadTestFonts() async {
  if (_fontsLoaded) return;
  TestWidgetsFlutterBinding.ensureInitialized();

  final loader = FontLoader('Pretendard')
    ..addFont(rootBundle.load('assets/fonts/Pretendard-Regular.otf'))
    ..addFont(rootBundle.load('assets/fonts/Pretendard-Bold.otf'));
  await loader.load();

  _fontsLoaded = true;
}
