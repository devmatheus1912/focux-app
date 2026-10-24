import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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
import '../../alunos/providers/alunos_provider.dart';
import '../models/ficha_modelo.dart';
import '../providers/ficha_modelos_provider.dart';
import '../providers/treinos_provider.dart';
import '../utils/semana_do_modelo.dart';
import '../utils/treino_criacao_fluxo.dart';
import '../widgets/ficha_acoes.dart';
import '../widgets/ficha_semana.dart';

/// Um modelo de ficha: a semana inteira, com as sessões prontas para montar.
class FichaModeloScreen extends ConsumerStatefulWidget {
  const FichaModeloScreen({super.key, required this.modeloId});

  final int modeloId;

  @override
  ConsumerState<FichaModeloScreen> createState() => _FichaModeloScreenState();
}

class _FichaModeloScreenState extends ConsumerState<FichaModeloScreen> {
  var _ocupado = false;

  void _recarregar() {
    ref.invalidate(fichaModeloProvider(widget.modeloId));
    ref.invalidate(fichaModelosProvider);
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final async = ref.watch(fichaModeloProvider(widget.modeloId));
    final modelo = async.asData?.value;

    return fxScreenA11yScope(
      label: s.modeloTitulo,
      child: FxShellScaffold(
        appBar: FxShellAppBar(
          title: modelo?.nome ?? s.modeloTitulo,
          actions: [
            if (modelo != null)
              IconButton(
                tooltip: s.rotinaMenuFicha,
                onPressed: _ocupado ? null : () => _menu(modelo),
                icon: const Icon(Icons.more_horiz_rounded),
              ),
          ],
        ),
        body: async.when(
          loading: () => const Center(child: FxLoading()),
          error: (_, __) => Center(
            child: TextButton(
              onPressed: _recarregar,
              child: Text(s.modeloNaoAbriu),
            ),
          ),
          data: (modelo) => _corpo(s, ShellChrome.of(context), modelo),
        ),
      ),
    );
  }

  Widget _corpo(S s, ShellPalette chrome, FichaModelo modelo) {
    final contagem = s.modeloContagem(modelo.sessoes.length, modelo.totalExercicios);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(TokensStrip.s4),
            children: [
              Text(
                modelo.nome,
                style: FocuxHubTypography.pageTitle(context, color: chrome.ink),
              ),
              const SizedBox(height: TokensStrip.s1),
              Text(
                '$contagem · ${modelo.pronto ? s.modeloPronto : s.modeloEmMontagem}',
                style: FocuxHubTypography.bodyMuted(color: chrome.mute),
              ),
              const SizedBox(height: TokensStrip.s4),
              FichaSemana(
                dias: semanaDoModelo(modelo),
                hoje: 0,
                ocupado: _ocupado,
                onAbrir: _abrirSessao,
              ),
            ],
          ),
        ),
        FxStickyActions(
          primaryLabel: s.modeloAplicarEmAluno,
          loading: _ocupado,
          onPrimary: () => _aplicar(modelo),
        ),
      ],
    );
  }

  Future<void> _abrirSessao(int treinoId) async {
    await context.push(
      '/treinos/$treinoId',
      extra: TreinoRouteExtra(modeloId: widget.modeloId).toExtra(),
    );
    if (!mounted) return;
    _recarregar();
  }

  Future<void> _menu(FichaModelo modelo) async {
    final acao = await mostrarMenuDoModelo(context, nome: modelo.nome);
    if (acao == null || !mounted) return;
    switch (acao) {
      case ModeloAcao.aplicar:
        await _aplicar(modelo);
      case ModeloAcao.renomear:
        await _renomear(modelo);
      case ModeloAcao.excluir:
        await _excluir();
    }
  }

  Future<void> _renomear(FichaModelo modelo) async {
    final s = S.of(context);
    final nome = await pedirTexto(
      context,
      titulo: s.rotinaModeloNomeTitulo,
      inicial: modelo.nome,
    );
    if (nome == null || !mounted) return;
    await _executar(() async {
      await ref.read(fichaModeloRepositoryProvider).renomear(modelo.id, nome);
      _recarregar();
    });
  }

  Future<void> _excluir() async {
    final s = S.of(context);
    final ok = await showFxConfirmSheet(
      context,
      title: s.modeloExcluirTitulo,
      message: s.modeloExcluirTexto,
      confirmLabel: s.modeloExcluir,
      destructive: true,
    );
    if (!ok || !mounted) return;
    await _executar(() async {
      await ref.read(fichaModeloRepositoryProvider).arquivar(widget.modeloId);
      ref.invalidate(fichaModelosProvider);
      if (mounted) context.pop();
    });
  }

  Future<void> _aplicar(FichaModelo modelo) async {
    final s = S.of(context);
    final alunos = await ref.read(alunosProvider.future);
    if (!mounted) return;
    final destino = await escolherAluno(context, alunos: alunos, excluirId: -1);
    if (destino == null || !mounted) return;
    final manterCargas = await escolherCargas(context);
    if (manterCargas == null || !mounted) return;
    final ok = await showFxConfirmSheet(
      context,
      title: s.rotinaAplicarConfirmaTitulo,
      message: s.rotinaAplicarConfirmaTexto,
      confirmLabel: s.modeloAplicarEmAluno,
      destructive: true,
    );
    if (!ok || !mounted) return;
    final nome = alunos.where((a) => a.id == destino).map((a) => a.nome).firstOrNull ?? '';
    await _executar(() async {
      await ref
          .read(fichaModeloRepositoryProvider)
          .aplicar(modelo.id, destino, manterCargas: manterCargas);
      ref.invalidate(alunoRotinaProvider(destino));
      if (mounted) FeedbackHelper.showSuccess(context, s.modeloAplicado(nome));
    });
  }

  Future<void> _executar(Future<void> Function() acao) async {
    if (_ocupado) return;
    setState(() => _ocupado = true);
    try {
      await acao();
    } catch (_) {
      if (mounted) FeedbackHelper.showError(context, S.of(context).checkinNaoSalvou);
    } finally {
      if (mounted) setState(() => _ocupado = false);
    }
  }
}
