import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import 'package:cartridge/features/steam/infra/windows/steam_app_library.dart';
import 'package:cartridge/features/steam/domain/steam_install_port.dart';

// Fake InstallPort: 임시 폴더를 base로 반환
class FakeInstall implements SteamInstallPort {
  final String base;
  FakeInstall(this.base);
  @override Future<String?> autoDetectBaseDir() async => base;
  @override Future<String?> resolveBaseDir({String? override}) async => override?.isNotEmpty == true ? override : base;
}

void main() {
  late Directory temp;
  late String base;

  setUp(() async {
    temp = await Directory.systemTemp.createTemp('steam_it_');
    base = temp.path;
    // steamapps 레이아웃
    Directory(p.join(base, 'steamapps')).createSync(recursive: true);
    Directory(p.join(base, 'steamapps', 'common')).createSync(recursive: true);
    Directory(p.join(base, 'steamapps', 'workshop', 'content', '250900')).createSync(recursive: true);

    // libraryfolders.vdf
    File(p.join(base, 'steamapps', 'libraryfolders.vdf')).writeAsStringSync(r'''
"libraryfolders"
{
  "0" "''' + base.replaceAll('\\', '\\\\') + r'''"
}
''');

    // appmanifest_250900.acf + installdir
    File(p.join(base, 'steamapps', 'appmanifest_250900.acf')).writeAsStringSync(r'''
"AppState"
{
  "appid" "250900"
  "installdir" "TheBindingOfIsaacRebirth"
  "InstalledDepots"
  {
    "250901" {}
    "250902" {}
  }
}
''');
    Directory(p.join(base, 'steamapps', 'common', 'TheBindingOfIsaacRebirth')).createSync(recursive: true);

    // workshop: ACF + content 디렉터리
    File(p.join(base, 'steamapps', 'workshop', 'appworkshop_250900.acf')).createSync(recursive: true);
    File(p.join(base, 'steamapps', 'workshop', 'appworkshop_250900.acf')).writeAsStringSync(r'''
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
    Directory(p.join(base, 'steamapps', 'workshop', 'content', '250900', '3333')).createSync();
    Directory(p.join(base, 'steamapps', 'workshop', 'content', '250900', '4444')).createSync();
  });

  tearDown(() async {
    try { await temp.delete(recursive: true); } catch (_) {}
  });

  test('게임 설치 경로/디포트/워크샵(ACF/디렉터리) 모두 읽힌다 (AAA)', () async {
    final lib = SteamAppLibrary(install: FakeInstall(base));

    final game = await lib.findGameInstallPath(250900);
    final depots = await lib.readInstalledDepots(250900);
    final wsAcf = await lib.readWorkshopItemIdsFromAcf(250900);
    final wsDir = await lib.listWorkshopContentItemIds(250900);

    expect(game, isNotNull);
    expect(depots, containsAll(<int>{250901, 250902}));
    expect(wsAcf, containsAll(<int>{1111, 2222}));
    expect(wsDir, containsAll(<int>{3333, 4444}));
  });
}
