import 'dart:io';

import 'package:desktop_updater/updater_controller.dart';
import 'package:cartridge/constants/urls.dart';
import 'package:cartridge/l10n/app_localizations.dart';
import 'package:cartridge/ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class AutoUpdater {
  static DesktopUpdaterController? _controller;
  static bool _dialogShown = false;

  static Future<void> checkAndUpdate(BuildContext context) async {
    final reachable = await _checkConnection();
    if (!reachable) {
      if (context.mounted) _showOfflineDialog(context);
      return;
    }

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

  static Future<bool> _checkConnection() async {
    try {
      final response = await http
          .get(Uri.parse(AppUrls.appArchive))
          .timeout(const Duration(seconds: 5));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  static void _showOfflineDialog(BuildContext context) {
    final loc = AppLocalizations.of(context);

    showAppDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AppDialog(
          constraints: const BoxConstraints(maxWidth: 368),
          title: Text(loc.home_dialog_update_title),
          content: Text(loc.home_dialog_network_error),
          actions: [
            AppButton.primary(
              onPressed: () => exit(0),
              child: Text(loc.common_confirm),
            ),
          ],
        );
      },
    );
  }

  static void _showUpdateDialog(BuildContext context) {
    final loc = AppLocalizations.of(context);

    _controller!.downloadUpdate();

    showAppDialog(
      context: context,
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

            return AppDialog(
              constraints: const BoxConstraints(maxWidth: 368),
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
                      final prefix = note.type != null ? '[${note.type}] ' : '';
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text('• $prefix${note.message}'),
                      );
                    }),
                  ],
                  const SizedBox(height: 16),
                  LinearProgressIndicator(
                    value: _controller!.downloadProgress,
                    minHeight: 4,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
