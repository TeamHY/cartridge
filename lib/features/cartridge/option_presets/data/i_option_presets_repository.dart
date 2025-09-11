import 'package:cartridge/features/cartridge/option_presets/domain/models/option_preset.dart';

abstract class IOptionPresetsRepository {
  Future<List<OptionPreset>> listAll();                    // pos ASC
  Future<OptionPreset?> findById(String id);
  Future<void> upsert(OptionPreset preset);                // 존재하면 갱신, 없으면 삽입(pos = max+1)
  Future<void> removeById(String id);
  Future<void> reorderByIds(List<String> orderedIds, {bool strict = true});
}
