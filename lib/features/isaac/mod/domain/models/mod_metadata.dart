import 'package:xml/xml.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:cartridge/features/isaac/mod/isaac_mod.dart';

part 'mod_metadata.freezed.dart';

/// 아이작 모드의 `metadata.xml`에서 읽어오는 **순수 메타데이터(Metadata)**.
/// - 런타임 경로(directory)나 활성/비활성 상태는 포함하지 않습니다.
/// - UI/Service에서는 이 객체를 **불변(immutable)** 데이터로 취급하세요.
/// - **주의:** `id`는 Steam Workshop에서 모드에 부여한 **Workshop ID**입니다.
@freezed
abstract class ModMetadata with _$ModMetadata {
  const ModMetadata._(); // private ctor for custom getters/methods

  const factory ModMetadata({
    /// 모드 고유 식별자. `<id>` 태그에서 읽음.
    /// Steam Workshop ID이며 비어 있으면 무시 대상입니다.
    required String id,

    /// 모드 표시 이름. `<name>` 태그에서 읽음(비어 있을 수 있음).
    required String name,

    /// 모드 버전 문자열. `<directory>` 태그에서 읽음(비어 있을 수 있음).
    required String directory,

    /// 모드 버전 문자열. `<version>` 태그에서 읽음(비어 있을 수 있음).
    required String version,

    /// 모드 공개 여부. `<visibility>` 태그에서 읽음(비어 있을 수 있음).
    required ModVisibility visibility,

    /// 모드 태그 목록. `<tag id="..."/>`들의 `id` 속성값만 수집.
    required List<String> tags,
  }) = _ModMetadata;

  /// `metadata.xml` **문자열**로부터 메타데이터를 파싱합니다.
  ///
  /// 규칙:
  /// - 태그는 모두 **소문자** 기준(`<id>`, `<name>`, `<version>`, `<visibility>`, `<tag id="..."/>`).
  /// - `<tag>`는 속성 `id` 값만 인정하며, 본문 텍스트는 무시합니다.
  /// - 누락된 태그는 **빈 문자열**로 처리합니다.
  factory ModMetadata.fromXmlString(String xml) {
    final doc = XmlDocument.parse(xml);

    String textOrEmpty(String tag) {
      final it = doc.findAllElements(tag);
      return it.isEmpty ? '' : it.first.innerText.trim();
    }

    final tagIds = doc
        .findAllElements('tag')
        .map((e) => e.getAttribute('id'))
        .whereType<String>()
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList(growable: false);

    return ModMetadata(
      id: textOrEmpty('id'),
      name: textOrEmpty('name'),
      directory: textOrEmpty('directory'),
      version: textOrEmpty('version'),
      visibility: parseModVisibility(textOrEmpty('visibility')),
      tags: tagIds,
    );
  }
}
