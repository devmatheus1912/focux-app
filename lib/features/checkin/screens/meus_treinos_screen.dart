import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/utils/a11y_announce.dart';
import '../../../core/ux/fx_hub_freshness.dart';
import '../../../core/widgets/feedback_helper.dart';
import '../../../core/widgets/fx_async_body.dart';
import '../../../core/widgets/fx_content_width_limiter.dart';
import '../../../core/widgets/fx_screen_a11y.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../../l10n/app_localizations.dart';
import '../../dashboard/data/dashboard_repository.dart';
import '../../dashboard/providers/dashboard_provider.dart';
import '../../dashboard/utils/aluno_ritmo_linha.dart';
import '../data/checkin_repository.dart';
import '../utils/historico_detalhe_view.dart';
import '../utils/treino_ficha_status.dart';
import '../utils/treinos_hub_view.dart';
import '../widgets/sua_semana_rows.dart';
import '../widgets/treino_preparacao_sheet.dart';
import '../widgets/treinos_hoje_acao.dart';
import '../widgets/treinos_hoje_linha.dart';
import '../widgets/treinos_hub_rows.dart';
import '../widgets/treinos_hub_skeleton.dart';

/// Aba Treinos do aluno: lê só o agregado da Home (`/api/dashboard/aluno/home`).
class MeusTreinosScreen extends ConsumerStatefulWidget {
  const MeusTreinosScreen({super.key});

  @override
  ConsumerState<MeusTreinosScreen> createState() => _MeusTreinosScreenState();
}

class _MeusTreinosScreenState extends ConsumerState<MeusTreinosScreen> {
  ({AlunoDashboardHomeBundle home, TreinosHubView view})? _memo;
  Timer? _virada;
  var _abrindo = false;

  @override
  void dispose() {
    _virada?.cancel();
    super.dispose();
  }

  /// Memo até a meia-noite: com a aba aberta, a virada do dia redesenha.
  TreinosHubView _viewFor(AlunoDashboardHomeBundle home, DateTime now) {
    final memo = _memo;
    if (memo != null &&
        identical(memo.home, home) &&
        now.isBefore(memo.view.validaAte)) {
      return memo.view;
    }
    final view = buildTreinosHubView(
      treinos: home.treinos,
      historico: home.historico,
      now: now,
      rotina: home.rotina,
    );
    _memo = (home: home, view: view);
    _virada?.cancel();
    _virada = Timer(
      view.validaAte.difference(now) + const Duration(seconds: 1),
      () {
        if (mounted) setState(() {});
      },
    );
    return view;
  }

  /// Execução e prévia mudam a sessão: ao voltar, relê o agregado.
  Future<void> _executar(ExecucaoTreino treino) async {
    if (_abrindo) return;
    _abrindo = true;
    await context.push('/checkin/executar', extra: treino.treinoId);
    _abrindo = false;
    if (mounted) invalidateAlunoDashboardHome(ref);
  }

  /// A prévia fecha com `true` para iniciar: a execução abre daqui, e ao
  /// concluir o aluno volta ao hub, não à prévia do treino que acabou de fazer.
  Future<void> _abrirPrevia(ExecucaoTreino treino) async {
    if (_abrindo) return;
    _abrindo = true;
    final iniciar = await context.push<bool>(treinoPreviaPath(treino.treinoId));
    _abrindo = false;
    if (!mounted) return;
    if (iniciar == true) {
      await _executar(treino);
    } else {
      invalidateAlunoDashboardHome(ref);
    }
  }

  void _abrirFicha(ExecucaoTreino treino) {
    if (isTreinoAguardandoLiberacao(treino)) {
      showTreinoPreparacaoSheet(context, treinoNome: treino.treinoNome);
      return;
    }
    _abrirPrevia(treino);
  }

  Future<void> _descartar(ExecucaoTreino aberta, {ExecucaoTreino? depois}) async {
    final ok = await descartarSessaoAberta(context, ref, aberta, depois: depois);
    if (!ok || !mounted) return;
    invalidateAlunoDashboardHome(ref);
    if (depois != null) await _executar(depois);
  }

  void _abrirExecucao(ExecucaoTreino execucao) {
    final id = execucao.id;
    context.push(id == null ? '/checkin/historico' : historicoDetalhePath(id));
  }

  Future<void> _refresh() async {
    final s = S.of(context);
    try {
      await refreshAlunoDashboardHome(ref);
    } catch (_) {
      if (mounted) FeedbackHelper.showError(context, s.treinosHubAtualizarErro);
      return;
    }
    if (mounted) fxAnnounce(context, s.treinosHubAtualizado);
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final homeAsync = ref.watch(alunoDashboardHomeProvider);

    return fxScreenA11yScope(
      label: s.treinosHubTitulo,
      child: FxShellScaffold(
        useMesh: true,
        constrainWidth: false,
        appBar: FxShellAppBar(
          title: s.treinosHubTitulo,
          subtitle: homeAsync.when(
            skipLoadingOnReload: true,
            skipError: true,
            data: (home) => FxHubFreshness.fromFetchedAt(home.fetchedAt),
            loading: () => null,
            error: (_, __) => null,
          ),
          showBack: false,
          actions: [
            const TreinosAjudaBotao(),
          ],
        ),
        body: FxAsyncBody<AlunoDashboardHomeBundle>(
          value: homeAsync,
          skipLoadingOnReload: true,
          skipError: true,
          skeleton: const TreinosHubSkeleton(),
          onRetry: () => ref.invalidate(alunoDashboardHomeProvider),
          builder: (context, home) => _buildHub(context, home, DateTime.now()),
        ),
      ),
    );
  }

