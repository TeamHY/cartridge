import 'package:fluent_ui/fluent_ui.dart';

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
    return ContentDialog(
      title: const Text('오류'),
      content: Text(text),
      actions: [
        FilledButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: const Text('닫기'),
        ),
      ],
    );
  }
}
