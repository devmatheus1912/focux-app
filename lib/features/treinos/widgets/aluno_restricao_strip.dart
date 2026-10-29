import 'package:flutter/material.dart';

import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/widgets/fx_help.dart';
import '../../../core/widgets/fx_tonal_button.dart';
import '../../anamnese/data/anamnese_repository.dart';
import '../utils/aluno_restricao_match.dart';

/// Faixa "Atenção do aluno: joelho · lombar". Só aviso: nunca bloqueia.
class AlunoRestricaoStrip extends StatelessWidget {
  const AlunoRestricaoStrip({
    super.key,
    required this.anamnese,
    required this.regioes,
    required this.onDispensar,
    required this.onVerAnamnese,
  });

  final Anamnese anamnese;
  final Set<RegiaoCorpo> regioes;
  final VoidCallback onDispensar;
  final VoidCallback onVerAnamnese;

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.of(context);
    const alerta = EagleTokens.warn;
    return Padding(
      padding: const EdgeInsets.only(bottom: TokensStrip.s2),
      child: Material(
        color: alerta.withValues(alpha: chrome.isDark ? 0.16 : 0.10),
        borderRadius: BorderRadius.circular(TokensStrip.rSm),
        child: InkWell(
          borderRadius: BorderRadius.circular(TokensStrip.rSm),
          onTap:
              () => showAlunoRestricaoSheet(
                context,
                anamnese: anamnese,
                onVerAnamnese: onVerAnamnese,
              ),
          child: Container(
            constraints: const BoxConstraints(minHeight: 48),
            padding: const EdgeInsets.fromLTRB(12, 4, 4, 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(TokensStrip.rSm),
              border: Border.all(color: alerta.withValues(alpha: 0.5)),
            ),
            child: Row(
              children: [
                const Icon(Icons.health_and_safety_outlined, color: alerta, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    regioes.isEmpty
                        ? 'Atenção do aluno: veja a anamnese'
                        : 'Atenção do aluno: ${resumoRegioes(regioes)}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: FocuxHubTypography.body(
                      color: chrome.ink,
                    ).copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
                IconButton(
                  tooltip: 'Dispensar aviso',
                  onPressed: onDispensar,
                  icon: Icon(Icons.close_rounded, size: 20, color: chrome.mute),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Texto completo da anamnese (lesões, dores, restrições, alertas) e o aviso de
/// que o casamento é automático por palavra.
Future<void> showAlunoRestricaoSheet(
  BuildContext context, {
  required Anamnese anamnese,
  required VoidCallback onVerAnamnese,
}) {
  String? linha(String titulo, String? valor) =>
      valor == null || valor.trim().isEmpty ? null : '$titulo: ${valor.trim()}';
  final itens = [
    linha('Lesões', anamnese.lesoes),
    linha('Dores crônicas', anamnese.doresCronicas),
    linha('Cirurgias', anamnese.cirurgias),
    if (anamnese.parqProblemaOsseoArticular == true)
      'PAR-Q: problema ósseo ou articular',
    for (final a in anamnese.alertas) a,
  ].whereType<String>().toList();
  return showFxHelpSheet(
    context,
    title: 'Atenção do aluno',
    subtitle: 'Aviso automático por palavras. Não substitui sua avaliação.',
    tips: [
      for (final i in itens)
        FxHelpTip(i.split(':').first, i.contains(':') ? i.substring(i.indexOf(':') + 1).trim() : i),
    ],
    extra: [
      const SizedBox(height: TokensStrip.s3),
      FxTonalButton(
        label: 'Ver anamnese',
        icon: Icons.assignment_outlined,
        expanded: true,
        onPressed: onVerAnamnese,
      ),
    ],
  );
}
