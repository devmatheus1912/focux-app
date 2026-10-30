import 'package:flutter/material.dart';

import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/widgets/fx_quick_chips.dart';
import '../../../l10n/app_localizations.dart';
import '../../alunos/widgets/aluno_form_choices.dart';
import '../../alunos/widgets/aluno_inset_form_field.dart';
import '../utils/anamnese_etapas.dart';

/// Pergunta do PAR-Q+ em uma linha: texto à esquerda, Sim/Não à direita.
class AnamneseParqLinha extends StatelessWidget {
  const AnamneseParqLinha({
    super.key,
    required this.pergunta,
    required this.resposta,
    required this.pendente,
    required this.onResponder,
  });

  final String pergunta;
  final bool? resposta;

  /// Tentou avançar sem responder: a pendência aparece aqui mesmo.
  final bool pendente;
  final ValueChanged<bool> onResponder;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final chrome = ShellChrome.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: TokensStrip.s2),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  pergunta,
                  style: FocuxHubTypography.body(color: chrome.ink),
                ),
                if (pendente) ...[
                  const SizedBox(height: 2),
                  Text(
                    s.anamneseAlunoResponda,
                    style: FocuxHubTypography.bodyMuted(
                      color: chrome.isDark ? EagleTokens.warnDark : EagleTokens.warn,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: TokensStrip.s3),
          SizedBox(
            width: 128,
            child: AlunoSegmentedChoice(
              options: [
                (value: 'true', label: s.anamneseAlunoSim),
                (value: 'false', label: s.anamneseAlunoNao),
              ],
              selected: resposta?.toString(),
              isDark: chrome.isDark,
              onSelect: (v) => onResponder(v == 'true'),
            ),
          ),
        ],
      ),
    );
  }
}

/// "Não tenho" ou "Tenho": o texto só abre quando há o que contar.
class AnamneseCampoTenho extends StatelessWidget {
  const AnamneseCampoTenho({
    super.key,
    required this.controller,
    required this.titulo,
    required this.icon,
    required this.aberto,
    required this.onAberto,
    required this.maxLength,
    this.hint,
  });

  final TextEditingController controller;
  final String titulo;
  final IconData icon;
  final String? hint;
  final int maxLength;

  /// Nulo: ainda sem resposta.
  final bool? aberto;
  final ValueChanged<bool> onAberto;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final chrome = ShellChrome.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: TokensStrip.s2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(titulo, style: FocuxHubTypography.cardTitle(color: chrome.ink)),
          const SizedBox(height: TokensStrip.s2),
          FxQuickChips<bool>(
            itens: const [false, true],
            selecionado: aberto,
            rotuloDe: (tem) => tem ? s.anamneseAlunoTenho : s.anamneseAlunoNaoTenho,
            onSelecionar: onAberto,
          ),
          if (aberto == true)
            AlunoInsetFormField(
              controller: controller,
              label: s.anamneseAlunoConte,
              hint: hint,
              icon: icon,
              maxLines: 3,
              maxLength: maxLength,
              rotuloVisivel: true,
              showDivider: false,
            ),
        ],
      ),
    );
  }
}

/// Escolha rápida que grava no mesmo campo de texto de sempre. Valor antigo
/// fora das opções aparece em "Outro", com o texto intacto.
class AnamneseChipsCampo extends StatefulWidget {
  const AnamneseChipsCampo({
    super.key,
    required this.controller,
    required this.titulo,
    required this.opcoes,
    required this.icon,
    required this.maxLength,
    this.comDetalhe,
    this.obrigatorio = false,
  });

  final TextEditingController controller;
  final String titulo;
  final List<String> opcoes;
  final IconData icon;
  final int maxLength;

  /// Opção que também pede texto ("Fumo": quantos por dia).
  final String? comDetalhe;
  final bool obrigatorio;

  @override
  State<AnamneseChipsCampo> createState() => _AnamneseChipsCampoState();
}

class _AnamneseChipsCampoState extends State<AnamneseChipsCampo> {
  var _outro = false;

  @override
  void initState() {
    super.initState();
    final t = widget.controller.text.trim();
    _outro =
        t.isNotEmpty &&
        anamneseChipDoValor(t, widget.opcoes, comDetalhe: widget.comDetalhe) == null;
  }

  void _escolher(String opcao) {
    setState(() {
      _outro = false;
      widget.controller.text = opcao;
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final chrome = ShellChrome.of(context);
    final atual = _outro
        ? null
        : anamneseChipDoValor(
            widget.controller.text,
            widget.opcoes,
            comDetalhe: widget.comDetalhe,
          );
    final comTexto = _outro || (atual != null && atual == widget.comDetalhe);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: TokensStrip.s2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            widget.titulo,
            style: FocuxHubTypography.cardTitle(color: chrome.ink),
          ),
          const SizedBox(height: TokensStrip.s2),
          FxQuickChips<String>(
            itens: widget.opcoes,
            selecionado: atual,
            onSelecionar: _escolher,
            outroRotulo: s.anamneseAlunoOutro,
            outroSelecionado: _outro,
            onOutro: () => setState(() {
              _outro = true;
              widget.controller.clear();
            }),
          ),
          if (comTexto)
            AlunoInsetFormField(
              controller: widget.controller,
              label: widget.titulo,
              icon: widget.icon,
              maxLines: 1,
              maxLength: widget.maxLength,
              rotuloVisivel: true,
              obrigatorio: widget.obrigatorio,
              showDivider: false,
            ),
        ],
      ),
    );
  }
}
