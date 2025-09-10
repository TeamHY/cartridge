import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:window_manager/window_manager.dart';

import 'l10n/app_localizations.dart';
import 'package:cartridge/app/presentation/app_navigation.dart';
import 'package:cartridge/providers/setting_provider.dart';
import 'package:cartridge/theme/theme.dart';

final currentVersion = Version.parse('4.14.1');

void main() async {
  await dotenv.load(fileName: '.env');

  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();

  WindowOptions windowOptions = const WindowOptions(
    backgroundColor: Colors.transparent,
    skipTaskbar: false,
    titleBarStyle: TitleBarStyle.hidden,
    minimumSize: Size(600, 300),
    center: true,
  );

  windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
  });

  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL'] ?? '',
    anonKey: dotenv.env['SUPABASE_ANON_KEY'] ?? '',
  );

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final languageCode = ref.watch(settingProvider).languageCode ?? 'ko';
    final resolved = ref.watch(resolvedThemeProvider);

    return FluentApp(
      title: 'Cartridge',
      debugShowCheckedModeBanner: false,
      locale: Locale(languageCode),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        DefaultWidgetsLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en'),
        Locale('ko'),
      ],
      themeMode: resolved.mode,
      theme: resolved.light,
      darkTheme: resolved.dark,
      home: const AppNavigation(),
    );
  }
}
