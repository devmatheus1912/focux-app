// ignore_for_file: avoid_print
import 'dart:io';

// Lista arquivos .dart em lib/ sem nenhum importador (exceto main e parts).
// Uso: dart run tools/find_orphan_dart.dart

void main() {
  final lib = Directory('lib');
  if (!lib.existsSync()) {
    stderr.writeln('Execute na raiz do pacote focux-app.');
    exit(1);
  }

  final files =
      lib
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'))
          .map((f) => f.path.replaceAll(r'\', '/'))
          .toList();

  final importers = <String, Set<String>>{};
  for (final path in files) {
    importers[path] = {};
  }

  for (final file in files) {
    final content = File(file).readAsStringSync();
    final self = _libPath(file);
    for (final other in files) {
      if (other == file) continue;
      final target = _libPath(other);
      if (content.contains(target) ||
          content.contains(target.replaceAll('.dart', ''))) {
        importers[other]!.add(self);
      }
    }
    for (final match in RegExp(r"part\s+'([^']+)'").allMatches(content)) {
      final partPath = _resolvePart(self, match.group(1)!);
      for (final entry in importers.entries) {
        if (_libPath(entry.key) == partPath) {
          entry.value.add(self);
        }
      }
    }
  }

  final orphans = <String>[];
  for (final path in files) {
    final normalized = _libPath(path);
    if (normalized == 'lib/main.dart') continue;
    if (importers[path]!.isEmpty) orphans.add(normalized);
  }

  orphans.sort();
  if (orphans.isEmpty) {
    print('Nenhum órfão em lib/.');
  } else {
    print('Possíveis órfãos (${orphans.length}):');
    for (final o in orphans) {
      print('  $o');
    }
  }
}

String _libPath(String filePath) {
  final normalized = filePath.replaceAll(r'\', '/');
  final idx = normalized.indexOf('lib/');
  return idx >= 0 ? normalized.substring(idx) : normalized;
}

String _resolvePart(String libraryPath, String part) {
  final dir = libraryPath.substring(0, libraryPath.lastIndexOf('/'));
  return '$dir/$part';
}
