import 'package:flutter/services.dart' show FontLoader, rootBundle;

Future<void> loadTestFonts() async {
  final loader = FontLoader('Pretendard')
    ..addFont(rootBundle.load('assets/fonts/Pretendard-Regular.otf'))
    ..addFont(rootBundle.load('assets/fonts/Pretendard-Bold.otf'));
  await loader.load();
}
