/// lib/models/mod.dart
class Mod {
  final String id;
  final String name;
  final String path;
  final String? version;

  bool isDisable;

  Mod({
    required this.id,
    required this.name,
    required this.path,
    this.version,
    this.isDisable = false,
  });

  factory Mod.fromJson(Map<String, dynamic> json) {
    final id = json['id']?.toString() ?? '';
    final name = (json['name'] as String?) ?? '';

    return Mod(id: id, name: name, path: '', isDisable: json['isDisable']);
  }

  static Mod none = Mod(id: '', name: '', path: '', isDisable: true);

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'isDisable': isDisable,
    };
  }
}
