part of 'agenda_aluno_screen.dart';

class _AgCard extends StatelessWidget {
  final Agendamento ag;
  final bool isDark;
  final Color primary;
  final void Function(Agendamento) onConfirmar;

  const _AgCard({
    required this.ag,
    required this.isDark,
    required this.primary,
    required this.onConfirmar,
  });

  @override
  Widget build(BuildContext context) {
    final cor = agendaStatusColor(
      ag.status,
      isDark: isDark,
      primary: primary,
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DecoratedBox(
        decoration: fxListCardDecoration(context, accent: cor),
        child: Padding(
          padding: const EdgeInsets.all(TokensStrip.s4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      agendaAlunoDefaultTitle(ag.titulo),
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  Text(
                    agendaStatusLabel(ag.status),
                    style: FocuxHubTypography.bodyMuted(
                      color: cor,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                agendaAlunoWhenLabel(ag.inicio, ag.fim),
                style: FocuxHubTypography.bodyMuted(
                  color: fxScreenMute(context),
                ),
              ),
              if (agendaStatusNeedsConfirm(ag.status)) ...[
                const SizedBox(height: 12),
                FxLiquidPrimaryButton(
                  label: 'Confirmar presença',
                  onPressed: () => onConfirmar(ag),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
