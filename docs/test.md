# 테스트 가이드 (Flutter · Fluent UI · Riverpod)

본 문서는 slot machine 및 전체 UI 테스트 작성 시 공통 규칙/헬퍼 사용법을 요약합니다.  
자세한 Golden 세팅은 [**testing_goldens.md**](./testing_goldens.md)를 함께 참고하세요.

---

## 0) 사전 셋업

- **폰트 로드**: 한글 폰트가 없으면 Golden/위젯 스냅샷이 깨집니다.
- **권장**: 모든 위젯/골든 테스트에서 `setUpAll`로 폰트 1회 로드.

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:test/helpers/load_test_fonts.dart';

setUpAll(() async {
  await loadTestFonts();
});
````

---

## 1) 테스트 호스트 (Fluent + ProviderScope + Theme)

`FluentTestHost`를 사용해 **FluentApp + ProviderScope + Localizations**를 한 번에 세팅합니다.

```dart
import 'package:test/helpers/fluent_host.dart';

// 기본 (ko 로케일, Light 테마, NavigationView 포함)
await tester.pumpWidget(FluentTestHost(child: MyWidget()));

// 다크 테마 + 영어 + NavigationView 미포함
await tester.pumpWidget(FluentTestHost(
  child: MyWidget(),
  themeKey: AppThemeKey.dark,
  useAppLocalizations: false,
  locale: const Locale('en'),
  useNavigationView: false,
));

// InfoBar/Overlay가 필요한 테스트는 useNavigationView: true 권장
```

### 프로바이더 오버라이드

컨트롤러/리포지토리 더블(Fake/Stub)을 주입할 때:

```dart
await tester.pumpWidget(FluentTestHost(
  child: MyWidget(),
  overrides: [
    slotMachineControllerProvider.overrideWith(/* FakeNotifier */),
    // 기타 Provider override...
  ],
));
```

---

## 2) Golden 테스트 요령

-폰트 로드 → 호스트로 감싸기 → `pumpWidgetBuilder` 또는 `pumpGolden(...)`.

```dart
import 'package:golden_toolkit/golden_toolkit.dart';
import 'package:test/helpers/pump_golden.dart';
import 'package:test/helpers/fluent_host.dart';

testGoldens('SlotView - light/dark', (tester) async {
  await loadTestFonts();

  final light = FluentTestHost(child: SlotView(...), themeKey: AppThemeKey.light);
  final dark  = FluentTestHost(child: SlotView(...),  themeKey: AppThemeKey.dark);

  final grid = GoldenBuilder.grid(columns: 2)
    ..addScenario('Light', light)
    ..addScenario('Dark', dark);

  await pumpGolden(tester, grid.build(), surfaceSize: const Size(900, 600));
  await screenMatchesGolden(tester, 'slot_view_variants');
});
```

**업데이트**:
`flutter test --update-goldens -r expanded`

**다이얼로그/오버레이**:

* 테스트에서 `showDialog(..., useRootNavigator: false)` 권장
* Overlay가 필요한 컴포넌트는 `NavigationView` 아래에서 호출

---

## 3) 애니메이션/입력·포커스

* **애니메이션 검증은 “존재/전이” 수준**으로: 정확한 타이밍 비교는 flaky합니다.
* `AnimatedOpacity`, `animateTo` 등은 `await tester.pump(Duration(...))`으로 프레임을 소화.
* 포커스/IME 조합 상태가 개입되는 입력 테스트는 **조합 중**(composing.valid)에는 단언을 피하세요.

---

## 4) 색상/토큰 규칙 (테스트 관점)

* 하드코딩 컬러 대신 **semantic colors**를 사용합니다:
  `final sem = ref.watch(themeSemanticsProvider);`
* 여백/크기/라운드: `AppSpacing`, `AppShapes` 사용
* 투명도: `withAlpha` 사용 (`withOpacity` 금지)

테스트에서 색상을 단언해야 한다면, **semantic에서 가져온 값**을 기준으로 비교하세요.

---

## 5) DB/Repo 테스트

* SQLite는 테스트에서 `sqflite_common_ffi` 사용 권장.
* in-memory DB(`inMemoryDatabasePath`)로 매 테스트를 격리.
* 마이그레이션은 **N→N+1 업그레이드 경로**를 별도 테스트로 커버.

---

## 6)Slot Machine 전용 체크

* `DesktopGrid._packRows`는 **full-row/cols wrapping** 조합을 커버(경계값 포함).
* 컨트롤러: `addLeft/addRight/remove/setItems`의 **ID/순서 보전**.
* `spinAllTickProvider` 브로드캐스트 확인.
* `SlotDialog`:

    * Enter → 행 추가, 빈칸 Backspace → 행 삭제
    * 멀티라인 Paste → 각 줄로 분배
* `SlotView`:

    * Hover 시 오버레이 토글(AnimatedOpacity)
    * 휠 스텝 애니메이션(간단히 호출 여부만)
    * 전역 스핀 틱 수신 시 애니메이션 시작

---

## 8) 샘플 스모크

```dart
testWidgets('smoke: SlotMachinePage builds in dark', (tester) async {
  await loadTestFonts();
  await tester.pumpWidget(FluentTestHost(
    themeKey: AppThemeKey.dark,
    child: const SlotMachinePage(),
  ));
  await tester.pump();
  expect(find.byType(ScaffoldPage), findsOneWidget);
});
```