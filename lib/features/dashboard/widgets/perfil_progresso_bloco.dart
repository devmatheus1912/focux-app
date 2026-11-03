import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/fx_settings_layout.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/utils/pt_br_display.dart';
import '../../../core/widgets/fx_settings_group.dart';
import '../../../core/widgets/fx_tonal_button.dart';
import '../../../l10n/app_localizations.dart';
import '../../evolucao/data/evolucao_repository.dart';
import '../../evolucao/providers/evolucao_home_provider.dart';
import '../../evolucao/utils/evolucao_series.dart';
import '../../evolucao/widgets/evolucao_hero.dart';

/// "105,0 kg · +15,0 kg"; sem medida, o texto de vazio.
String perfilPesoLinha(S s, List<MedidaCorporal> medidas) {
  final pesos = serieDaMetrica(medidas, EvolucaoMetrica.peso);
  if (pesos.isEmpty) return s.progressoSemPeso;
  final atual = '${formatBrDecimal(pesos.last.valor)} kg';
  if (pesos.length < 2) return atual;
  return '$atual · ${diferencaTexto(pesos.last.valor - pesos.first.valor, 'kg')}';
}

/// Resumo com os anéis, igual ao do personal. Abre Meu progresso em todo estado.
class PerfilProgressoBloco extends ConsumerWidget {
  const PerfilProgressoBloco({super.key, required this.medidas});

  final List<MedidaCorporal> medidas;

  void _abrirProgresso(BuildContext context) =>
      context.push('/aluno/progresso');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    final chrome = ShellChrome.of(context);
    final evolucao = ref.watch(minhaEvolucaoProvider);
    final peso = perfilPesoLinha(s, medidas);
    return FxSettingsGroup(
      header: s.alunoPerfilGrupoProgresso,
      children: [
        Padding(
          padding: const EdgeInsets.all(FxSettingsLayout.groupPadH),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (evolucao.value?.aneis case final aneis?)
                EvolucaoMiniAneis(
                  aneis: aneis,
                  doPersonal: false,
                  onTap: () => _abrirProgresso(context),
                  pesoLinha: peso,
                )
              else if (evolucao.isLoading)
                const SizedBox(height: 88)
              else
                Semantics(
                  button: true,
                  label: s.meuProgressoTitulo,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(TokensStrip.rSm),
                    onTap: () => _abrirProgresso(context),
                    child: Padding(
                      padding: const EdgeInsets.all(TokensStrip.s3),
                      child: Text(
                        peso,
                        style: FocuxHubTypography.body(color: chrome.ink),
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: TokensStrip.s3),
              FxTonalButton(
                label: s.alunoPerfilRegistrarMedida,
                icon: Icons.add_chart,
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
