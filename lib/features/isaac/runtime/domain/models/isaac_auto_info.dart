import 'package:cartridge/features/isaac/runtime/application/install_path_result.dart';
import 'package:cartridge/features/isaac/runtime/domain/isaac_versions.dart';

class IsaacAutoInfo {
  final String? editionName;
  final String? editionAsset;
  final IsaacEdition? edition;
  final String? installPath;
  final bool repentogonInstalled;
  final InstallPathStatus installStatus;
  final InstallPathSource installSource;

  const IsaacAutoInfo({
    required this.editionName,
    required this.editionAsset,
    this.edition,
    this.installPath,
    this.repentogonInstalled = false,
    this.installStatus = InstallPathStatus.notConfigured,
    this.installSource = InstallPathSource.auto,
  });

  bool get canUseRepentogon =>
      edition == IsaacEdition.repentance || edition == IsaacEdition.repentancePlus;
}