import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/analytics/analytics_service.dart';
import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/widgets/feedback_helper.dart';
import '../../../core/widgets/fx_confirm_sheet.dart';
import '../../../core/widgets/fx_loading.dart';
import '../../../core/widgets/fx_screen_a11y.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../../core/widgets/fx_sticky_actions.dart';
import '../../../l10n/app_localizations.dart';
import '../models/ficha_historico.dart';
import '../providers/ficha_historico_provider.dart';
import '../providers/treinos_provider.dart';
import '../utils/ficha_historico_textos.dart';
import '../widgets/ficha_acoes.dart';
import '../widgets/ficha_semana.dart';
import '../../../core/widgets/fx_tonal_button.dart';

/// Uma ficha anterior como era: só leitura, com "Usar como base".
class FichaAnteriorScreen extends ConsumerStatefulWidget {
  const FichaAnteriorScreen({
    super.key,
    required this.alunoId,
    required this.alunoNome,
    required this.fichaId,
  });

  final int alunoId;
  final String alunoNome;
  final int fichaId;

  @override
  ConsumerState<FichaAnteriorScreen> createState() => _FichaAnteriorScreenState();
}

class _FichaAnteriorScreenState extends ConsumerState<FichaAnteriorScreen> {
  var _ocupado = false;

  ({int alunoId, int fichaId}) get _chave =>
      (alunoId: widget.alunoId, fichaId: widget.fichaId);

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final async = ref.watch(fichaAnteriorProvider(_chave));

    return fxScreenA11yScope(
      label: s.historicoDetalheTitulo,
      child: FxShellScaffold(
        appBar: FxShellAppBar(title: s.historicoDetalheTitulo),
        body: async.when(
          loading: () => const Center(child: FxLoading()),
          error: (_, __) => Center(
            child: FxTonalButton(label: s.historicoNaoAbriu, onPressed: () => ref.invalidate(fichaAnteriorProvider(_chave)), compact: true),
          ),
          data: (ficha) => _corpo(s, ShellChrome.of(context), ficha),
        ),
      ),
    );
  }

  Widget _corpo(S s, ShellPalette chrome, FichaHistorico ficha) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(TokensStrip.s4),
            children: [
              Text(
                periodoDaFicha(s, ficha),
                style: FocuxHubTypography.pageTitle(context, color: chrome.ink),
              ),
              const SizedBox(height: TokensStrip.s1),
              Text(
                '${motivoDaFicha(s, ficha)} · ${s.modeloContagem(ficha.sessoes, ficha.exercicios)}',
                style: FocuxHubTypography.bodyMuted(color: chrome.mute),
              ),
              const SizedBox(height: TokensStrip.s4),
              FichaSemana(
                dias: semanaDaFichaAnterior(s, ficha),
                hoje: 0,
                ocupado: false,
                alertarVazia: false,
                onAbrir: (_) {},
              ),
            ],
          ),
        ),
        FxStickyActions(
          primaryLabel: s.historicoUsarComoBase,
          loading: _ocupado,
          onPrimary: ficha.temSessaoDisponivel ? () => _usar(ficha) : null,
        ),
      ],
    );
  }

  Future<void> _usar(FichaHistorico ficha) async {
    final s = S.of(context);
    final manterCargas = await escolherCargas(context);
    if (manterCargas == null || !mounted) return;
    final ok = await showFxConfirmSheet(
      context,
      title: s.historicoUsarConfirmaTitulo,
      message: s.historicoUsarConfirmaTexto,
      confirmLabel: s.historicoUsarComoBase,
      destructive: true,
    );
    if (!ok || !mounted) return;
    final router = GoRouter.of(context);
    setState(() => _ocupado = true);
    try {
      final uso = await ref
          .read(fichaHistoricoRepositoryProvider)
          .usar(widget.alunoId, ficha.id, manterCargas: manterCargas);
      AnalyticsService.instance.track(
        ProductEvents.fichaHistoricoUsada,
        props: {'motivo': ficha.motivo.name},
      );
      ref.invalidate(alunoRotinaProvider(widget.alunoId));
      ref.invalidate(fichasAnterioresProvider(widget.alunoId));
      if (!mounted) return;
      FeedbackHelper.showSuccess(
        context,
        uso.semSessao.isEmpty
            ? s.historicoUsada
            : s.historicoUsadaSemSessoes(uso.semSessao.length),
      );
      router.pop();
      router.pop();
    } catch (_) {
      if (!mounted) return;
      setState(() => _ocupado = false);
      FeedbackHelper.showError(context, s.checkinNaoSalvou);
    }
  }
}
