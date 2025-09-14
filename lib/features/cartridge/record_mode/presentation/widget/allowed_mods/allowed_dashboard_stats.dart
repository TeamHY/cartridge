// allowed_dashboard_stats.dart
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
    this.loading = false,
  });

  final int allowed;
  final int enabled;
  final int installed;
  final bool loading;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = AppLocalizations.of(context);
    final nf  = NumberFormat.decimalPattern();
    final missing = (allowed - installed).clamp(0, allowed);
    final sem = ref.watch(themeSemanticsProvider);

    final items = <_StatItem>[
      _StatItem(label: loc.allowed_stats_allowed,   value: allowed,   icon: FluentIcons.check_list),
      _StatItem(label: loc.allowed_stats_enabled,   value: enabled,   icon: FluentIcons.power_button, tone: sem.info),
      _StatItem(label: loc.allowed_stats_installed, value: installed, icon: FluentIcons.accept, tone: sem.success),
      _StatItem(label: loc.allowed_stats_missing,   value: missing,   icon: FluentIcons.cancel,
          tone: sem.danger, highlightValue: missing > 0),
    ];

    return LayoutBuilder(
      builder: (context, c) {
        final bounded = c.hasBoundedHeight;

        Widget twoTiles(int i, int j) => Row(children: [
          Expanded(child: _StatTile(item: items[i], formatter: nf, loading: loading, expandToHeight: bounded)),
          Gaps.w12,
          Expanded(child: _StatTile(item: items[j], formatter: nf, loading: loading, expandToHeight: bounded)),
        ]);

        if (bounded) {
          return Column(
            children: [
              Expanded(child: twoTiles(0, 1)),
              Gaps.h12,
              Expanded(child: twoTiles(2, 3)),
            ],
          );
        }

        return Column(
          children: [
            twoTiles(0, 1),
            Gaps.h12,
            twoTiles(2, 3),
          ],
        );
      },
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
  const _StatTile({
    required this.item,
    required this.formatter,
    required this.loading,
    this.expandToHeight = false,
  });
  final _StatItem item;
  final NumberFormat formatter;
  final bool loading;
  final bool expandToHeight;

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
    return StatusColor(fg: base, bg: base.withAlpha(bgA), border: base.withAlpha(bdA));
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
        constraints: widget.expandToHeight
            ? const BoxConstraints(minHeight: double.infinity)
            : const BoxConstraints(),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _hover ? tone.border : stroke, width: _hover ? 1.2 : .8),
        ),
        child: _StatTileBody(
          icon: widget.item.icon,
          label: widget.item.label,
          valueText: widget.formatter.format(widget.item.value),
          tone: tone,
          highlightValue: widget.item.highlightValue,
          loading: widget.loading, // ⟵ 전달
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
    required this.loading, // ⟵ 추가
  });

  final IconData icon;
  final String label;
  final String valueText;
  final StatusColor tone;
  final bool highlightValue;
  final bool loading; // ⟵ 추가

  @override
  Widget build(BuildContext context) {
    final t = FluentTheme.of(context);

    final iconBadge = Container(
      width: 32, height: 32,
      decoration: BoxDecoration(color: tone.bg, borderRadius: AppShapes.chip),
      child: Icon(icon, size: 20, color: tone.fg),
    );

    final valueStyle = const TextStyle(
      fontSize: 32,
      fontWeight: FontWeight.w800,
      letterSpacing: -0.5,
      fontFeatures: [FontFeature.tabularFigures()],
    );

    // 로딩이면 동일 레이아웃에 숫자만 '—'로 노출 (색상은 보조 컬러)
    final valueWidget = Text(
      loading ? '—' : valueText,
      style: valueStyle.copyWith(
        color: loading ? t.resources.textFillColorSecondary : null,
      ),
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.caption.merge(
              TextStyle(color: t.resources.textFillColorSecondary, fontWeight: FontWeight.w600),
            ),
          ),
          Gaps.h12,
          // 값 애니메이션은 로딩 해제 후 한 번만 부드럽게
          TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            tween: Tween<double>(begin: 0, end: 1),
            builder: (_, __, child) => child!,
            child: valueWidget,
          ),
        ]),
        const Spacer(),
        iconBadge,
      ],
    );
  }
}
