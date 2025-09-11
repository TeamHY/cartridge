// 예: lib/app/presentation/widgets/ut/ut_header_refresh_button.dart

import 'package:fluent_ui/fluent_ui.dart';

class UTHeaderRefreshButton extends StatefulWidget {
  const UTHeaderRefreshButton({
    super.key,
    required this.onRefresh,
    this.tooltip = 'Refresh',
    this.duration = const Duration(milliseconds: 600),
  });

  final Future<void> Function() onRefresh;
  final String tooltip;
  final Duration duration;

  @override
  State<UTHeaderRefreshButton> createState() => _UTHeaderRefreshButtonState();
}

class _UTHeaderRefreshButtonState extends State<UTHeaderRefreshButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl =
  AnimationController(vsync: this, duration: widget.duration);
  bool _busy = false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _handlePressed() async {
    if (_busy) return;
    setState(() => _busy = true);

    // 아이콘 한 바퀴 회전
    _ctrl.forward(from: 0.0);

    try {
      await widget.onRefresh();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final icon = RotationTransition(
      turns: _ctrl, // 0→1 == 360°
      child: const Icon(FluentIcons.refresh, size: 16),
    );

    return Tooltip(
      message: widget.tooltip,
      child: IconButton(
        icon: icon,
        onPressed: _busy ? null : _handlePressed,
      ),
    );
  }
}