  Widget _buildHub(
    BuildContext context,
    AlunoDashboardHomeBundle home,
    DateTime now,
  ) {
    final s = S.of(context);
    final List<Widget> blocos;
    if (home.treinos.isEmpty) {
      blocos = const [TreinosHubVazio()];
    } else {
      blocos = _blocos(s, _viewFor(home, now), now, home.treinos, home);
    }

    return RefreshIndicator(
      onRefresh: _refresh,
      child: FxContentWidthLimiter(
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(TokensStrip.s4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final (i, bloco) in blocos.indexed) ...[
                if (i > 0) const SizedBox(height: TokensStrip.s4),
                bloco,
              ],
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _blocos(
    S s,
    TreinosHubView view,
    DateTime now,
    List<ExecucaoTreino> treinos,
    AlunoDashboardHomeBundle home,
  ) {
    final destaque = view.destaque;
    final ordem = destaque != null && destaque.ordemTotal > 1
        ? (destaque.ordem, destaque.ordemTotal)
        : treinosDestaqueOrdem(destaque, treinos);
    final proximoNome = destaque?.depoisNome ?? treinosProximoNome(view, treinos);
    final comSemana = home.rotina.temTreino;
    final abrirHoje = _aoAbrirHoje(destaque);
    final fazerHoje = _aoFazerHoje(destaque, view);
    final semana = alunoRitmoDaSemana(s, home);
    final jaTreinou = treinosJaTreinou(home.historico);
    final foraDaSemana = treinosForaDaSemana(view.plano, home.rotina);
    return [
      if (view.sessaoAntiga case final aberta?)
        TreinosSessaoAbertaAviso(
          nome: aberta.treinoNome,
          onContinuar: () => _executar(aberta),
          onDescartar: () => _descartar(aberta),
        ),
      if (destaque != null && !comSemana)
        TreinosHojeLinha(
          destaque: destaque,
          hoje: now,
          proximoNome: proximoNome,
          ordem: ordem?.$1,
          ordemTotal: ordem?.$2,
          onOpen: abrirHoje,
          onAction: fazerHoje,
        ),
      if (comSemana)
        SuaSemanaBloco(
          rotina: home.rotina,
          hoje: now,
          historico: home.historico,
          onAbrirSessao: (treinoId) {
            final t = treinos.where((x) => x.treinoId == treinoId).firstOrNull;
            return t == null ? null : () => _abrirFicha(t);
          },
          acaoDeHoje: acaoDeHoje(
            s,
            view,
            now,
            proximoNome: proximoNome,
            ordem: ordem,
            aoFazer: fazerHoje,
            aoAbrir: abrirHoje,
            aoComecarDescartando: (aberta, hoje) => _descartar(aberta, depois: hoje),
          ),
        ),
      if (jaTreinou && semana != null)
        TreinosRitmoLinha(titulo: semana.titulo, frase: semana.frase),
      ...treinosProximaSessao(home.agendaProximoInicio, now),
      if (foraDaSemana.isNotEmpty)
        TreinosHubSecao(
          titulo: s.treinosPlanoTitulo,
          linhas: [
            for (final t in foraDaSemana)
              TreinoPlanoRow(treino: t, hoje: now, onTap: () => _abrirFicha(t)),
          ],
        ),
      if (view.ultimos.isEmpty) TreinosVerHistoricoLink(view.destaque),
      if (view.ultimos.isNotEmpty)
        TreinosHubSecao(
          titulo: s.treinosUltimosTitulo,
          acaoLabel: s.treinosVerHistorico,
          onAcao: () => context.push('/checkin/historico'),
          linhas: [
            for (final r in view.ultimos)
              TreinoRecenteRow(
                recente: r,
                hoje: now,
                onTap: () => _abrirExecucao(r.execucao),
              ),
          ],
        ),
    ];
  }

  VoidCallback? _aoAbrirHoje(TreinosDestaque? destaque) {
    if (destaque == null) return null;
    return switch (destaque.tipo) {
      TreinosDestaqueTipo.concluidoHoje => () => _abrirExecucao(destaque.treino),
      TreinosDestaqueTipo.emPreparacao => null,
      _ => () => _abrirPrevia(destaque.treino),
    };
  }

  VoidCallback _aoFazerHoje(TreinosDestaque? destaque, TreinosHubView view) {
    if (destaque == null) return () {};
    return switch (destaque.tipo) {
      TreinosDestaqueTipo.concluidoHoje when view.depois != null =>
        () => _executar(view.depois!),
      TreinosDestaqueTipo.concluidoHoje => () => _abrirExecucao(destaque.treino),
      _ => () => _executar(destaque.treino),
    };
  }
}
