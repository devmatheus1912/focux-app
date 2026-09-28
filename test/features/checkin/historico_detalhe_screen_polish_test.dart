import 'package:flutter_test/flutter_test.dart';

import '../../support/screen_source_bundle.dart';

void main() {
  test(
    'detalhe: uma rolagem, prévia para treinar de novo e fold antigo fora',
    () {
      final screen = readScreenSourceBundle(
        'lib/features/checkin/screens/historico_detalhe_screen.dart',
      );

      expect(screen, contains('fxScreenA11yScope'));
      expect(screen, contains('FxShellScaffold'));
      expect(screen, contains('FxAsyncBody<ExecucaoTreino>'));
      expect(screen, contains('historicoDetalheProvider'));
      expect(screen, contains('historicoEvolucaoProvider'));
      expect(screen, contains('buildHistoricoDetalheView'));
      expect(screen, contains('treinoPreviaPath'));
      expect(screen, contains("safePopOrGo(context, '/checkin/historico')"));
      expect(screen, contains('statusCode == 404'));
      expect(screen, contains('RefreshIndicator'));
      expect(screen, contains('FxLiquidPrimaryButton'));

      for (final morto in [
        'HistoricoDetalheMemCache',
        'AlunoSegmentedChoice',
        'FxHelpIconButton',
        "'Sinal'",
        'sinalLabel',
        'historicoStickyLabel',
        'PopScope',
        'FxLoading.sectionShimmer',
      ]) {
        expect(screen, isNot(contains(morto)), reason: morto);
      }
    },
  );
}
