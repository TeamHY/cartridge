import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';
import '../helpers/pump_golden.dart';
import '../helpers/fluent_host.dart';
import '../helpers/load_test_fonts.dart';

import 'package:cartridge/app/presentation/pages/splash_page.dart';
import 'package:cartridge/app/presentation/widgets/error_view.dart';
import 'package:cartridge/theme/theme.dart';


void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  testGoldens('Splash & Error - light/dark', (tester) async {
    await loadAppFonts();
    await loadTestFonts();

    final logo = AssetImage('assets/images/Cartridge_icon_200_200.png');

    Widget bound(Widget child) => AspectRatio(aspectRatio: 3 / 2, child: child);
    Widget freeze(Widget child) => TickerMode(enabled: false, child: child);

    final splashLight = freeze(
      FluentBareHost(
        themeKey: AppThemeKey.light,
        disableAnimations: true,
        assetBundle: rootBundle,
        child: bound(SplashPage(
          showSpinner: true,
          logo: logo,
        )),
      ),
    );

    final splashDark = freeze(
      FluentBareHost(
        themeKey: AppThemeKey.dark,
        disableAnimations: true,
        assetBundle: rootBundle,
        child: bound(SplashPage(
          showSpinner: true,
          logo: logo,
        )),
      ),
    );

    final errorLight = freeze(
      FluentBareHost(
        themeKey: AppThemeKey.light,
        disableAnimations: true,
        assetBundle: rootBundle,
        child: bound(
          const ErrorView(
            messageText: 'Something went wrong during startup.',
            retryText: 'Retry',
            closeText: 'Close',
            onRetry: _noop,
          ),
        ),
      ),
    );

    final errorDark = freeze(
      FluentBareHost(
        themeKey: AppThemeKey.dark,
        disableAnimations: true,
        assetBundle: rootBundle,
        child: bound(
          const ErrorView(
            messageText: 'Something went wrong during startup.',
            retryText: 'Retry',
            closeText: 'Close',
            onRetry: _noop,
          ),
        ),
      ),
    );

    final builder = GoldenBuilder.grid(columns: 2, widthToHeightRatio: 1)
      ..addScenario('Splash Light', splashLight)
      ..addScenario('Splash Dark', splashDark)
      ..addScenario('Error Light', errorLight)
      ..addScenario('Error Dark', errorDark);


    await pumpGolden(
      tester,
      builder.build(),
      surfaceSize: const Size(900, 600),
      pump: const Duration(milliseconds: 50),
    );
    await screenMatchesGolden(
      tester,
      'startup_splash_error_variants',
      customPump: (tester) async {
        await tester.pump(const Duration(milliseconds: 16));
        await tester.pump(const Duration(milliseconds: 16));
      },
    );
  });
}

void _noop() {}