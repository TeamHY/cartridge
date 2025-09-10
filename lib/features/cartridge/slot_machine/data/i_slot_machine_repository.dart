import 'package:cartridge/features/cartridge/slot_machine/domain/models/slot.dart';

abstract class ISlotMachineRepository {
  Future<List<Slot>> listAll();
  Future<Slot?> findById(String id);
  Future<void> upsert(Slot slot);
  Future<void> removeById(String id);

  /// 슬롯 순서(리스트 순서)를 영구화 (strict=true면 완전 순열 요구)
  Future<void> reorderByIds(List<String> orderedIds, {bool strict = true});
}
