/// {@template feature_overview}
/// # AppliedPresetRef (Value Object)
///
/// 인스턴스에서 프리셋 적용/필수 여부를 나타내는 값 객체.
/// - 영속 데이터로서 presetId/isMandatory만 가진다.
/// {@endtemplate}
library;

import 'package:freezed_annotation/freezed_annotation.dart';

part 'applied_preset_ref.freezed.dart';
part 'applied_preset_ref.g.dart';

/// Instance(또는 다른 Aggregate)에서 프리셋을 적용할 때 참조/필수 여부를 나타내는 값 객체.
///
/// - [presetId]는 연결 대상 [ModPreset]의 식별자입니다(빈 값 금지).
/// - [isMandatory]가 true면 “필수 프리셋”으로 간주해 방어 로직에 활용할 수 있습니다.
@freezed
sealed class AppliedPresetRef with _$AppliedPresetRef {
  const AppliedPresetRef._();

  @Assert('presetId.isNotEmpty', 'AppliedPresetRef.presetId must not be empty')
  factory AppliedPresetRef({
    required String presetId,
    @Default(false) bool isMandatory,
  }) = _AppliedPresetRef;

  factory AppliedPresetRef.fromJson(Map<String, dynamic> json) =>
      _$AppliedPresetRefFromJson(json);
}
