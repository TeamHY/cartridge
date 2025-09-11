/// {@template feature_overview}
/// # Setting Service
///
/// 앱 전역 설정을 로드/검증/정규화/저장하는 **Domain Service**.
/// - 파일 I/O는 Repository가 담당하고, 본 클래스는 도메인 규칙만 수행한다.
/// {@endtemplate}
library;

import 'package:cartridge/core/log.dart';
import 'package:cartridge/core/result.dart';
import 'package:cartridge/core/validation.dart';
import 'package:cartridge/features/cartridge/setting/data/i_setting_repository.dart';
import 'package:cartridge/features/cartridge/setting/domain/models/app_setting.dart';
import 'package:cartridge/features/cartridge/setting/domain/setting_domain_exception.dart';
import 'package:cartridge/features/cartridge/setting/domain/setting_policy.dart';

/// {@template setting_service}
/// # SettingService
///
/// 설정 로드/정규화/부분 업데이트/초기화 API를 제공하는 **Domain Service**.
///
/// ## 유스케이스(Use cases)
/// - 저장소에서 설정을 로드하고 내부 규칙으로 정규화(교정 시 저장)
/// - 특정 필드만 부분 업데이트(정규화 후 저장)
///
/// ## 전제(Preconditions)
/// - 정규화 규칙은 언어/테마/숫자 범위/경로 trim 을 포함
///
/// ## 관련(See also)
/// - [ISettingRepository]
/// - [AppSetting]
/// - [SettingPolicy]
/// - [SettingUseCase]
/// - [SettingQueryPort]
/// {@endtemplate}
/// {@macro setting_service}
class SettingService {
  static const _tag = 'SettingService';

  final ISettingRepository _repo;

  SettingService({required ISettingRepository repo}) : _repo = repo;

  // ── Queries(조회) ──────────────────────────────────────────────────────────────

  /// 설정을 로드한 뒤 **정규화(normalize)** 합니다.
  /// 원본과 달라지면 자동으로 교정본을 저장합니다.
  Future<Result<AppSetting>> getSettingView() async {
    try {
      final s = await getNormalized();
      return Result.ok(data: s, code: 'setting.getNormalized.ok');
    } on SettingDomainException catch (e) {
      return Result.invalid(violations: e.violations, code: e.code);
    } catch (_) {
      return const Result.failure(code: 'setting.getNormalized.fail');
    }
  }

  /// 설정을 로드한 뒤 **정규화(normalize)** 합니다.
  /// 원본과 달라지면 자동으로 교정본을 저장합니다.
  Future<AppSetting> getNormalized() async {
    final raw = await _repo.load();
    final normalized = SettingPolicy.normalize(raw);
    final vr = SettingPolicy.validate(normalized);
    _throwIfInvalid(vr, code: 'setting.getNormalized.invalid');

    if (!raw.equals(normalized)) {
      await _repo.save(normalized);
      logI(_tag, 'op=get fn=getNormalized msg=자동 교정 저장');
    }
    return normalized;
  }

  // ── Commands(생성/수정/삭제) ───────────────────────────────────────────────────

  /// 개별 필드 업데이트(부분 업데이트). 내부에서 정규화 후 저장합니다.
  Future<Result<AppSetting>> update({
    String? isaacPath,
    String? optionsIniPath,
    int? rerunDelay,
    String? languageCode,
    String? themeName,
    bool? useAutoDetectInstallPath,
    bool? useAutoDetectOptionsIni,
  }) async {
    try {
      final curr = await getNormalized();
      var next = curr.copyWith(
        isaacPath: isaacPath ?? curr.isaacPath,
        optionsIniPath: optionsIniPath ?? curr.optionsIniPath,
        rerunDelay: rerunDelay ?? curr.rerunDelay,
        languageCode: languageCode ?? curr.languageCode,
        themeName: themeName ?? curr.themeName,
        useAutoDetectInstallPath: useAutoDetectInstallPath ?? curr.useAutoDetectInstallPath,
        useAutoDetectOptionsIni: useAutoDetectOptionsIni ?? curr.useAutoDetectOptionsIni,
      );

      next = SettingPolicy.normalize(next);
      final vr = SettingPolicy.validate(next);
      if (!vr.isOk) {
        return Result.invalid(violations: vr.violations, code: 'setting.update.invalid');
      }

      if (curr.equals(next)) {
        return Result.ok(data: next, code: 'setting.update.noop');
      }
      await _repo.save(next);
      logI(_tag, 'op=update fn=update msg=설정 업데이트');
      return Result.ok(data: next, code: 'setting.update.ok');
    } on SettingDomainException catch (e) {
    return Result.invalid(violations: e.violations, code: e.code);
    } catch (_) {
    return const Result.failure(code: 'setting.update.fail');
    }
  }

  // ── Internals(내부 유틸) ──────────────────────────────────────────────────────
  void _throwIfInvalid(ValidationResult vr, {required String code}) {
    if (!vr.isOk) {
      throw SettingDomainException(code: code, violations: vr.violations);
    }
  }

}
