import 'dart:async';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:cartridge/app/presentation/widgets/badge/badge.dart';
import 'package:cartridge/theme/theme.dart';

class PlusPillFlyout extends ConsumerStatefulWidget {
  const PlusPillFlyout({
    super.key,
    required this.count,
    required this.hiddenBadges,
    this.maxWidth = 360,
    this.maxHeight = 240,
  });

  final int count;
  final List<BadgeSpec> hiddenBadges;
  final double maxWidth;
  final double maxHeight;

  @override
  ConsumerState<PlusPillFlyout> createState() => _PlusPillFlyoutState();
}

class _PlusPillFlyoutState extends ConsumerState<PlusPillFlyout> {
  final _flyout = FlyoutController();

  bool _opened = false;
  bool _hoverInPill = false;
  bool _hoverInPanel = false;
  Timer? _closeDelayTimer;

  void _openDeferred() {
    if (_opened) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _opened) return;
      _opened = true;

      final fTheme = FluentTheme.of(context);
      _flyout.showFlyout(
        barrierColor: Colors.transparent,
        placementMode: FlyoutPlacementMode.bottomLeft,
        builder: (ctx) => FlyoutContent(
          color: fTheme.scaffoldBackgroundColor,
          padding: const EdgeInsets.all(1),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: widget.maxWidth,
              maxHeight: widget.maxHeight,
            ),
            child: MouseRegion(
              onEnter: (_) {
                _hoverInPanel = true;
                _closeDelayTimer?.cancel();
              },
              onExit: (_) {
                _hoverInPanel = false;
                _scheduleClose();
              },
              child: _BadgeTooltipPanel(badges: widget.hiddenBadges),
            ),
          ),
        ),
      );
    });
  }

  void _closeDeferred() {
    if (!_opened) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _opened = false;
      Flyout.of(context).close();
    });
  }

  void _scheduleClose() {
    _closeDelayTimer?.cancel();
    _closeDelayTimer = Timer(const Duration(milliseconds: 140), () {
      if (!_hoverInPill && !_hoverInPanel) {
        _closeDeferred();
      }
    });
  }

  @override
  void dispose() {
    _closeDelayTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pill = PlusPill(widget.count);

    return FlyoutTarget(
      controller: _flyout,
      child: MouseRegion(
        onEnter: (_) {
          _hoverInPill = true;
          _closeDelayTimer?.cancel();
          _openDeferred();
        },
        onExit: (_) {
          _hoverInPill = false;
          _scheduleClose();
        },
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            if (_opened) {
              _closeDeferred();
            } else {
              _openDeferred();
            }
          },
          child: pill,
        ),
      ),
    );
  }
}

class _BadgeTooltipPanel extends ConsumerWidget {
  const _BadgeTooltipPanel({required this.badges});
  final List<BadgeSpec> badges;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fTheme = FluentTheme.of(context);
    final Color shadowColor = fTheme.shadowColor.withAlpha(20);

    return Container(
      decoration: BoxDecoration(
        color: fTheme.cardColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: fTheme.dividerColor),
        boxShadow: [
          BoxShadow(
            blurRadius: 10,
            spreadRadius: 1,
            color: shadowColor,
          ),
        ],
      ),
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: badges.map((b) => Pill(b)).toList(),
      ),
    );
  }
}
