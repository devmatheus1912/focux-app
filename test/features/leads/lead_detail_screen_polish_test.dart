import 'package:flutter_test/flutter_test.dart';

import '../../support/screen_source_bundle.dart';

/// Ficha do interessado (11/11): sem cartões, abas, Lista/Kanban nem ícones
/// soltos no topo; etapa como pílula, histórico e "⋯".
void main() {
  test('ficha do interessado cumpre contrato e o redesign', () {
    final screen = readScreenSourceBundle(
      'lib/features/leads/screens/lead_detail_screen.dart',
    );
    expect(screen, contains('fxScreenA11yScope'));
    expect(screen, contains('FxShellScaffold'));
    expect(screen, contains('FxContentWidthLimiter'));
    expect(screen, contains('SkeletonList'));
    expect(screen, contains('friendlyError'));
    expect(screen, contains('FxLiquidPrimaryButton'));
    expect(screen, contains('FxHelpIconButton'));
    expect(screen, contains('safePopOrGo'));
    expect(screen, contains('RefreshIndicator'));
    expect(screen, contains('PopScope'));
    expect(screen, contains('marca: true'));
    expect(screen, contains('leadConverterRoute'));
    expect(screen, contains("'Cadastrar como aluno'"));
    expect(screen, contains("'Anotar contato'"));
    expect(screen, contains('interessadoHistorico'));
    expect(screen, contains('showFxGroupedActionSheet'));
    expect(screen, contains('InteressadoContatoMixin'));
    expect(screen, contains('showFxCalendarioSheet'));
    expect(screen, isNot(contains('OperationalMetricTile')));
    expect(screen, isNot(contains('AlunoSegmentedChoice')));
    expect(screen, isNot(contains('Kanban')));
    expect(screen, isNot(contains('Follow-up')));
    expect(screen, isNot(contains('PopupMenuButton')));
    expect(screen, isNot(contains('showDatePicker')));
  });
}
