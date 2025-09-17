import 'package:cartridge/core/result.dart';
import 'package:cartridge/features/cartridge/instances/instances.dart';
import 'package:cartridge/features/cartridge/mod_presets/mod_presets.dart';
import 'package:cartridge/features/cartridge/option_presets/option_presets.dart';
import 'package:cartridge/features/isaac/mod/isaac_mod.dart';
import 'package:fluent_ui/fluent_ui.dart';

abstract class IInstancesService {
  const IInstancesService();

  // Queries
  Future<List<InstanceView>> listAllViews({
    Map<String, InstalledMod>? installedOverride,
    String? modsRootOverride,
  });

  Future<InstanceView?> getViewById(
      String id, {
        Map<String, InstalledMod>? installedOverride,
        String? modsRootOverride,
      });

  Future<(InstanceView, List<ModPresetView>, OptionPresetView?)?> getViewWithRelated(
      String id, {
        Map<String, InstalledMod>? installedOverride,
        String? modsRootOverride,
      });

  // Commands
  Future<Result<Instance?>> create({
    required String name,
    required SeedMode seedMode,
    String? optionPresetId,
    List<AppliedPresetRef> appliedPresets = const [],
    Map<String, InstalledMod>? installedOverride,
    String? modsRootOverride,
    InstanceSortKey? sortKey,
    bool? ascending,
    InstanceImage? image,
  });

  Future<Result<Instance>> rename(String id, String newName);

  Future<Result<void>> delete(String instanceId);

  Future<Result<Instance?>> clone({
    required String sourceId,
    required String duplicateSuffix,
  });

  Future<Result<Instance?>> setImageToSprite({
    required String instanceId,
    required int index,
  });

  Future<Result<Instance?>> setImageToUserFile({
    required String instanceId,
    required String path,
    BoxFit fit = BoxFit.cover,
  });

  Future<Result<Instance?>> setImageToRandomSprite({
    required String instanceId,
    int? seed,
  });

  Future<Result<Instance?>> clearImage(String instanceId);

  Future<Result<void>> removeMissingFromAllAppliedPresets({
    required String instanceId,
    required Map<String, InstalledMod>? installedOverride,
  });

  Future<Result<void>> reorderInstances(
      List<String> orderedIds, {
        bool strict = true,
      });

  Future<Result<Instance?>> setItemState({
    required String instanceId,
    required ModView item,
    bool? enabled,
    bool? favorite,
  });

  Future<Instance?> setModelState({
    required String instanceId,
    required ModView item,
    bool? enabled,
    bool? favorite,
  });

  Future<Result<Instance?>> bulkSetItemState({
    required String instanceId,
    required Iterable<ModView> items,
    bool? enabled,
    bool? favorite,
  });

  Future<Result<Instance?>> setOptionPreset(String instanceId, String? optionPresetId);

  Future<Instance?> replaceAppliedPresets({
    required String instanceId,
    required List<AppliedPresetRef> refs,
  });

  Future<void> deleteItem({
    required String instanceId,
    required String itemId,
  });
}