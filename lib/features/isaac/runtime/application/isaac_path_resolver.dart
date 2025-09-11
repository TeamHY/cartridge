import 'dart:io';
import 'package:path/path.dart' as p;

import 'package:cartridge/features/isaac/runtime/domain/isaac_versions.dart';

/// OS 환경/폴더 기반 경로 탐색 전담
class IsaacPathResolver {
  /// Windows/OS 환경변수 (기본: Platform.environment)
  final Map<String, String> env;

  /// Documents 루트 커스터마이즈(테스트 용이성)
  final Directory? Function()? documentsProvider;

  IsaacPathResolver({
    Map<String, String>? environment,
    this.documentsProvider,
  }) : env = environment ?? Platform.environment;

  /// 설치 경로에서 mods 루트 유도
  String deriveModsRootFromInstallPath(String installPath) =>
      p.join(installPath, 'mods');

  /// options.ini 후보 경로 수집 (존재하는 것만)
  ///
  /// [preferredEdition]이 있으면 해당 에디션 폴더를 우선 탐색
  Future<List<String>> listCandidateOptionsIniPaths({
    IsaacEdition? preferredEdition,
  }) async {
    final one  = env['OneDrive'] ?? env['ONEDRIVE'];
    final user = env['USERPROFILE'];
    final doc  = documentsProvider?.call();

    final folders = buildEditionFirstFolders(preferredEdition);

    final bases = <String>[
      if (doc  != null) doc.path,
      if (user != null) p.join(user),   // USERPROFILE
      if (one  != null) p.join(one),    // OneDrive
    ];

    // 중복 제거 + **삽입 순서 보존**을 위해 LinkedHashSet 사용
    final hits = <String>{};

    for (final folder in folders) {
      for (final base in bases) {
        final path = p.join(base, 'Documents', 'My Games', folder, 'options.ini');
        if (await File(path).exists()) {
          hits.add(path);
        }
      }
    }

    return hits.toList();
  }


  /// 에디션 우선 순서를 반영해 **옵션 폴더명 목록**을 구성.
  ///
  /// 1) [preferredEdition]이 있으면 그걸 최상위로,
  /// 2) 이후에는 최신순([IsaacEditionInfo.editionPriority])으로 이어붙임.
  ///
  /// 이 함수는 **정렬을 절대 하지 않습니다.** (의도된 우선순위를 보존하기 위해)
  List<String> buildEditionFirstFolders(IsaacEdition? preferredEdition) {
    final orderedEditions = <IsaacEdition>[
      if (preferredEdition != null) preferredEdition,
      ...IsaacEditionInfo.editionPriority.where((e) => e != preferredEdition),
    ];
    return [
      for (final e in orderedEditions) IsaacEditionInfo.folderName[e]!,
    ];
  }

}
