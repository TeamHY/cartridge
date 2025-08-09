import 'package:cartridge/constants/urls.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cartridge/l10n/app_localizations.dart';

class QuickBar extends StatelessWidget {
  const QuickBar({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);

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
            child: Text(loc.quick_live)),
        const SizedBox(width: 4),
        Button(
            onPressed: () =>
                launchUrl(Uri.parse(AppUrls.openChat)),
            child: Text(loc.quick_chat)),
        const SizedBox(width: 4),
        Button(
            onPressed: () =>
                launchUrl(Uri.parse(AppUrls.modsPost)),
            child: Text(loc.quick_mods)),
        const SizedBox(width: 4),
        Button(
            onPressed: () => launchUrl(Uri.parse(AppUrls.donation)),
            child: Text(loc.quick_donation)),
      ],
    );
  }
}
