part of 'treino_detail_screen.dart';

/// "ABDÔMEN" → "Abdômen" (o grupo vira texto pequeno da linha).
String _grupoEmTexto(TreinoExercicioItem te) {
  final g = treinoDetailGroupLabel(te);
  if (g == 'OUTROS' || g.isEmpty) return '';
  return g[0] + g.substring(1).toLowerCase();
}

/// Linha do exercício: alça de arrasto visível, miniatura, nome, músculo e
/// prescrição. Tocar na linha edita a prescrição; o "⋯" guarda o resto.
class _ExercicioRow extends StatelessWidget {
  final TreinoExercicioItem te;

  /// Posição na lista única (para a alça de arrasto).
  final int reorderIndex;
  final bool isDark;
  final bool isLast;
  final VoidCallback onEditPrescription;
  final VoidCallback onMenu;

  const _ExercicioRow({
    required this.te,
    required this.reorderIndex,
    required this.isDark,
    required this.isLast,
    required this.onEditPrescription,
    required this.onMenu,
  });

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.forBrightness(context, isDark);
    final ink = chrome.ink;
    final mute = chrome.mute;
    final line = chrome.line;
    final note = te.observacoes?.trim();
    final hasNote = note != null && note.isNotEmpty;
    final prescription = treinoDetailExerciseLine(te);
    final grupo = _grupoEmTexto(te);
    final nome =
        te.exercicio.isPersonalUpload
            ? '${te.exercicio.nomeDisplay} · Meu'
            : te.exercicio.nomeDisplay;
    final apoio = [
      if (grupo.isNotEmpty) grupo,
      if (hasNote) note,
    ].join(' · ');

    return Container(
      decoration: BoxDecoration(
        border:
            isLast ? null : Border(bottom: BorderSide(color: line, width: 0.5)),
      ),
      child: Row(
        children: [
          // Alça: arrasta na hora, sem precisar segurar.
          ReorderableDragStartListener(
            index: reorderIndex,
            child: Semantics(
              label: 'Arrastar ${te.exercicio.nomeDisplay}',
              child: SizedBox(
                width: 40,
                height: TreinosLayout.touchTarget,
                child: Icon(
                  Icons.drag_indicator_rounded,
                  size: 22,
                  color: mute.withValues(alpha: 0.85),
                ),
              ),
            ),
          ),
          Expanded(
            child: Material(
              color: fxTransparent,
              child: InkWell(
                onTap: onEditPrescription,
                child: Semantics(
                  button: true,
                  label:
                      '${te.exercicio.nomeDisplay}. $prescription'
                      '${apoio.isEmpty ? '' : '. $apoio'}. Editar prescrição.',
                  excludeSemantics: true,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      0,
                      TreinosLayout.exerciseRowPadV,
                      TokensStrip.s2,
                      TreinosLayout.exerciseRowPadV,
                    ),
                    child: Row(
                      children: [
                        ExerciseMediaThumb.fromExercicio(
                          te.exercicio,
                          size: 40,
                          radius: 10,
                        ),
                        const SizedBox(width: TokensStrip.s2),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                nome,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: FocuxHubTypography.cardTitle(color: ink),
                              ),
                              const SizedBox(height: 1),
                              Text(
                                prescription,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: FocuxHubTypography.metric(
                                  color: ink.withValues(alpha: 0.8),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              if (apoio.isNotEmpty)
                                Text(
                                  apoio,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: FocuxHubTypography.bodyMuted(
                                    color: mute,
                                    fontWeight: FontWeight.w600,
                                  ).copyWith(fontSize: 11),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          Semantics(
            button: true,
            label: 'Ações de ${te.exercicio.nomeDisplay}',
            child: IconButton(
              tooltip: 'Ações de ${te.exercicio.nomeDisplay}',
              onPressed: onMenu,
              style: IconButton.styleFrom(
                minimumSize: const Size(
                  TreinosLayout.headerChromeSize,
                  TreinosLayout.touchTarget,
                ),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
              ),
              icon: Icon(Icons.more_horiz_rounded, color: mute, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}
