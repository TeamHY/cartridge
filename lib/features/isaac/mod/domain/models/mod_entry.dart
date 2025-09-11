import 'package:freezed_annotation/freezed_annotation.dart';

part 'mod_entry.freezed.dart';
part 'mod_entry.g.dart';

/// 하나의 모드 레코드(영구 저장용 최소 필드)
///
/// - [key] : 실제 폴더명 key
/// - [workshopId]: 워크샵 ID
/// - [workshopName]: 표시용 라벨
/// - [enabled]: 인스턴스/프리셋 관점의 **직접 활성 여부**
/// - [favorite]: 즐겨찾기 여부
///
/// ⚠️ 의미 명확화:
/// - `enabled == true`  → 사용자가 **직접 활성**
/// - `enabled == false` → 사용자가 **직접 비활성(강제 OFF)**
@freezed
sealed class ModEntry with _$ModEntry {
  const ModEntry._();


  @Assert('key.isNotEmpty', 'key(폴더명)는 비어 있을 수 없습니다')
  factory ModEntry({
    required String key,
    String? workshopId,
    String? workshopName,
    bool? enabled, // null=미지정, true=ON, false=강제 OFF
    @Default(false) bool favorite,
    DateTime? updatedAt,
  }) = _ModEntry;

  /// JSON 역직렬화
  factory ModEntry.fromJson(Map<String, dynamic> json) =>
      _$ModEntryFromJson(json);
}