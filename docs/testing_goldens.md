# Golden Tests — Fluent UI + 한글 폰트

## 사전 셋업
- 패키지: `golden_toolkit`
- 폰트: 한글은 기본 폰트 미포함 → **Pretendard** 같은 앱 폰트를 로드하거나 `loadTestFonts()` 유틸 사용

```dart
setUpAll(() async {
  TestWidgetsFlutterBinding.ensureInitialized();
  await loadTestFonts();     // 혹은 await loadAppFonts();
});
````

## 위젯 감싸기(Fluent)

```dart
await tester.pumpWidgetBuilder(
  ProviderScope(overrides: overrides, child: FluentApp(
    localizationsDelegates: const [FluentLocalizations.delegate],
    supportedLocales: const [Locale('en')],
    home: NavigationView(
      content: ScaffoldPage(child: ...),
    ),
  )),
  surfaceSize: const Size(800, 600),
);
```

## 다이얼로그/오버레이

* `showDialog(..., useRootNavigator: false)` 권장 (테스트 하네스의 Navigator/Overlay를 그대로 사용)
* InfoBar는 Overlay를 요구 → `NavigationView` 아래에서 호출

## 스냅샷

```dart
await screenMatchesGolden(tester, 'eden_dialog_initial');
```

### 업데이트

```bash
flutter test --update-goldens -r expanded
```