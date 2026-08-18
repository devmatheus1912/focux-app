import '../data/aluno_repository.dart';
import '../constants/alunos_list_filters.dart';

class AlunosHomeQuery {
  static const pageSize = 40;
  static const ttl = Duration(seconds: 90);

  const AlunosHomeQuery({
    this.q = '',
    this.filtro = AlunoFiltro.todos,
    this.ordenacao = AlunoOrdenacao.prioridade,
  });

  final String q;
  final AlunoFiltro filtro;
  final AlunoOrdenacao ordenacao;

  String get filtroApi => switch (filtro) {
    AlunoFiltro.todos => 'todos',
    AlunoFiltro.contatoHoje => 'contatoHoje',
    AlunoFiltro.ativos => 'ativos',
    AlunoFiltro.inadimplentes => 'inadimplentes',
    AlunoFiltro.risco => 'risco',
    AlunoFiltro.novos => 'novos',
  };

  String get ordenacaoApi => switch (ordenacao) {
    AlunoOrdenacao.prioridade => 'prioridade',
    AlunoOrdenacao.nome => 'nome',
    AlunoOrdenacao.semFoto => 'semFoto',
  };

  AlunosHomeQuery copyWith({
    String? q,
    AlunoFiltro? filtro,
    AlunoOrdenacao? ordenacao,
  }) => AlunosHomeQuery(
    q: q ?? this.q,
    filtro: filtro ?? this.filtro,
    ordenacao: ordenacao ?? this.ordenacao,
  );

  @override
  bool operator ==(Object other) =>
      other is AlunosHomeQuery &&
      other.q == q &&
      other.filtro == filtro &&
      other.ordenacao == ordenacao;

  @override
  int get hashCode => Object.hash(q, filtro, ordenacao);
}

/// Cache client do BFF `/api/alunos/home` alinhado ao TTL BE (90s).
abstract final class AlunosHomeClientCache {
  static AlunosHomeQuery? _query;
  static AlunosHomeBundle? _bundle;
  static DateTime? _fetchedAt;

  static AlunosHomeBundle? getIfFresh(AlunosHomeQuery query, {DateTime? now}) {
    final bundle = _bundle;
    final at = _fetchedAt;
    if (bundle == null || at == null || _query != query) return null;
    final age = (now ?? DateTime.now()).difference(at);
    if (age > AlunosHomeQuery.ttl) return null;
    return bundle;
  }

  static void put(
    AlunosHomeQuery query,
    AlunosHomeBundle bundle, {
    DateTime? now,
  }) {
    _query = query;
    _bundle = bundle;
    _fetchedAt = now ?? DateTime.now();
  }

  static void clear() {
    _query = null;
    _bundle = null;
    _fetchedAt = null;
  }

  static DateTime? get fetchedAt => _fetchedAt;
}
