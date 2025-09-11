import 'dart:async';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:cartridge/features/web_preview/web_preview.dart';

final warmupEnabledProvider = Provider<bool>((_) => true);

class WarmBootHook extends ConsumerStatefulWidget {
  final Widget child;
  const WarmBootHook({super.key, required this.child});

  @override
  ConsumerState<WarmBootHook> createState() => _WarmBootHookState();
}

class _WarmBootHookState extends ConsumerState<WarmBootHook> {
  bool _kicked = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_kicked) return;
    _kicked = true;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      if (!ref.read(warmupEnabledProvider)) return;
      try {
        final svc = ref.read(previewWarmupServiceProvider);
        unawaited(svc.start(maxItems: 30));
      } catch (_) { }
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}