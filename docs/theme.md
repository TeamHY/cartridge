---
description: >
  lib/theme은 디자인 토큰(여백·타이포·브레이크포인트)과 반응형 헬퍼를 중앙에서 관리하고,
  프로젝트 전역을 한 줄 import로 일관되게 스타일링하기 위한 기준 모음입니다.
globs: /lib/theme/*
alwaysApply: false
------------------

# Theme — MDC

> 매직 넘버 금지, 토큰·헬퍼로 일관성 유지, `import 'package:cartridge/theme/theme.dart'` 한 줄로 쓰기.

## 1) 모듈 맵

* `tokens/spacing.dart` — **AppSpacing/Gaps**: 여백 스케일·레이아웃 상수·`EdgeInsets`/`SizedBox` 헬퍼.
* `tokens/typography.dart` — **AppTypography**: 텍스트 스타일 토큰(타이틀/바디/캡션/내비 등).
* `tokens/breakpoints.dart` — **AppBreakpoints/SizeClass**: 반응형 구간 정의(xs\~xl)와 분류 함수.
* `responsive/context_breakpoints.dart` — **BuildContext 확장**: `screenWidth`, `isLgUp` 등 폭 기반 쿼리.
* `responsive/adaptive_visibility.dart` — **AdaptiveVisibility**: `minWidth/maxWidth`로 표시/숨김 제어.
* `tokens.dart` — **토큰 배럴**: spacing/typography/breakpoints를 한 번에 export.
* `theme.dart` — **통합 배럴**: `tokens.dart` + responsive 확장/위젯을 한 번에 export.

## 2) 사용 규칙

* **숫자 하드코딩 금지**: 여백·높이·패널 너비·브레이크포인트는 모두 토큰으로 사용.
* **반응형은 의미로 표현**: `context.isLgUp`/`AdaptiveVisibility(minWidth: AppBreakpoints.lg)`로 가독성 확보.
* **타이포는 토큰으로**: `Text('...', style: AppTypography.sectionTitle)` 등 의미 중심 스타일명 사용.
* **한 줄 import 권장**: `import 'package:cartridge/theme/theme.dart';` 만으로 토큰/헬퍼 전부 접근.

## 3) 짧은 예시

```dart
import 'package:cartridge/theme/theme.dart';

Container(
  padding: AppSpacing.sym(h: AppSpacing.gutter, v: AppSpacing.lg),
  child: Column(
    children: [
      Text('Settings', style: AppTypography.sectionTitle),
      if (context.isLgUp) const QuickBar(),
      AdaptiveVisibility(minWidth: AppBreakpoints.md, child: const Text('MD↑')),
    ],
  ),
);
```

## 4) 체크리스트

* [ ] 새 컴포넌트에서 **여백/높이/폭/폰트**는 토큰만 사용했는가?
* [ ] 반응형 분기는 **의미 메서드**(`isMdUp` 등)로 표현했는가?
* [ ] 반복되는 숫자(예: 캡션 영역 너비)는 **토큰으로 추출**했는가?
* [ ] 신규 파일은 `theme.dart`에 의해 **한 줄 import**로 접근 가능한가?

## 5) 네이밍/버전

* **토큰 접두사**: `AppSpacing`, `AppTypography`, `AppBreakpoints`로 통일.
* **확장/위젯 접두사**: `Adaptive*`, `Breakpoint*`처럼 역할이 드러나게 유지.
* **변경 시**: 토큰 값 수정 → 영향 범위 리뷰 → 릴리즈 노트에 기록.
