import 'package:fluent_ui/fluent_ui.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class SubPageHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onBackPressed;
  final List<Widget>? actions;

  const SubPageHeader({
    super.key,
    required this.title,
    this.onBackPressed,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Row(
        spacing: 4,
        children: [
          if (onBackPressed != null)
            IconButton(
              icon: const PhosphorIcon(
                PhosphorIconsRegular.arrowLeft,
                size: 20,
              ),
              onPressed: onBackPressed,
            ),
          Text(
            title,
            style: FluentTheme.of(context).typography.subtitle,
          ),
          Expanded(child: Container()),
          if (actions != null) ...actions!,
        ],
      ),
    );
  }
}
