import 'dart:io';

import 'package:cartridge/models/repentogon_status.dart';
import 'package:cartridge/providers/setting_provider.dart';
import 'package:cartridge/services/repentogon_cli_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum RepentogonInstallOutcome { installed, upToDate, failed }

/// State of rgon-cli and of the REPENTOGON installation of the configured
/// Isaac folder.
class RepentogonNotifier extends ChangeNotifier {
  RepentogonNotifier(this.ref);

  final Ref ref;

  static bool get isSupported => Platform.isWindows;

  RepentogonStatus? status;

  /// Installed rgon-cli release tag.
  String? cliTag;

  bool isBusy = false;
  Object? lastError;

  /// Log lines of the current / last installation.
  final List<String> installLogs = [];

  /// Bytes downloaded per file during the current installation.
  final Map<String, int> downloads = {};

  bool _disposed = false;

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  Future<String> _isaacPath() async {
    final setting = ref.read(settingProvider);
    await setting.loadSetting();
    return setting.isaacPath;
  }

  /// Update rgon-cli if needed, then refresh [status].
  Future<void> refresh({bool checkCliUpdate = true}) async {
    if (!isSupported || isBusy) return;

    isBusy = true;
    lastError = null;
    _notify();

    try {
      cliTag = await RepentogonCliService.ensureInstalled(
          checkUpdate: checkCliUpdate);
      status = await RepentogonCliService.status(await _isaacPath());
    } catch (e) {
      lastError = e;
    } finally {
      isBusy = false;
      _notify();
    }
  }

  /// Refresh [status] without downloading rgon-cli when it is missing.
  Future<void> refreshIfInstalled() async {
    if (!isSupported || isBusy) return;
    if (await RepentogonCliService.installedTag() == null) return;
    await refresh(checkCliUpdate: false);
  }

  /// Install, update or repair REPENTOGON.
  Future<RepentogonInstallOutcome> install() async {
    if (!isSupported || isBusy) return RepentogonInstallOutcome.failed;

    isBusy = true;
    lastError = null;
    installLogs.clear();
    downloads.clear();
    _notify();

    try {
      cliTag = await RepentogonCliService.ensureInstalled();

      // Reinstall when the current installation cannot be launched, so the
      // game files are copied / patched again.
      final force = status != null && !status!.launchable;
      final result = await RepentogonCliService.install(
        await _isaacPath(),
        force: force,
        onEvent: (event) {
          switch (event) {
            case RgonCliLogEvent(:final level, :final message):
              installLogs.add(level == 'info' ? message : '[$level] $message');
            case RgonCliDownloadEvent(:final file, :final bytes):
              downloads[file] = bytes;
          }
          _notify();
        },
      );

      if (result.json['isaac'] != null) {
        status = RepentogonStatus.fromJson(result.json);
      }

      if (!result.ok) {
        lastError = result.toException();
        return RepentogonInstallOutcome.failed;
      }

      return result.json['outcome'] == 'up_to_date'
          ? RepentogonInstallOutcome.upToDate
          : RepentogonInstallOutcome.installed;
    } catch (e) {
      lastError = e;
      return RepentogonInstallOutcome.failed;
    } finally {
      isBusy = false;
      _notify();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}

final repentogonProvider = ChangeNotifierProvider<RepentogonNotifier>((ref) {
  return RepentogonNotifier(ref);
});
