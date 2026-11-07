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

  /// Latest REPENTOGON release when it differs from the installed one.
  String? availableUpdate;

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

  /// Refresh [status]. With [checkUpdates], rgon-cli is updated first and
  /// [availableUpdate] is checked.
  Future<void> refresh({bool checkUpdates = true}) async {
    if (!isSupported || isBusy) return;

    isBusy = true;
    lastError = null;
    _notify();

    try {
      cliTag =
          await RepentogonCliService.ensureInstalled(checkUpdate: checkUpdates);
      status = await RepentogonCliService.status(await _isaacPath());
      if (checkUpdates) availableUpdate = await _findUpdate();
    } catch (e) {
      lastError = e;
    } finally {
      isBusy = false;
      _notify();
    }
  }

  /// Refresh [status] without downloading rgon-cli when it is missing.
  Future<void> refreshIfInstalled({bool checkUpdates = false}) async {
    if (!isSupported || isBusy) return;
    if (await RepentogonCliService.installedTag() == null) return;
    await refresh(checkUpdates: checkUpdates);
  }

  Future<String?> _findUpdate() async {
    final installed = status?.zhlVersion;
    if (status?.installed != true ||
        installed == null ||
        installed == 'nightly' ||
        installed == 'dev') {
      return null;
    }

    try {
      final latest = await RepentogonCliService.fetchLatestRepentogonVersion();
      return latest == installed ? null : latest;
    } catch (_) {
      return availableUpdate;
    }
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

      availableUpdate = null;

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
