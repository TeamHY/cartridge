class Mod {
  String name;
  String path;
  bool isDisable;

  Mod({required this.name, required this.path, this.isDisable = false});

  factory Mod.fromJson(Map<String, dynamic> json) {
    return Mod(
        name: json['name'], path: json['path'], isDisable: json['isDisable']);
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'path': path,
      'isDisable': isDisable,
    };
  }
}
