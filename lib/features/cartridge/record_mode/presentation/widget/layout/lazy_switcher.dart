// 스켈레톤 스위처 (최소 노출 시간)
import 'package:fluent_ui/fluent_ui.dart';

class LazySwitcher extends StatefulWidget {
  const LazySwitcher({
    super.key,
    required this.loading,
    required this.skeleton,
    required this.child,
    this.empty,
    this.minSkeleton = const Duration(milliseconds: 400),
    this.fade = const Duration(milliseconds: 180),
  });

  final bool loading;
  final Widget skeleton;
  final Widget child;
  final Widget? empty;
  final Duration minSkeleton;
  final Duration fade;

  @override
  State<LazySwitcher> createState() => _LazySwitcherState();
}

class _LazySwitcherState extends State<LazySwitcher> {
  bool _showSkeleton = false;
  DateTime? _start;

  @override
  void initState() { super.initState(); _maybeStartSkeleton(); }
  @override
  void didUpdateWidget(covariant LazySwitcher oldWidget) { super.didUpdateWidget(oldWidget); _maybeStartSkeleton(); }

  void _maybeStartSkeleton() {
    if (widget.loading) {
      _start = DateTime.now();
      if (!_showSkeleton) setState(() => _showSkeleton = true);
    } else if (_showSkeleton) {
      final spent = DateTime.now().difference(_start ?? DateTime.now());
      final remain = widget.minSkeleton - spent;
      if (remain.isNegative) {
        setState(() => _showSkeleton = false);
      } else {
        Future.delayed(remain, () { if (mounted) setState(() => _showSkeleton = false); });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final showSkeleton = widget.loading || _showSkeleton;
    final body = showSkeleton ? widget.skeleton
        : (widget.child is SizedBox && (widget.child as SizedBox).height == 0)
        ? (widget.empty ?? const SizedBox.shrink())
        : widget.child;

    return AnimatedSwitcher(
      duration: widget.fade,
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      child: body,
    );
  }
}