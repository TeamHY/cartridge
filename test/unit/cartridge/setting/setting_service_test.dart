import 'package:cartridge/core/result.dart';
import 'package:cartridge/features/cartridge/setting/setting.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SettingService', () {
    late _FakeRepo repo;
    late SettingService sut;

    setUp(() {
      repo = _FakeRepo();
      sut = SettingService(repo: repo);
    });

    test('getNormalized(): raw → normalize 교정 저장(save 1회)', () async {
      // Given: 비정상(raw) 값
      repo.stored = AppSetting(
        steamPath: '',
        isaacPath: '  D:/Games/Isaac  ', // trim 대상
        optionsIniPath: '   ', // trim → ''
        rerunDelay: AppSetting.rerunDelayMax + 999, // clamp 대상
        languageCode: 'EN', // lower-case 대상
        themeName: 'invalid-theme', // fallback → system
        useAutoDetectSteamPath: true,
        useAutoDetectInstallPath: true,
        useAutoDetectOptionsIni: true,
      );

      // When
      final got = await sut.getNormalized();

      // Then
      expect(repo.saveCount, 1);
      expect(got.languageCode, 'en');
      expect(got.themeName, 'system');
      expect(got.rerunDelay, AppSetting.rerunDelayMax);
      expect(got.isaacPath, 'D:/Games/Isaac');
      expect(got.optionsIniPath, '');
    });

    test('getNormalized(): 이미 정상 값이면 save 호출 없음(noop)', () async {
      // Given: defaults는 이미 normalize된 상태라고 가정
      repo.stored = AppSetting.defaults;

      // When
      final got = await sut.getNormalized();

      // Then
      expect(repo.saveCount, 0);
      expect(got.languageCode, AppSetting.defaults.languageCode);
      expect(got.themeName, AppSetting.defaults.themeName);
      expect(got.rerunDelay, AppSetting.defaults.rerunDelay);
    });

    test('getSettingView(): validate 위반 시 Result.invalid 반환(save 없음)', () async {
      // Given: auto-detect OFF + 빈 경로 → 정책 위반
      repo.stored = AppSetting.defaults.copyWith(
        useAutoDetectOptionsIni: false,
        optionsIniPath: '   ',
      );

      // When
      final res = await sut.getSettingView();

      // Then
      expect(repo.saveCount, 0);
      res.map(
        ok: (_) => fail('expected invalid'),
        notFound: (_) => fail('expected invalid'),
        conflict: (_) => fail('expected invalid'),
        failure: (_) => fail('expected invalid'),
        invalid: (r) {
          expect(r.code, 'setting.getNormalized.invalid');
          expect(r.violations, isNotEmpty);
        },
      );
    });

    test('update(): 부분 업데이트 → normalize/validate 후 save 및 Result.ok', () async {
      // Given
      repo.stored = AppSetting.defaults;

      // When
      final res = await sut.update(
        languageCode: 'EN', // → 'en'
        themeName: 'invalid-theme', // → 'system'
        rerunDelay: AppSetting.rerunDelayMax + 1, // → clamp to max
      );

      // Then
      expect(repo.saveCount, 1);
      res.map(
        invalid: (_) => fail('expected ok'),
        notFound: (_) => fail('expected ok'),
        conflict: (_) => fail('expected ok'),
        failure: (_) => fail('expected ok'),
        ok: (r) {
          expect(r.code, 'setting.update.ok');
          final s = r.data!;
          expect(s.languageCode, 'en');
          expect(s.themeName, 'system');
          expect(s.rerunDelay, AppSetting.rerunDelayMax);
        },
      );
    });

    test('update(): invalid → Result.invalid, save 없음', () async {
      // Given
      repo.stored = AppSetting.defaults;

      // When: auto-detect OFF인데 빈 isaacPath → 위반
      final res = await sut.update(
        useAutoDetectInstallPath: false,
        isaacPath: '   ',
      );

      // Then
      expect(repo.saveCount, 0);
      res.map(
        ok: (_) => fail('expected invalid'),
        notFound: (_) => fail('expected invalid'),
        conflict: (_) => fail('expected invalid'),
        failure: (_) => fail('expected invalid'),
        invalid: (r) {
          expect(r.code, 'setting.update.invalid');
          expect(r.violations, isNotEmpty);
        },
      );
    });

    test('update(): 변경 없음(noop) → Result.ok(code noop), save 없음', () async {
      // Given: 이미 normalize된 상태
      final curr = AppSetting.defaults;
      repo.stored = curr;

      // When: 아무것도 변경하지 않음
      final res = await sut.update();

      // Then
      expect(repo.saveCount, 0);
      res.map(
        invalid: (_) => fail('expected ok'),
        notFound: (_) => fail('expected ok'),
        conflict: (_) => fail('expected ok'),
        failure: (_) => fail('expected ok'),
        ok: (r) {
          expect(r.code, 'setting.update.noop');
          final s = r.data!;
          expect(s.languageCode, curr.languageCode);
          expect(s.themeName, curr.themeName);
          expect(s.rerunDelay, curr.rerunDelay);
        },
      );
    });

    test('getNormalized(): validate 위반 시 SettingDomainException throw', () async {
      // Given: auto-detect OFF + 빈 isaacPath → 정책 위반
      repo.stored = AppSetting.defaults.copyWith(
        useAutoDetectInstallPath: false,
        isaacPath: ' ',
      );


      // When/Then
      await expectLater(
        sut.getNormalized(),
        throwsA(
          isA<SettingDomainException>()
              .having((e) => e.code, 'code', 'setting.getNormalized.invalid')
              .having((e) => e.violations, 'violations', isNotEmpty),
        ),
      );
      // 저장 시도 없음
      expect(repo.saveCount, 0);
    });


    test('update(): 내부 getNormalized() 예외 → Result.invalid으로 변환', () async {
      // Given: 최초 로드 시 validate 위반이 발생하는 상태
      repo.stored = AppSetting.defaults.copyWith(
        useAutoDetectOptionsIni: false,
        optionsIniPath: ' ',
      );


      // When: update 호출(내부에서 먼저 getNormalized() 수행)
      final res = await sut.update(themeName: 'dark');


      // Then: 예외를 Result.invalid으로 변환해 반환
      expect(repo.saveCount, 0);
      res.map(
        ok: (_) => fail('expected invalid'),
        notFound: (_) => fail('expected invalid'),
        conflict: (_) => fail('expected invalid'),
        failure: (_) => fail('expected invalid'),
        invalid: (r) {
          expect(r.code, 'setting.getNormalized.invalid');
          expect(r.violations, isNotEmpty);
        },
      );
    });
  });
}

// ── Test Doubles ───────────────────────────────────────────────────────────
class _FakeRepo implements ISettingRepository {
  AppSetting? stored;
  int saveCount = 0;
  final List<AppSetting> saveHistory = [];

  _FakeRepo();

  @override
  Future<AppSetting> load() async {
    stored ??= AppSetting.defaults;
    return stored!;
  }

  @override
  Future<void> save(AppSetting s) async {
    stored = s;
    saveCount += 1;
    saveHistory.add(s);
  }
}
