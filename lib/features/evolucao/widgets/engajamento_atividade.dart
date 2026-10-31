import 'package:flutter/material.dart';

import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/widgets/fx_icon.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../dashboard/widgets/dashboard_section_header.dart';
import '../data/evolucao_repository.dart';
import '../utils/engajamento_display.dart';

/// Um dia da Atividade: título e um cartão com as linhas.
class EngajamentoAtividadeDia extends StatelessWidget {
  const EngajamentoAtividadeDia({
    super.key,
    required this.dia,
    required this.eventos,
    required this.onEvento,
    required this.podeAbrir,
  });

  final String dia;
  final List<EventoEngajamento> eventos;
  final ValueChanged<EventoEngajamento> onEvento;
  final bool Function(EventoEngajamento) podeAbrir;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(
            top: TokensStrip.s5,
            bottom: TokensStrip.s3,
          ),
          child: DashboardSectionHeader(title: dia),
        ),
        Container(
          decoration: fxListCardDecoration(context),
          child: Column(
            children: [
              for (final (i, evento) in eventos.indexed) ...[
                if (i > 0) const Divider(height: 1),
                EngajamentoLinhaAtividade(
                  evento: evento,
                  onTap: podeAbrir(evento) ? () => onEvento(evento) : null,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// Uma linha do cartão de Atividade: ícone, o que houve e a hora.
class EngajamentoLinhaAtividade extends StatelessWidget {
  const EngajamentoLinhaAtividade({
    super.key,
    required this.evento,
    required this.onTap,
  });

  final EventoEngajamento evento;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.of(context);
    final titulo = engajamentoEventoLabel(evento.descricao, evento.tipo);
    final apoio = engajamentoEventoSubtitle(tipo: evento.tipo, titulo: titulo);
    return InkWell(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 56),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: TokensStrip.s3,
            vertical: TokensStrip.s2,
          ),
          child: Row(
            children: [
              FxIcon(
                name: engajamentoFxIcon(evento.tipo),
                size: 18,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: TokensStrip.s3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      titulo,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: FocuxHubTypography.cardTitle(color: chrome.ink),
                    ),
                    if (apoio != null)
                      Text(
                        apoio,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: FocuxHubTypography.bodyMuted(color: chrome.mute),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: TokensStrip.s2),
              Text(
                engajamentoHoraLabel(evento.dataHora),
                style: FocuxHubTypography.bodyMuted(
                  color: chrome.mute,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

