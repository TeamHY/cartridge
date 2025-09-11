import 'package:flutter/foundation.dart';

enum InstallPathStatus {
  ok,                 // 경로 유효(폴더+isaac-ng.exe 존재)
  dirNotFound,        // 폴더 없음
  exeNotFound,        // 폴더는 있음, 실행 파일 없음
  autoDetectFailed,   // 자동탐지 실패
  notConfigured,      // 설정 미구성(둘 다 공란 등)
}

enum InstallPathSource { manual, auto }

@immutable
class InstallPathResolution {
  final String? path;                     // 최종 후보 경로 (없을 수도 있음)
  final InstallPathStatus status;         // 결과 상태
  final InstallPathSource source;         // manual/auto
  final bool isValid;                     // status == ok
  const InstallPathResolution({
    required this.path,
    required this.status,
    required this.source,
    required this.isValid,
  });
}
