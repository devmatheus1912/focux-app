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
import '../../dashboard/providers/dashboard_provider.dart';
import '../data/checkin_repository.dart';
import '../providers/historico_provider.dart';
import '../utils/historico_detalhe_view.dart';
import '../utils/historico_fichas.dart';
import '../utils/historico_semanas.dart';
import '../widgets/historico_lista_widgets.dart';
import '../widgets/treinos_hub_rows.dart';

/// Sessões concluídas, semana a semana. Cada linha abre a própria sessão.
class HistoricoCheckinScreen extends ConsumerStatefulWidget {
  const HistoricoCheckinScreen({super.key});

  @override
  ConsumerState<HistoricoCheckinScreen> createState() =>
      _HistoricoCheckinScreenState();
}

class _HistoricoCheckinScreenState
    extends ConsumerState<HistoricoCheckinScreen> {
  int? _treinoId;

  HistoricoListaNotifier get _notifier =>
      ref.read(historicoListaProvider(_treinoId).notifier);

  Future<void> _refresh() async {
    final s = S.of(context);
    try {
      await _notifier.atualizar();
    } catch (_) {
      if (mounted) FeedbackHelper.showError(context, s.historicoAtualizarErro);
      return;
    }
    if (mounted) fxAnnounce(context, s.historicoAtualizado);
  }

  void _abrir(ExecucaoTreino execucao) {
    final id = execucao.id;
    if (id != null) context.push(historicoDetalhePath(id));
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final listaAsync = ref.watch(historicoListaProvider(_treinoId));
    final fichas = historicoFichasFiltro(
      ref.watch(alunoDashboardHomeProvider).value?.treinos ?? const [],
    );

    return fxScreenA11yScope(
      label: s.historicoTitulo,
      child: FxShellScaffold(
        useMesh: true,
        constrainWidth: false,
        appBar: FxShellAppBar(
          title: s.historicoTitulo,
          subtitle: listaAsync.when(
            skipLoadingOnReload: true,
            skipError: true,
            data: (l) => FxHubFreshness.fromFetchedAt(l.fetchedAt),
            loading: () => null,
            error: (_, __) => null,
          ),
          showBack: true,
          fallbackLocation: '/checkin/treinos',
        ),
        body: Column(
          children: [
            if (fichas.isNotEmpty)
              HistoricoFiltroFichas(
                fichas: fichas,
                selecionado: _treinoId,
                onSelect: (id) => setState(() => _treinoId = id),
              ),
            Expanded(
              child: FxAsyncBody<HistoricoLista>(
                value: listaAsync,
                skipLoadingOnReload: true,
                skipError: true,
                skeleton: const HistoricoSkeleton(),
                onRetry:
                    () => ref.invalidate(historicoListaProvider(_treinoId)),
                builder:
                    (context, lista) =>
                        _buildLista(context, lista, fichas, DateTime.now()),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLista(
    BuildContext context,
    HistoricoLista lista,
    List<HistoricoFicha> fichas,
    DateTime now,
  ) {
    final s = S.of(context);
    final semanas = agruparHistoricoPorSemana(
      lista.sessoes,
      now: now,
      temMais: lista.temMais,
    );
    final List<Widget> itens;
    if (semanas.isEmpty && !lista.temMais) {
      itens = [_vazio(s, fichas)];
    } else {
      itens = [
        for (final (i, semana) in semanas.indexed) ...[
          if (i > 0) const SizedBox(height: TokensStrip.s4),
          TreinosHubSecao(
            titulo: historicoSemanaCabecalho(s, semana),
            linhas: [
              for (final r in semana.sessoes)
                TreinoRecenteRow(
                  recente: r,
                  hoje: now,
                  onTap: () => _abrir(r.execucao),
                ),
            ],
          ),
        ],
        if (lista.temMais) ...[
          const SizedBox(height: TokensStrip.s3),
          HistoricoMaisRodape(
            key: ValueKey(lista.nextCursor),
            erro: lista.erroMais,
            onCarregar: _notifier.carregarMais,
          ),
        ],
      ];
    }

    return RefreshIndicator(
      onRefresh: _refresh,
      child: FxContentWidthLimiter(
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(TokensStrip.s4),
          children: itens,
        ),
      ),
    );
  }

  Widget _vazio(S s, List<HistoricoFicha> fichas) {
    final filtro = _treinoId;
    if (filtro != null) {
      final nome = fichas.where((f) => f.treinoId == filtro).firstOrNull?.nome;
      return FxEmptyState(
        icon: 'search',
        title: s.historicoFiltradoVazioTitulo(nome ?? ''),
        action: FxEmptyAction(
          label: s.historicoFiltradoVazioCta,
          onTap: () => setState(() => _treinoId = null),
        ),
      );
    }
    return FxEmptyState(
      icon: 'dumbbell',
      title: s.historicoVazioTitulo,
      subtitle: s.historicoVazioSubtitulo,
      action: FxEmptyAction(
        label: s.historicoVazioCta,
        onTap: () => safePopOrGo(context, '/checkin/treinos'),
      ),
    );
  }
}
