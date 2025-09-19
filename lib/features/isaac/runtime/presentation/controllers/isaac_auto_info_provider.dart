import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:cartridge/core/service_providers.dart';
import 'package:cartridge/features/isaac/runtime/domain/models/isaac_auto_info.dart';
import 'package:cartridge/features/isaac/runtime/isaac_runtime.dart';

/// Provides aggregated Isaac installation auto-detect info suitable for home/settings UI.
final isaacAutoInfoProvider = FutureProvider<IsaacAutoInfo>((ref) async {
  final env = ref.read(isaacEnvironmentServiceProvider);
  final isaac = ref.read(isaacRuntimeServiceProvider);

  // 1) Install path resolution with details
  final r = await env.resolveInstallPathDetailed();

  // 2) Edition info
  final ed = await isaac.inferIsaacEdition();
  final asset = (ed == null) ? null : IsaacEditionInfo.imageAssetFor(ed);

  // 3) Repentogon installed only valid when path is valid (handled by provider contract)
  final repInstalled = await ref.watch(repentogonInstalledProvider.future);

  return IsaacAutoInfo(
    editionName: IsaacEditionInfo.folderName[ed],
    editionAsset: asset,
    edition: ed,
    installPath: r.path,
    installStatus: r.status,
    installSource: r.source,
    repentogonInstalled: repInstalled,
  );
});
