import 'package:xml/xml.dart';
import 'package:xml/xpath.dart';

class Metadata {
  String? name;
  String? directory;
  String? id;
  String? version;

  Metadata({this.name, this.directory, this.id, this.version});

  factory Metadata.fromString(String data) {
    final document = XmlDocument.parse(data);

    try {
      return Metadata(
        name: document.xpath("/metadata/name").first.innerText,
        directory: document.xpath("/metadata/directory").first.innerText,
        id: document.xpath("/metadata/id").first.innerText,
        version: document.xpath("/metadata/version").first.innerText,
      );
    } catch (e) {
      return Metadata(
        name: document.xpath("/metadata/name").first.innerText,
      );
    }
  }
}
