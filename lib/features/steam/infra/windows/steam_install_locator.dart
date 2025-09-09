import 'package:path/path.dart' as p;
import 'package:win32_registry/win32_registry.dart';
import 'package:cartridge/core/log.dart';

import '../../domain/steam_install_port.dart';
import 'registry_reader.dart';
import 'fs_probe.dart';

class WindowsSteamInstallLocator implements SteamInstallPort {
  static const _tag = 'SteamInstallLocator';
  final RegReader reg;
  final FileSystemProbe fs;
  final List<String> Function() _defaultCandidates;
  final _ctx = p.Context(style: p.Style.windows);

  WindowsSteamInstallLocator({
    RegReader? regReader,
    FileSystemProbe? fileSystemProbe,
    List<String> Function()? candidateProvider,
  })  : reg = regReader ?? RealRegReader(),
        fs = fileSystemProbe ?? RealFileSystemProbe(),
        _defaultCandidates = candidateProvider ?? _envCandidates;

  @override
  Future<String?> autoDetectBaseDir() async {
    // 1) HKCU
    final hkcu = reg.readString(RegistryHive.currentUser, r'Software\Valve\Steam', 'SteamPath');
    final okHkcu = _validateSteamDir(hkcu);
    if (okHkcu != null) {
      logI(_tag, 'msg=steam base resolved source=hkcu path=$okHkcu');
      return okHkcu;
    }

    // 2) HKLM WOW6432Node
    final wow = reg.readString(RegistryHive.localMachine, r'SOFTWARE\WOW6432Node\Valve\Steam', 'InstallPath');
    final okWow = _validateSteamDir(wow);
    if (okWow != null) {
      logI(_tag, 'msg=steam base resolved source=wow6432 path=$okWow');
      return okWow;
    }

    // 3) HKLM
    final hklm = reg.readString(RegistryHive.localMachine, r'SOFTWARE\Valve\Steam', 'InstallPath');
    final okHklm = _validateSteamDir(hklm);
    if (okHklm != null) {
      logI(_tag, 'msg=steam base resolved source=hklm path=$okHklm');
      return okHklm;
    }

    // 4) 후보 디렉터리
    for (final c in _defaultCandidates()) {
      final ok = _validateSteamDir(c);
      if (ok != null) {
        logI(_tag, 'msg=steam base resolved source=candidate path=$ok');
        return ok;
      }
    }

    logW(_tag, 'msg=steam base not found');
    return null;
  }

  @override
  Future<String?> resolveBaseDir({String? override}) async {
    if (override != null && override.trim().isNotEmpty) {
      final ok = _validateSteamDir(override);
      if (ok != null) {
        logI(_tag, 'msg=override accepted path=$ok');
        return ok;
      }
      logW(_tag, 'msg=override invalid path=$override');
      // fall through
    }
    return autoDetectBaseDir();
  }

  String? _validateSteamDir(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    final dir = _ctx.normalize(raw);
    final exe = _ctx.join(dir, 'steam.exe');
    final exists = fs.dirExists(dir) && fs.fileExists(exe);
    return exists ? dir : null;
  }

  static List<String> _envCandidates() {
    final c = <String>[
      r'C:\Program Files (x86)\Steam',
      r'C:\Program Files\Steam',
      r'C:\Steam',
      r'D:\Steam',
    ];
    return c;
  }
}
