part of 'churn_dashboard_screen.dart';

/// "Saúde 10 de 100", com quanto subiu ou caiu desde a leitura anterior.
String retencaoSaudeTexto(S s, RetencaoAlunoScore score) {
  if (score.delta < 0) {
    return s.retencaoSaudeCaiu(score.scoreAtual, -score.delta);
  }
  if (score.delta > 0) {
    return s.retencaoSaudeSubiu(score.scoreAtual, score.delta);
  }
  return s.retencaoSaude(score.scoreAtual);
}

class _SemRiscoAlto extends StatelessWidget {
  const _SemRiscoAlto({required this.titulo, required this.texto});

  final String titulo;
  final String texto;

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.of(context);
    return Container(
      padding: const EdgeInsets.all(TokensStrip.s3),
      decoration: BoxDecoration(
        color: chrome.cardFill,
        borderRadius: BorderRadius.circular(TokensStrip.rCard),
        border: Border.all(color: chrome.lineStrong),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titulo,
            style: TextStyle(color: chrome.ink, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 2),
          Text(texto, style: TextStyle(color: chrome.mute)),
        ],
      ),
    );
  }
}

/// Barrinha de saúde: cheia = saudável. A cor segue o nível.
class _BarraSaude extends StatelessWidget {
  const _BarraSaude({required this.score});

  final int score;

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.of(context);
    final nivel = nivelDoScore(score);
    final cor = switch (nivel) {
      RetencaoNivel.alto => Theme.of(context).colorScheme.error,
      RetencaoNivel.atencao => chrome.mute,
      RetencaoNivel.saudavel => chrome.brand,
    };
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: LinearProgressIndicator(
        value: (score.clamp(0, 100)) / 100,
        minHeight: 4,
        backgroundColor: chrome.line,
        valueColor: AlwaysStoppedAnimation(cor),
      ),
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
    final mute = ShellChrome.of(context).mute;
    return Padding(
      padding: const EdgeInsets.only(bottom: TokensStrip.s2),
      child: FxSatelliteListTile(
        title: score.alunoNome,
        titleCase: false,
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(retencaoSaudeTexto(s, score)),
            const SizedBox(height: 4),
            _BarraSaude(score: score.scoreAtual),
          ],
        ),
        accent: null,
        onTap: onAluno,
        onLongPress: onMais,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: TokensStrip.s7,
              height: TokensStrip.s7,
              child: IconButton(
                tooltip: s.retencaoVerboChamar,
                onPressed: onChat,
                icon: Icon(Icons.chat_bubble_outline_rounded, color: primary),
              ),
            ),
            SizedBox(
              width: TokensStrip.s7,
              height: TokensStrip.s7,
              child: IconButton(
                tooltip: s.retencaoMaisAcoes,
                onPressed: onMais,
                icon: Icon(Icons.more_horiz_rounded, color: mute),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
