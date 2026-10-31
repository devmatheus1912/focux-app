part of 'copilot_actions_screen.dart';

/// Tarefa em uma linha: aluno, motivo e prazo. O resto fica no "⋯".
/// Concluídas de hoje, recolhidas para não competir com o que falta.
class _FeitasHoje extends StatelessWidget {
  const _FeitasHoje({
    required this.acoes,
    required this.ink,
    required this.mute,
  });

  final List<FilaAcaoResumo> acoes;
  final Color ink;
  final Color mute;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: fxListCardDecoration(context),
      child: ExpansionTile(
        shape: const Border(),
        title: Text(
          ptS.tarefasFeitasHoje(acoes.length),
          style: FocuxHubTypography.cardTitle(color: ink),
        ),
        children: [
          for (final a in acoes)
            ListTile(
              dense: true,
              leading: Icon(Icons.check_rounded, color: mute, size: 18),
              title: Text(
                copilotActionsNome(a),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: FocuxHubTypography.body(color: mute),
              ),
            ),
        ],
      ),
    );
  }
}
