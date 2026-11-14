import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/fx_settings_layout.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/utils/pt_br_display.dart';
import '../../../core/widgets/fx_settings_group.dart';
import '../../../core/widgets/fx_tonal_button.dart';
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

/// Peso atual e "Registrar medida". A semana e a meta ficam na Hoje e no Meu
/// progresso; aqui não se repetem (os mini-anéis saíram em 14/11).
class PerfilProgressoBloco extends StatelessWidget {
  const PerfilProgressoBloco({super.key, required this.medidas});

  final List<MedidaCorporal> medidas;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final chrome = ShellChrome.of(context);
    final peso = '${ptS.evolucaoMetricaPeso}: ${perfilPesoLinha(s, medidas)}';
    return FxSettingsGroup(
      header: s.alunoPerfilGrupoProgresso,
      children: [
        Padding(
          padding: const EdgeInsets.all(FxSettingsLayout.groupPadH),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Semantics(
                button: true,
                label: '${s.meuProgressoTitulo}. $peso',
                excludeSemantics: true,
                child: InkWell(
                  borderRadius: BorderRadius.circular(TokensStrip.rSm),
                  onTap: () => context.push('/aluno/progresso'),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: TokensStrip.s2),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            peso,
                            style: FocuxHubTypography.body(color: chrome.ink),
                          ),
                        ),
                        Icon(FxIcons.chevronDireita, color: chrome.mute),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: TokensStrip.s3),
              FxTonalButton(
                label: s.alunoPerfilRegistrarMedida,
                icon: FxIcons.grafico,
                expanded: true,
                onPressed:
                    () => context.push('/aluno/perfil/editar?acao=medida'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
