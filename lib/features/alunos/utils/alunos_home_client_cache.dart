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

class _AlunosHomeCacheEntry {
  const _AlunosHomeCacheEntry({required this.bundle, required this.at});

  final AlunosHomeBundle bundle;
  final DateTime at;
}

/// Cache client do BFF `/api/alunos/home` — uma entrada por query (filtro/busca/ordem).
abstract final class AlunosHomeClientCache {
  static const _maxEntries = 16;
  static final _entries = <AlunosHomeQuery, _AlunosHomeCacheEntry>{};

  static AlunosHomeBundle? getIfFresh(AlunosHomeQuery query, {DateTime? now}) {
    final entry = _entries[query];
    if (entry == null) return null;
    final age = (now ?? DateTime.now()).difference(entry.at);
    if (age > AlunosHomeQuery.ttl) {
      _entries.remove(query);
      return null;
    }
    return entry.bundle;
  }

  static void put(
    AlunosHomeQuery query,
    AlunosHomeBundle bundle, {
    DateTime? now,
  }) {
    _entries[query] = _AlunosHomeCacheEntry(
      bundle: bundle,
      at: now ?? DateTime.now(),
    );
    _trim();
  }

  static void clear() {
    _entries.clear();
  }

  static DateTime? get fetchedAt {
    if (_entries.isEmpty) return null;
    return _entries.values
        .map((e) => e.at)
        .reduce((a, b) => a.isAfter(b) ? a : b);
  }

  static void _trim() {
    while (_entries.length > _maxEntries) {
      AlunosHomeQuery? oldestKey;
      DateTime? oldestAt;
      for (final entry in _entries.entries) {
        if (oldestAt == null || entry.value.at.isBefore(oldestAt)) {
          oldestAt = entry.value.at;
          oldestKey = entry.key;
        }
      }
      if (oldestKey != null) {
        _entries.remove(oldestKey);
      } else {
        break;
      }
    }
  }
}
