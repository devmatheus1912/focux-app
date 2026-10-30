part of 'evolucao_screen.dart';

/// Peso é o número que o personal abre a tela para ver.
class _EvolucaoPesoHero extends StatelessWidget {
  const _EvolucaoPesoHero({required this.medidas});

  final List<MedidaCorporal> medidas;

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.of(context);
    final variacao = evolucaoVariacaoPeso(medidas);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(TokensStrip.s3),
      decoration: fxListCardDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Peso atual', style: FocuxHubTypography.chip(chrome.mute)),
          const SizedBox(height: TokensStrip.s1),
          Text(
            evolucaoPesoAtual(medidas),
            style: FocuxHubTypography.metric(
              color: chrome.ink,
              fontSize: 34,
              height: 1.1,
            ),
          ),
          const SizedBox(height: TokensStrip.s1),
          Text(
            [
              if (variacao.isNotEmpty) variacao,
              evolucaoUltimaMedidaHint(medidas),
            ].join(' · '),
            style: FocuxHubTypography.bodyMuted(color: chrome.mute),
          ),
        ],
      ),
    );
  }
}

class _EvolucaoAtalho extends StatelessWidget {
  const _EvolucaoAtalho({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(TokensStrip.rCard),
        child: Ink(
          padding: const EdgeInsets.all(TokensStrip.s3),
          decoration: fxListCardDecoration(context),
          child: Row(
            children: [
              Icon(
                icon,
                size: 20,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: TokensStrip.s2),
              Expanded(
                child: Text(
                  label,
                  style: FocuxHubTypography.cardTitle(color: chrome.ink),
                ),
              ),
              Icon(Icons.chevron_right_rounded, size: 20, color: chrome.mute),
            ],
          ),
        ),
      ),
    );
  }
}

class _TabMedidas extends StatelessWidget {
  final String alunoNome;
  final AsyncValue<List<MedidaCorporal>> medidasAsync;
  final VoidCallback onRetry;
  const _TabMedidas({
    required this.alunoNome,
    required this.medidasAsync,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.of(context);
    final primary = Theme.of(context).colorScheme.primary;
    return medidasAsync.when(
      loading:
          () => const Padding(
            padding: EdgeInsets.all(FxSettingsLayout.pageInset),
            child: SkeletonList(count: 4),
          ),
      error:
          (e, _) => FxErrorState(
            chromeOnDark: chrome.isDark,
            primary: primary,
            message: friendlyError(e),
            onRetry: onRetry,
            title: 'Não conseguimos carregar as medidas',
          ),
      data: (lista) {
        if (lista.isEmpty) {
          final first = satelliteFirstName(alunoNome);
          return RefreshIndicator(
            onRefresh: () async => onRetry(),
            child: satelliteEmptyBody(
              child: FxEmptyState(
                key: const ValueKey('evolucao_medidas_empty'),
                icon: 'trend',
                title: 'Nenhuma medida registrada',
                subtitle:
                    'Registre peso e circunferências de $first para acompanhar a evolução.',
              ),
            ),
          );
        }
        final ordenada = evolucaoMedidasComConteudo(lista);
        final weightData = evolucaoPesosOrdenados(lista);
        if (ordenada.isEmpty && weightData.isEmpty) {
          final first = satelliteFirstName(alunoNome);
          return RefreshIndicator(
            onRefresh: () async => onRetry(),
            child: satelliteEmptyBody(
              child: FxEmptyState(
                key: const ValueKey('evolucao_medidas_empty'),
                icon: 'trend',
                title: 'Nenhuma medida registrada',
                subtitle:
                    'Registre peso e circunferências de $first para acompanhar a evolução.',
              ),
            ),
          );
        }
        return RefreshIndicator(
          onRefresh: () async => onRetry(),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(
              FxSettingsLayout.pageInset,
              8,
              FxSettingsLayout.pageInset,
              96,
            ),
            children: [
              if (weightData.length > 1) ...[
                Container(
                  padding: const EdgeInsets.all(TokensStrip.s3),
                  decoration: fxListCardDecoration(context),
                  child: Center(
                    child: FxSparkline(
                      data: weightData,
                      width: 320,
                      height: 72,
                      color: EagleTokens.good,
                      fill: true,
                    ),
                  ),
                ),
                const SizedBox(height: TokensStrip.s4),
              ],
              for (final medida in ordenada)
                FxSatelliteListTile(
                  title: evolucaoMedidaLabel(medida),
                  subtitle: Text(evolucaoMedidaSubtitle(medida)),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _TabRecordes extends StatelessWidget {
  final String alunoNome;
  final AsyncValue<List<RecordePessoal>> recordesAsync;
  final VoidCallback onRetry;
  const _TabRecordes({
    required this.alunoNome,
    required this.recordesAsync,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.of(context);
    final primary = Theme.of(context).colorScheme.primary;
    return recordesAsync.when(
      loading:
          () => const Padding(
            padding: EdgeInsets.all(FxSettingsLayout.pageInset),
            child: SkeletonList(count: 4),
          ),
      error:
          (e, _) => FxErrorState(
            chromeOnDark: chrome.isDark,
            primary: primary,
            message: friendlyError(e),
            onRetry: onRetry,
            title: 'Não conseguimos carregar os recordes',
          ),
      data: (lista) {
        if (lista.isEmpty) {
          final first = satelliteFirstName(alunoNome);
          return RefreshIndicator(
            onRefresh: () async => onRetry(),
            child: satelliteEmptyBody(
              child: FxEmptyState(
                key: const ValueKey('evolucao_recordes_empty'),
                icon: 'star',
                title: 'Nenhum recorde registrado',
                subtitle:
                    'Marque o primeiro recorde de $first após um check-in ou treino forte.',
              ),
            ),
          );
        }
        final melhores = evolucaoMelhoresRecordes(lista);
        return RefreshIndicator(
          onRefresh: () async => onRetry(),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(
              FxSettingsLayout.pageInset,
              8,
              FxSettingsLayout.pageInset,
              32,
            ),
            children: [
              for (final recorde in melhores)
                FxSatelliteListTile(
                  title: recorde.exercicioNome,
                  subtitle: Text(evolucaoRecordeSubtitle(recorde)),
                  trailing: Text(
                    evolucaoRecordeValue(recorde),
                    style: FocuxHubTypography.metric(
                      color: fxScreenInk(context),
                      fontSize: TokensStrip.fontBody,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

