import 'package:cartridge/ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:cartridge/l10n/app_localizations.dart';

void showErrorDialog(BuildContext context, String text) {
  showAppDialog(
    context: context,
    builder: (context) {
      return ErrorDialog(text: text);
    },
  );
}

class ErrorDialog extends StatelessWidget {
  const ErrorDialog({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);

    return AppDialog(
      constraints: const BoxConstraints(maxWidth: 368),
      title: Text(loc.common_error),
      content: Text(text),
      actions: [
        AppButton.primary(
          onPressed: () {
            Navigator.pop(context);
          },
          child: Text(loc.common_close),
        ),
      ],
    );
  }
}
