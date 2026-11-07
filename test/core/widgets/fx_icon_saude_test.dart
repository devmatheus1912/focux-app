import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/core/theme/fx_icons.dart';
import 'package:focux_app/core/widgets/fx_dock.dart';
import 'package:focux_app/l10n/app_localizations_pt.dart';

void main() {
  test('Saúde tem ícone próprio no dock, com par Fill na aba ativa', () {
    final saude = FxDockItems.aluno(SPt())[2];
    expect(saude.icon, FxIcons.saudeVida);
    expect(saude.iconAtivo, FxIcons.saudeVidaAtivo);
    expect(saude.iconAtivo.fontFamily, 'PhosphorFill');
    expect(saude.icon, isNot(FxIcons.grafico));
  });
}
