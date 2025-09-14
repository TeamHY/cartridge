import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:cartridge/l10n/app_localizations.dart';
import 'package:cartridge/theme/theme.dart';

class AllowedDashboardStats extends ConsumerWidget {
  const AllowedDashboardStats({
    super.key,
    required this.allowed,
    required this.enabled,
    required this.installed,
  });

  final int allowed;
  final int enabled;
  final int installed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = AppLocalizations.of(context);
    final nf  = NumberFormat.decimalPattern(); // 1,234 포맷
    final missing = (allowed - installed).clamp(0, allowed);
    final sem = ref.watch(themeSemanticsProvider);
    final acc2 = accent2StatusOf(context, ref);

    // 각 항목 정의
    final items = <_StatItem>[
      _StatItem(label: loc.allowed_stats_allowed,   value: allowed,   icon: FluentIcons.check_list),
      _StatItem(label: loc.allowed_stats_enabled,   value: enabled,   icon: FluentIcons.power_button, tone: acc2),
      _StatItem(label: loc.allowed_stats_installed, value: installed, icon: FluentIcons.accept),
      _StatItem(label: loc.allowed_stats_missing,   value: missing,   icon: FluentIcons.cancel,
          tone: sem.danger, highlightValue: missing > 0),
    ];

    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _StatTile(item: items[0], formatter: nf)),
            Gaps.w12,
            Expanded(child: _StatTile(item: items[1], formatter: nf)),
          ],
        ),
        Gaps.h12,
        Row(
          children: [
            Expanded(child: _StatTile(item: items[2], formatter: nf)),
            Gaps.w12,
            Expanded(child: _StatTile(item: items[3], formatter: nf)),
          ],
        ),
      ],
    );
  }
}

class _StatItem {
  const _StatItem({
    required this.label,
    required this.value,
    required this.icon,
    this.tone,
    this.highlightValue = false,
  });
  final String label;
  final int value;
  final IconData icon;
  final StatusColor? tone;
  final bool highlightValue;
}

class _StatTile extends StatefulWidget {
  const _StatTile({required this.item, required this.formatter});
  final _StatItem item;
  final NumberFormat formatter;

  @override
  State<_StatTile> createState() => _StatTileState();
}

class _StatTileState extends State<_StatTile> {
  bool _hover = false;

  StatusColor _toneOrAccent(BuildContext context, StatusColor? tone) {
    if (tone != null) return tone;
    final theme = FluentTheme.of(context);
    final base  = theme.accentColor.normal;
    final dark  = theme.brightness == Brightness.dark;
    final bgA   = dark ? 36 : 28;
    final bdA   = dark ? 140 : 120;
    return StatusColor(
      fg: base,
      bg: base.withAlpha(bgA),
      border: base.withAlpha(bdA),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = FluentTheme.of(context);
    final tone   = _toneOrAccent(context, widget.item.tone);
    final bg     = t.resources.cardBackgroundFillColorDefault;
    final stroke = t.resources.controlStrokeColorSecondary.withAlpha(32);


    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit:  (_) => setState(() => _hover = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOut,
        padding: const EdgeInsets.all(AppRadius.xl),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _hover ? tone.border : stroke,
            width: _hover ? 1.2 : .8,
          ),
        ),
        child: _StatTileBody(
          icon: widget.item.icon,
          label: widget.item.label,
          valueText: widget.formatter.format(widget.item.value),
          tone: tone,
          highlightValue: widget.item.highlightValue,
        ),
      ),
    );
  }
}

class _StatTileBody extends StatelessWidget {
  const _StatTileBody({
    required this.icon,
    required this.label,
    required this.valueText,
    required this.tone,
    required this.highlightValue,
  });

  final IconData icon;
  final String label;
  final String valueText;
  final StatusColor tone;
  final bool highlightValue;

  @override
  Widget build(BuildContext context) {
    final t = FluentTheme.of(context);

    // 아이콘 배지 (엣지 둥근 원형 배경)
    final iconBadge = Container(
      width: 32, height: 32,
      decoration: BoxDecoration(
        color: tone.bg,
        shape: BoxShape.rectangle,
        borderRadius: AppShapes.chip,
      ),
      child: Icon(icon, size: 20, color: tone.fg),
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.caption.merge(
                TextStyle(
                  color: t.resources.textFillColorSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Gaps.h12,
            TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              tween: Tween<double>(begin: 0, end: 1),
              builder: (_, __, child) => child!,
              child: Text(
                valueText,
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            ),
          ],
        ),
        const Spacer(),
        iconBadge,
      ],
    );
  }
}
