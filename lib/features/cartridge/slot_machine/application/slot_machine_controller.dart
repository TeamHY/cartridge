/// {@template feature_overview}
/// # SlotMachine Controller (Application Controller)
///
/// 슬롯머신 화면의 상태/액션을 관리하는 **Application Controller**.
/// - Service 위임을 통해 슬롯/아이템 CRUD를 수행하고 상태를 갱신한다.
/// {@endtemplate}
library;

import 'package:cartridge/core/service_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cartridge/features/cartridge/slot_machine/domain/models/slot.dart';
import 'package:cartridge/features/cartridge/slot_machine/domain/slot_machine_service.dart';


/// 슬롯머신 화면의 상태/액션을 담당하는 컨트롤러.
///
/// - 상태 타입: `AsyncValue<List<Slot>>`
/// - 책임:
///   1) 최초 로드 및 새로고침
///   2) 슬롯/아이템 CRUD를 Service에 위임
///   3) 모든 변경 후 **서비스가 반환한 최신 리스트**로 상태 갱신(불필요한 재조회 없음)
class SlotMachineController extends AsyncNotifier<List<Slot>> {
  SlotMachineService get _service => ref.read(slotMachineServiceProvider);

  @override
  Future<List<Slot>> build() async {
    return _service.listAll();
  }

  /// 공통 적용 유틸: [op]의 결과(`List<Slot>`)를 에러 래핑하여 상태에 반영.
  Future<void> _apply(Future<List<Slot>> Function() op) async {
    state = await AsyncValue.guard(() async => await op());
  }

  /// 수동 새로고침.
  Future<void> refresh() => _apply(() => _service.listAll());

  // ───────────── 슬롯 CRUD ─────────────

  /// 왼쪽(인덱스 0)에 슬롯 추가.
  Future<void> addLeft({String defaultText = 'Item'}) =>
      _apply(() => _service.createLeft(defaultText: defaultText));

  /// 오른쪽(마지막)에 슬롯 추가.
  Future<void> addRight({String defaultText = 'Item'}) =>
      _apply(() => _service.createRight(defaultText: defaultText));

  /// 슬롯 삭제(id 기반).
  Future<void> removeSlot(String slotId) =>
      _apply(() => _service.delete(slotId));

  /// 슬롯 아이템 일괄 교체(슬롯 편집 화면 저장).
  /// - 결과가 빈 배열이면 서비스 규칙에 따라 **슬롯 자체 삭제**.
  Future<void> setSlotItems(String slotId, List<String> items) =>
      _apply(() => _service.setItems(slotId, items));

  // ───────────── 아이템 CRUD ─────────────

  /// 아이템 추가(맨 끝).
  Future<void> addItem(String slotId, String text) =>
      _apply(() => _service.addItem(slotId, text));

  /// 아이템 수정(인덱스 기반).
  Future<void> updateItem(String slotId, int index, String text) =>
      _apply(() => _service.updateItem(slotId, index, text));

  /// 아이템 삭제(인덱스 기반).
  /// - 결과가 빈 배열이면 서비스 규칙에 따라 **슬롯 자체 삭제**.
  Future<void> removeItem(String slotId, int index) =>
      _apply(() => _service.removeItem(slotId, index));
}

/// UI에서 구독할 슬롯 리스트 상태.
final slotMachineControllerProvider =
AsyncNotifierProvider<SlotMachineController, List<Slot>>(
  SlotMachineController.new,
);

/// 전체 스핀 신호를 브로드캐스트하는 단순 카운터.
/// - UI에서 `ref.read(spinAllTickProvider.notifier).state++` 로 트리거
/// - 화면 전용 상호작용 상태이므로 presentation 레이어에 두어도 무방합니다.
final spinAllTickProvider = StateProvider<int>((ref) => 0);
