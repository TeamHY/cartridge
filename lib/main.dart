import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:window_manager/window_manager.dart';

import 'package:cartridge/app/app.dart';
import 'package:cartridge/features/cartridge/setting/setting.dart';

final currentVersion = Version.parse('4.14.1');

void main() async {
  final binding = WidgetsFlutterBinding.ensureInitialized();

  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  await dotenv.load(fileName: '.env');

  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL'] ?? '',
    anonKey: dotenv.env['SUPABASE_ANON_KEY'] ?? '',
  );

  await windowManager.ensureInitialized();
  WindowOptions windowOptions = const WindowOptions(
    backgroundColor: Colors.transparent,
    skipTaskbar: false,
    titleBarStyle: TitleBarStyle.hidden,
    minimumSize: Size(640, 460),
    center: true,
  );

  windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
  });

  binding.deferFirstFrame();

  final container = ProviderContainer();
  try {
    await container.read(appSettingControllerProvider.future);
  } catch (_) { }

  WidgetsFlutterBinding.ensureInitialized();

  runApp(UncontrolledProviderScope(
    container: container,
    child: const App(),
  ));

  binding.addPostFrameCallback((_) => binding.allowFirstFrame());
}