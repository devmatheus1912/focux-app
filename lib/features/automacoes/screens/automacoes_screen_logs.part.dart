part of 'automacoes_screen.dart';

Future<void> _showAutomacaoLogsSheet({
  required BuildContext context,
  required AutomacaoFluxo fluxo,
  required List<AutomacaoLog> logs,
}) {
  final chrome = ShellChrome.of(context);
  return showFxHomeSheet<void>(
    context,
    builder: (sheetContext) => FxHomeSheetSurface(
      isDark: chrome.isDark,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FxHomeSheetHandle(isDark: chrome.isDark),
          FxHomeSheetHeader(
            isDark: chrome.isDark,
            leading: Icon(
              Icons.timeline_outlined,
              color: Theme.of(sheetContext).colorScheme.primary,
              size: 18,
            ),
            title: fluxo.nome,
            subtitle: automacaoTriggerLabel(fluxo.triggerTipo),
          ),
          SizedBox(
            height: 280,
            child: logs.isEmpty
                ? const FxEmptyState(
                    icon: 'zap',
                    title: 'Nenhuma execução ainda',
                    subtitle:
                        'Quando o gatilho disparar, o histórico aparece aqui.',
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(
                      FxSettingsLayout.pageInset,
                      0,
                      FxSettingsLayout.pageInset,
                      TokensStrip.s3,
                    ),
                    itemCount: logs.length,
                    itemBuilder: (context, i) {
                      final log = logs[i];
                      return FxSatelliteListTile(
                        title: automacaoLogStatusLabel(log.status),
                        subtitle: Text(
                          automacaoLogSubtitle(
                            status: log.status,
                            passoAtual: log.passoAtual,
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    ),
  );
}
