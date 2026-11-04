import 'package:cartridge/l10n/app_localizations.dart';
import 'package:cartridge/providers/repentogon_provider.dart';
import 'package:cartridge/utils/repentogon_error_text.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

/// Runs a REPENTOGON install / update / repair and shows its progress.
class RepentogonInstallDialog extends ConsumerStatefulWidget {
  const RepentogonInstallDialog({super.key});

  @override
  ConsumerState<RepentogonInstallDialog> createState() =>
      _RepentogonInstallDialogState();
}

class _RepentogonInstallDialogState
    extends ConsumerState<RepentogonInstallDialog> {
  RepentogonInstallOutcome? _outcome;

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      final outcome = await ref.read(repentogonProvider).install();
      if (mounted) setState(() => _outcome = outcome);
    });
  }

  String _formatBytes(int bytes) {
    if (bytes >= 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / 1024).toStringAsFixed(0)} KB';
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final repentogon = ref.watch(repentogonProvider);
    final isDone = _outcome != null;

    final Widget header;
    switch (_outcome) {
      case null:
        header = Row(
          children: [
            const SizedBox(width: 16, height: 16, child: ProgressRing()),
            const SizedBox(width: 8),
            Text(loc.repentogon_install_in_progress),
          ],
        );
      case RepentogonInstallOutcome.installed:
        header = Text(loc.repentogon_install_done);
      case RepentogonInstallOutcome.upToDate:
        header = Text(loc.repentogon_install_up_to_date);
      case RepentogonInstallOutcome.failed:
        header = Text(
          describeRepentogonError(
              loc, repentogon.lastError ?? loc.repentogon_error_install_failed),
          style: TextStyle(color: Colors.red),
        );
    }

    final lines = [
      ...repentogon.installLogs,
      for (final entry in repentogon.downloads.entries)
        loc.repentogon_download_progress(
            p.basename(entry.key), _formatBytes(entry.value)),
    ];

    return ContentDialog(
      constraints: const BoxConstraints(maxWidth: 640),
      title: Text(loc.repentogon_install_dialog_title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          header,
          const SizedBox(height: 12),
          Container(
            height: 240,
            width: double.infinity,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(4),
            ),
            child: ListView.builder(
              // Newest line at the bottom, kept in view.
              reverse: true,
              itemCount: lines.length,
              itemBuilder: (context, index) => Text(
                lines[lines.length - 1 - index],
                style: const TextStyle(fontSize: 12, fontFamily: 'Consolas'),
              ),
            ),
          ),
        ],
      ),
      actions: [
        Button(
          onPressed: isDone ? () => Navigator.pop(context) : null,
          child: Text(loc.common_close),
        ),
      ],
    );
  }
}
