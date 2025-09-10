---
description: >
  lib/theme은 디자인 토큰(여백·타이포·브레이크포인트·팔레트)과 반응형 헬퍼, 다중 테마(Accent/표면색) 시스템을 중앙관리합니다.
  설정(themeId) → enum → Provider → FluentApp 까지 표준 파이프라인을 제공합니다.
globs: /lib/theme/*
alwaysApply: false
---

# Theme — MDC

> 매직 넘버 금지. 토큰·헬퍼·테마를 모듈화하고, `import 'package:cartridge/theme/theme.dart'` 한 줄로 사용.

## 1) 모듈 맵
- `tokens/spacing.dart` — **AppSpacing/Gaps**: 여백 스케일·레이아웃 상수·`EdgeInsets`/`SizedBox` 헬퍼.
- `tokens/typography.dart` — **AppTypography**: 텍스트 스타일 토큰(타이틀/본문/캡션/내비).
- `tokens/breakpoints.dart` — **AppBreakpoints/SizeClass**: 반응형 구간(xs~xl)과 분류 함수.
- `tokens/colors.dart` — **AppThemeKey/AppColors**: 테마 키(enum)와 라이트/다크/OLED/커스텀 팔레트.
- `tokens/radius.dart` — **AppRadius/AppShapes**: 반지름 스케일과 의미 기반 모양 프리셋(card/panel/dialog/chip).
- `responsive/context_breakpoints.dart` — **BuildContext 확장**: `screenWidth`, `isLgUp` 등.
- `responsive/adaptive_visibility.dart` — **AdaptiveVisibility**: `minWidth/maxWidth`로 표시/숨김.
- `app_theme.dart` — **AppTheme**: `FluentThemeData` 생성·보관(light/dark/oled/tangerine/claude) + `resolve(key)`.
- `theme_state.dart` — **Providers**: 설정(themeId)→`selectedThemeKeyProvider`→`resolvedThemeProvider`.
- `semantic_colors.dart` — **의미색**: info/success/warning/danger/neutral 팔레트 매핑 함수.
- `theme_previews.dart` — **미리보기/라벨**: `kThemePreviews`, `localizedThemeName`.
- `tokens.dart` — **토큰 배럴**: spacing/typography/breakpoints/colors export.
- `theme.dart` — **통합 배럴**: 토큰 + 테마 + 프리뷰 + 의미색 + 반응형 헬퍼 일괄 export.

## 2) 파이프라인 (설정 → 앱)
```

Setting(themeId:string)
↓  (byName/fallback)
selectedThemeKeyProvider : AppThemeKey
↓
resolvedThemeProvider    : { themeMode, light, dark }
↓
FluentApp(themeMode, theme, darkTheme)

````

## 3) 사용 규칙
- **숫자 하드코딩 금지**: 여백/높이/폭/브레이크포인트/패널 너비는 토큰만 사용.
- **반응형은 의미로 표현**: `context.isLgUp` / `AdaptiveVisibility(minWidth: AppBreakpoints.lg)`.
- **글꼴/타이포는 토큰으로**: `Text('...', style: AppTypography.sectionTitle)`.
- **테마 변경은 설정만 수정**: `settingProvider.setThemeId(key.name)` → 앱 전역 자동 반영.
- **라운드 규칙**:
    - 기본 반지름은 `AppRadius`(xs/sm/md/lg/xl) 스텝을 따른다.
    - 컴포넌트별 의미 프리셋은 `AppShapes` 사용(예: 카드= `AppShapes.card`, 다이얼로그= `AppShapes.dialog`).

## 4) 짧은 예시
```dart
import 'package:cartridge/theme/theme.dart';

return FluentApp(
  themeMode: ref.watch(resolvedThemeProvider).mode,
  theme:     ref.watch(resolvedThemeProvider).light,
  darkTheme: ref.watch(resolvedThemeProvider).dark,
);
````

## 4.1 반지름/모양 예시
```dart
Container(
  decoration: BoxDecoration(
    color: FluentTheme.of(context).cardColor,
    borderRadius: AppShapes.card,
    border: Border.all(color: FluentTheme.of(context).dividerColor),
  ),
);

ContentDialogThemeData(
  decoration: BoxDecoration(
    color: AppTheme.light.scaffoldBackgroundColor,
    borderRadius: AppShapes.dialog,
  ),
);
```

## 5) 새 테마 추가 절차

1. `AppThemeKey`에 키 추가 (예: `mint`).
2. `AppColors`에 팔레트/표면/구분선 추가(Accent swatch 권장).
3. `AppTheme`에 `_buildMint()` 및 `static final mint` 추가, `resolve`에 분기 추가.
4. (선택) `semantic_colors.dart`에서 의미색 미세 튜닝.
5. `kThemePreviews`/`localizedThemeName`에 라벨·프리뷰 추가.
6. 설정 화면의 ComboBox는 `AppThemeKey.values`를 쓰므로 자동 반영(라벨은 `localizedThemeName` 사용).

## 6) 체크리스트

* [ ] 새 컴포넌트의 여백/폭/높이는 **AppSpacing**을 사용했는가?
* [ ] 반응형 분기는 **의미 메서드**(`isMdUp` 등)로 표현했는가?
* [ ] 반복되는 숫자는 **토큰화**했는가?
* [ ] 라운드는 AppRadius/AppShapes로만 지정했는가? 
* [ ] 투명도는 withAlpha만 사용했는가?
* [ ] 테마 라벨은 `localizedThemeName`으로 다국어 표기했는가?
* [ ] `FluentApp`는 `resolvedThemeProvider`를 통해 연결했는가?

## 7) 테스트(권장)

* **직렬화**: `themeId → themeKey` 매핑, enum 설정 시 JSON `themeId` 문자열 저장.
* **Provider**: `settingProvider` 오버라이드로 테마 키를 주입했을 때 `resolvedThemeProvider` 결과 검증.
* **라벨**: 로케일별 `localizedThemeName`이 기대 문자열인지(Widget 테스트). 
* **시각 스냅샷**: Golden에서 폰트 로드 + FluentApp로 감싸고, 라운드/여백은 토큰 값 기준