import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/widgets/feedback_helper.dart';
import '../../../core/widgets/fx_confirm_sheet.dart';
import '../../../core/widgets/fx_help.dart';
import '../../../core/widgets/fx_loading.dart';
import '../../../core/widgets/fx_screen_a11y.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../../core/widgets/fx_sticky_actions.dart';
import '../../../l10n/app_localizations.dart';
import '../models/ficha_modelo.dart';
import '../providers/ficha_modelos_provider.dart';
import '../providers/ficha_volume_provider.dart';
import '../utils/semana_da_fila.dart';
import '../utils/semana_do_modelo.dart';
import '../utils/treino_criacao_fluxo.dart';
import '../widgets/editor_da_semana.dart';
import '../widgets/ficha_acoes.dart';
import '../widgets/ficha_help_sheets.dart';
import '../widgets/ficha_semana.dart';
import '../widgets/ficha_vazia.dart';
import '../widgets/ficha_volume_secao.dart';
import '../widgets/modelo_acoes.dart';
import '../../../core/widgets/fx_tonal_button.dart';

/// Um modelo de ficha: a semana inteira, editada como a ficha de um aluno.
class FichaModeloScreen extends ConsumerStatefulWidget {
  const FichaModeloScreen({super.key, required this.modeloId});

  final int modeloId;

  @override
  ConsumerState<FichaModeloScreen> createState() => _FichaModeloScreenState();
}

class _FichaModeloScreenState extends ConsumerState<FichaModeloScreen>
    with EditorDaSemana<FichaModeloScreen> {
  var _ocupado = false;

  /// Semana gravada nesta tela; nula = a que veio do servidor.
  List<DiaDaSemana>? _semana;
  FichaModelo? _modelo;
  PlanoDaFicha? _plano;

  void _recarregar() {
    _semana = null;
    ref.invalidate(fichaModeloProvider(widget.modeloId));
    ref.invalidate(modeloVolumeProvider(widget.modeloId));
    ref.invalidate(fichaModelosProvider);
  }

  @override
  List<DiaDaSemana> get semanaAtual =>
      _semana ?? (_modelo == null ? semanaVazia() : semanaDoModelo(_modelo!));

  @override
  bool get gravandoSemana => _ocupado;

  @override
  void definirGravando(bool valor) => setState(() => _ocupado = valor);

  @override
  Future<bool> gravarSemanaInteira(List<DiaDaSemana> dias) async {
    if (_ocupado) return false;
    setState(() {
      _ocupado = true;
      _semana = dias;
    });
    try {
      final gravado = await ref
          .read(fichaModeloRepositoryProvider)
          .gravarSemana(widget.modeloId, dias);
      if (!mounted) return true;
      setState(() {
        _modelo = gravado;
        _semana = semanaDoModelo(gravado);
        _ocupado = false;
      });
      ref.invalidate(fichaModeloProvider(widget.modeloId));
      ref.invalidate(modeloVolumeProvider(widget.modeloId));
      ref.invalidate(fichaModelosProvider);
      return true;
    } catch (_) {
      if (!mounted) return false;
      setState(() {
        _ocupado = false;
        _semana = null;
      });
      FeedbackHelper.showError(context, S.of(context).checkinNaoSalvou);
      return false;
    }
  }

  @override
  Future<void> recarregarSemana() async => setState(_recarregar);

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final async = ref.watch(fichaModeloProvider(widget.modeloId));
    final carregado = async.asData?.value;
    if (carregado != null && !_ocupado) _modelo = carregado;
    final modelo = _modelo;

    return fxScreenA11yScope(
      label: s.modeloTitulo,
      child: FxShellScaffold(
        appBar: FxShellAppBar(
          title: modelo?.nome ?? s.modeloTitulo,
          actions: [
            FxHelpIconButton(
              tooltip: 'Sobre o modelo',
              onTap: () => showModeloHelpSheet(context),
            ),
            if (modelo != null)
              IconButton(
                tooltip: s.rotinaMenuFicha,
                onPressed: _ocupado ? null : () => _menu(modelo),
                icon: const Icon(Icons.more_horiz_rounded),
              ),
          ],
        ),
        body: modelo == null
            ? async.hasError
                  ? Center(
                      child: FxTonalButton(
                        label: s.modeloNaoAbriu,
                        onPressed: _recarregar,
                        compact: true,
                      ),
                    )
                  : const Center(child: FxLoading())
            : _corpo(s, ShellChrome.of(context), modelo),
      ),
    );
  }

  Widget _corpo(S s, ShellPalette chrome, FichaModelo modelo) {
    final dias = semanaAtual;
    final vazia = estadoDaFicha(dias).vazia;
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
              if (vazia)
                FichaVazia(
                  ocupado: _ocupado,
                  mostrarPrazo: false,
                  onPlano: (plano) => setState(() => _plano = plano),
                )
              else ...[
                FichaSemana(
                  dias: dias,
                  hoje: 0,
                  ocupado: _ocupado,
                  onAbrir: _abrirSessao,
                  onAdicionar: adicionarNoDia,
                  onMais: menuDaSessao,
                  onMaisDoDia: menuDoDia,
                ),
                const SizedBox(height: TokensStrip.s3),
                FichaVolumeSecao(
                  provider: modeloVolumeProvider(widget.modeloId),
                  origem: 'modelo',
                ),
              ],
            ],
          ),
        ),
        FxStickyActions(
          primaryLabel: vazia ? s.modeloCriarSemana : s.modeloAplicarEmAluno,
          loading: _ocupado,
          onPrimary: !vazia
              ? () => aplicarModeloEmAluno(context, ref, modelo)
              : _plano == null
              ? null
              : () async {
                  if (await gravarSemanaInteira(_plano!.semana)) _plano = null;
                },
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
    setState(_recarregar);
  }

  Future<void> _menu(FichaModelo modelo) async {
    final acao = await mostrarMenuDoModelo(context, nome: modelo.nome);
    if (acao == null || !mounted) return;
    switch (acao) {
      case ModeloAcao.aplicar:
        await aplicarModeloEmAluno(context, ref, modelo);
      case ModeloAcao.renomear:
        await renomearModelo(context, ref, modelo);
      case ModeloAcao.recomecar:
        await _recomecar();
      case ModeloAcao.excluir:
        if (await excluirModelo(context, ref, modelo) && mounted) context.pop();
    }
  }

  Future<void> _recomecar() async {
    final s = S.of(context);
    final ok = await showFxConfirmSheet(
      context,
      title: s.modeloRecomecarTitulo,
      message: s.modeloRecomecarTexto,
      confirmLabel: s.modeloRecomecar,
      destructive: true,
    );
    if (!ok || !mounted) return;
    await gravarSemanaInteira(semanaVazia());
  }
}
