/// {@template feature_overview}
/// # SlotMachine Service
///
/// 슬롯머신 도메인의 목록/수정/스핀 유틸을 제공하는 **Domain Service**.
/// {@endtemplate}
library;

import 'dart:math';

import 'package:cartridge/core/utils/id.dart';
import 'package:cartridge/features/cartridge/slot_machine/data/i_slot_machine_repository.dart';
import 'package:cartridge/features/cartridge/slot_machine/domain/models/slot.dart';

/// {@template slot_machine_service}
/// # SlotMachineService
///
/// 슬롯 추가/삭제/수정과 목록 조회, 스핀 유틸을 제공하는 **Domain Service**.
///
/// ## 유스케이스(Use cases)
/// - 슬롯 CRUD와 아이템 CRUD 관리
/// - 스핀 결과를 즉시 UI에서 사용(비영속)
///
/// ## 전제(Preconditions)
/// - 저장은 Repository를 통해 원자적으로 수행
/// - 아이템이 모두 삭제되면 슬롯은 삭제되는 규칙 적용
///
/// ## 비기능(Non-functional)
/// - 스핀은 순수 계산(Random)으로 외부 I/O 없음
/// - 저장은 전체 리스트 불변 갱신(copyWith)로 정렬 보존
///
/// ## 관련(See also)
/// - [ISlotMachineRepository]
/// - [Slot]
/// {@endtemplate}
/// {@macro slot_machine_service}
class SlotMachineService {
  final ISlotMachineRepository repo;

  SlotMachineService({required this.repo});

  // ── Queries(조회) ──────────────────────────────────────────────────────────────

  /// 전체 슬롯머신(슬롯 리스트) 반환.
  Future<List<Slot>> listAll() => repo.listAll();
  Future<Slot?> getById(String id) => repo.findById(id);

  // ── Commands(생성/수정/삭제) ───────────────────────────────────────────────────

  /// 좌측(인덱스 0)에 신규 슬롯 추가.
  ///
  /// 정렬(순서)을 보장해야 하므로 `store.copyWith(slots: next)`를 저장합니다.
  Future<List<Slot>> createLeft({String defaultText = 'Item'}) async {
    final cur = await repo.listAll();
    final newSlot = Slot.withGeneratedKey(genId: IdUtil.genId, items: [defaultText]);

    await repo.upsert(newSlot);
    await repo.reorderByIds([newSlot.id, ...cur.map((s) => s.id)]);

    return repo.listAll();
  }

  /// 우측(마지막)에 신규 슬롯 추가.
  Future<List<Slot>> createRight({String defaultText = 'Item'}) async {
    final cur = await repo.listAll();
    final newSlot = Slot.withGeneratedKey(genId: IdUtil.genId, items: [defaultText]);

    await repo.upsert(newSlot);
    await repo.reorderByIds([...cur.map((s) => s.id), newSlot.id]);

    return repo.listAll();
  }

  /// 슬롯 삭제.
  ///
  /// 정렬을 깨뜨리지 않으므로 `repo.remove(id)`를 활용합니다.
  Future<List<Slot>> delete(String slotId) async {
    await repo.removeById(slotId);
    return repo.listAll();
  }

  // ── State Changes(상태 변경) ───────────────────────────────────────────────────

  /// 슬롯 전체 아이템 교체(슬롯 편집 화면의 일괄 저장).
  ///
  /// - 교체 결과가 빈 배열이면 **슬롯 자체를 삭제**합니다.
  Future<List<Slot>> setItems(String slotId, List<String> items) async {
    if (items.isEmpty) {
      await repo.removeById(slotId);
      return repo.listAll();
    }
    final cur = await repo.findById(slotId);
    if (cur == null) return repo.listAll();
    await repo.upsert(cur.copyWith(items: items));
    return repo.listAll();
  }

  Future<List<Slot>> addItem(String slotId, String text) async {
    final cur = await repo.findById(slotId);
    if (cur == null) return repo.listAll();
    await repo.upsert(cur.copyWith(items: [...cur.items, text]));
    return repo.listAll();
  }

  Future<List<Slot>> updateItem(String slotId, int itemIndex, String text) async {
    final cur = await repo.findById(slotId);
    if (cur == null) return repo.listAll();
    if (itemIndex < 0 || itemIndex >= cur.items.length) return repo.listAll();
    final items = [...cur.items]..[itemIndex] = text;
    await repo.upsert(cur.copyWith(items: items));
    return repo.listAll();
  }

  Future<List<Slot>> removeItem(String slotId, int itemIndex) async {
    final cur = await repo.findById(slotId);
    if (cur == null) return repo.listAll();
    if (itemIndex < 0 || itemIndex >= cur.items.length) return repo.listAll();
    final items = [...cur.items]..removeAt(itemIndex);
    return setItems(slotId, items);
  }

  Future<void> persistOrder(List<String> orderedIds, {bool strict = true}) {
    return repo.reorderByIds(orderedIds, strict: strict);
  }

  // ── View Helpers(뷰 유틸) ─────────────────────────────────────────────────────

  /// 슬롯 하나 스핀 → `(선택 인덱스, 값)`. 저장하지 않습니다.
  (int index, String value)? spinOne(Slot slot, {Random? rng}) {
    if (slot.items.isEmpty) return null;
    final r = rng ?? Random();
    final i = r.nextInt(slot.items.length);
    return (i, slot.items[i]);
  }

  /// 전체 슬롯 스핀 → 슬롯 순서대로 `(index, value)` 결과 리스트.
  List<(int index, String value)?> spinAll(List<Slot> slots, {Random? rng}) {
    final r = rng ?? Random();
    return [
      for (final s in slots)
        s.items.isEmpty ? null : (() {
          final i = r.nextInt(s.items.length);
          return (i, s.items[i]);
        })(),
    ];
  }
}
