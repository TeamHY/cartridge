import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:cartridge/core/service_providers.dart';
import 'package:cartridge/core/result.dart';
import 'package:cartridge/core/validation.dart';
import 'package:cartridge/features/cartridge/setting/setting.dart';

/// 앱 전역에서 공유하는 AppSetting의 단일 출처.
/// - 다른 feature/provider는 이 값을 watch해서 사용
/// - I/O는 SettingService가 담당, 컨트롤러는 상태를 소유/배포
class AppSettingController extends AsyncNotifier<AppSetting> {
  SettingService get _settings => ref.read(settingServiceProvider);

  @override
  Future<AppSetting> build() async {
    final res = await _settings.getSettingView();
    return res.when(
      ok: (data, code, ctx) {
        if (data == null) throw _ResultException(code ?? 'setting.getNormalized.ok(null)');
        return data;
      },
      invalid:  (violations, code, ctx) => throw _ValidationException(violations, code),
      notFound: (code, ctx)             => throw _ResultException(code ?? 'setting.notFound'),
      conflict: (code, ctx)             => throw _ResultException(code ?? 'setting.conflict'),
      failure:  (code, error, ctx)      => throw _ResultException(code ?? 'setting.failure', error: error),
    );
  }

  /// 부분 업데이트(merge → normalize → save → 상태 갱신)
  Future<void> patch({
    int? rerunDelay,
    String? languageCode,
    String? themeName,
    String? steamPath,
    String? isaacPath,
    String? optionsIniPath,
    bool? useAutoDetectSteamPath,
    bool? useAutoDetectInstallPath,
    bool? useAutoDetectOptionsIni,
  }) async {
    // 낙관적 업데이트가 필요하면 state = AsyncData(...)로 미리 반영도 가능
    final res = await _settings.update(
      rerunDelay: rerunDelay,
      languageCode: languageCode,
      themeName: themeName,
      steamPath: steamPath,
      isaacPath: isaacPath,
      optionsIniPath: optionsIniPath,
      useAutoDetectSteamPath: useAutoDetectSteamPath,
      useAutoDetectInstallPath: useAutoDetectInstallPath,
      useAutoDetectOptionsIni: useAutoDetectOptionsIni,
    );
    res.when(
      ok:       (data, code, ctx) {
        if (code == 'setting.update.noop') return; // 변화 없음 → 상태 유지
        final v = data;
        if (v == null) {
          state = AsyncError(_ResultException('setting.update.ok(null)'), StackTrace.current);
        } else {
          state = AsyncData(v);
        }
      },
      invalid:  (violations, code, ctx) =>
      state = AsyncError(_ValidationException(violations, code), StackTrace.current),
      notFound: (code, ctx) =>
      state = AsyncError(_ResultException(code ?? 'setting.update.notFound'), StackTrace.current),
      conflict: (code, ctx) =>
      state = AsyncError(_ResultException(code ?? 'setting.update.conflict'), StackTrace.current),
      failure:  (code, error, ctx) =>
      state = AsyncError(_ResultException(code ?? 'setting.update.failure', error: error), StackTrace.current),
    );
  }
}

/// 전역 설정 상태 Provider(모든 기능/화면이 이걸 구독)
final appSettingControllerProvider =
AsyncNotifierProvider<AppSettingController, AppSetting>(
  AppSettingController.new,
);

/// 편의: 값만 필요할 때(로드 전이면 null)
final appSettingValueProvider = Provider<AppSetting?>((ref) {
  final async = ref.watch(appSettingControllerProvider);
  return async.valueOrNull;
});

/// 내부 경량 예외(AsyncError용)
class _ResultException implements Exception {
  final String code;
  final Object? error;
  _ResultException(this.code, {this.error});
  @override
  String toString() => 'ResultException(code=$code, error=$error)';
}

class _ValidationException implements Exception {
  final List<Violation> violations;
  final String? code;
  _ValidationException(this.violations, [this.code]);
  @override
  String toString() => 'ValidationException(code=$code, violations=$violations)';
}