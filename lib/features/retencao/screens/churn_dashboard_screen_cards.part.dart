part of 'churn_dashboard_screen.dart';

class _SemRiscoAlto extends StatelessWidget {
  const _SemRiscoAlto({required this.texto});

  final String texto;

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.of(context);
    return Text(
      texto,
      style: FocuxHubTypography.bodyMuted(color: chrome.mute),
    );
  }
}

/// Nível com ícone e texto, nunca só cor.
class _SeloNivel extends StatelessWidget {
  const _SeloNivel({required this.nivel});

  final RetencaoNivel nivel;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final chrome = ShellChrome.of(context);
    final (rotulo, icone, cor) = switch (nivel) {
      RetencaoNivel.alto => (
        s.retencaoMetAlto,
        Icons.error_outline_rounded,
        Theme.of(context).colorScheme.error,
      ),
      RetencaoNivel.atencao => (
        s.retencaoMetAtencao,
        Icons.schedule_rounded,
        EagleTokens.warn,
      ),
      RetencaoNivel.saudavel => (
        s.retencaoMetSaudaveis,
        Icons.check_circle_outline_rounded,
        chrome.brand,
      ),
    };
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icone, size: 14, color: cor),
        const SizedBox(width: 4),
        Text(rotulo, style: FocuxHubTypography.chip(cor)),
      ],
    );
  }
}

class _RetencaoTile extends StatelessWidget {
  const _RetencaoTile({
    required this.score,
    required this.onChat,
    required this.onAluno,
    required this.onMais,
  });

  final RetencaoAlunoScore score;
  final VoidCallback onChat;
  final VoidCallback onAluno;
  final VoidCallback onMais;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final primary = Theme.of(context).colorScheme.primary;
    final motivo = retencaoMotivoCurto(score);
    return Padding(
      padding: const EdgeInsets.only(bottom: TokensStrip.s2),
      child: FxSatelliteListTile(
        title: score.alunoNome,
        titleCase: false,
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (motivo != null)
              Text(motivo, maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 4),
            _SeloNivel(nivel: score.nivelTela),
          ],
        ),
        accent: null,
        onTap: onMais,
        trailing: SizedBox(
          width: TokensStrip.s7,
          height: TokensStrip.s7,
          child: IconButton(
            tooltip: s.retencaoAcaoMensagem,
            onPressed: onChat,
            icon: Icon(Icons.chat_bubble_outline_rounded, color: primary),
          ),
        ),
      ),
    );
  }
}
