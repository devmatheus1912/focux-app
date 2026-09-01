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
                FxSettingsGroup(
                  header: 'Peso',
                  caption: 'Últimas medidas com peso.',
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: FxSparkline(
                        data: weightData,
                        width: 320,
                        height: 72,
                        color: EagleTokens.good,
                        fill: true,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: FxSettingsLayout.groupGap),
              ],
              FxSettingsGroup(
                header: 'Medidas',
                children: [
                  for (var i = 0; i < ordenada.length; i++)
                    FxSettingsTile(
                      fxIcon: 'trend',
                      label: evolucaoMedidaLabel(ordenada[i]),
                      subtitle: evolucaoMedidaSubtitle(ordenada[i]),
                      value: evolucaoMedidaValue(ordenada[i]),
                      numeric: true,
                      showDivider: i != ordenada.length - 1,
                      onTap: () {},
                    ),
                ],
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
              FxSettingsGroup(
                header: 'Recordes',
                children: [
                  for (var i = 0; i < ordenada.length; i++)
                    FxSettingsTile(
                      fxIcon: 'star',
                      label: ordenada[i].exercicioNome,
                      subtitle: evolucaoRecordeSubtitle(ordenada[i]),
                      value: evolucaoRecordeValue(ordenada[i]),
                      numeric: true,
                      showDivider: i != ordenada.length - 1,
                      onTap: () {},
                    ),
                ],
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
