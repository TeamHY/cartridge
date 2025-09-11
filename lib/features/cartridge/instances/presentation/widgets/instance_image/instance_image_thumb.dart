import 'dart:io';
import 'package:fluent_ui/fluent_ui.dart';

import 'package:cartridge/features/cartridge/instances/presentation/widgets/instance_image/sprite_sheet.dart';
import 'package:cartridge/features/cartridge/instances/domain/instance_policy.dart';
import 'package:cartridge/features/cartridge/instances/domain/models/instance_image.dart';

/// File 유효성 체크(교체 가능)
abstract interface class ImageSourceGuard {
  bool isUsableUserFile(String path);
}

class DefaultImageSourceGuard implements ImageSourceGuard {
  const DefaultImageSourceGuard();
  @override
  bool isUsableUserFile(String path) {
    try {
      final f = File(path);
      return f.existsSync();
    } catch (_) {
      return false;
    }
  }
}

/// 이름을 해싱해 사용 가능한 스프라이트 인덱스로 매핑(djb2a)
int _hashToUsableSpriteIndex(String seed) {
  const usable = InstanceImageRules.spriteFilledCount;
  if (usable <= 0) return 0;

  int h = 5381;
  for (final code in seed.codeUnits) {
    h = ((h << 5) + h) ^ code; // h*33 ^ c
  }
  final positive = h & 0x7fffffff;
  return positive % usable;
}

/// InstanceImage -> 렌더 전략 결정
({bool useUserFile, String? path, BoxFit? fit, int? spriteIndex}) _decideFromModel({
  required InstanceImage? image,
  required String fallbackSeed,
  required ImageSourceGuard guard,
}) {
  if (image == null) {
    return (
    useUserFile: false,
    path: null,
    fit: null,
    spriteIndex: _hashToUsableSpriteIndex(fallbackSeed),
    );
  }

  return image.map(
    userFile: (InstanceUserFile u) {
      final ok = guard.isUsableUserFile(u.path);
      if (ok) {
        return (useUserFile: true, path: u.path, fit: u.fit, spriteIndex: null);
      }
      return (
      useUserFile: false,
      path: null,
      fit: null,
      spriteIndex: _hashToUsableSpriteIndex(fallbackSeed),
      );
    },
    sprite: (InstanceSprite s) => (
    useUserFile: false,
    path: null,
    fit: null,
    spriteIndex: s.index,
    ),
  );
}

/// 인스턴스 이미지 표시:
/// - userFile: 파일 표시(디코딩 실패 시 스프라이트 폴백)
/// - sprite: 고정 assets 스프라이트 표시
/// - null:    fallbackSeed 해싱으로 스프라이트 인덱스 결정
class InstanceImageThumb extends StatelessWidget {
  const InstanceImageThumb({
    super.key,
    required this.image,
    required this.fallbackSeed,
    this.size = 80,
    this.borderRadius,
    this.guard = const DefaultImageSourceGuard(),
  });

  final InstanceImage? image;
  final String fallbackSeed;
  final double size;
  final BorderRadius? borderRadius;
  final ImageSourceGuard guard;

  @override
  Widget build(BuildContext context) {
    final br = borderRadius ?? BorderRadius.circular(10);

    Widget sprite(int index) => RepaintBoundary(
      // 레이어 고정으로 드롭/픽업 깜박임 방지
      child: SpriteTile(
        key: ValueKey('sprite:$index'), // 동일 조각 재사용 힌트
        asset: 'assets/images/instance_thumbs.png',
        grid: grid, // sprite_sheet.dart 내 정의
        index: index,
        width: size,
        height: size,
        borderRadius: br,
      ),
    );

    final decision = _decideFromModel(
      image: image,
      fallbackSeed: fallbackSeed,
      guard: guard,
    );

    if (decision.useUserFile && decision.path != null) {
      final file = File(decision.path!);
      return ClipRRect(
        borderRadius: br,
        child: Image.file(
          file,
          width: size,
          height: size,
          fit: decision.fit ?? BoxFit.cover,
          filterQuality: FilterQuality.medium,
          gaplessPlayback: true,
          isAntiAlias: false,
          // 디코딩 실패(훼손/코덱 문제) 시 스프라이트 폴백
          errorBuilder: (context, error, stack) =>
              sprite(_hashToUsableSpriteIndex(fallbackSeed)),
        ),
      );
    }

    return sprite(decision.spriteIndex ?? _hashToUsableSpriteIndex(fallbackSeed));
  }
}
