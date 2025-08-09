import 'package:cartridge/constants/urls.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:url_launcher/url_launcher.dart';

class QuickBar extends StatelessWidget {
  const QuickBar({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Button(
            onPressed: () async {
              await launchUrl(Uri.parse(AppUrls.youtube));
              await launchUrl(Uri.parse(AppUrls.twitch));
              await launchUrl(Uri.parse(AppUrls.afreeca));
              await launchUrl(Uri.parse(AppUrls.chzzk));
            },
            child: const Text('생방송')),
        const SizedBox(width: 4),
        Button(
            onPressed: () =>
                launchUrl(Uri.parse(AppUrls.openChat)),
            child: const Text('오픈채팅')),
        const SizedBox(width: 4),
        Button(
            onPressed: () =>
                launchUrl(Uri.parse(AppUrls.modsPost)),
            child: const Text('모드')),
        const SizedBox(width: 4),
        Button(
            onPressed: () => launchUrl(Uri.parse(AppUrls.donation)),
            child: const Text('후원')),
      ],
    );
  }
}
