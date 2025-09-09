import 'dart:io';
import 'package:cartridge/features/steam/infra/windows/steam_install_locator.dart';
import 'package:cartridge/features/steam/infra/windows/registry_reader.dart';
import 'package:cartridge/features/steam/infra/windows/fs_probe.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final isWindows = Platform.isWindows;

  group('WindowsSteamInstallLocator — Integration(FS)', () {
    test('실제 파일시스템에서 후보 경로에 steam.exe가 있으면 탐지된다 (AAA)',
        skip: !isWindows ? 'Windows 전용' : false, () async {
          // Arrange
          final temp = await Directory.systemTemp.createTemp('steam_it_');
          final steamDir = Directory('${temp.path}\\Steam')..createSync(recursive: true);
          final exe = File('${steamDir.path}\\steam.exe')..writeAsStringSync(''); // 더미
          addTearDown(() async {
            try { await temp.delete(recursive: true); } catch (_) {}
          });

          final locator = WindowsSteamInstallLocator(
            regReader: FakeRegReader({}),                 // 레지스트리 비활성
            fileSystemProbe: RealFileSystemProbe(),       // 실제 FS
            candidateProvider: () => [steamDir.path],     // 후보로 지정
          );

          // Act
          final path = await locator.autoDetectBaseDir();

          // Assert
          expect(path, equals(steamDir.path));
          expect(exe.existsSync(), isTrue);
        });
  });
}

// 최소 FakeReg (통합테스트에서도 레지스트리 모킹)
class FakeRegReader implements RegReader {
  final Map<String, String> map;
  FakeRegReader(this.map);
  @override
  String? readString(hive, String path, String value) => map['$hive|$path|$value'];
}
