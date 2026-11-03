import 'package:flutter/material.dart';

import '../../evolucao/providers/evolucao_home_provider.dart';
import '../../evolucao/utils/evolucao_series.dart';
import '../../evolucao/widgets/evolucao_hero.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/tokens_strip.dart';
import '../../../core/widgets/fx_loading.dart';
import '../../../core/widgets/fx_action_chip.dart';
import '../../dashboard/widgets/dashboard_section_header.dart';
import '../constants/aluno_360_layout.dart';
import '../data/aluno_repository.dart';
import '../providers/aluno_detail_providers.dart';
import '../../../l10n/app_localizations.dart';
import '../utils/aluno360_medida_plausivel.dart';
import '../utils/aluno360_peso_fonte.dart';
import '../../../core/utils/pt_br_display.dart';

class Aluno360WeightActivityCard extends ConsumerWidget {
  const Aluno360WeightActivityCard({
    super.key,
    required this.aluno,
    required this.alunoId,
    required this.isDark,
    required this.ink,
    this.hasRadarP0 = false,
    this.suppressRadarHint = false,
  });

  final Aluno aluno;
  final int alunoId;
  final bool isDark;
  final Color ink;
  final bool hasRadarP0;
  final bool suppressRadarHint;

  void _openEvolucao(BuildContext context) {
    context.push('/alunos/$alunoId/evolucao', extra: aluno.nome);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pesoHistoricoAsync = ref.watch(alunoPesoHistoricoProvider(alunoId));
    final primary = Theme.of(context).colorScheme.primary;
    final historico = pesoHistoricoAsync.asData?.value ?? const <double>[];
    final peso = pesoMostrado(historico: historico, cadastro: aluno.peso);
    final suspeito =
        peso != null && !medidaPlausivel(MedidaTipo.pesoKg, peso.valor);
    final showRadarHint = hasRadarP0 && !suppressRadarHint && peso == null;

    return Semantics(
      container: true,
      label: 'Peso e tendência corporal',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DashboardSectionHeader(title: S.of(context).corpoTitulo),
          const SizedBox(height: TokensStrip.s3),
          if (ref.watch(evolucaoHomeProvider(alunoId)).value?.aneis case final aneis?)
            EvolucaoMiniAneis(
              aneis: aneis,
              doPersonal: true,
              onTap: () => _openEvolucao(context),
              pesoLinha: peso == null
                  ? S.of(context).aluno360SemMedida
                  : suspeito
                  ? S.of(context).aluno360PesoAConfirmar
                  : peso.origem == PesoOrigem.cadastro
                  ? '${formatBrDecimal(peso.valor)} kg · ${S.of(context).aluno360PesoDoCadastro}'
                  : _pesoComDiferenca(peso.valor, historico),
            )
          else
            FxLoading.sectionShimmer(context, height: 72, showHeader: false),
          if (peso == null) ...[
            const SizedBox(height: TokensStrip.s2),
            Align(
              alignment: Alignment.centerLeft,
              child: FxActionChip(
                label: 'Registrar primeira medida',
                accent: primary,
                isDark: isDark,
                onPressed: () => _openEvolucao(context),
              ),
            ),
          ],
          if (showRadarHint) ...[
            const SizedBox(height: TokensStrip.s2),
            Text(
              'Mapa corporal pendente no radar',
              style: Aluno360Layout.metaStyle(context),
            ),
          ],
        ],
      ),
    );
  }

  static String _pesoComDiferenca(double atual, List<double> historico) {
    final texto = '${formatBrDecimal(atual)} kg';
    if (historico.length < 2) return texto;
    return '$texto · ${diferencaTexto(historico.last - historico.first, 'kg')}';
  }
}
