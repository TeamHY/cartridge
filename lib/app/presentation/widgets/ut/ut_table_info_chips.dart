import 'package:fluent_ui/fluent_ui.dart';

enum _ChipTone { neutral, info, success }

class UTInfoChipsRow extends StatelessWidget {
  const UTInfoChipsRow({
    super.key,
    required this.total,
    required this.matched,
    required this.selected,
    this.showMatched = false,
    this.showSelected = false,
  });

  final int total;
  final int matched;
  final int selected;
  final bool showMatched;
  final bool showSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        _InfoChip(
          icon: FluentIcons.bulleted_list,
          label: '전체',
          value: total,
          tone: _ChipTone.neutral,
        ),
        if (showMatched)
          _InfoChip(
            icon: FluentIcons.search,
            label: '검색됨',
            value: matched,
            tone: _ChipTone.info,
          ),
        if (showSelected)
          _InfoChip(
            icon: FluentIcons.check_mark,
            label: '선택됨',
            value: selected,
            tone: _ChipTone.success,
          ),
      ],
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.icon,
    required this.label,
    required this.value,
    this.tone = _ChipTone.neutral,
  });

  final IconData icon;
  final String label;
  final int value;
  final _ChipTone tone;

  @override
  Widget build(BuildContext context) {
    final t = FluentTheme.of(context);
    final isDark = t.brightness == Brightness.dark;

    late final Color fg;
    late final Color bg;
    late final Color border;

    if (tone == _ChipTone.neutral) {
      final base = isDark ? Colors.white : Colors.black;
      fg = base.withAlpha(isDark ? 192 : 168);
      bg = base.withAlpha(isDark ? 25 : 15);
      border = base.withAlpha(isDark ? 60 : 46);
    } else {
      final base = (tone == _ChipTone.info)
          ? t.accentColor.normal
          : t.accentColor.light;
      fg = base;
      bg = base.withAlpha(isDark ? 60 : 24);
      border = base.withAlpha(isDark ? 130 : 160);
    }

    return Container(
      height: 22,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: fg),
          const SizedBox(width: 6),
          Text(
            '$label ',
            style: TextStyle(
              color: fg,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            '$value',
            style: TextStyle(
              color: fg,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
