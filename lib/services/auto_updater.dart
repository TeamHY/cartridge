import 'package:desktop_updater/updater_controller.dart';
import 'package:cartridge/constants/urls.dart';
import 'package:cartridge/l10n/app_localizations.dart';
import 'package:fluent_ui/fluent_ui.dart';

class AutoUpdater {
  static DesktopUpdaterController? _controller;
  static bool _dialogShown = false;

  static void checkAndUpdate(BuildContext context) {
    _controller = DesktopUpdaterController(
      appArchiveUrl: Uri.parse(AppUrls.appArchive),
    );

    _controller!.addListener(() {
      if (_controller!.needUpdate && !_dialogShown && context.mounted) {
        _dialogShown = true;
        _showUpdateDialog(context);
      }
    });
  }

  static void _showUpdateDialog(BuildContext context) {
    final loc = AppLocalizations.of(context);

    _controller!.downloadUpdate();

    showDialog(
      context: context,
      dismissWithEsc: false,
      barrierDismissible: false,
      builder: (context) {
        return ListenableBuilder(
          listenable: _controller!,
          builder: (context, _) {
            if (_controller!.isDownloaded) {
              Future.microtask(() => _controller!.restartApp());
            }

            return ContentDialog(
              title: Text(loc.home_dialog_update_title),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(loc.home_dialog_update_required),
                  const SizedBox(height: 16),
                  ProgressBar(value: _controller!.downloadProgress * 100),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
