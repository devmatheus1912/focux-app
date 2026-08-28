import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/fx_loading.dart';
import '../../../core/widgets/fx_settings_group.dart';
import '../../../core/widgets/fx_settings_tile.dart';
import '../constants/aluno_360_layout.dart';
import '../data/aluno_repository.dart';
import '../utils/aluno360_ferramentas_logic.dart';
import 'aluno360_help_sheets.dart';
import 'aluno360_operacao_tab.dart';

/// Ferramentas tab: resumo de medidas + módulos inset.
class Aluno360FerramentasTab extends StatelessWidget {
  const Aluno360FerramentasTab({
    super.key,
    required this.aluno,
    required this.alunoId,
    required this.primary,
    required this.isDark,
    required this.modulesSection,
    this.bf,
    this.massaMagra,
    this.measurementsLoading = false,
    this.animateEntrance = false,
    this.onEntrancePlayed,
  });

  final Aluno aluno;
  final int alunoId;
  final Color primary;
  final bool isDark;
  final Widget modulesSection;
  final String? bf;
  final String? massaMagra;
  final bool measurementsLoading;
  final bool animateEntrance;
  final VoidCallback? onEntrancePlayed;

  void _openMeasurements(BuildContext context) {
    final editarRoute = '/alunos/$alunoId/editar';
    final evolucaoRoute = '/alunos/$alunoId/evolucao';
    if (aluno.idade == null || aluno.altura == null) {
      context.push(editarRoute, extra: aluno);
      return;
    }
    context.push(evolucaoRoute, extra: aluno.nome);
  }

  Widget _section(int step, Widget child) {
    return Aluno360OperacaoEntrance(
      enabled: animateEntrance,
      delay: Duration(milliseconds: step * 40),
      onPlayed: onEntrancePlayed,
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final pending = Aluno360FerramentasLogic.measurementsPendingCount(
      aluno: aluno,
      bf: bf,
      massaMagra: massaMagra,
    );
    final summary = Aluno360FerramentasLogic.measurementsSummary(
      aluno: aluno,
      bf: bf,
      massaMagra: massaMagra,
    );

    final measurements = _section(
      0,
      FxSettingsGroup(
        header: 'Medidas',
        helpTooltip: 'Ajuda sobre medidas corporais',
        onHelpTap: () => showAluno360FerramentasHelpSheet(context),
        accent: primary,
        children: [
          if (measurementsLoading)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: FxLoading.sectionShimmer(
                context,
                height: 52,
                showHeader: false,
              ),
            )
          else
            FxSettingsTile(
              icon: Icons.straighten_outlined,
              label: 'Resumo corporal',
              subtitle: summary,
              value: pending == 0 ? 'OK' : '$pending pend.',
              showDivider: false,
              onTap: () => _openMeasurements(context),
            ),
        ],
      ),
    );
    final modules = _section(1, modulesSection);

    return Semantics(
      container: true,
      label: 'Ferramentas do aluno: medidas corporais e módulos de ação',
      child: Aluno360Layout.operacaoContentWidthLimiter(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            measurements,
            const SizedBox(height: Aluno360FerramentasLogic.sectionDividerGap),
            modules,
          ],
        ),
      ),
    );
  }
}
