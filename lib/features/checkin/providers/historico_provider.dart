import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/checkin_repository.dart';
import 'checkin_provider.dart';

class HistoricoLista {
  const HistoricoLista({
    required this.sessoes,
    required this.nextCursor,
    required this.temMais,
    required this.fetchedAt,
    this.carregandoMais = false,
    this.erroMais = false,
  });

  final List<ExecucaoTreino> sessoes;
  final String? nextCursor;
  final bool temMais;
  final DateTime fetchedAt;
  final bool carregandoMais;

  /// Falhou a página seguinte: a lista fica, e a linha final oferece retry.
  final bool erroMais;

  HistoricoLista copyWith({bool? carregandoMais, bool? erroMais}) =>
      HistoricoLista(
        sessoes: sessoes,
        nextCursor: nextCursor,
        temMais: temMais,
        fetchedAt: fetchedAt,
        carregandoMais: carregandoMais ?? this.carregandoMais,
        erroMais: erroMais ?? this.erroMais,
      );
}

final historicoDetalheProvider = FutureProvider.autoDispose
    .family<ExecucaoTreino, int>(
      (ref, id) => ref.read(checkinRepositoryProvider).detalhe(id),
    );

/// Complemento do detalhe: sem ela, a tela usa as séries do próprio detalhe.
final historicoEvolucaoProvider = FutureProvider.autoDispose
    .family<SessaoEvolucaoDto?, int>((ref, id) async {
      try {
        return await ref.read(checkinRepositoryProvider).evolucaoSessao(id);
      } catch (_) {
        return null;
      }
    });

/// Sessões concluídas; `null` = todas as fichas.
final historicoListaProvider = AsyncNotifierProvider.autoDispose
    .family<HistoricoListaNotifier, HistoricoLista, int?>(
      HistoricoListaNotifier.new,
    );

class HistoricoListaNotifier extends AsyncNotifier<HistoricoLista> {
  HistoricoListaNotifier(this.treinoId);

  final int? treinoId;

  @override
  Future<HistoricoLista> build() => _primeiraPagina();

  Future<HistoricoLista> _primeiraPagina() async {
    final p = await ref
        .read(checkinRepositoryProvider)
        .historicoConcluidos(treinoId: treinoId);
    return HistoricoLista(
      sessoes: p.content,
      nextCursor: p.nextCursor,
      temMais: p.hasNext,
      fetchedAt: DateTime.now(),
    );
  }

  /// Puxar para atualizar: em erro a lista atual fica e o erro sobe.
  Future<void> atualizar() async {
    final nova = await _primeiraPagina();
    state = AsyncData(nova);
  }

  Future<void> carregarMais() async {
    final atual = state.value;
    if (atual == null || !atual.temMais || atual.carregandoMais) return;
    state = AsyncData(atual.copyWith(carregandoMais: true, erroMais: false));
    try {
      final p = await ref
          .read(checkinRepositoryProvider)
          .historicoConcluidos(cursor: atual.nextCursor, treinoId: treinoId);
      final vistos = {for (final s in atual.sessoes) s.id};
      state = AsyncData(
        HistoricoLista(
          sessoes: [
            ...atual.sessoes,
            ...p.content.where((s) => vistos.add(s.id)),
          ],
          nextCursor: p.nextCursor,
          temMais: p.hasNext,
          fetchedAt: atual.fetchedAt,
        ),
      );
    } catch (_) {
      state = AsyncData(atual.copyWith(carregandoMais: false, erroMais: true));
    }
  }
}
