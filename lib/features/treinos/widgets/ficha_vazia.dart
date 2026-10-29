import 'package:flutter/material.dart';

import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/widgets/fx_action_link.dart';
import '../../../core/widgets/fx_action_sheet.dart';
import '../../../core/widgets/fx_choice_chip.dart';
import '../../../core/widgets/fx_choice_strip.dart';
import '../../../core/widgets/fx_link_row.dart';
import '../../../core/widgets/fx_tap_row.dart';
import '../../../l10n/app_localizations.dart';
import '../models/ficha_modelo.dart';
import '../utils/divisao_catalogo.dart';
import '../utils/semana_da_fila.dart';
import 'ficha_acoes.dart';

/// O que o personal escolheu em "Montar do zero": a semana e por quantas semanas vale.
class PlanoDaFicha {
  const PlanoDaFicha({required this.semana, required this.semanas});

  final List<DiaDaSemana> semana;

  /// Nulo = sem prazo.
  final int? semanas;
}

/// Ficha vazia: usar um modelo, montar do zero (dias → divisão → prévia) ou copiar de outro aluno.
/// A tela dona desenha "Criar ficha" com o [PlanoDaFicha] que chega em [onPlano].
class FichaVazia extends StatefulWidget {
  const FichaVazia({
    super.key,
    required this.modelos,
    required this.ocupado,
    required this.onUsarModelo,
    required this.onVerModelos,
    required this.onCopiarDeAluno,
    required this.onPlano,
  });

  final List<FichaModelo> modelos;
  final bool ocupado;
  final ValueChanged<FichaModelo> onUsarModelo;
  final VoidCallback onVerModelos;
  final VoidCallback onCopiarDeAluno;
  final ValueChanged<PlanoDaFicha?> onPlano;

  static const modelosVisiveis = 3;

  @override
  State<FichaVazia> createState() => _FichaVaziaState();
}

class _FichaVaziaState extends State<FichaVazia> {
  List<int> _diasDeTreino = const [];
  Divisao? _divisao;
  var _outrasAbertas = false;

  /// 0 = sem prazo.
  var _semanas = 8;

  int get _dias => _diasDeTreino.length;

  void _avisar() {
    final divisao = _divisao;
    widget.onPlano(
      divisao == null
          ? null
          : PlanoDaFicha(
              semana: semanaPorDivisao(_diasDeTreino, divisao),
              semanas: _semanas == 0 ? null : _semanas,
            ),
    );
  }

  void _escolherDias(int dias) {
    setState(() {
      _diasDeTreino = [...?diasPorFrequencia[dias]];
      _divisao = divisoesSugeridas(dias).firstOrNull;
      _outrasAbertas = false;
    });
    _avisar();
  }

  /// Mantém a divisão se ela ainda cabe nos dias; senão volta à recomendada.
  void _alternarDia(int dia) {
    final novos = _diasDeTreino.contains(dia)
        ? (_diasDeTreino.where((d) => d != dia).toList())
        : [..._diasDeTreino, dia];
    if (novos.length < 2) return;
    novos.sort();
    setState(() {
      _diasDeTreino = novos;
      final atual = _divisao;
      if (atual == null || atual.letras > novos.length) {
        _divisao = divisoesSugeridas(novos.length).firstOrNull;
      }
    });
    _avisar();
  }

  Future<void> _mudarPrazo() async {
    final s = S.of(context);
    final escolha = await showFxActionSheet<int>(
      context,
      title: s.valePorTitulo,
      itens: [
        for (final n in const [4, 8, 12])
          FxActionSheetItem(value: n, label: s.valePorSemanas(n), icon: Icons.event_rounded),
        FxActionSheetItem(value: 0, label: s.vigenciaSemPrazo, icon: Icons.all_inclusive_rounded),
      ],
    );
    if (escolha == null || !mounted) return;
    setState(() => _semanas = escolha);
    _avisar();
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final chrome = ShellChrome.of(context);
    final modelos = widget.modelos.take(FichaVazia.modelosVisiveis).toList();

    Widget painel(List<Widget> filhos) => Padding(
      padding: const EdgeInsets.only(bottom: TokensStrip.s3),
      child: DecoratedBox(
        decoration: chrome.panel(radius: 20),
        child: Padding(
          padding: const EdgeInsets.all(TokensStrip.s3),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: filhos),
        ),
      ),
    );
    Widget titulo(String texto) =>
        Text(texto, style: FocuxHubTypography.cardTitle(color: chrome.ink));

