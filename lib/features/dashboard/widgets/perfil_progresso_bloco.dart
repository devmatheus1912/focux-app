import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/shell_chrome.dart';
import '../../../core/utils/pt_br_display.dart';
import '../../../core/widgets/fx_settings_group.dart';
import '../../../core/widgets/fx_settings_tile.dart';
import '../../../l10n/app_localizations.dart';
import '../../../l10n/pt.dart';
import '../../evolucao/data/evolucao_repository.dart';
import '../../evolucao/utils/evolucao_series.dart';
import '../../../core/theme/fx_icons.dart';

/// "105,0 kg · +15,0 kg desde 12/03"; sem medida, o texto de vazio.
/// A data diz de onde vem a diferença (sem ela, "+26 kg" parece alarme).
String perfilPesoLinha(S s, List<MedidaCorporal> medidas) {
  final pesos = serieDaMetrica(medidas, EvolucaoMetrica.peso);
  if (pesos.isEmpty) return s.progressoSemPeso;
  final atual = '${formatBrDecimal(pesos.last.valor)} kg';
  if (pesos.length < 2) return atual;
  final dif = diferencaTexto(pesos.last.valor - pesos.first.valor, 'kg');
  return '$atual · ${s.perfilPesoDesde(dif, dataCurta(pesos.first.data))}';
}

/// Peso atual e "Registrar medida", como linhas da lista (o mesmo padrão do
/// grupo Conta). A semana e a meta ficam na Hoje e no Meu progresso.
class PerfilProgressoBloco extends StatelessWidget {
  const PerfilProgressoBloco({super.key, required this.medidas});

  final List<MedidaCorporal> medidas;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final chrome = ShellChrome.of(context);
    return FxSettingsGroup(
      header: s.alunoPerfilGrupoProgresso,
      children: [
        FxSettingsTile(
          icon: FxIcons.grafico,
          label: ptS.evolucaoMetricaPeso,
          subtitle: perfilPesoLinha(s, medidas),
          value: '',
          mute: chrome.mute,
          line: chrome.line,
          onTap: () => context.push('/aluno/progresso'),
        ),
        FxSettingsTile(
          icon: FxIcons.fitaMetrica,
          label: s.alunoPerfilRegistrarMedida,
          value: '',
          mute: chrome.mute,
          line: chrome.line,
          showDivider: false,
          onTap: () => context.push('/aluno/perfil/editar?acao=medida'),
        ),
      ],
    );
  }
}
