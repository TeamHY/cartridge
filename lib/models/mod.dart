class Mod {
  final String name;
  final String path;
  final String? version;

  bool isDisable;

  Mod({
    required this.name,
    required this.path,
    this.version,
    this.isDisable = false,
  });

  factory Mod.fromJson(Map<String, dynamic> json) {
    return Mod(name: json['name'], path: '', isDisable: json['isDisable']);
  }

  static Mod none = Mod(name: '', path: '', isDisable: true);

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'isDisable': isDisable,
    };
  }
}
