import 'dart:io';

/// Reads a Dart library and sibling part files sharing the same base name.
String readScreenSourceBundle(String mainPath) {
  final mainFile = File(mainPath);
  final main = mainFile.readAsStringSync();
  final baseName = mainFile.uri.pathSegments.last.replaceAll('.dart', '');
  final parts = mainFile.parent
      .listSync()
      .whereType<File>()
      .where(
        (file) =>
            file.path.endsWith('.part.dart') &&
            file.uri.pathSegments.last.startsWith(baseName),
      )
      .map((file) => file.readAsStringSync())
      .join('\n');
  return '$main\n$parts';
}

/// Reads paywall_components and all of its part files.
String readPaywallComponentsBundle() {
  const mainPath = 'lib/features/planos/paywall/paywall_components.dart';
  final main = File(mainPath).readAsStringSync();
  final parts = File(mainPath)
      .parent
      .listSync()
      .whereType<File>()
      .where((file) => file.path.endsWith('.part.dart'))
      .map((file) => file.readAsStringSync())
      .join('\n');
  return '$main\n$parts';
}

/// Reads app_router.dart and all app_router_*.dart siblings.
String readRouterSourceBundle() {
  const dirPath = 'lib/core/router';
  final dir = Directory(dirPath);
  final main = File('$dirPath/app_router.dart').readAsStringSync();
  final siblings = dir
      .listSync()
      .whereType<File>()
      .where((f) {
        final name = f.uri.pathSegments.last;
        return name.startsWith('app_router_') && name.endsWith('.dart');
      })
      .toList()
    ..sort((a, b) => a.path.compareTo(b.path));
  final extra = siblings.map((f) => f.readAsStringSync()).join('\n');
  return '$main\n$extra';
}
