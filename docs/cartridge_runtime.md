---
description: >
  Cartridge Runtime(Isaac 런칭 오케스트레이션) 모듈의 계약·시퀀스·정책·에러 매핑·테스트 기준을 정의합니다.
  환경 해석→옵션 프리셋 적용→모드 동기화→실행의 원클릭 플로우를 안전/보수적으로 수행합니다.
globs: /lib/features/cartridge/runtime/*
alwaysApply: false
---

# Cartridge Runtime — MDC

> AI/개발자가 `cartridge/runtime` 런칭 기능을 구현/확장할 때 따르는 **단일 기준**입니다. (Windows 전용)

## 1) 모듈 맵
- `isaac_launcher_service.dart` — **오케스트레이터**: `launchIsaac()` 단일 진입점.
- **의존 서비스/모델**
    - `IsaacEnvironmentService` — `resolveEnvironment(optionsIniPathOverride?) → {installPath, optionsIniPath, modsRoot}?`
    - `IsaacOptionsIniService` — `apply(optionsIniPath, options)`로 **스키마/정책 기반 교정 저장**.
    - `ModsService` — `applyPreset(modsRoot, Map<String, ModEntry> entries)`로 **enable/disable** 반영.
    - `IsaacRuntimeService` — `startIsaac(installPath, extraArgs) → Future<Process>` (**실행/로깅/자원 최소화**).
    - `OptionPreset` / `ModEntry` / `buildIsaacExtraArgs()` — 프리셋/엔트리/실행 인자 모델.

---

## 2) 퍼블릭 계약 — `IsaacLauncherService.launchIsaac` 
```dart
Future<Process?> launchIsaac({
  OptionPreset? optionPreset,
  Map<String, ModEntry> entries = const <String, ModEntry>{}, // 켤 목록(나머지는 disable)
  AppSetting? appSetting,              // (현재 미사용, 예약)
  String? optionsIniPathOverride,      // 강제 INI 경로
  String? installPathOverride,         // 강제 설치 경로
  List<String> extraArgs = const [],   // 기본 인자
});
```
- **반환**: `Process?`(실행 성공 시 핸들, 환경 미해결 시 `null`)
- **부작용**: options.ini 교정 저장(프리셋 있을 때), 모드 enable/disable, Isaac 프로세스 실행

---

## 3) 실행 시퀀스
```mermaid
sequenceDiagram
  participant UI
  participant L as IsaacLauncherService
  participant ENV as IsaacEnvironmentService
  participant OPT as IsaacOptionsIniService
  participant MOD as ModsService
  participant RT as IsaacRuntimeService

  UI->>L: launchIsaac(preset, entries, overrides, extraArgs)
  L->>ENV: resolveEnvironment(optionsIniPathOverride)
  alt env == null
    ENV-->>L: null
    L-->>UI: return null
  else env ok
    ENV-->>L: {installPath, optionsIniPath, modsRoot}
    alt preset != null
      L->>OPT: apply(optionsIniPath, preset.options)
      OPT-->>L: ok
      L->>RT: buildIsaacExtraArgs(installPath, preset, base=extraArgs)
      RT-->>L: effectiveArgs
    else no preset
      L-->>L: effectiveArgs = extraArgs
    end
    L->>MOD: applyPreset(modsRoot, entries)
    alt success
      MOD-->>L: ok
      L-->>L: logI("Mods applyPreset 성공")
    else error
      MOD-->>L: throw
      L-->>L: logE("ModsService.applyPreset 실패", e)
    end
    L->>RT: startIsaac(installPath, effectiveArgs)
    RT-->>L: Process
    L-->>UI: Process
  end
```

---

## 4) 인자 병합 규칙
- **기본**: `effectiveArgs = [...extraArgs]`
- **프리셋 존재 시**: `effectiveArgs = buildIsaacExtraArgs(installPath*, preset, base=extraArgs)`
    - installPath* = `installPathOverride ?? env.installPath`
    - `buildIsaacExtraArgs`는 **중복 인자 방지** 및 **순서 안정성** 보장(프로젝트 정책).

---

## 5) 모드 동기화 정책
- 입력 `entries`는 **켜둘 목록**으로 간주하고, 나머지는 **disable 정책**에 따라 처리(`ModsService.applyPreset` 내부 규칙).
- 실패 시 런처는 **에러를 삼키고 로그만 남긴 뒤 계속 진행**(실행 시도 유지).

---

## 6) 환경/오류 정책
- 환경(`ENV`)이 `null`이면 **launch 중단**하며 `null` 반환(사용자에게 경로/설정 안내).
- 기타 오류(옵션/모드)는 **부분 실패 허용**, 실행 자체는 시도하여 **사용자 가치 극대화**.
- 로깅 포맷: 태그=`IsaacLauncherService`, `logI/logE`에 **key=value** 스타일 메시지 권장.

---

## 7) 보안/UX/성능
- **사용자 트리거**에서만 실행, 인자/경로 **정규화/따옴표** 필수.
- 실행 전 옵션/모드 작업은 **짧게**(I/O는 예외 안전), 실패 시 즉시 안내하고 런치 지속.
- 실행 직전/중에는 **자원 최소화 모드**(IsaacRuntimeService 훅)로 백그라운드 작업 완화.

---

## 8) 테스트 케이스
- “환경 실패 시 **null**을 반환한다”
- “프리셋이 있으면 `options.apply`가 호출되고 **인자가 보강**된다”
- “프리셋이 없으면 **extraArgs 그대로** 전달된다”
- “`applyPreset` 실패 시 **logE 후에도** `startIsaac`이 호출된다”
- “`installPathOverride`가 있으면 그것이 **우선 적용**된다”
- “`entries`가 비어도 실행은 가능하다(모드 동기화는 no-op)”

---

## 9) 체크리스트
- [ ] `resolveEnvironment` 결과 필수 필드(installPath/optionsIniPath/modsRoot) 검증
- [ ] `buildIsaacExtraArgs`의 **중복/순서** 규칙 테스트
- [ ] `applyPreset` 실패 로그 형식/문구 표준화
- [ ] `startIsaac` 호출 전 인자/경로 **따옴표 처리** 확인
- [ ] 외부 의존 서비스들을 **모킹**하여 단위 테스트 구성
- [ ] 향후 `appSetting` 파라미터 사용 계획 문서화(현재는 **예약 필드**)
