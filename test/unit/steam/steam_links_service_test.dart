import 'package:flutter_test/flutter_test.dart';
import 'package:cartridge/features/steam/application/steam_links_service.dart';
import 'package:cartridge/features/steam/domain/steam_links_port.dart';

class _Recorder {
  String? lastTarget;
  String? lastOp;
  bool throwOnOpen = false;
}

class _FakePort implements SteamLinksPort {
  final _Recorder rec;
  const _FakePort(this.rec);

  @override
  Future<void> openUri(String target) async {
    rec.lastOp = 'openUri';
    rec.lastTarget = target;
    if (rec.throwOnOpen) throw StateError('boom');
  }

  @override
  Future<void> openAppPage(int appId) async {
    rec.lastOp = 'openAppPage';
    rec.lastTarget = '$appId';
  }

  @override
  Future<void> openAppWorkshopHub(int appId) async {
    rec.lastOp = 'openAppWorkshopHub';
    rec.lastTarget = '$appId';
  }

  @override
  Future<void> openWorkshopItem(String workshopId) async {
    rec.lastOp = 'openWorkshopItem';
    rec.lastTarget = workshopId;
  }

  @override
  Future<void> openGameProperties(int appId) async {
    rec.lastOp = 'openGameProperties';
    rec.lastTarget = '$appId';
  }

  @override
  Future<void> startVerifyIntegrity(int appId) async {
    rec.lastOp = 'startVerifyIntegrity';
    rec.lastTarget = '$appId';
  }
}

void main() {
  group('SteamLinksService — Unit', () {
    test('openWebUrl: 스팀 도메인은 steam://openurl 로 변환된다 (AAA)', () async {
      // Arrange
      final rec = _Recorder();
      final svc = SteamLinksService(port: _FakePort(rec));

      // Act
      await svc.openWebUrl('https://steamcommunity.com/app/250900/workshop/');

      // Assert
      expect(rec.lastOp, 'openUri');
      expect(rec.lastTarget, startsWith('steam://openurl/'));
    });

    test('openWebUrl: 비스팀 도메인은 변환하지 않는다 (AAA)', () async {
      final rec = _Recorder();
      final svc = SteamLinksService(port: _FakePort(rec));

      await svc.openWebUrl('https://example.com/x');

      expect(rec.lastOp, 'openUri');
      expect(rec.lastTarget, equals('https://example.com/x'));
    });

    test('포트 호출 중 예외가 발생해도 서비스는 throw 하지 않는다 (AAA)', () async {
      final rec = _Recorder()..throwOnOpen = true;
      final svc = SteamLinksService(port: _FakePort(rec));

      await svc.openWebUrl('https://store.steampowered.com/app/250900/');

      // 예외는 삼켜지고 테스트는 통과해야 한다.
      expect(true, isTrue);
    });
  });
}
