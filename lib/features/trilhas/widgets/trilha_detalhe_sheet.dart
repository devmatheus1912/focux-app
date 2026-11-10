import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/fx_icons.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../core/widgets/feedback_helper.dart';
import '../../../core/widgets/fx_grouped_action_sheet.dart';
import '../../../core/widgets/fx_home_sheet.dart';
import '../../../core/widgets/fx_input_deco.dart';
import '../../../core/widgets/fx_keyboard_dismiss_scope.dart';
import '../../../core/widgets/fx_sheet_frame.dart';
import '../../../core/widgets/fx_tonal_button.dart';
import '../models/trilha.dart';
import '../providers/trilhas_provider.dart';
import '../utils/trilhas_display.dart';
import 'trilha_cartao.dart';

/// O que o detalhe pede para a tela fazer depois de fechar.
enum TrilhaDetalheSaida { editar, excluir }

enum _AcaoEtapa { marcar, desfazer, remover }

/// Detalhe da trilha (mesma folha para personal e aluno). O personal marca,
/// desfaz, adiciona e remove etapas; o aluno marca a etapa atual ("Consegui")
/// e desfaz. Toda mudança chama [onMudou] para a lista se atualizar.
Future<TrilhaDetalheSaida?> showTrilhaDetalhe(
  BuildContext context, {
  required TrilhaModel trilha,
  required bool doPersonal,
  required ValueChanged<TrilhaModel> onMudou,
}) {
  return showFxHomeSheet<TrilhaDetalheSaida>(
    context,
    builder:
        (_) => _TrilhaDetalhe(
          inicial: trilha,
          doPersonal: doPersonal,
          onMudou: onMudou,
        ),
  );
}

class _TrilhaDetalhe extends ConsumerStatefulWidget {
  const _TrilhaDetalhe({
    required this.inicial,
    required this.doPersonal,
    required this.onMudou,
  });

  final TrilhaModel inicial;
  final bool doPersonal;
  final ValueChanged<TrilhaModel> onMudou;

  @override
  ConsumerState<_TrilhaDetalhe> createState() => _TrilhaDetalheState();
}

class _TrilhaDetalheState extends ConsumerState<_TrilhaDetalhe> {
  late TrilhaModel _trilha = widget.inicial;
  final _novaEtapa = TextEditingController();
  var _busy = false;

  @override
  void dispose() {
    _novaEtapa.dispose();
    super.dispose();
  }

