import 'dart:io';

void main(List<String> args) {
  if (args.isEmpty) {
    print('Usage: dart bump_version.dart <major|minor|patch>');
    exit(1);
  }

  final bumpType = args[0].toLowerCase();
  if (!['major', 'minor', 'patch'].contains(bumpType)) {
    print('Error: Bump type must be one of: major, minor, patch');
    exit(1);
  }

  final pubspecFile = File('pubspec.yaml');
  if (!pubspecFile.existsSync()) {
    print('Error: pubspec.yaml not found');
    exit(1);
  }

  final lines = pubspecFile.readAsLinesSync();
  var newLines = <String>[];
  var versionFound = false;
  String? newVersion;

  final versionRegex = RegExp(r'^version:\s*(\d+)\.(\d+)\.(\d+)(.*)$');

  for (var line in lines) {
    final match = versionRegex.firstMatch(line);
    if (match != null && !versionFound) {
      versionFound = true;
      var major = int.parse(match.group(1)!);
      var minor = int.parse(match.group(2)!);
      var patch = int.parse(match.group(3)!);
      final suffix = match.group(4) ?? '';

      switch (bumpType) {
        case 'major':
          major++;
          minor = 0;
          patch = 0;
          break;
        case 'minor':
          minor++;
          patch = 0;
          break;
        case 'patch':
          patch++;
          break;
      }

      newVersion = '$major.$minor.$patch';
      newLines.add('version: $newVersion$suffix');
      print('Version bumped: $newVersion');
    } else {
      newLines.add(line);
    }
  }

  if (!versionFound) {
    print('Error: Version line not found in pubspec.yaml');
    exit(1);
  }

  pubspecFile.writeAsStringSync(newLines.join('\n') + '\n');
  print('pubspec.yaml updated successfully');

  print('NEW_VERSION=$newVersion');
}
