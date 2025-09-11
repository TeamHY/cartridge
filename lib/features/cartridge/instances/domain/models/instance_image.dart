import 'dart:math' as math;
import 'package:fluent_ui/fluent_ui.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:cartridge/features/cartridge/instances/domain/instance_policy.dart';

part 'instance_image.freezed.dart';
part 'instance_image.g.dart';

@freezed
sealed class InstanceImage with _$InstanceImage {
  /// 사용자가 직접 업로드한 파일(절대경로 또는 앱데이터 상대경로)
  const factory InstanceImage.userFile({
    required String path,
    @Default(BoxFit.cover) BoxFit fit,
  }) = InstanceUserFile;

  /// 고정 스프라이트 시트(assets/images/instance_thumbs.png)의 grid index
  const factory InstanceImage.sprite({
    required int index, // 0..(8*38-1)
  }) = InstanceSprite;

  factory InstanceImage.fromJson(Map<String, dynamic> json) =>
      _$InstanceImageFromJson(json);

  /// 현재 사용 가능한 인덱스(0..278) 중 랜덤
  static int pickRandomUsableSpriteIndex({int? seed}) {
    final rng = seed == null ? math.Random() : math.Random(seed);
    return rng.nextInt(InstanceImageRules.spriteFilledCount); // [0, 279)
  }
}

