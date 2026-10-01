import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/safe_navigation.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/utils/a11y_announce.dart';
import '../../../core/ux/fx_hub_freshness.dart';
import '../../../core/widgets/feedback_helper.dart';
import '../../../core/widgets/fx_async_body.dart';
import '../../../core/widgets/fx_content_width_limiter.dart';
import '../../../core/widgets/fx_empty_state.dart';
import '../../../core/widgets/fx_screen_a11y.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../../l10n/app_localizations.dart';
import '../../dashboard/data/dashboard_repository.dart';
import '../../dashboard/providers/dashboard_provider.dart';
import '../data/checkin_repository.dart';
import '../utils/historico_detalhe_view.dart';
import '../utils/treino_ficha_status.dart';
import '../utils/treinos_hub_view.dart';
import '../widgets/treino_preparacao_sheet.dart';
import '../widgets/treinos_destaque_card.dart';
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
      blocos = [
        FxEmptyState(
          icon: 'dumbbell',
          title: s.treinosHubVazioTitulo,
          subtitle: s.treinosHubVazioSubtitulo,
          action: FxEmptyAction(
            label: s.treinosHubVazioCta,
            onTap: () => openAlunoRoute(context, '/chat/aluno'),
          ),
        ),
      ];
    } else {
      blocos = _blocos(s, _viewFor(home, now), now);
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

  /// Só entra bloco com conteúdo: nenhum espaçamento sobra quando um some.
  List<Widget> _blocos(S s, TreinosHubView view, DateTime now) {
    final destaque = view.destaque;
    final depois = view.depois;
    return [
      if (destaque != null)
        TreinosDestaqueCard(
          destaque: destaque,
          hoje: now,
          onOpen: switch (destaque.tipo) {
            TreinosDestaqueTipo.concluidoHoje =>
              () => _abrirExecucao(destaque.treino),
            TreinosDestaqueTipo.emPreparacao => null,
            _ => () => _abrirPrevia(destaque.treino),
          },
          onAction: switch (destaque.tipo) {
            TreinosDestaqueTipo.concluidoHoje =>
              () => _abrirExecucao(destaque.treino),
            _ => () => _executar(destaque.treino),
          },
        ),
      if (depois != null)
        TreinosHubSecao(
          titulo: s.treinosDepoisTitulo,
          linhas: [
            TreinoDepoisRow(
              treino: depois,
              onTap: () => _abrirPrevia(depois),
              onIniciar: () => _executar(depois),
            ),
          ],
        ),
      if (view.plano.isNotEmpty)
        TreinosHubSecao(
          titulo: s.treinosPlanoTitulo,
          linhas: [
            for (final t in view.plano)
              TreinoPlanoRow(treino: t, hoje: now, onTap: () => _abrirFicha(t)),
          ],
        ),
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
}
