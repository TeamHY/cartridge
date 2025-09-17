// test/unit/cartridge/record_mode/record_mode_allowed_prefs_service_test.dart
import 'package:cartridge/features/cartridge/record_mode/domain/record_mode_allowed_prefs_service.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cartridge/features/cartridge/record_mode/domain/models/game_preset_view.dart';
import 'package:cartridge/features/cartridge/record_mode/domain/repositories/record_mode_allowed_prefs_repository.dart';


void main() {
  group('RecordModeAllowedPrefsServiceImpl (no fake_async)', () {
    late _MemRepo repo;
    late RecordModeAllowedPrefsServiceImpl svc;

    AllowedModRow row({
      required String name,
      String? workshopId,
      bool installed = false,
      bool alwaysOn = false,
    }) {
      return AllowedModRow(
        name: name,
        installed: installed,
        workshopId: workshopId,
        alwaysOn: alwaysOn,
      );
    }

    setUp(() {
      repo = _MemRepo();
      svc = RecordModeAllowedPrefsServiceImpl(repo);
    });

    test('keyFor(): workshopId 우선, 없으면 name 기반', () {
      expect(svc.keyFor(row(name: 'Cool', workshopId: '123')), 'wid:123');
      expect(svc.keyFor(row(name: 'LocalOnly')), 'name:LocalOnly');
      expect(svc.keyFor(row(name: 'X', workshopId: '')), 'name:X');
    });

    test('ensureInitialized(): 신규 키는 (alwaysOn || installed)로 초기화 후 저장 1회', () async {
      // 기존 저장값 1개 이미 존재
      repo.store = {'name:Existing': false};

      final items = [
        row(name: 'Existing', installed: true),          // 이미 존재 → 변경 없음
        row(name: 'A', installed: true),                 // 신규 → true
        row(name: 'B', installed: false),                // 신규 → false
        row(name: 'C', installed: false, alwaysOn: true) // 신규(alwaysOn) → true
      ];

      final out = await svc.ensureInitialized(items);

      expect(repo.writeCount, 1);
      expect(out, {
        'name:Existing': false,
        'name:A': true,
        'name:B': false,
        'name:C': true,
      });
      expect(repo.store, out);
    });

    test('ensureInitialized(): 동일 목록으로 2번째 호출은 write 없이 캐시 반환', () async {
      final items = [
        row(name: 'A', installed: true),
        row(name: 'B', installed: false),
      ];
      final first = await svc.ensureInitialized(items);
      expect(repo.writeCount, 1);

      final second = await svc.ensureInitialized(items);
      expect(repo.writeCount, 1, reason: '변화 없음 → 추가 저장 없음');
      expect(second, first);
    });

    test('setEnabled(): 즉시 write 안 됨 → flush() 후 write 1회', () async {
      await svc.setEnabled(row(name: 'M'), true);

      // 디바운스 중: 아직 write 안 됨
      expect(repo.writeCount, 0);

      await svc.flush();
      expect(repo.writeCount, 1);
      expect(repo.store['name:M'], true);
    });

    test('setManyByRows(): 다건 설정 후 flush()로 1회 저장', () async {
      final rows = [
        row(name: 'A', workshopId: '11'),
        row(name: 'B'),
        row(name: 'C'),
      ];

      await svc.setManyByRows(rows, true);
      expect(repo.writeCount, 0, reason: '디바운스 중');

      await svc.flush();
      expect(repo.writeCount, 1);
      expect(repo.store, {
        'wid:11': true,
        'name:B': true,
        'name:C': true,
      });
    });

    test('flush(): pending 없으면 no-op', () async {
      // pending 없음
      await svc.flush();
      expect(repo.writeCount, 0);

      // 초기화로 저장 1회
      await svc.ensureInitialized([row(name: 'A', installed: true)]);
      expect(repo.writeCount, 1);

      // pending 없음 → flush no-op
      await svc.flush();
      expect(repo.writeCount, 1);
    });

    test('ensureInitialized 이후 사용자 변경 → flush로 최종 반영', () async {
      await svc.ensureInitialized([
        row(name: 'A', installed: true),
        row(name: 'B', installed: false),
      ]);
      expect(repo.store, {'name:A': true, 'name:B': false});
      expect(repo.writeCount, 1);

      await svc.setEnabled(row(name: 'B'), true);
      await svc.flush();

      expect(repo.writeCount, 2);
      expect(repo.store, {'name:A': true, 'name:B': true});
    });

    test('여러 setEnabled 호출 후 flush(): 마지막 값이 반영되고 write 1회', () async {
      await svc.setEnabled(row(name: 'X'), true);
      await svc.setEnabled(row(name: 'X'), false);
      await svc.setEnabled(row(name: 'Y', workshopId: '777'), true);

      // 아직 디바운스 중
      expect(repo.writeCount, 0);

      await svc.flush();
      expect(repo.writeCount, 1);
      expect(repo.store, {
        'name:X': false,  // 마지막 값
        'wid:777': true,
      });
    });

    // 참고: 진짜 타이머 경과를 검증하고 싶다면 아래 테스트를 해제(느려질 수 있음)
    // test('디바운스 타이머가 자동으로 write를 트리거한다(실시간 대기)', () async {
    //   await svc.setEnabled(row(name: 'D'), true);
    //   await Future<void>.delayed(const Duration(milliseconds: 450));
    //   expect(repo.writeCount, 1);
    //   expect(repo.store['name:D'], true);
    // });
  });
}

/// 메모리 저장소 스텁(호출 횟수/최신 상태 추적)
class _MemRepo implements RecordModeAllowedPrefsRepository {
  Map<String, bool> store = {};
  int readCount = 0;
  int writeCount = 0;
  final List<Map<String, bool>> writes = [];

  @override
  Future<Map<String, bool>> readAll() async {
    readCount++;
    return Map<String, bool>.from(store);
  }

  @override
  Future<void> writeAll(Map<String, bool> map) async {
    writeCount++;
    final snap = Map<String, bool>.from(map);
    writes.add(snap);
    store = snap;
  }
}
