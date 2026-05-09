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

            final notes = _controller!.releaseNotes;
            final version = _controller!.appVersion;

            return ContentDialog(
              title: Text(
                '${loc.home_dialog_update_title} ${version ?? ''}',
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(loc.home_dialog_update_required),
                  if (notes != null && notes.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    ...notes.map((note) {
                      if (note == null) return const SizedBox.shrink();
                      final prefix =
                          note.type != null ? '[${note.type}] ' : '';
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text('• $prefix${note.message}'),
                      );
                    }),
                  ],
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
