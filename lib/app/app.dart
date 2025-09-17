import 'dart:io' as io;
import 'package:cartridge/app/presentation/widgets/minimize_observer.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:cartridge/app/presentation/widgets/stage_shell.dart';
import 'package:cartridge/features/cartridge/setting/setting.dart';
import 'package:cartridge/l10n/app_localizations.dart';
import 'package:cartridge/theme/theme.dart';

class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final setting = ref.watch(appSettingControllerProvider);

    final languageCode = setting.maybeWhen(
      data: (s) => s.languageCode,
      orElse: () => _systemLanguageCode(),
    );

    final resolvedTheme = setting.maybeWhen(
      data: (_) => ref.watch(resolvedThemeProvider),
      orElse: () => AppTheme.resolve(AppThemeKey.system),
    );

    return _buildFluentApp(
      languageCode: languageCode,
      resolved: resolvedTheme,
        home: const MinimizeObserver(
          child: TickerGate(child: StageShell()),
        ),
    );
  }

  Widget _buildFluentApp({
    required String languageCode,
    required ResolvedFluentTheme resolved,
    required Widget home,
  }) {
    return FluentApp(
      title: 'Cartridge',
      debugShowCheckedModeBanner: false,
      locale: Locale(languageCode),
      localizationsDelegates: const [
        FluentLocalizations.delegate,
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        DefaultWidgetsLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en'), Locale('ko')],
      themeMode: resolved.mode,
      theme: resolved.light,
      darkTheme: resolved.dark,
      builder: (context, child) {
        final bg = FluentTheme.of(context).scaffoldBackgroundColor;
        return ColoredBox(color: bg, child: child!);
      },
      home: home,
    );
  }
}

@visibleForTesting
String resolveLanguageCode(String rawLocale) {
  final raw = rawLocale.toLowerCase();
  final code = raw.split(RegExp(r'[_\-.]')).first;
  const supported = {'ko', 'en'};
  return supported.contains(code) ? code : 'en';
}

String _systemLanguageCode() => resolveLanguageCode(io.Platform.localeName);

