import 'dart:collection';
import 'dart:io';
import 'package:cartridge/core/log.dart';
import 'package:path/path.dart' as p;

import 'package:cartridge/features/steam/domain/steam_users_port.dart';
import 'package:cartridge/features/steam/domain/models/steam_account_profile.dart';
import 'package:cartridge/features/isaac/runtime/domain/isaac_steam_ids.dart';
import 'package:cartridge/features/steam/domain/steam_install_port.dart';

class SteamUsersVdfRepository implements SteamUsersPort {
  static const _tag = 'SteamUsersVdfRepository';
  static const _offset = 76561197960265728;
  final SteamInstallPort install;

  const SteamUsersVdfRepository({required this.install});

  @override
  Future<List<SteamAccountProfile>> findAccountsWithIsaacSaves() async {
    const op = 'findAccounts';
    final base = await install.resolveBaseDir(/* override: settings.steamInstallPath */);
    if (base == null) {
      logW(_tag, 'op=$op msg=steam base not found');
      return const [];
    }
    logI(_tag, 'op=$op msg=start base=$base');

    final userdata = Directory(p.join(base, 'userdata'));
    if (!userdata.existsSync()) {
      logW(_tag, 'op=$op msg=userdata missing path=${userdata.path}');
      return const [];
    }

    final login = await _readLoginUsers(base); // 상세 카운트 로그 제거

    final result = <SteamAccountProfile>[];
    final ctx = p.Context(style: p.Style.windows);

    for (final dir in userdata.listSync().whereType<Directory>()) {
      final name = p.basename(dir.path);
      if (!RegExp(r'^\d+$').hasMatch(name)) continue;

      final accountId = int.tryParse(name);
      if (accountId == null) continue;

      final rawSave = p.join(dir.path, '${IsaacSteamIds.appId}', 'remote');
      final savePath = Platform.isWindows ? ctx.normalize(rawSave) : p.normalize(rawSave);
      if (!Directory(savePath).existsSync()) continue;

      final steamId64 = (accountId + _offset).toString();
      final persona = login[steamId64]?.personaName;
      final mostRecent = login[steamId64]?.mostRecent ?? false;

      String? avatar;
      final avatarPng = File(p.join(base, 'config', 'avatarcache', '$steamId64.png'));
      if (avatarPng.existsSync()) {
        avatar = Platform.isWindows ? ctx.normalize(avatarPng.path) : avatarPng.path;
      }

      result.add(SteamAccountProfile(
        accountId: accountId,
        steamId64: steamId64,
        personaName: persona,
        avatarPngPath: avatar,
        savePath: savePath,
        mostRecent: mostRecent,
      ));
    }

    // 정렬 동일
    result.sort((a, b) {
      final mr = (b.mostRecent ? 1 : 0) - (a.mostRecent ? 1 : 0);
      if (mr != 0) return mr;
      final pnA = a.personaName ?? '';
      final pnB = b.personaName ?? '';
      final byName = pnA.toLowerCase().compareTo(pnB.toLowerCase());
      if (byName != 0) return byName;
      return a.accountId.compareTo(b.accountId);
    });

    logI(_tag, 'op=$op msg=done accounts=${result.length}');
    return result;
  }

  // ── 내부: loginusers.vdf 파싱(경고/에러만 남김) ─────────────────────────────
  Future<_LoginUserMap> _readLoginUsers(String steamBase) async {
    const op = 'readLoginusers';
    final f = File(p.join(steamBase, 'config', 'loginusers.vdf'));
    if (!f.existsSync()) {
      logW(_tag, 'op=$op msg=loginusers not found path=${f.path}');
      return _LoginUserMap();
    }
    try {
      final txt = await f.readAsString();
      final userBlock = RegExp(r'"\s*(\d{17})\s*"\s*\{([^}]*)\}', dotAll: true);
      String? field(String block, String key) {
        final m = RegExp('"$key"\\s*"([^"]*)"', multiLine: true).firstMatch(block);
        return m?.group(1);
      }
      final map = _LoginUserMap();
      for (final m in userBlock.allMatches(txt)) {
        final sid64 = m.group(1)!;
        final body = m.group(2)!;
        map[sid64] = _LoginUser(
          personaName: field(body, 'PersonaName'),
          accountName: field(body, 'AccountName'),
          mostRecent: field(body, 'MostRecent') == '1',
        );
      }
      return map;
    } catch (e, st) {
      logE(_tag, 'op=$op msg=parse failed path=${f.path}', e, st);
      return _LoginUserMap();
    }
  }
}

class _LoginUser {
  final String? personaName;
  final String? accountName;
  final bool mostRecent;
  const _LoginUser({this.personaName, this.accountName, this.mostRecent = false});
}
class _LoginUserMap extends MapBase<String, _LoginUser> {
  final _m = <String, _LoginUser>{};
  @override _LoginUser? operator [](Object? key) => _m[key];
  @override void operator []=(String key, _LoginUser value) => _m[key] = value;
  @override void clear() => _m.clear();
  @override Iterable<String> get keys => _m.keys;
  @override _LoginUser? remove(Object? key) => _m.remove(key);
}
