import 'package:cartridge/app/presentation/controllers/splash_providers.dart';
import 'package:cartridge/app/presentation/widgets/warm_boot_hook.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cartridge/app/app.dart';

import '../helpers/load_test_fonts.dart';

void main() {
  setUpAll(() async {
    await loadTestFonts();
  });

  testWidgets('앱이 예외 없이 첫 프레임을 빌드한다 (smoke, AAA)', (tester) async {

    await tester.pumpWidget(ProviderScope(
      overrides: [
        splashMinDurationProvider.overrideWithValue(Duration.zero),
        warmupEnabledProvider.overrideWithValue(false),
      ],
      child: const App(),
    ));


    await tester.pump(const Duration(milliseconds: 50)); // 유한 펌프
    expect(tester.takeException(), isNull);
  });
}