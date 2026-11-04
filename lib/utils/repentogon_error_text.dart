import 'package:cartridge/l10n/app_localizations.dart';
import 'package:cartridge/services/repentogon_cli_service.dart';

/// Localized description of a REPENTOGON / rgon-cli error.
String describeRepentogonError(AppLocalizations loc, Object error) {
  if (error is! RgonCliException) {
    return loc.repentogon_error_unknown(error.toString());
  }

  final text = switch (error.code) {
    'invalid_isaac' => loc.repentogon_error_invalid_isaac,
    'isaac_incompatible' => loc.repentogon_error_isaac_incompatible,
    'repentogon_not_installed' => loc.repentogon_error_not_installed,
    'repentogon_incompatible' => loc.repentogon_error_incompatible,
    'launch_failed' => loc.repentogon_error_launch_failed,
    'busy' => loc.repentogon_error_busy,
    'check_updates_failed' => loc.repentogon_error_check_updates_failed,
    'launcher_update_required' => loc.repentogon_error_launcher_update_required,
    'install_failed' => loc.repentogon_error_install_failed,
    'cli_download_failed' ||
    'cli_release_not_found' ||
    'cli_hash_mismatch' ||
    'cli_invalid_archive' =>
      loc.repentogon_error_cli_download_failed,
    'cli_in_use' => loc.repentogon_error_cli_in_use,
    _ => null,
  };

  final detail = error.message;
  if (text == null) {
    return loc.repentogon_error_unknown(
        detail == null ? error.code : '${error.code}: $detail');
  }

  return detail == null || detail.isEmpty ? text : '$text\n\n$detail';
}
