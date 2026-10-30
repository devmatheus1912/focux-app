part of 'anamnese_screen.dart';

/// Revisão: decisão no topo, depois o que pede cuidado; respostas sob demanda.
class _AnamneseBody extends StatelessWidget {
  const _AnamneseBody({required this.anamnese});

  final Anamnese anamnese;

  @override
  Widget build(BuildContext context) {
    final a = anamnese;
    final chrome = ShellChrome.of(context);
    final treino = anamneseTreinoLinha(a);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _AnamneseDecisao(anamnese: a),
        if (a.isNaoIniciada) ...[
          const SizedBox(height: TokensStrip.s5),
          // CTA único no sticky S3 — empty sem action (§11 / §13).
          const FxEmptyState(
            icon: 'article',
            title: 'Nenhuma ficha ainda',
            subtitle: 'O aluno preenche a anamnese. Você solicita e revisa.',
            quiet: true,
          ),
        ] else if (a.isSolicitada && !a.personalPodeRevisar) ...[
          const SizedBox(height: TokensStrip.s5),
          const FxEmptyState(
            icon: 'calendar',
            title: 'Aguardando preenchimento',
            subtitle:
                'O aluno foi notificado. Quando enviar, você revisa aqui.',
            quiet: true,
          ),
        ] else if (a.personalPodeRevisar) ...[
          const SizedBox(height: TokensStrip.s4),
          Text(
            'Pontos de atenção',
            style: FocuxHubTypography.sectionTitle(context, color: chrome.ink),
          ),
          const SizedBox(height: TokensStrip.s2),
          _AnamnesePontos(pontos: anamnesePontosDeAtencao(a)),
          if (treino.isNotEmpty) ...[
            const SizedBox(height: TokensStrip.s3),
            Text(treino, style: FocuxHubTypography.body(color: chrome.ink)),
          ],
          const SizedBox(height: TokensStrip.s4),
          Text(
            'Respostas',
            style: FocuxHubTypography.sectionTitle(context, color: chrome.ink),
          ),
          const SizedBox(height: TokensStrip.s2),
          for (final secao in anamneseDetalheSecoes)
            _AnamneseSecao(
              titulo: anamneseSecaoTitle(secao.value),
              respostas: anamneseRespostas(a, secao.value),
            ),
          if (anamneseNotasDoPersonal(a) case final notas
              when notas.isNotEmpty) ...[
            const SizedBox(height: TokensStrip.s3),
            Text(
              'Suas notas',
              style: FocuxHubTypography.sectionTitle(
                context,
                color: chrome.ink,
              ),
            ),
            const SizedBox(height: TokensStrip.s2),
            _AnamneseLinhas(linhas: notas),
          ],
        ],
      ],
    );
  }
}

class _AnamneseDecisao extends StatelessWidget {
  const _AnamneseDecisao({required this.anamnese});

  final Anamnese anamnese;

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.of(context);
    return Container(
      padding: const EdgeInsets.all(TokensStrip.s3),
      decoration: fxListCardDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            anamneseDecisaoTitulo(anamnese),
            style: FocuxHubTypography.cardTitle(color: chrome.ink),
          ),
          const SizedBox(height: 2),
          Text(
            anamneseDecisaoApoio(anamnese),
            style: FocuxHubTypography.bodyMuted(color: chrome.mute),
          ),
        ],
      ),
    );
  }
}

class _AnamnesePontos extends StatelessWidget {
  const _AnamnesePontos({required this.pontos});

  final List<String> pontos;

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.of(context);
    if (pontos.isEmpty) {
      return Text(
        'Nenhum ponto de atenção.',
        style: FocuxHubTypography.bodyMuted(color: chrome.mute),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final ponto in pontos)
          Padding(
            padding: const EdgeInsets.only(bottom: TokensStrip.s2),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.warning_amber_rounded,
                  size: 20,
                  color: EagleTokens.warn,
                ),
                const SizedBox(width: TokensStrip.s2),
                Expanded(
                  child: Text(
                    ponto,
                    style: FocuxHubTypography.body(color: chrome.ink),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _AnamneseSecao extends StatelessWidget {
  const _AnamneseSecao({required this.titulo, required this.respostas});

  final String titulo;
  final List<(String, String)> respostas;

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.of(context);
    final n = respostas.length;
    return Padding(
      padding: const EdgeInsets.only(bottom: TokensStrip.s2),
      child: Container(
        decoration: fxListCardDecoration(context),
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            tilePadding: const EdgeInsets.symmetric(horizontal: TokensStrip.s3),
            childrenPadding: const EdgeInsets.fromLTRB(
              TokensStrip.s3,
              0,
              TokensStrip.s3,
              TokensStrip.s3,
            ),
            title: Text(
              titulo,
              style: FocuxHubTypography.cardTitle(color: chrome.ink),
            ),
            subtitle: Text(
              n == 0
                  ? 'Não respondeu'
                  : n == 1
                  ? '1 resposta'
                  : '$n respostas',
              style: FocuxHubTypography.bodyMuted(color: chrome.mute),
            ),
            children: [
              if (n == 0)
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'O aluno deixou esta parte em branco.',
                    style: FocuxHubTypography.bodyMuted(color: chrome.mute),
                  ),
                )
              else
                _AnamneseLinhas(linhas: respostas),
            ],
          ),
        ),
      ),
    );
  }
}

class _AnamneseLinhas extends StatelessWidget {
  const _AnamneseLinhas({required this.linhas});

  final List<(String, String)> linhas;

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (rotulo, valor) in linhas)
          Padding(
            padding: const EdgeInsets.only(bottom: TokensStrip.s2),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  rotulo,
                  style: FocuxHubTypography.bodyMuted(color: chrome.mute),
                ),
                Text(
                  valor,
                  style: FocuxHubTypography.body(color: chrome.ink),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
