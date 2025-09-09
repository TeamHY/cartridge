import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Fluent + Localizations + ProviderScope를 한번에 세팅하는 테스트 호스트.
/// needButton을 켜면 중앙에 Button('Open')을 렌더링하고, onOpen을 눌렀을 때 호출한다.
class FluentTestHost extends ConsumerWidget {
  final Widget? child;
  final VoidCallback? onOpen;
  final bool needButton;

  const FluentTestHost({
    super.key,
    this.child,
    this.onOpen,
    this.needButton = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FluentApp(
      localizationsDelegates: const [FluentLocalizations.delegate],
      supportedLocales: const [Locale('en')],
      locale: const Locale('en'),
      home: ScaffoldPage(
        content: Center(
          child: needButton
              ? Button(onPressed: onOpen, child: const Text('Open'))
              : (child ?? const SizedBox.shrink()),
        ),
      ),
    );
  }
}
