import 'package:cartridge/l10n/app_localizations.dart';
import 'package:cartridge/theme/theme.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Fluent + Localizations + ProviderScope를 한번에 세팅하는 테스트 호스트.
/// needButton을 켜면 중앙에 Button('Open')을 렌더링하고, onOpen을 눌렀을 때 호출한다.
class FluentTestHost extends ConsumerWidget {
  final Widget? child;
  final VoidCallback? onOpen;
  final bool needButton;
  final AppThemeKey themeKey;
  final List<Override> overrides;
  final bool useNavigationView;
  final bool useAppLocalizations;
  final Locale locale;
  final bool wrapWithScaffoldPage;

  const FluentTestHost({
    super.key,
    this.child,
    this.onOpen,
    this.needButton = false,
    this.themeKey = AppThemeKey.light,
    this.overrides = const [],
    this.useNavigationView = true,
    this.useAppLocalizations = true,
    this.locale = const Locale('ko'),
    this.wrapWithScaffoldPage = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resolved = AppTheme.resolve(themeKey);
    final sem = semanticsFor(themeKey);

    final List<LocalizationsDelegate<dynamic>> delegates = [
      if (useAppLocalizations) ...AppLocalizations.localizationsDelegates,
      FluentLocalizations.delegate,
    ];
    final locales = useAppLocalizations
        ? AppLocalizations.supportedLocales
        : const [Locale('en')];

    final content = Center(
      child: needButton
          ? Button(onPressed: onOpen, child: const Text('Open'))
          : (child ?? const SizedBox.shrink()),
    );

    late final Widget home;
    if (useNavigationView) {
      home = NavigationView(content: ScaffoldPage(content: content));
    } else if (wrapWithScaffoldPage) {
      home = ScaffoldPage(content: content);
    } else {
      home = content;
    }

    return ProviderScope(
      overrides: [
        selectedThemeKeyProvider.overrideWithValue(themeKey),
        themeSemanticsProvider.overrideWithValue(sem),
        resolvedThemeProvider.overrideWithValue(resolved),
        ...overrides,
      ],
      child: FluentApp(
        locale: locale,
        localizationsDelegates: delegates,
        supportedLocales: locales,
        themeMode: resolved.mode,
        theme: resolved.light,
        darkTheme: resolved.dark,
        home: home,
      ),
    );
  }
}