  Future<void> _rodar(Future<TrilhaModel> Function() acao, {String? ok}) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final nova = await acao();
      if (!mounted) return;
      setState(() => _trilha = nova);
      widget.onMudou(nova);
      if (ok != null) FeedbackHelper.showSuccess(context, ok);
    } catch (e) {
      if (mounted) FeedbackHelper.showError(context, friendlyError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _marcar(MarcoModel etapa) async {
    HapticFeedback.mediumImpact();
    final repo = ref.read(trilhasRepositoryProvider);
    final eraUltima = trilhaEtapasFeitas(_trilha) == _trilha.marcos.length - 1;
    await _rodar(
      () => repo.concluirMarco(trilhaId: _trilha.id, marcoId: etapa.id),
    );
    if (!mounted || !_trilha.marcos.any((m) => m.id == etapa.id && m.concluido)) {
      return;
    }
    final msg =
        eraUltima
            ? 'Trilha concluída!'
            : widget.doPersonal
            ? 'Etapa marcada como feita.'
            : 'Etapa concluída. Seu personal vai ver.';
    FeedbackHelper.showSuccessAction(
      context,
      msg,
      actionLabel: 'Desfazer',
      onAction: () => _desfazer(etapa),
    );
  }

  Future<void> _desfazer(MarcoModel etapa) {
    final repo = ref.read(trilhasRepositoryProvider);
    return _rodar(
      () => repo.reabrirMarco(trilhaId: _trilha.id, marcoId: etapa.id),
      ok: 'Etapa desfeita.',
    );
  }

  Future<void> _remover(MarcoModel etapa) {
    final repo = ref.read(trilhasRepositoryProvider);
    return _rodar(
      () => repo.removerMarco(trilhaId: _trilha.id, marcoId: etapa.id),
      ok: 'Etapa removida.',
    );
  }

  Future<void> _adicionar() async {
    final titulo = _novaEtapa.text.trim();
    if (titulo.isEmpty) return;
    FxKeyboardDismissScope.dismiss();
    final repo = ref.read(trilhasRepositoryProvider);
    await _rodar(
      () => repo.adicionarMarco(trilhaId: _trilha.id, titulo: titulo),
      ok: 'Etapa adicionada.',
    );
    if (mounted) _novaEtapa.clear();
  }

  Future<void> _acoesDaEtapa(MarcoModel etapa) async {
    final podeRemover =
        widget.doPersonal && _trilha.marcos.length > trilhaEtapasMin;
    final escolha = await showFxGroupedActionSheet<_AcaoEtapa>(
      context,
      titulo: etapa.titulo,
      grupos: [
        FxActionGroup<_AcaoEtapa>(null, [
          if (etapa.concluido)
            const FxActionItem(
              valor: _AcaoEtapa.desfazer,
              rotulo: 'Desfazer',
              icone: FxIcons.desfazer,
            )
          else if (widget.doPersonal)
            const FxActionItem(
              valor: _AcaoEtapa.marcar,
              rotulo: 'Marcar como feita',
              icone: FxIcons.concluido,
            ),
          if (podeRemover)
            const FxActionItem(
              valor: _AcaoEtapa.remover,
              rotulo: 'Remover etapa',
              icone: FxIcons.excluir,
              perigo: true,
            ),
        ]),
      ],
    );
    switch (escolha) {
      case _AcaoEtapa.marcar:
        await _marcar(etapa);
      case _AcaoEtapa.desfazer:
        await _desfazer(etapa);
      case _AcaoEtapa.remover:
        await _remover(etapa);
      case null:
        break;
    }
  }

  Future<void> _maisDaTrilha() async {
    final escolha = await showFxGroupedActionSheet<TrilhaDetalheSaida>(
      context,
      titulo: _trilha.titulo,
      grupos: [
        FxActionGroup<TrilhaDetalheSaida>(null, const [
          FxActionItem(
            valor: TrilhaDetalheSaida.editar,
            rotulo: 'Editar trilha',
            icone: FxIcons.editar,
          ),
          FxActionItem(
            valor: TrilhaDetalheSaida.excluir,
            rotulo: 'Excluir trilha',
            icone: FxIcons.excluir,
            perigo: true,
          ),
        ]),
      ],
    );
    if (escolha != null && mounted) {
      FxHomeSheetChrome.dismissAndPop(context, escolha);
    }
  }

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.of(context);
    final etapas = trilhaEtapas(_trilha);
    final atual = trilhaEtapaAtual(_trilha);
    final prazo = trilhaPrazoLabel(_trilha, DateTime.now());
    final descricao = _trilha.descricao?.trim() ?? '';
    final podeAdicionar =
        widget.doPersonal && _trilha.marcos.length < trilhaEtapasMax;
    return FxSheetFrame(
      title: _trilha.titulo,
      subtitle: [
        trilhaResumoLinha(_trilha).split(' · ').first,
        if (prazo != null) prazo,
      ].join(' · '),
      leading: Icon(FxIcons.rota, color: chrome.brand, size: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.doPersonal)
            Align(
              alignment: Alignment.centerRight,
              child: IconButton(
                tooltip: 'Mais opções da trilha',
                icon: Icon(FxIcons.mais, color: chrome.mute),
                onPressed: _busy ? null : _maisDaTrilha,
              ),
            ),
          TrilhaSegmentos(trilha: _trilha),
          if (descricao.isNotEmpty) ...[
            const SizedBox(height: TokensStrip.s3),
            Text(descricao, style: FocuxHubTypography.body(color: chrome.ink)),
          ],
          const SizedBox(height: TokensStrip.s3),
          for (final (i, e) in etapas.indexed)
            _EtapaLinha(
              numero: i + 1,
              etapa: e,
              atual: e.id == atual?.id,
              ultima: i == etapas.length - 1,
              acaoLabel:
                  e.id == atual?.id
                      ? (widget.doPersonal ? 'Marcar' : 'Consegui')
                      : null,
              onAcao: _busy ? null : () => _marcar(e),
              onTap:
                  _busy
                      ? null
                      : (e.concluido || widget.doPersonal)
                      ? () => _acoesDaEtapa(e)
                      : null,
            ),
          if (podeAdicionar) ...[
            const SizedBox(height: TokensStrip.s3),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _novaEtapa,
                    enabled: !_busy,
                    textCapitalization: TextCapitalization.sentences,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _adicionar(),
                    onTapOutside: (_) => FxKeyboardDismissScope.dismiss(),
                    style: FocuxHubTypography.body(color: chrome.ink),
                    decoration: FxInputDeco.build(
                      context,
                      'Nova etapa',
                      hint: 'Ex.: Correr 4 km',
                    ),
                  ),
                ),
                const SizedBox(width: TokensStrip.s2),
                FxTonalButton(
                  label: 'Adicionar',
                  compact: true,
                  onPressed: _busy ? null : _adicionar,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _EtapaLinha extends StatelessWidget {
  const _EtapaLinha({
    required this.numero,
    required this.etapa,
    required this.atual,
    required this.ultima,
    required this.onTap,
    this.acaoLabel,
    this.onAcao,
  });

  final int numero;
  final MarcoModel etapa;
  final bool atual;
  final bool ultima;
  final String? acaoLabel;
  final VoidCallback? onAcao;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.of(context);
    final primary = Theme.of(context).colorScheme.primary;
    final feita = etapa.concluido;
    final feitaEm = etapa.concluidoEm;
    return Semantics(
      label:
          'Etapa $numero: ${etapa.titulo}. '
          '${feita ? 'Feita' : atual ? 'Etapa atual' : 'A fazer'}',
      child: InkWell(
        onTap: onTap,
        onLongPress: onTap,
        child: Container(
          decoration: BoxDecoration(
            border:
                ultima
                    ? null
                    : Border(bottom: BorderSide(color: chrome.line)),
          ),
          padding: const EdgeInsets.symmetric(vertical: TokensStrip.s2),
          child: Row(
            children: [
              SizedBox.square(
                dimension: 28,
                child:
                    feita
                        ? Icon(FxIcons.concluido, color: primary, size: 24)
                        : DecoratedBox(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: atual ? primary : chrome.line,
                              width: atual ? 2 : 1,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              '$numero',
                              style: FocuxHubTypography.rotulo(
                                color: atual ? primary : chrome.mute,
                              ),
                            ),
                          ),
                        ),
              ),
              const SizedBox(width: TokensStrip.s2),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      etapa.titulo,
                      style:
                          atual
                              ? FocuxHubTypography.cardTitle(color: chrome.ink)
                              : FocuxHubTypography.body(
                                color: feita ? chrome.mute : chrome.ink,
                              ),
                    ),
                    if (feita && feitaEm != null)
                      Text(
                        'feita em ${trilhaDiaMes(feitaEm)}',
                        style: FocuxHubTypography.bodyMuted(color: chrome.mute),
                      ),
                  ],
                ),
              ),
              if (acaoLabel != null)
                FxTonalButton(
                  label: acaoLabel!,
                  compact: true,
                  onPressed: onAcao,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
