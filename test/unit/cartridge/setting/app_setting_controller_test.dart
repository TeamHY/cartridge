import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:cartridge/core/result.dart';
import 'package:cartridge/core/validation.dart';
import 'package:cartridge/features/cartridge/setting/setting.dart';
import 'package:cartridge/core/service_providers.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppSettingController', () {
    late ProviderContainer container;
    late _StubSettingService stub;

    setUp(() {
      stub = _StubSettingService();
      container = ProviderContainer(overrides: [
        settingServiceProvider.overrideWithValue(stub),
      ]);
    });

    tearDown(() {
      container.dispose();
    });

    test('build(): getSettingView OK → AsyncData(AppSetting)', () async {
      // Given
      final init = AppSetting.defaults;
      stub.onGetSettingView = () async => Result.ok(data: init, code: 'setting.getNormalized.ok');

      // When
      final value = await container.read(appSettingControllerProvider.future);

      // Then
      expect(value, init);
      final state = container.read(appSettingControllerProvider);
      expect(state.hasValue, isTrue);
      expect(state.value, init);
    });

    test('build(): getSettingView INVALID → AsyncError(ValidationException)', () async {
      // Given
      stub.onGetSettingView = () async => Result.invalid(
        violations: const [Violation('setting.isaacPath.required')],
        code: 'setting.getNormalized.invalid',
      );

      // When
      Object? error;
      try {
        await container.read(appSettingControllerProvider.future);
        fail('expected throw');
      } catch (e) {
        error = e;
      }

      // Then: AsyncError with our internal _ValidationException (private type → 문자열 검증)
      final state = container.read(appSettingControllerProvider);
      expect(state.hasError, isTrue);
      expect(error.toString(), contains('ValidationException'));
      expect(error.toString(), contains('setting.getNormalized.invalid'));
    });

    test('patch(): update OK(code=ok) → state 갱신', () async {
      // Given: 초기 로드 OK
      final init = AppSetting.defaults;
      final patched = init.copyWith(languageCode: 'en', themeName: 'system');
      stub.onGetSettingView = () async => Result.ok(data: init, code: 'setting.getNormalized.ok');
      await container.read(appSettingControllerProvider.future);

      // And: update가 변경된 값을 반환
      stub.onUpdate = ({
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
        return Result.ok(data: patched, code: 'setting.update.ok');
      };

      // When
      await container.read(appSettingControllerProvider.notifier).patch(
        languageCode: 'en',
      );

      // Then
      final state = container.read(appSettingControllerProvider);
      expect(state.hasValue, isTrue);
      expect(state.value, patched);
    });

    test('patch(): update OK(code=noop) → state 유지', () async {
      // Given
      final init = AppSetting.defaults;
      stub.onGetSettingView = () async => Result.ok(data: init, code: 'setting.getNormalized.ok');
      await container.read(appSettingControllerProvider.future);

      // And: update가 noop 반환
      stub.onUpdate = ({
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
        return Result.ok(data: init, code: 'setting.update.noop');
      };

      // When
      await container.read(appSettingControllerProvider.notifier).patch();

      // Then
      final state = container.read(appSettingControllerProvider);
      expect(state.hasValue, isTrue);
      expect(state.value, init);
    });

    test('patch(): update INVALID → AsyncError(ValidationException)', () async {
      // Given
      final init = AppSetting.defaults;
      stub.onGetSettingView = () async => Result.ok(data: init);
      await container.read(appSettingControllerProvider.future);

      // And: update invalid
      stub.onUpdate = ({
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
        return Result.invalid(
          code: 'setting.update.invalid',
          violations: const [Violation('setting.optionsIniPath.required')],
        );
      };

      // When
      await container.read(appSettingControllerProvider.notifier).patch(
        optionsIniPath: '   ',
        useAutoDetectOptionsIni: false,
      );

      // Then
      final state = container.read(appSettingControllerProvider);
      expect(state.hasError, isTrue);
      expect(state.error.toString(), contains('ValidationException'));
      expect(state.error.toString(), contains('setting.update.invalid'));
    });
  });
}

// ── Test Stub ───────────────────────────────────────────────────────────
class _StubSettingService extends SettingService {
  _StubSettingService() : super(repo: _NoopRepo());

  Future<Result<AppSetting>> Function()? onGetSettingView;
  Future<Result<AppSetting>> Function({
  int? rerunDelay,
  String? languageCode,
  String? themeName,
  String? steamPath,
  String? isaacPath,
  String? optionsIniPath,
  bool? useAutoDetectSteamPath,
  bool? useAutoDetectInstallPath,
  bool? useAutoDetectOptionsIni,
  })? onUpdate;

  @override
  Future<Result<AppSetting>> getSettingView() async {
    final fn = onGetSettingView;
    if (fn == null) throw StateError('onGetSettingView not set');
    return fn();
  }

  @override
  Future<Result<AppSetting>> update({
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
    final fn = onUpdate;
    if (fn == null) throw StateError('onUpdate not set');
    return fn(
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
  }
}

class _NoopRepo implements ISettingRepository {
  @override
  Future<AppSetting> load() async => AppSetting.defaults;

  @override
  Future<void> save(AppSetting s) async {}
}