    return IgnorePointer(
      ignoring: widget.ocupado,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (modelos.isNotEmpty)
            painel([
              titulo(s.fichaVaziaUsarModelo),
              const SizedBox(height: TokensStrip.s2),
              for (final modelo in modelos) ...[
                FxTapRow(
                  title: modelo.nome,
                  subtitle: [
                    if (modelo.resumoDasSessoes.isNotEmpty) modelo.resumoDasSessoes,
                    s.modeloContagem(modelo.sessoes.length, modelo.totalExercicios),
                  ].join(' · '),
                  onTap: () => widget.onUsarModelo(modelo),
                ),
                const SizedBox(height: TokensStrip.s1),
              ],
              if (widget.modelos.length > modelos.length)
                FxLinkRow(
                  label: s.fichaVaziaVerModelos,
                  detalhe: '${widget.modelos.length}',
                  onTap: widget.onVerModelos,
                ),
            ]),
          painel([
            titulo(s.fichaVaziaDoZero),
            const SizedBox(height: TokensStrip.s2),
            Text(s.rotinaFrequenciaTitulo, style: FocuxHubTypography.bodyMuted(color: chrome.mute)),
            const SizedBox(height: TokensStrip.s1),
            FxChoiceStrip<int>(
              quebrar: true,
              itens: [for (final n in const [2, 3, 4, 5, 6, 7]) FxChoiceItem(value: n, label: '$n')],
              selecionado: _dias == 0 ? null : _dias,
              onSelecionar: _escolherDias,
            ),
            if (_divisao != null) ..._escolhaDaDivisao(s, chrome),
          ]),
          FxLinkRow(
            label: s.fichaVaziaCopiarAluno,
            icon: Icons.people_alt_outlined,
            onTap: widget.onCopiarDeAluno,
          ),
        ],
      ),
    );
  }

  List<Widget> _escolhaDaDivisao(S s, ShellPalette chrome) {
    final sugeridas = divisoesSugeridas(_dias);
    final outras = outrasDivisoes(_dias);
    final nomes = nomesDosDias(s);
    final semana = semanaPorDivisao(_diasDeTreino, _divisao!);
    final escolhida = _divisao!;
    void escolher(Divisao d) {
      setState(() => _divisao = [...sugeridas, ...outras].firstWhere((x) => x.id == d.id));
      _avisar();
    }

    return [
      const SizedBox(height: TokensStrip.s3),
      Text(s.fichaVaziaDivisao, style: FocuxHubTypography.bodyMuted(color: chrome.mute)),
      const SizedBox(height: TokensStrip.s1),
      FxChoiceStrip<String>(
        quebrar: true,
        itens: [for (final d in sugeridas) FxChoiceItem(value: d.id, label: d.rotulo)],
        selecionado: escolhida.id,
        onSelecionar: (id) => escolher(sugeridas.firstWhere((d) => d.id == id)),
      ),
      if (sugeridas.isNotEmpty)
        Padding(
          padding: const EdgeInsets.only(top: TokensStrip.s1),
          child: Text(
            s.fichaVaziaRecomendada(sugeridas.first.rotulo),
            style: FocuxHubTypography.bodyMuted(color: chrome.mute),
          ),
        ),
      if (outras.isNotEmpty) ...[
        const SizedBox(height: TokensStrip.s2),
        Align(
          alignment: Alignment.centerLeft,
          child: FxActionLink(
            label: s.fichaVaziaOutras,
            onTap: () => setState(() => _outrasAbertas = !_outrasAbertas),
          ),
        ),
        if (_outrasAbertas) ...[
          const SizedBox(height: TokensStrip.s1),
          FxChoiceStrip<String>(
            quebrar: true,
            itens: [for (final d in outras) FxChoiceItem(value: d.id, label: d.rotulo)],
            selecionado: escolhida.id,
            onSelecionar: (id) => escolher(outras.firstWhere((d) => d.id == id)),
          ),
        ],
      ],
      const SizedBox(height: TokensStrip.s3),
      Text(s.fichaVaziaDiasDeTreino, style: FocuxHubTypography.bodyMuted(color: chrome.mute)),
      const SizedBox(height: TokensStrip.s1),
      Wrap(
        spacing: TokensStrip.s1,
        runSpacing: TokensStrip.s1,
        children: [
          for (var dia = 1; dia <= 7; dia++)
            FxChoiceChip(
              label: nomes[dia - 1],
              selected: _diasDeTreino.contains(dia),
              onTap: () => _alternarDia(dia),
            ),
        ],
      ),
      const SizedBox(height: TokensStrip.s3),
      for (final dia in semana)
        Padding(
          padding: const EdgeInsets.only(bottom: TokensStrip.s1),
          child: Row(
            children: [
              SizedBox(
                width: 44,
                child: Text(nomes[dia.dia - 1], style: FocuxHubTypography.cardTitle(color: chrome.ink)),
              ),
              if (dia.segueSequencia) ...[
                Icon(Icons.repeat_rounded, size: 16, color: chrome.mute),
                const SizedBox(width: TokensStrip.s1),
              ],
              Expanded(
                child: Text(
                  dia.sessoes.isNotEmpty
                      ? dia.sessoes.first.nome
                      : dia.segueSequencia
                      ? s.rotinaSegueSequencia
                      : s.rotinaDescanso,
                  style: FocuxHubTypography.bodyMuted(
                    color: dia.sessoes.isNotEmpty ? chrome.ink : chrome.mute,
                  ),
                ),
              ),
            ],
          ),
        ),
      const SizedBox(height: TokensStrip.s1),
      FxLinkRow(
        label: _semanas == 0 ? s.vigenciaSemPrazo : s.fichaVaziaValePor(_semanas),
        icon: Icons.event_rounded,
        detalhe: s.fichaVaziaMudar,
        onTap: _mudarPrazo,
      ),
    ];
  }
}
