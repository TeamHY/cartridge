import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import 'package:cartridge/features/steam/infra/steam_users_vdf_repository.dart';
import 'package:cartridge/features/steam/domain/steam_install_port.dart';
import 'package:cartridge/features/isaac/runtime/domain/isaac_steam_ids.dart';

// 설치 경로를 강제로 주입하는 Fake
class _FakeInstall implements SteamInstallPort {
  final String base;
  _FakeInstall(this.base);
  @override Future<String?> autoDetectBaseDir() async => base;
  @override Future<String?> resolveBaseDir({String? override}) async => base;
}

// SteamID64 오프셋과 동일한 계산
int _toSteamId64(int accountId) => accountId + 76561197960265728;

void main() {
  group('SteamUsersVdfRepository — Integration', () {
    test('userdata 및 loginusers.vdf 기준으로 세이브 보유 계정만 반환한다 (AAA)',
        skip: !Platform.isWindows ? 'Windows 전용' : false, () async {
          // Arrange
          final temp = await Directory.systemTemp.createTemp('users_vdf_it_');
          addTearDown(() async { try { await temp.delete(recursive: true); } catch (_) {} });

          final base = temp.path;
          final cfg = Directory(p.join(base, 'config'))..createSync(recursive: true);
          final userdata = Directory(p.join(base, 'userdata'))..createSync(recursive: true);
          final avatarDir = Directory(p.join(cfg.path, 'avatarcache'))..createSync();

          // 계정 A: 유효 (세이브 있음, mostRecent)
          const accA = 123456; // accountId(32-bit)
          final sidA = _toSteamId64(accA).toString();
          Directory(p.join(userdata.path, '$accA', '${IsaacSteamIds.appId}', 'remote')).createSync(recursive: true);
          File(p.join(avatarDir.path, '$sidA.png')).writeAsBytesSync([0, 1, 2]);

          // 계정 B: userdata는 있지만 세이브 없음 → 제외
          const accB = 222222;
          Directory(p.join(userdata.path, '$accB')).createSync();

          // 숫자 아님 → 제외
          Directory(p.join(userdata.path, 'non-numeric')).createSync();

          // loginusers.vdf
          final login = File(p.join(cfg.path, 'loginusers.vdf'))..createSync();
          login.writeAsStringSync('''
"users"
{
  "$sidA"
  {
    "AccountName" "userA"
    "PersonaName" "Alice"
    "MostRecent" "1"
  }
  "${_toSteamId64(accB)}"
  {
    "AccountName" "userB"
    "PersonaName" "Bob"
    "MostRecent" "0"
  }
}
''');

          final repo = SteamUsersVdfRepository(install: _FakeInstall(base));

          // Act
          final accounts = await repo.findAccountsWithIsaacSaves();

          // Assert
          expect(accounts.length, 1);
          final a = accounts.first;
          expect(a.accountId, accA);
          expect(a.steamId64, sidA);
          expect(a.personaName, 'Alice');
          expect(a.avatarPngPath, isNotNull);
          expect(Directory(a.savePath).existsSync(), isTrue);
        });
  });
}
