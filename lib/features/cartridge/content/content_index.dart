import 'package:flutter/services.dart' show rootBundle;
import 'package:yaml/yaml.dart';

enum ContentCategory { hyZone, info }
enum ContentType { detail, link, custom }

class ContentEntry {
  final String id;
  final ContentCategory category;
  final ContentType type;
  final Map<String, String> title;       // {'ko': ..., 'en': ...}
  final Map<String, String> description; // {'ko': ..., 'en': ...}
  final String? image;                   // asset path
  final String? markdown;                // type == detail
  final Map<String, String>? url;        // type == link; {'ko':..., 'en':...} or {'*':...}

  ContentEntry({
    required this.id,
    required this.category,
    required this.type,
    required this.title,
    required this.description,
    this.image,
    this.markdown,
    this.url,
  });

  String titleFor(String lang) => _pickLang(title, lang);
  String descriptionFor(String lang) => _pickLang(description, lang);
  String? urlFor(String lang) => url == null ? null : _pickLang(url!, lang, allowWildcard: true);

  static String _pickLang(Map<String, String> map, String lang, {bool allowWildcard = false}) {
    if (map.containsKey(lang)) return map[lang]!;
    if (allowWildcard && map.containsKey('*')) return map['*']!;
    if (map.containsKey('ko')) return map['ko']!;
    if (map.containsKey('en')) return map['en']!;
    return map.values.isNotEmpty ? map.values.first : '';
  }

  factory ContentEntry.fromYaml(Map yaml) {
    final id = (yaml['id'] ?? '').toString().trim();
    final catStr = (yaml['category'] ?? '').toString().trim();
    final typeStr = (yaml['type'] ?? '').toString().trim();
    if (id.isEmpty) { throw FormatException('content.id required'); }

    ContentCategory cat = switch (catStr) {
      'hyZone' => ContentCategory.hyZone,
      'info'   => ContentCategory.info,
      _        => ContentCategory.info,
    };
    ContentType type = switch (typeStr) {
      'detail' => ContentType.detail,
      'link'   => ContentType.link,
      'custom' => ContentType.custom,
      _        => ContentType.detail,
    };

    Map<String, String> toStrMap(dynamic v) {
      if (v == null) return {};
      if (v is String) return {'*': v};
      if (v is Map) {
        return v.map((k, val) => MapEntry(k.toString(), (val ?? '').toString()));
      }
      throw FormatException('invalid map');
    }

    final title = toStrMap(yaml['title']);
    final desc  = toStrMap(yaml['description']);
    final image = (yaml['image'] ?? '').toString().trim().isEmpty ? null : (yaml['image'] as String);
    final markdown = (yaml['markdown'] ?? '').toString().trim().isEmpty ? null : (yaml['markdown'] as String);
    final url = yaml['url'] == null ? null : toStrMap(yaml['url']);

    if (type == ContentType.detail && markdown == null) {
      throw FormatException('content[$id]: markdown required for detail type');
    }
    if (type == ContentType.link && url == null) {
      throw FormatException('content[$id]: url required for link type');
    }

    return ContentEntry(
      id: id,
      category: cat,
      type: type,
      title: title.isEmpty ? {'ko': id, 'en': id} : title,
      description: desc.isEmpty ? {'ko': '', 'en': ''} : desc,
      image: image,
      markdown: markdown,
      url: url,
    );
  }
}

class ContentIndex {
  final List<ContentEntry> entries;
  ContentIndex(this.entries);

  List<ContentEntry> filter({ContentCategory? category, String? query, required String lang}) {
    final q = (query ?? '').trim().toLowerCase();
    return entries.where((e) {
      final catOk = category == null || category == e.category;
      if (!catOk) return false;
      if (q.isEmpty) return true;
      final t = e.titleFor(lang).toLowerCase();
      final d = e.descriptionFor(lang).toLowerCase();
      return t.contains(q) || d.contains(q);
    }).toList(growable: false);
  }
}

Future<ContentIndex> loadContentIndex({String assetPath = 'assets/content/index.yaml'}) async {
  final text = await rootBundle.loadString(assetPath);
  final doc = loadYaml(text);
  if (doc is! YamlList) { throw FormatException('index.yaml must be a YAML list'); }

  final list = <ContentEntry>[];
  for (final node in doc) {
    if (node is YamlMap) {
      list.add(ContentEntry.fromYaml(Map<String, dynamic>.from(node)));
    }
  }
  return ContentIndex(list);
}
