part of 'evolucao_screen.dart';

class _TabMedidas extends StatelessWidget {
  final String alunoNome;
  final AsyncValue<List<MedidaCorporal>> medidasAsync;
  final VoidCallback onRegister;
  final VoidCallback onRetry;
  const _TabMedidas({
    required this.alunoNome,
    required this.medidasAsync,
    required this.onRegister,
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
                action: FxEmptyAction(
                  label: 'Registrar medida',
                  onTap: onRegister,
                ),
              ),
            ),
          );
        }
        final ordenada = [...lista]..sort((a, b) => b.data.compareTo(a.data));
        final weightData = evolucaoPesosOrdenados(lista);
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
              if (weightData.length > 1) ...[
                const DashboardSectionHeader(title: 'Peso'),
                const SizedBox(height: TokensStrip.s2),
                Text(
                  'Últimas medidas com peso.',
                  style: FocuxHubTypography.bodyMuted(
                    color: fxScreenMute(context),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: TokensStrip.s3),
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: fxListCardDecoration(context),
                  child: FxSparkline(
                    data: weightData,
                    width: 320,
                    height: 72,
                    color: EagleTokens.good,
                    fill: true,
                  ),
                ),
                const SizedBox(height: TokensStrip.s5),
              ],
              const DashboardSectionHeader(title: 'Medidas'),
              const SizedBox(height: TokensStrip.s3),
              for (final medida in ordenada)
                FxSatelliteListTile(
                  title: evolucaoMedidaLabel(medida),
                  subtitle: Text(evolucaoMedidaSubtitle(medida)),
                  trailing: Text(
                    evolucaoMedidaValue(medida),
                    style: FocuxHubTypography.bodyMuted(
                      color: fxScreenMute(context),
                      fontWeight: FontWeight.w700,
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

class _TabRecordes extends StatelessWidget {
  final String alunoNome;
  final AsyncValue<List<RecordePessoal>> recordesAsync;
  final VoidCallback onRegister;
  final VoidCallback onRetry;
  const _TabRecordes({
    required this.alunoNome,
    required this.recordesAsync,
    required this.onRegister,
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
                action: FxEmptyAction(
                  label: 'Registrar recorde',
                  onTap: onRegister,
                ),
              ),
            ),
          );
        }
        final ordenada = [...lista]..sort((a, b) => b.data.compareTo(a.data));
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
              const DashboardSectionHeader(title: 'Recordes'),
              const SizedBox(height: TokensStrip.s3),
              for (final recorde in ordenada)
                FxSatelliteListTile(
                  title: recorde.exercicioNome,
                  subtitle: Text(evolucaoRecordeSubtitle(recorde)),
                  trailing: Text(
                    evolucaoRecordeValue(recorde),
                    style: FocuxHubTypography.bodyMuted(
                      color: fxScreenMute(context),
                      fontWeight: FontWeight.w700,
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

class _CampoNumerico extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  const _CampoNumerico({required this.controller, required this.label});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: FxInputDeco.build(context, label),
    );
  }
}
