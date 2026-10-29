import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/feedback_helper.dart';
import '../../../core/widgets/fx_confirm_sheet.dart';
import '../../../l10n/app_localizations.dart';
import '../providers/treinos_provider.dart';
import '../utils/semana_da_fila.dart';
import 'ficha_acoes.dart';
import 'ficha_vazia.dart';

/// Edição da semana que a ficha do aluno e o modelo fazem igual: adicionar,
/// "…" da sessão e do dia, mover, copiar e marcar descanso. Cada tela diz de
/// onde vem a semana e como grava.
mixin EditorDaSemana<W extends ConsumerStatefulWidget> on ConsumerState<W> {
  List<DiaDaSemana> get semanaAtual;

  bool get gravandoSemana;

  /// Liga e desliga o "ocupado" da tela durante uma cópia de sessão.
  void definirGravando(bool valor);

  /// Grava a semana inteira; devolve true quando gravou.
  Future<bool> gravarSemanaInteira(List<DiaDaSemana> dias);

  /// Busca a semana de novo (depois de renomear uma sessão, por exemplo).
  Future<void> recarregarSemana();

  Future<void> adicionarNoDia(int dia) async {
    final nome = await pedirNomeDaSessao(context);
    if (nome == null || !mounted) return;
    await gravarSemanaInteira(
      comSessaoNoDia(semanaAtual, dia: dia, sessao: SessaoDaSemana(nome: nome)),
    );
  }

  Future<void> menuDaSessao(int dia, int indice) async {
    final sessao = semanaAtual[dia - 1].sessoes[indice];
    final acao = await mostrarMenuDaSessao(
      context,
      nome: sessao.nome,
      podeCopiar: sessao.treinoId != null,
    );
    if (acao == null || !mounted) return;
    switch (acao) {
      case SessaoAcao.maisUm:
        await adicionarNoDia(dia);
      case SessaoAcao.renomear:
        await _renomear(sessao);
      case SessaoAcao.descanso:
        await marcarDescanso(dia);
      case SessaoAcao.mover:
        final para = await escolherDia(context, excluir: dia);
        if (para == null || !mounted) return;
        await gravarSemanaInteira(moverDia(semanaAtual, de: dia, para: para));
      case SessaoAcao.copiar:
        final para = await escolherDia(context);
        if (para == null || !mounted) return;
        await _copiarSessao(sessao, para);
    }
  }

  /// Dia sem sessão: "Treinar neste dia" (segue a sequência), adicionar ou marcar descanso.
  Future<void> menuDoDia(int dia) async {
    final atual = semanaAtual[dia - 1];
    final acao = await mostrarMenuDoDia(
      context,
      dia: nomesDosDias(S.of(context))[dia - 1],
      segue: atual.segueSequencia,
    );
    if (acao == null || !mounted) return;
    switch (acao) {
      case DiaAcao.adicionar:
        await adicionarNoDia(dia);
      case DiaAcao.treinar:
      case DiaAcao.descanso:
        await gravarSemanaInteira(alternarTreinoDescanso(semanaAtual, dia));
    }
  }

  /// Troca dias e divisão sem perder exercício (A com A); confirma se alguma sessão sai.
  Future<void> mudarDivisao() async {
    final s = S.of(context);
    final plano = await escolherDivisao(
      context,
      titulo: s.rotinaMudarDivisao,
      botao: s.rotinaMudarDivisao,
    );
    if (plano == null || !mounted) return;
    final troca = trocarDivisao(semanaAtual, plano.semana);
    if (troca.saem.isNotEmpty) {
      final ok = await showFxConfirmSheet(
        context,
        title: s.rotinaMudarDivisaoTitulo,
        message: s.rotinaMudarDivisaoSaem(troca.saem.map((x) => x.nome).join(', ')),
        confirmLabel: s.rotinaMudarDivisao,
        destructive: true,
      );
      if (!ok || !mounted) return;
    }
    await gravarSemanaInteira(troca.semana);
  }

  Future<void> marcarDescanso(int dia) async {
    final s = S.of(context);
    final ok = await showFxConfirmSheet(
      context,
      title: s.rotinaDescansoConfirmaTitulo,
      message: s.rotinaDescansoConfirmaTexto,
      confirmLabel: s.rotinaMarcarDescanso,
      destructive: true,
    );
    if (!ok || !mounted) return;
    await gravarSemanaInteira([
      for (final d in semanaAtual)
        d.dia == dia ? DiaDaSemana(dia: d.dia, descanso: true) : d,
    ]);
  }

  Future<void> _renomear(SessaoDaSemana sessao) async {
    final s = S.of(context);
    final nome = await pedirTexto(context, titulo: s.treinoRenomear, inicial: sessao.nome);
    if (nome == null || !mounted || sessao.treinoId == null) return;
    definirGravando(true);
    try {
      await ref.read(treinoRepositoryProvider).renomearTreino(sessao.treinoId!, nome);
      if (!mounted) return;
      definirGravando(false);
      await recarregarSemana();
    } catch (_) {
      if (!mounted) return;
      definirGravando(false);
      FeedbackHelper.showError(context, s.checkinNaoSalvou);
    }
  }

  Future<void> _copiarSessao(SessaoDaSemana sessao, int para) async {
    if (gravandoSemana || sessao.treinoId == null) return;
    definirGravando(true);
    try {
      final copia = await ref.read(treinoRepositoryProvider).duplicar(sessao.treinoId!);
      if (!mounted) return;
      definirGravando(false);
      await gravarSemanaInteira(
        comSessaoNoDia(
          semanaAtual,
          dia: para,
          sessao: SessaoDaSemana(
            treinoId: copia.id,
            nome: copia.nome,
            exerciciosCount: sessao.exerciciosCount,
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      definirGravando(false);
      FeedbackHelper.showError(context, S.of(context).checkinNaoSalvou);
    }
  }
}
