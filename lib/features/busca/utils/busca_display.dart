import '../models/busca_global_models.dart';

const buscaMinQueryLength = 2;
const buscaDebounceMs = 400;

const _allowedInternalPrefixes = <String>[
  '/alunos/',
  '/treinos/',
  '/financeiro/',
  '/agenda/',
  '/checkin/',
  '/chat/',
  '/leads/',
  '/perfil/',
];

String buscaHint() => 'Nome, treino ou cobrança';

String buscaMinQueryTitle() => 'Digite ao menos 2 caracteres';

String buscaMinQuerySubtitle() => 'Busque por alunos, treinos ou cobranças.';

String buscaEmptyTitle(String query) => 'Nenhum resultado para "$query"';

String buscaEmptySubtitle() => 'Tente outro nome, apelido ou trecho do treino.';

String buscaEmptyFilterTitle(String filterLabel) =>
    'Nenhum resultado em $filterLabel';

String buscaEmptyFilterSubtitle() =>
    'Troque o filtro para ver os outros resultados.';

String buscaCountLabel(int count) {
  if (count <= 0) return 'Nenhum resultado';
  if (count == 1) return '1 resultado';
  return '$count resultados';
}

String buscaCountInFilterLabel(int count, String filterLabel) {
  if (count <= 0) return 'Nenhum resultado em $filterLabel';
  if (count == 1) return '1 resultado em $filterLabel';
  return '$count resultados em $filterLabel';
}

String buscaSectionHeader(BuscaTipo tipo) => switch (tipo) {
  BuscaTipo.todos => 'Resultados',
  BuscaTipo.aluno => 'Alunos',
  BuscaTipo.treino => 'Treinos',
  BuscaTipo.cobranca => 'Cobranças',
};

String buscaDestinationMissing() => 'Item sem destino válido.';

String buscaDestinationForbidden() => 'Destino não permitido.';

String buscaDestinationUnsupported() => 'Destino não suportado.';

String buscaLaunchFailed() => 'Não foi possível abrir este link.';

String buscaExternalSheetTitle() => 'Abrir link externo?';

String buscaExternalConfirmLabel() => 'Abrir';

bool buscaInternalPathAllowed(String path) {
  return _allowedInternalPrefixes.any(path.startsWith);
}

String buscaNormalizePath(String path) {
  var normalized = path.trim();
  while (normalized.contains('//')) {
    normalized = normalized.replaceAll('//', '/');
  }
  return normalized;
}

bool buscaIsHttpUrl(Uri uri) =>
    uri.scheme == 'http' || uri.scheme == 'https';

List<BuscaItem> buscaFilterByTipo(BuscaGlobalResult result, BuscaTipo filter) =>
    switch (filter) {
      BuscaTipo.todos => [
        ...result.alunos,
        ...result.treinos,
        ...result.cobrancas,
      ],
      BuscaTipo.aluno => result.alunos,
      BuscaTipo.treino => result.treinos,
      BuscaTipo.cobranca => result.cobrancas,
    };
