import 'package:cartridge/core/validation.dart';
import 'package:cartridge/features/cartridge/instances/instances.dart';

/// Instance 도메인 정책
/// - normalize: 기본값/여백/프리셋 중복 정리(키는 절대 변환/삭제하지 않음)
/// - validate : 이름/프리셋 id/override key 유효성 및 중복 검사
class InstancePolicy {
  /// 정규화 (키는 가공/삭제하지 않음)
  static Instance normalize(Instance p) {
    final trimmedName = p.name.trim();

    // 이미지: userFile.path만 trim (값 삭제/치환 없음)
    final normalizedImage = p.image?.map(
      userFile: (u) => u.copyWith(path: u.path.trim()),
      sprite: (s) => s,
    );

    return p.copyWith(
      name     : trimmedName.isEmpty ? '알 수 없는 인스턴스' : trimmedName,
      sortKey  : p.sortKey ?? InstanceSortKey.name,
      ascending: p.ascending ?? true,
      image    : normalizedImage,
      // 프리셋 중복 제거(앞선 항목 우선, 순서 보존), 빈 id 제거
      appliedPresets: _dedupAppliedPresets(p.appliedPresets),
    );
  }

  /// 검증
  /// - 이름 공백 금지
  /// - appliedPresets: 빈/중복 id 금지
  /// - overrides.key: 빈 값/중복 금지, Windows 금지문자/예약어 금지
  static ValidationResult validate(Instance p) {
    final v = <Violation>[];

    // 1) 이름
    if (p.name.trim().isEmpty) {
      v.add(const Violation('instance.name.empty'));
    }

    // 2) 프리셋 id
    final seenPreset = <String>{};
    for (int i = 0; i < p.appliedPresets.length; i++) {
      final raw = p.appliedPresets[i].presetId;
      final id  = raw.trim();
      if (id.isEmpty) {
        v.add(Violation('instance.appliedPreset.id.empty', {'idx': i}));
        continue;
      }
      if (!seenPreset.add(id)) {
        v.add(Violation('instance.appliedPreset.id.duplicate', {
          'idx': i, 'presetId': id,
        }));
      }
    }

    // 3) overrides.key
    final seenKey = <String>{};
    for (int i = 0; i < p.overrides.length; i++) {
      final k = p.overrides[i].key;
      if (k.trim().isEmpty) {
        v.add(Violation('instance.override.key.empty', {'idx': i}));
        continue;
      }
      if (!seenKey.add(k)) {
        v.add(Violation('instance.override.key.duplicate', {
          'idx': i, 'key': k,
        }));
      }
    }

    // 4) image 규칙
    final img = p.image;
    if (img != null) {
      img.map(
        userFile: (u) {
          final path = u.path.trim();
          if (path.isEmpty) {
            v.add(const Violation('instance.image.userFile.path.empty'));
          } else {
            final base = _basename(path);
            if (_isWindowsReservedName(base)) {
              v.add(Violation('instance.image.userFile.path.reserved', {'basename': base}));
            }
            if (_hasIllegalFileNameChars(base)) {
              v.add(Violation('instance.image.userFile.path.illegalChars', {'basename': base}));
            }
            if (_endsWithDotOrSpace(base)) {
              v.add(Violation('instance.image.userFile.path.trailingDotOrSpace', {'basename': base}));
            }
          }
        },
        sprite: (s) {
          final idx = s.index;
          if (idx < 0) {
            v.add(Violation('instance.image.sprite.index.negative', {'index': idx}));
          } else if (idx >= InstanceImageRules.spriteMaxCount) {
            v.add(Violation('instance.image.sprite.index.out_of_range', {
              'index': idx,
              'max'  : InstanceImageRules.spriteMaxCount - 1, // 303
            }));
          }
        },
      );
    }
    return ValidationResult(v);
  }

  /// 프리셋 ID 중복 제거(앞선 항목 우선, 순서 보존) + 빈 id 제거
  static List<AppliedPresetRef> _dedupAppliedPresets(List<AppliedPresetRef> refs) {
    final out  = <AppliedPresetRef>[];
    final seen = <String>{};
    for (final r in refs) {
      final id = r.presetId.trim();
      if (id.isEmpty) continue;
      if (seen.add(id)) out.add(r);
    }
    return out;
  }

  // ── 파일명/경로 점검 보조 (Windows 호환) ───────────────────────────────────────────────────────────

  static String _basename(String path) {
    final parts = path.split(RegExp(r'[\\/]+'));
    return parts.isEmpty ? path : parts.last;
  }

  // Windows 예약어 (대소문자 무시)
  static bool _isWindowsReservedName(String name) {
    final n = name.split('.').first.toUpperCase(); // 확장자 제거 후 비교
    const reserved = {
      'CON','PRN','AUX','NUL',
      'COM1','COM2','COM3','COM4','COM5','COM6','COM7','COM8','COM9',
      'LPT1','LPT2','LPT3','LPT4','LPT5','LPT6','LPT7','LPT8','LPT9',
    };
    return reserved.contains(n);
  }

  // 파일명에 허용되지 않는 문자(경로 구분자는 제외: \ / 는 경로에서만 등장)
  static bool _hasIllegalFileNameChars(String name) {
    final re = RegExp(r'[<>:"/|?*]'); // \는 분리자라 basename엔 없어야 함
    return re.hasMatch(name);
  }

  static bool _endsWithDotOrSpace(String name) {
    return name.endsWith(' ') || name.endsWith('.');
  }
}

class InstanceImageRules {
  static const int spriteCols = 8;
  static const int spriteRowsMax = 38;

  /// 시트 전체 최대 수용 칸(= 8 * 38 = 304)
  static const int spriteMaxCount = spriteCols * spriteRowsMax;

  /// 현재 실제로 채워 넣은 칸: 8×34 + 7 = 279 (index 0..278)
  static const int spriteFilledCount =
      spriteCols * spriteFilledRows + spriteFilledExtra; // 279
  static const int spriteFilledRows = 34;
  static const int spriteFilledExtra = 7;

  static bool isUsableSpriteIndex(int i) =>
      i >= 0 && i < spriteFilledCount;

  static bool isReservedSpriteIndex(int i) =>
      i >= spriteFilledCount && i < spriteMaxCount;

  /// 고정 자원 경로 (참고용)
  static const String assetPath = 'assets/images/instance_thumbs.png';
}