import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:cartridge/core/log.dart';

import '../../domain/steam_library_port.dart';
import '../../domain/steam_install_port.dart';
import '../parsing/acf_utils.dart';

class SteamAppLibrary implements SteamLibraryPort {
  static const _tag = 'SteamAppLibrary';
  final SteamInstallPort install;
  final _ctx = p.Context(style: p.Style.windows);

  SteamAppLibrary({required this.install});

  @override
  Future<String?> findGameInstallPath(int appId, {String? steamBaseOverride}) async {
    final base = await install.resolveBaseDir(override: steamBaseOverride);
    if (base == null) {
      logW(_tag, 'msg=steam base not found (override=$steamBaseOverride)');
      return null;
    }
    final libs = await _listSteamLibraries(base);

    for (final lib in libs) {
      final acf = File(_ctx.join(lib, 'steamapps', 'appmanifest_$appId.acf'));
      if (!acf.existsSync()) continue;
      try {
        final text = await acf.readAsString();
        final m = RegExp(r'"installdir"\s*"([^"]+)"', multiLine: true).firstMatch(text);
        final dir = m?.group(1);
        if (dir == null || dir.trim().isEmpty) continue;

        final candidate = Directory(_ctx.join(lib, 'steamapps', 'common', dir));
        if (candidate.existsSync()) {
          logI(_tag, 'msg=game path found appId=$appId path=${candidate.path}');
          return candidate.path;
        }
      } catch (e, st) {
        logE(_tag, 'msg=read appmanifest failed file=${acf.path}', e, st);
      }
    }
    logW(_tag, 'msg=game path not found appId=$appId');
    return null;
  }

  @override
  Future<Set<int>> readInstalledDepots(int appId, {String? steamBaseOverride}) async {
    final f = await _locateAppManifest(appId, steamBaseOverride);
    if (f == null) return <int>{};
    try {
      final txt = await f.readAsString();
      final ids = acfExtractNumericKeys(acfExtractBlock(txt, 'InstalledDepots'));
      logI(_tag, 'msg=depots parsed appId=$appId count=${ids.length}');
      return ids;
    } catch (e, st) {
      logE(_tag, 'msg=parse depots failed file=${f.path}', e, st);
      return <int>{};
    }
  }

  @override
  Future<Set<int>> readWorkshopItemIdsFromAcf(int appId, {String? steamBaseOverride}) async {
    final base = await install.resolveBaseDir(override: steamBaseOverride);
    if (base == null) {
      logW(_tag, 'msg=steam base not found');
      return <int>{};
    }
    final acf = File(_ctx.join(base, 'steamapps', 'workshop', 'appworkshop_$appId.acf'));
    if (!acf.existsSync()) {
      logW(_tag, 'msg=workshop acf not found appId=$appId file=${acf.path}');
      return <int>{};
    }

    try {
      final txt = await acf.readAsString();
      // 실제 파일 기준: WorkshopItemsInstalled 위주
      final sections = ['WorkshopItemsInstalled', 'SubscribedItems', 'WorkshopItems', 'InstalledItems'];
      final acc = <int>{};
      for (final sec in sections) {
        final b = acfExtractBlock(txt, sec);
        if (b.isEmpty) continue;
        acc.addAll(acfExtractNumericKeys(b));
      }
      logI(_tag, 'msg=workshop ids parsed appId=$appId count=${acc.length}');
      return acc;
    } catch (e, st) {
      logE(_tag, 'msg=parse workshop failed file=${acf.path}', e, st);
      return <int>{};
    }
  }

  @override
  Future<Set<int>> listWorkshopContentItemIds(int appId, {String? steamBaseOverride}) async {
    final base = await install.resolveBaseDir(override: steamBaseOverride);
    if (base == null) {
      logW(_tag, 'msg=steam base not found');
      return <int>{};
    }
    final contentDir = Directory(_ctx.join(base, 'steamapps', 'workshop', 'content', '$appId'));
    if (!contentDir.existsSync()) {
      logW(_tag, 'msg=workshop content dir not found path=${contentDir.path}');
      return <int>{};
    }

    final ids = <int>{};
    for (final e in contentDir.listSync().whereType<Directory>()) {
      final id = int.tryParse(_ctx.basename(e.path));
      if (id != null) ids.add(id);
    }
    logI(_tag, 'msg=workshop content ids parsed appId=$appId count=${ids.length}');
    return ids;
  }

  // ── 내부 ───────────────────────────────────────────────────────────
  Future<File?> _locateAppManifest(int appId, String? override) async {
    final base = await install.resolveBaseDir(override: override);
    if (base == null) {
      logW(_tag, 'msg=steam base not found');
      return null;
    }
    final libs = await _listSteamLibraries(base);
    for (final lib in libs) {
      final f = File(_ctx.join(lib, 'steamapps', 'appmanifest_$appId.acf'));
      if (f.existsSync()) return f;
    }
    logW(_tag, 'msg=appmanifest not found appId=$appId');
    return null;
  }

  Future<List<String>> _listSteamLibraries(String base) async {
    final libs = <String>{};
    final vdf = File(_ctx.join(base, 'steamapps', 'libraryfolders.vdf'));
    if (vdf.existsSync()) {
      try {
        final text = await vdf.readAsString();
        final rx = RegExp(r'"\s*path\s*"\s*"([^"]+)"|"\d+"\s*"([^"]+)"', multiLine: true);
        for (final m in rx.allMatches(text)) {
          final s = (m.group(1) ?? m.group(2))?.trim();
          if (s != null && s.isNotEmpty) libs.add(s.replaceAll('\\\\', '\\'));
        }
        libs.add(base);
      } catch (e, st) {
        logE(_tag, 'msg=read libraryfolders failed file=${vdf.path}', e, st);
        libs.add(base);
      }
    } else {
      libs.add(base);
    }
    return libs
        .map((e) => Directory(e).absolute.path)
        .where((e) => Directory(_ctx.join(e, 'steamapps')).existsSync())
        .toList();
  }
}
