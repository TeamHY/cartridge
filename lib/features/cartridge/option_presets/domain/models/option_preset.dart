import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:cartridge/core/utils/id.dart';
import 'package:cartridge/features/isaac/options/domain/models/isaac_options.dart';

part 'option_preset.freezed.dart';
part 'option_preset.g.dart';


/// 실행 전 `options.ini`의 [Options] 섹션에 반영될 게임 옵션 스냅샷.
/// UI나 파일 접근과 분리된 **순수 데이터 모델**입니다.
@freezed
sealed class OptionPreset with _$OptionPreset {
  const OptionPreset._(); // 커스텀 getter/메서드용

  @Assert('id.isNotEmpty', 'OptionPreset.id must not be empty')
  @Assert('name.trim().isNotEmpty', 'OptionPreset.name must not be empty')
  factory OptionPreset({
    required String id,
    required String name,
    bool? useRepentogon,
    required IsaacOptions options,
    DateTime? updatedAt,
  }) = _OptionPreset;

  /// 내부 규칙으로 id를 생성하는 팩토리 (예: `genId('op')`)
  factory OptionPreset.withGeneratedKey({
    required String Function(String prefix) genId,
    required String name,
    bool? useRepentogon,
    IsaacOptions? options,
    DateTime? updatedAt,
  }) =>
      OptionPreset(
        id: genId('op'),
        name: name,
        useRepentogon: useRepentogon,
        options: options ?? IsaacOptions(),
        updatedAt: updatedAt,
      );

  /// JSON 역직렬화 (관대한 파서 + null 필드 미출력)
  factory OptionPreset.fromJson(Map<String, dynamic> json) =>
      _$OptionPresetFromJson(json);

  OptionPreset duplicated(String? name, {DateTime? now}) => copyWith(
    id: IdUtil.genId('op'),
    name: (name ?? this.name).trim(),
    // useRepentogon은 그대로 유지(명시적 복사)
    useRepentogon: useRepentogon,
    // IsaacOptions도 새 인스턴스로 복제 (불변 보장)
    options: options.copyWith(),
    updatedAt: now ?? DateTime.now(),
  );
}
