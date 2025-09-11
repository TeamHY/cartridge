// app_stage_provider.dart
import 'package:cartridge/app/presentation/controllers/splash_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cartridge/features/cartridge/setting/setting.dart';

enum AppStage { splash, main, error }

final appStageProvider = Provider<AppStage>((ref) {
  final setting = ref.watch(appSettingControllerProvider);
  final hold    = ref.watch(splashMinHoldProvider);

  if (setting.hasError) return AppStage.error;
  if (setting.isLoading || hold.isLoading) return AppStage.splash;
  return AppStage.main;
});
