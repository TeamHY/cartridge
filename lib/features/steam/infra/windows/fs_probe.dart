import 'dart:io';

abstract class FileSystemProbe {
  bool dirExists(String path);
  bool fileExists(String path);
}

class RealFileSystemProbe implements FileSystemProbe {
  @override bool dirExists(String path) => Directory(path).existsSync();
  @override bool fileExists(String path) => File(path).existsSync();
}