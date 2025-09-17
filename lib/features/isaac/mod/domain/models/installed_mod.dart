import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:cartridge/features/isaac/mod/isaac_mod.dart';
import 'package:path/path.dart' as p;

part 'installed_mod.freezed.dart';

enum ModInstallOrigin { local, workshop, unknown }
/// 실제 파일시스템 상의 **설치 정보(Installed)** 를 포함한 런타임 모델.
/// - `folderName`: 실제 설치 폴더명(워크샵 ID 접미사 포함)
/// - `disabled`  : 폴더 내 `disable.it` 파일 존재 여부 (존재하면 비활성화)
@freezed
sealed class InstalledMod with _$InstalledMod {

  const InstalledMod._();

  const factory InstalledMod({
    required ModMetadata metadata,
    required bool disabled,
    @Default('') String installPath,
    @Default(ModInstallOrigin.unknown) ModInstallOrigin origin,
  }) = _InstalledMod;

  String get version => metadata.version;
  String get directory => metadata.directory;
  ModVisibility get visibility => metadata.visibility;
  List<String> get tags => metadata.tags;
  bool get isEnabled => !disabled;
  bool get isDisabled => disabled;
  String get folderName {
    if (installPath.isNotEmpty) {
      return p.basename(installPath);
    }
    // Fallback when installPath is not provided (legacy behavior)
    final base = metadata.directory;
    final suffix = metadata.id.isNotEmpty ? '_${metadata.id}' : '';
    return '$base$suffix';
  }

  static const empty = InstalledMod(
    metadata: ModMetadata(
      id: '',
      name: '',
      directory: '',
      version: '',
      visibility: ModVisibility.private,
      tags: [],
    ),
    disabled: true,
    origin: ModInstallOrigin.unknown,
  );
}
