import 'package:cartridge/ui/ui.dart';
import 'package:flutter/material.dart';
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
            AppIconButton(
              icon: const PhosphorIcon(PhosphorIconsRegular.arrowLeft),
              iconSize: 20,
              onPressed: onBackPressed,
            ),
          Text(
            title,
            style: AppTextStyles.title,
          ),
          Expanded(child: Container()),
          if (actions != null) ...actions!,
        ],
      ),
    );
  }
}
