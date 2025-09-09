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
  group('SteamAppLibrary — Workshop Variants (Integration)', () {
    test('WorkshopItemsInstalled 섹션만 있어도 아이디를 추출한다 (AAA)',
        skip: !Platform.isWindows ? 'Windows 전용' : false, () async {
          // Arrange
          final temp = await Directory.systemTemp.createTemp('ws_installed_it_');
          addTearDown(() async { try { await temp.delete(recursive: true); } catch (_) {} });

          final base = temp.path;
          final wsDir = Directory(p.join(base, 'steamapps', 'workshop'))..createSync(recursive: true);
          final acf = File(p.join(wsDir.path, 'appworkshop_250900.acf'))..createSync();
          acf.writeAsStringSync(r'''
"AppWorkshop"
{
  "AppID" "250900"
  "WorkshopItemsInstalled"
  {
    "1111" {}
    "2222" {}
  }
}
''');
          final lib = SteamAppLibrary(install: _FakeInstall(base));

          // Act
          final ids = await lib.readWorkshopItemIdsFromAcf(250900);

          // Assert
          expect(ids, containsAll(<int>{1111, 2222}));
        });

    test('Installed 섹션이 없고 SubscribedItems만 있어도 추출한다 (AAA)',
        skip: !Platform.isWindows ? 'Windows 전용' : false, () async {
          final temp = await Directory.systemTemp.createTemp('ws_subscribed_it_');
          addTearDown(() async { try { await temp.delete(recursive: true); } catch (_) {} });

          final base = temp.path;
          final wsDir = Directory(p.join(base, 'steamapps', 'workshop'))..createSync(recursive: true);
          final acf = File(p.join(wsDir.path, 'appworkshop_250900.acf'))..createSync();
          acf.writeAsStringSync(r'''
"AppWorkshop"
{
  "AppID" "250900"
  "SubscribedItems"
  {
    "3333" {}
    "4444" {}
  }
}
''');
          final lib = SteamAppLibrary(install: _FakeInstall(base));

          final ids = await lib.readWorkshopItemIdsFromAcf(250900);

          expect(ids, containsAll(<int>{3333, 4444}));
        });

    test('content/{appId} 디렉터리의 숫자 폴더만 아이디로 인식한다 (AAA)',
        skip: !Platform.isWindows ? 'Windows 전용' : false, () async {
          final temp = await Directory.systemTemp.createTemp('ws_content_it_');
          addTearDown(() async { try { await temp.delete(recursive: true); } catch (_) {} });

          final base = temp.path;
          final root = Directory(p.join(base, 'steamapps', 'workshop', 'content', '250900'))
            ..createSync(recursive: true);
          Directory(p.join(root.path, '7777')).createSync();
          Directory(p.join(root.path, 'abc')).createSync();
          Directory(p.join(root.path, '8888')).createSync();

          final lib = SteamAppLibrary(install: _FakeInstall(base));

          final ids = await lib.listWorkshopContentItemIds(250900);

          expect(ids, containsAll(<int>{7777, 8888}));
          expect(ids.contains(0), isFalse);
        });
  });
}
