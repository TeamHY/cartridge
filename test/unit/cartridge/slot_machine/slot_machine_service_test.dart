import 'dart:math';
import 'package:flutter_test/flutter_test.dart';

import 'package:cartridge/features/cartridge/slot_machine/domain/slot_machine_service.dart';
import 'package:cartridge/features/cartridge/slot_machine/domain/models/slot.dart';
import 'package:cartridge/features/cartridge/slot_machine/data/i_slot_machine_repository.dart';

// 결정적 Random
class FixedRandom implements Random {
  FixedRandom(this.values);
  final List<int> values;
  int _i = 0;
  int _raw() => values[_i++ % values.length];
  @override int nextInt(int max) => _raw().abs() % max;
  @override double nextDouble() => (_raw().abs() % 1000) / 1000.0;
  @override bool nextBool() => (_raw() & 1) == 1;
}

// 메모리 Fake Repo (pos는 목록 순서로 해석)
class _MemRepo implements ISlotMachineRepository {
  final List<Slot> _list = [];
  @override Future<List<Slot>> listAll() async => List.unmodifiable(_list);
  @override Future<Slot?> findById(String id) async => _list.where((s) => s.id == id).cast<Slot?>().firstWhere((_) => true, orElse: () => null);
  @override Future<void> upsert(Slot slot) async {
    final idx = _list.indexWhere((e) => e.id == slot.id);
    if (idx < 0) {
      _list.add(slot);
    } else {
      _list[idx] = slot;
    }
  }
  @override Future<void> removeById(String id) async {
    _list.removeWhere((e) => e.id == id);
  }
  @override Future<void> reorderByIds(List<String> orderedIds, {bool strict = true}) async {
    if (strict) {
      final a = orderedIds.toSet();
      final b = _list.map((e) => e.id).toSet();
      if (a.length != b.length || !a.containsAll(b)) {
        throw ArgumentError('permutation mismatch');
      }
    }
    final map = {for (final s in _list) s.id: s};
    _list
      ..clear()
      ..addAll(orderedIds.map((id) => map[id]!).toList());
  }
}

void main() {
  group('SlotMachineService — CRUD & 스핀', () {
    late _MemRepo repo;
    late SlotMachineService svc;

    setUp(() {
      repo = _MemRepo();
      svc = SlotMachineService(repo: repo);
    });

    test('createLeft는 새 슬롯을 맨 앞에 추가한다', () async {
      // Arrange
      await repo.upsert(const Slot(id: 'A', items: ['x']));
      await repo.upsert(const Slot(id: 'B', items: ['y']));

      // Act
      final next = await svc.createLeft(defaultText: 'L');

      // Assert
      expect(next.first.items.single, 'L');
      expect(next.length, 3);
    });

    test('createRight는 새 슬롯을 맨 뒤에 추가한다', () async {
      // Arrange
      await repo.upsert(const Slot(id: 'A', items: ['x']));

      // Act
      final next = await svc.createRight(defaultText: 'R');

      // Assert
      expect(next.last.items.single, 'R');
    });

    test('delete는 슬롯을 제거한다', () async {
      // Arrange
      await repo.upsert(const Slot(id: 'A', items: ['x']));
      await repo.upsert(const Slot(id: 'B', items: ['y']));

      // Act
      final next = await svc.delete('A');

      // Assert
      expect(next.map((e) => e.id), ['B']);
    });

    test('setItems: 빈 배열이면 슬롯 자체를 삭제한다', () async {
      // Arrange
      await repo.upsert(const Slot(id: 'A', items: ['x']));

      // Act
      final next = await svc.setItems('A', const []);

      // Assert
      expect(next, isEmpty);
    });

    test('setItems: 존재하지 않는 슬롯이면 목록 변화 없음', () async {
      // Arrange
      await repo.upsert(const Slot(id: 'A', items: ['x']));

      // Act
      final next = await svc.setItems('NOPE', const ['z']);

      // Assert
      expect(next.single.items, ['x']);
    });

    test('addItem는 슬롯 맨 뒤에 아이템을 추가한다', () async {
      // Arrange
      await repo.upsert(const Slot(id: 'A', items: ['x']));

      // Act
      final next = await svc.addItem('A', 'y');

      // Assert
      expect(next.single.items, ['x', 'y']);
    });

    test('updateItem는 인덱스 범위 내에서만 수정한다', () async {
      // Arrange
      await repo.upsert(const Slot(id: 'A', items: ['x', 'y']));

      // Act
      final ok = await svc.updateItem('A', 1, 'Y');
      final bad = await svc.updateItem('A', 9, 'Z');

      // Assert
      expect(ok.single.items, ['x', 'Y']);
      expect(bad.single.items, ['x', 'Y']); // 변화 없음
    });

    test('removeItem는 아이템 제거, 마지막 아이템 제거시 슬롯 삭제', () async {
      // Arrange
      await repo.upsert(const Slot(id: 'A', items: ['x', 'y']));

      // Act
      final after1 = await svc.removeItem('A', 0);
      final after2 = await svc.removeItem('A', 0); // 남은 1개 제거

      // Assert
      expect(after1.single.items, ['y']);
      expect(after2, isEmpty);
    });

    test('persistOrder는 repo에 위임한다(strict=false)', () async {
      // Arrange
      repo
        ..upsert(const Slot(id: 'A', items: ['x']))
        ..upsert(const Slot(id: 'B', items: ['y']));

      // Act
      await svc.persistOrder(const ['B', 'A'], strict: false);
      final all = await repo.listAll();

      // Assert
      expect(all.map((e) => e.id), ['B', 'A']);
    });

    test('spinOne/All — 결정적 RNG에 따라 (index,value)를 반환한다', () {
      // Arrange
      final r = FixedRandom([1, 2]);
      final s1 = const Slot(id: 'A', items: ['x', 'y', 'z']);
      final s2 = const Slot(id: 'B', items: []);

      // Act
      final one = svc.spinOne(s1, rng: r)!;
      final all = svc.spinAll([s1, s2], rng: r);

      // Assert
      expect(one.$1, 1);
      expect(one.$2, 'y');
      expect(all[0]!.$2, anyOf('x', 'y', 'z'));
      expect(all[1], isNull);
    });
  });
}
