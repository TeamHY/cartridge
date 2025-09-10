/// lib/features/cartridge/slot_machine/domain/models/slot.dart
library;

import 'package:freezed_annotation/freezed_annotation.dart';

part 'slot.freezed.dart';
part 'slot.g.dart';

/// 슬롯머신의 단일 슬롯(Slot).
///
/// - **불변(immutable)** 데이터 모델입니다. 모든 변경은 `copyWith`로 수행하세요.
/// - 아이템은 현재 **텍스트(String)** 기반으로만 구성됩니다.
/// - 저장 로직(Service)에서 **빈 슬롯은 삭제** 규칙을 적용하세요(모델은 규칙만 문서화).
@freezed
sealed class Slot with _$Slot {
  /// 기본 생성자
  const factory Slot({
    /// 슬롯 식별자. 서비스에서 생성합니다(간단한 문자열 ID).
    required String id,

    /// 슬롯에 포함된 텍스트 아이템들.
    /// 빈 배열 허용. 저장 시점에서 제거 규칙 적용은 Service 책임입니다.
    @Default(<String>[]) List<String> items,
  }) = _Slot;

  /// JSON → 모델
  factory Slot.fromJson(Map<String, dynamic> json) => _$SlotFromJson(json);


  /// 내부 규칙으로 id를 생성하는 팩토리 (예: `genId('op')`)
  factory Slot.withGeneratedKey({
    required String Function(String prefix) genId,
    required List<String> items,
  }) =>
      Slot(
        id: genId('slot'),
        items: items,
      );
}
