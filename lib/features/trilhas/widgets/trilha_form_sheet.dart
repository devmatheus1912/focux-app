import 'package:flutter/material.dart';

import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/fx_icons.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/widgets/fx_calendario_sheet.dart';
import '../../../core/widgets/fx_choice_chip.dart';
import '../../../core/widgets/fx_form_sheet.dart';
import '../../../core/widgets/fx_inset_picker_row.dart';
import '../../../core/widgets/fx_tonal_button.dart';
import '../../alunos/widgets/aluno_inset_form_field.dart';
import '../models/trilha.dart';
import '../utils/trilhas_display.dart';

/// O que o formulário devolve. Na edição, [etapas] vem vazio (etapas têm
/// ações próprias no detalhe).
typedef TrilhaFormulario = ({
  String titulo,
  String? descricao,
  DateTime? dataFim,
  List<String> etapas,
});

/// Nova trilha (modelos, nome, etapas, descrição, prazo) ou edição de uma
/// existente (nome, descrição, prazo).
Future<TrilhaFormulario?> showTrilhaFormSheet(
  BuildContext context, {
  TrilhaModel? editar,
}) async {
  final nova = editar == null;
  final nome = TextEditingController(text: editar?.titulo ?? '');
  final descricao = TextEditingController(text: editar?.descricao ?? '');
  final etapas = [for (var i = 0; i < 3; i++) TextEditingController()];
  DateTime? prazo = editar == null ? null : trilhaPrazo(editar);
  String? erro;
  TrilhaModeloPronto? modelo;
  StateSetter? redesenhar;
  try {
    final ok = await showFxFormSheet(
      context,
      title: nova ? 'Nova trilha' : 'Editar trilha',
      subtitle: nova ? 'Um caminho em etapas até uma conquista.' : editar.titulo,
      icon: FxIcons.rota,
      confirmLabel: nova ? 'Criar trilha' : 'Salvar',
      podeConfirmar: () {
        final e = trilhaErroFormulario(
          nome: nome.text,
          etapas:
              nova
                  ? trilhaEtapasValidas(etapas.map((c) => c.text))
                  : const ['-', '-'],
        );
        redesenhar?.call(() => erro = e);
        return e == null;
      },
      child: StatefulBuilder(
        builder: (ctx, setState) {
          redesenhar = setState;
          final chrome = ShellChrome.of(ctx);
          void aplicarModelo(TrilhaModeloPronto m) {
            setState(() {
              modelo = m;
              nome.text = m.nome;
              while (etapas.length < m.etapas.length) {
                etapas.add(TextEditingController());
              }
              for (var i = 0; i < etapas.length; i++) {
                etapas[i].text = i < m.etapas.length ? m.etapas[i] : '';
              }
            });
          }

          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (nova) ...[
                Text('Começar de um modelo', style: FocuxHubTypography.chip(chrome.mute)),
                const SizedBox(height: TokensStrip.s1),
                Wrap(
                  spacing: TokensStrip.s2,
                  runSpacing: TokensStrip.s1,
                  children: [
                    for (final m in trilhaModelos)
                      FxChoiceChip(
                        label: m.nome,
                        selected: modelo == m,
                        onTap: () => aplicarModelo(m),
                      ),
                  ],
                ),
                const SizedBox(height: TokensStrip.s2),
              ],
              AlunoInsetFormField(
                controller: nome,
                label: 'Nome da trilha',
                hint: 'Ex.: Primeira barra fixa',
                icon: FxIcons.titulo,
                textCapitalization: TextCapitalization.sentences,
              ),
              if (nova)
                for (final (i, c) in etapas.indexed)
                  AlunoInsetFormField(
                    controller: c,
                    label: 'Etapa ${i + 1}',
                    icon: FxIcons.listaNumerada,
                    textCapitalization: TextCapitalization.sentences,
                  ),
              if (nova && etapas.length < trilhaEtapasMax)
                Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: TokensStrip.s1),
                    child: FxTonalButton(
                      label: 'Adicionar etapa',
                      icon: FxIcons.adicionar,
                      compact: true,
                      onPressed:
                          () => setState(() => etapas.add(TextEditingController())),
                    ),
                  ),
                ),
              AlunoInsetFormField(
                controller: descricao,
                label: 'Por que essa trilha (opcional)',
                hint: 'O aluno vê este texto.',
                icon: FxIcons.notas,
                maxLines: 2,
                textCapitalization: TextCapitalization.sentences,
              ),
              FxInsetPickerRow(
                icon: FxIcons.calendario,
                label: 'Prazo',
                value: prazo == null ? 'Sem prazo' : 'até ${trilhaDiaMes(prazo!)}',
                showDivider: false,
                onTap: () async {
                  final hoje = DateTime.now();
                  final escolha = await showFxCalendarioSheet(
                    ctx,
                    titulo: 'Prazo da trilha',
                    inicial: prazo ?? hoje.add(const Duration(days: 30)),
                    primeiro: hoje,
                    ultimo: DateTime(hoje.year + 1, hoje.month, hoje.day),
                    semDataLabel: 'Sem prazo',
                  );
                  if (escolha == null) return;
                  setState(() => prazo = escolha.data);
                },
              ),
              if (erro != null)
                Padding(
                  padding: const EdgeInsets.only(top: TokensStrip.s2),
                  child: Text(
                    erro!,
                    style: FocuxHubTypography.bodyMuted(
                      color: chrome.isDark ? EagleTokens.warnDark : EagleTokens.warn,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
    if (!ok) return null;
    final d = descricao.text.trim();
    return (
      titulo: nome.text.trim(),
      descricao: d.isEmpty ? null : d,
      dataFim: prazo,
      etapas: nova ? trilhaEtapasValidas(etapas.map((c) => c.text)) : const <String>[],
    );
  } finally {
    nome.dispose();
    descricao.dispose();
    for (final c in etapas) {
      c.dispose();
    }
  }
}
