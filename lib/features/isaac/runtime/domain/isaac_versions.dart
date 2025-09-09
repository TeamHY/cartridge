/// lib/core/constants/isaac_versions.dart
library;

import 'package:cartridge/features/isaac/runtime/domain/isaac_steam_ids.dart';

/// Isaac 에디션(본편/각 DLC) 식별자.
/// 문서(옵션) 폴더명은 `C:\Users\<USER>\Documents\My Games\<folder>\options.ini`
enum IsaacEdition {
  repentancePlus,
  repentance,
  afterbirthPlus,
  afterbirth,
  rebirth,
}

abstract final class IsaacEditionInfo {
  /// 문서 폴더 표시명 (My Games 하위 폴더 이름)
  static const Map<IsaacEdition, String> folderName = {
    IsaacEdition.rebirth:        'Binding of Isaac Rebirth',
    IsaacEdition.afterbirth:     'Binding of Isaac Afterbirth',
    IsaacEdition.afterbirthPlus: 'Binding of Isaac Afterbirth+',
    IsaacEdition.repentance:     'Binding of Isaac Repentance',
    IsaacEdition.repentancePlus: 'Binding of Isaac Repentance+',
  };

  /// Depot → Edition 매핑 (SteamDB Depots 근거)
  static const Map<int, IsaacEdition> depotToEdition = {
    IsaacSteamDepotIds.rebirth:        IsaacEdition.rebirth,
    IsaacSteamDepotIds.afterbirth:     IsaacEdition.afterbirth,
    IsaacSteamDepotIds.afterbirthPlus: IsaacEdition.afterbirthPlus,
    IsaacSteamDepotIds.repentance:     IsaacEdition.repentance,
    IsaacSteamDepotIds.repentancePlus: IsaacEdition.repentancePlus,
  };

  /// 설치된 것 중 **최신 에디션** 우선순위
  static const List<IsaacEdition> editionPriority = [
    IsaacEdition.repentancePlus,
    IsaacEdition.repentance,
    IsaacEdition.afterbirthPlus,
    IsaacEdition.afterbirth,
    IsaacEdition.rebirth,
  ];

  /// 문서 폴더 표시명 (My Games 하위 폴더 이름)
  static const Map<IsaacEdition, String> imageName = {
    IsaacEdition.rebirth:        "rebirth_200_200.png",
    IsaacEdition.afterbirth:     "afterbirth_200_200.png",
    IsaacEdition.afterbirthPlus: "afterbirthPlus_200_200.png",
    IsaacEdition.repentance:     "repentance_200_200.png",
    IsaacEdition.repentancePlus: "repentance_200_200.png",
  };

  /// 에디션 → 에셋 경로(프로젝트의 실제 경로에 맞춰 basePath 조정)
  static String? imageAssetFor(IsaacEdition e, {String basePath = 'assets/images/editions/'}) {
    final name = imageName[e];
    return name == null ? null : '$basePath$name';
  }

  /// InstalledDepots 집합에서 최신 에디션 추론
  static IsaacEdition? chooseEditionFromDepots(Set<int> installedDepots) {
    final installed = installedDepots
        .map((d) => depotToEdition[d])
        .whereType<IsaacEdition>()
        .toSet();
    for (final e in editionPriority) {
      if (installed.contains(e)) return e;
    }
    return null;
  }
}
