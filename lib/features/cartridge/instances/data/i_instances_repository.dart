import 'package:cartridge/features/cartridge/instances/domain/models/instance.dart';

abstract class IInstancesRepository {
  Future<List<Instance>> listAll();              // pos ASC
  Future<Instance?> findById(String id);
  Future<void> upsert(Instance i);               // 트랜잭션: 본체 + children 싹 교체
  Future<void> removeById(String id);
  Future<void> reorderByIds(List<String> orderedIds, {bool strict = true});
}
