import 'package:flutter_test/flutter_test.dart';
import 'package:win32_registry/win32_registry.dart';
import 'package:cartridge/core/log.dart';
import 'package:cartridge/features/steam/infra/windows/steam_install_locator.dart';
import 'package:cartridge/features/steam/infra/windows/registry_reader.dart';
import 'package:cartridge/features/steam/infra/windows/fs_probe.dart';

// Fakes
class FakeRegReader implements RegReader {
  final Map<String, String> map;
  FakeRegReader(this.map);
  @override
  String? readString(RegistryHive hive, String path, String value) =>
      map['${hive.name}|$path|$value'];
}

class FakeFs implements FileSystemProbe {
  final Set<String> dirs = {};
  final Set<String> files = {};
  @override bool dirExists(String path) => dirs.contains(_n(path));
  @override bool fileExists(String path) => files.contains(_n(path));
  String _n(String s) => s.replaceAll('/', '\\');
}

void main() {
  setUp(() { LogConfig.mirrorToStdout = false; });

  group('WindowsSteamInstallLocator — Unit', () {
    test('override가 유효하면 즉시 채택된다 (AAA)', () async {
      // Arrange
      final fs = FakeFs()
        ..dirs.add(r'X:\Steam')
        ..files.add(r'X:\Steam\steam.exe');
      final locator = WindowsSteamInstallLocator(
        regReader: FakeRegReader({}),
        fileSystemProbe: fs,
        candidateProvider: () => [r'C:\Steam'],
      );

      // Act
      final path = await locator.resolveBaseDir(override: r'X:\Steam');

      // Assert
      expect(path, equals(r'X:\Steam'));
    });

    test('HKCU가 유효하면 우선 채택된다 (AAA)', () async {
      // Arrange
      final fs = FakeFs()
        ..dirs.add(r'Z:\Valve\Steam')
        ..files.add(r'Z:\Valve\Steam\steam.exe');
      final reg = FakeRegReader({
        '${RegistryHive.currentUser.name}|Software\\Valve\\Steam|SteamPath': r'Z:\Valve\Steam',
        '${RegistryHive.localMachine.name}|SOFTWARE\\WOW6432Node\\Valve\\Steam|InstallPath': r'Y:\Steam',
      });
      final locator = WindowsSteamInstallLocator(
        regReader: reg, fileSystemProbe: fs, candidateProvider: () => [],
      );

      // Act
      final path = await locator.autoDetectBaseDir();

      // Assert
      expect(path, equals(r'Z:\Valve\Steam'));
    });

    test('HKCU 무효 → WOW6432Node가 유효하면 채택된다 (AAA)', () async {
      // Arrange
      final fs = FakeFs()
        ..dirs.add(r'Y:\Steam')
        ..files.add(r'Y:\Steam\steam.exe');
      final reg = FakeRegReader({
        '${RegistryHive.currentUser.name}|Software\\Valve\\Steam|SteamPath': r'X:\Broken\Steam',
        '${RegistryHive.localMachine.name}|SOFTWARE\\WOW6432Node\\Valve\\Steam|InstallPath': r'Y:\Steam',
      });
      final locator = WindowsSteamInstallLocator(
        regReader: reg, fileSystemProbe: fs, candidateProvider: () => [],
      );

      // Act
      final path = await locator.autoDetectBaseDir();

      // Assert
      expect(path, equals(r'Y:\Steam'));
    });

    test('레지스트리 전부 무효 → 후보 경로가 유효하면 채택된다 (AAA)', () async {
      // Arrange
      final fs = FakeFs()
        ..dirs.add(r'C:\Steam')
        ..files.add(r'C:\Steam\steam.exe');
      final locator = WindowsSteamInstallLocator(
        regReader: FakeRegReader({}), fileSystemProbe: fs,
        candidateProvider: () => [r'C:\Steam', r'D:\Steam'],
      );

      // Act
      final path = await locator.autoDetectBaseDir();

      // Assert
      expect(path, equals(r'C:\Steam'));
    });

    test('override 무효 → 자동탐지로 폴백한다 (AAA)', () async {
      // Arrange
      final fs = FakeFs()
        ..dirs.add(r'D:\Steam')
        ..files.add(r'D:\Steam\steam.exe');
      final reg = FakeRegReader({
        '${RegistryHive.currentUser.name}|Software\\Valve\\Steam|SteamPath': r'D:\Steam',
      });
      final locator = WindowsSteamInstallLocator(
        regReader: reg, fileSystemProbe: fs, candidateProvider: () => [],
      );

      // Act
      final path = await locator.resolveBaseDir(override: r'C:\Bad\Steam');

      // Assert
      expect(path, equals(r'D:\Steam'));
    });
  });
}
