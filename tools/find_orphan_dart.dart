// ignore_for_file: avoid_print
import 'dart:io';

// Lista arquivos .dart em lib/ que ninguém importa (nem lib/, nem test/).
// Resolve import/export/part de verdade (relativo + package:), então o
// resultado é acionável — não é heurística de substring.
// Uso: dart run tools/find_orphan_dart.dart

const _entryPoints = {'lib/main.dart'};

/// Superfícies do design system (barrel + gates de pilar exigem que
/// existam), mesmo sem importador em código hoje.
const _documentedApi = <String>{};

void main() {
  final lib = Directory('lib');
  if (!lib.existsSync()) {
    stderr.writeln('Execute na raiz do pacote focux-app.');
    exit(1);
  }

  final libFiles = _dartFilesIn(lib);
  final referenced = <String>{};

  for (final source in [...libFiles, ..._dartFilesIn(Directory('test'))]) {
    for (final target in _directiveTargets(source)) {
      referenced.add(target);
    }
  }

  final orphans =
      libFiles
          .where(
            (f) =>
                !_entryPoints.contains(f) &&
                !_documentedApi.contains(f) &&
                !referenced.contains(f),
          )
          .toList()
        ..sort();

  if (orphans.isEmpty) {
    print('Nenhum órfão em lib/.');
    return;
  }
  print('Órfãos em lib/ (${orphans.length}):');
  for (final orphan in orphans) {
    print('  $orphan');
  }
  exit(1);
}

List<String> _dartFilesIn(Directory dir) {
  if (!dir.existsSync()) return const [];
  return dir
      .listSync(recursive: true)
      .whereType<File>()
      .map(_normalize)
      .where((p) => p.endsWith('.dart'))
      .toList();
}

/// Caminhos `lib/...` referenciados pelas diretivas de [source].
///
/// Cobre import/export/part, incluindo os alvos condicionais
/// (`export 'a.dart' if (dart.library.io) 'b.dart';`) — ambos contam como uso.
Iterable<String> _directiveTargets(String source) {
  final directive = RegExp(
    r'^\s*(?:import|export|part)\s+[^;]+;',
    multiLine: true,
  );
  final uri = RegExp(r"""['"]([^'"]+\.dart)['"]""");
  final sourceUri = Uri.file(File(source).absolute.path);

  return directive
      .allMatches(File(source).readAsStringSync())
      .expand((d) => uri.allMatches(d.group(0)!))
      .map((m) => m.group(1)!)
      .map((raw) => _resolveTarget(raw, sourceUri))
      .whereType<String>();
}

String? _resolveTarget(String raw, Uri sourceUri) {
  if (raw.startsWith('dart:')) return null;

  if (raw.startsWith('package:focux_app/')) {
    return 'lib/${raw.substring('package:focux_app/'.length)}';
  }
  if (raw.startsWith('package:')) return null;

  final libRoot = Directory('lib').absolute.path.replaceAll(r'\', '/');
  final resolved = sourceUri.resolve(raw).toFilePath().replaceAll(r'\', '/');
  if (resolved.startsWith(libRoot)) {
    return _normalize('lib${resolved.substring(libRoot.length)}');
  }

  // O compilador tolera `../` a mais e clampa na raiz de lib/ — espelhamos
  // isso para não marcar o alvo real como órfão.
  final tail = raw.replaceAll(RegExp(r'^(?:\.\./)+'), '');
  final clamped = 'lib/$tail';
  return File(clamped).existsSync() ? clamped : null;
}

String _normalize(Object pathOrFile) {
  final raw = pathOrFile is File ? pathOrFile.path : pathOrFile as String;
  final normalized = raw.replaceAll(r'\', '/');
  final idx = normalized.indexOf('lib/');
  return idx >= 0 ? normalized.substring(idx) : normalized;
}
