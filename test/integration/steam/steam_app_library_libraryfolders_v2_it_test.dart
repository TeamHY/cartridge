import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import 'package:cartridge/features/steam/infra/windows/steam_app_library.dart';
import 'package:cartridge/features/steam/domain/steam_install_port.dart';

class _FakeInstall implements SteamInstallPort {
  final String base;
  _FakeInstall(this.base);
  @override Future<String?> autoDetectBaseDir() async => base;
  @override Future<String?> resolveBaseDir({String? override}) async => base;
}

void main() {
  group('SteamAppLibrary — libraryfolders.v2 (Integration)', () {
    test('v2 형식의 "path" 키에서 보조 라이브러리를 읽고 installdir을 찾는다 (AAA)',
        skip: !Platform.isWindows ? 'Windows 전용' : false, () async {
          // Arrange
          final temp = await Directory.systemTemp.createTemp('libv2_it_');
          addTearDown(() async { try { await temp.delete(recursive: true); } catch (_) {} });

          final base = temp.path;
          final steamapps = Directory(p.join(base, 'steamapps'))..createSync(recursive: true);

          // 보조 라이브러리 디렉터리
          final lib2 = Directory(p.join(base, 'lib2'))..createSync();
          final lib2Steamapps = Directory(p.join(lib2.path, 'steamapps'))..createSync();
          Directory(p.join(lib2Steamapps.path, 'common')).createSync();

          // v2 libraryfolders.vdf (path 키 사용)
          final v2 = File(p.join(steamapps.path, 'libraryfolders.vdf'))..createSync();
          final lib2Escaped = lib2.path.replaceAll('\\', '\\\\');
          v2.writeAsStringSync('''
"libraryfolders"
{
  "contentstatsid" "123"
  "1"
  {
    "path" "$lib2Escaped"
    "label" ""
  }
}
''');

          // appmanifest_250900.acf in lib2 + installdir 생성
          File(p.join(lib2Steamapps.path, 'appmanifest_250900.acf'))
            ..createSync()
            ..writeAsStringSync(r'''
"AppState"
{
  "appid" "250900"
  "installdir" "TheBindingOfIsaacRebirth"
}
''');
          Directory(p.join(lib2Steamapps.path, 'common', 'TheBindingOfIsaacRebirth')).createSync();

          final lib = SteamAppLibrary(install: _FakeInstall(base));

          // Act
          final gamePath = await lib.findGameInstallPath(250900);

          // Assert
          expect(gamePath, isNotNull);
          expect(gamePath!.replaceAll('/', '\\'),
              endsWith(r'\lib2\steamapps\common\TheBindingOfIsaacRebirth'));
        });
  });
}
