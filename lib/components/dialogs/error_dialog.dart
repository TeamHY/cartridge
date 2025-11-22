import 'package:fluent_ui/fluent_ui.dart';
import 'package:cartridge/l10n/app_localizations.dart';

void showErrorDialog(BuildContext context, String text) {
  showDialog(
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

    return ContentDialog(
      title: Text(loc.common_error),
      content: Text(text),
      actions: [
        FilledButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: Text(loc.common_close),
        ),
      ],
    );
  }
}
