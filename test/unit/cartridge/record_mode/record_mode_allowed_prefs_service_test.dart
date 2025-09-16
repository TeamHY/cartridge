// test/unit/record_mode/record_mode_allowed_prefs_service_test.dart
import 'package:cartridge/features/cartridge/record_mode/domain/record_mode_allowed_prefs_service.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cartridge/features/cartridge/record_mode/domain/models/game_preset_view.dart';
import 'package:cartridge/features/cartridge/record_mode/domain/repositories/record_mode_allowed_prefs_repository.dart';


// ── Test Double: In-memory repo ───────────────────────────────────────────────
class _FakeRepo implements RecordModeAllowedPrefsRepository {
  Map<String, bool> store;
  int readCalls = 0;
  int writeCalls = 0;
  final List<Map<String, bool>> writeSnapshots = [];

  _FakeRepo({Map<String, bool>? initial}) : store = Map.of(initial ?? {});

  @override
  Future<Map<String, bool>> readAll() async {
    readCalls++;
    return Map.of(store);
  }

  @override
  Future<void> writeAll(Map<String, bool> map) async {
    writeCalls++;
    store = Map.of(map);
    writeSnapshots.add(Map.of(map));
  }
}

// AllowedModRow 헬퍼 (필요 필드만)
AllowedModRow row({
  required String name,
  String? workshopId,
  bool installed = false,
}) {
  // AllowedModRow의 실제 생성자가 프로젝트마다 다를 수 있는데,
  // 일반적으로 다음과 같은 형태를 가정한다.
  // (필요 시 여기만 프로젝트 실제 시그니처에 맞춰 수정)
  return AllowedModRow(
    name: name,
    workshopId: workshopId,
    installed: installed,
  );
}

void main() {
  group('RecordModeAllowedPrefsServiceImpl', () {
    test('keyFor(): workshopId 우선, 없으면 name 기반', () {
      final svc = RecordModeAllowedPrefsServiceImpl(_FakeRepo());
      expect(svc.keyFor(row(name: 'A', workshopId: '123')), 'wid:123');
      expect(svc.keyFor(row(name: 'B', workshopId: '')), 'name:B');
      expect(svc.keyFor(row(name: 'C')), 'name:C');
    });

    test('ensureInitialized(): 비어있으면 installed=true/false로 기본값 저장', () async {
      final repo = _FakeRepo(); // empty
      final svc = RecordModeAllowedPrefsServiceImpl(repo);

      final items = [
        row(name: 'Alpha', workshopId: '1', installed: true),
        row(name: 'Beta',  workshopId: '2', installed: false),
        row(name: 'Gamma',                installed: true), // no wid -> name key
      ];

      final map = await svc.ensureInitialized(items);
      expect(map['wid:1'], isTrue);
      expect(map['wid:2'], isFalse);
      expect(map['name:Gamma'], isTrue);

      // 최초 한 번 writeAll 호출
      expect(repo.writeCalls, 1);

      // 같은 목록으로 다시 호출해도 변경 없음 → writeAll 추가 호출 없음
      final again = await svc.ensureInitialized(items);
      expect(again, equals(map));
      expect(repo.writeCalls, 1);

      // 새 항목 추가 → 누락 키만 추가되고 writeAll 1회 더
      final next = [...items, row(name: 'Delta', workshopId: '4', installed: false)];
      final map2 = await svc.ensureInitialized(next);
      expect(map2['wid:4'], isFalse);
      expect(repo.writeCalls, 2);
    });

    test('setEnabled(): 단건 토글 + 캐시 갱신', () async {
      final repo = _FakeRepo(initial: {'wid:1': true});
      final svc = RecordModeAllowedPrefsServiceImpl(repo);

      // false로 토글
      await svc.setEnabled(row(name: 'X', workshopId: '1'), false);
      expect(repo.store['wid:1'], isFalse);
      expect(repo.writeCalls, 1);

      // 새 키에도 동작(없던 키 추가)
      await svc.setEnabled(row(name: 'Y', workshopId: '2'), true);
      expect(repo.store['wid:2'], isTrue);
      expect(repo.writeCalls, 2);
    });

    test('setManyByRows(): 여러 항목 일괄 설정', () async {
      final repo = _FakeRepo(initial: {'wid:1': true, 'wid:2': true, 'name:Z': true});
      final svc = RecordModeAllowedPrefsServiceImpl(repo);

      await svc.setManyByRows([
        row(name: 'A', workshopId: '1'),
        row(name: 'B', workshopId: '2'),
        row(name: 'Z'), // name-key
      ], false);

      expect(repo.store['wid:1'], isFalse);
      expect(repo.store['wid:2'], isFalse);
      expect(repo.store['name:Z'], isFalse);
      expect(repo.writeCalls, 1);
    });


    test('ensureInitialized() 이후 setEnabled()/setManyByRows(): readAll 재호출 없이 캐시 사용', () async {
      final repo = _FakeRepo(); // empty start
      final svc = RecordModeAllowedPrefsServiceImpl(repo);

      // 초기화(한 번 readAll)
      await svc.ensureInitialized([
        row(name: 'Alpha', workshopId: '1', installed: true),
      ]);
      final readsAfterInit = repo.readCalls;

      // 캐시로 동작 → readAll 호출 수 증가하지 않아야 함
      await svc.setEnabled(row(name: 'Alpha', workshopId: '1'), false);
      await svc.setManyByRows([row(name: 'Alpha', workshopId: '1')], true);

      expect(repo.readCalls, readsAfterInit);
      expect(repo.store['wid:1'], isTrue); // 마지막 호출(true) 반영
    });
  });
}
