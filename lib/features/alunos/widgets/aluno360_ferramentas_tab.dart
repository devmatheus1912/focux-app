import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/tokens_strip.dart';
import '../../../core/widgets/fx_loading.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../dashboard/widgets/dashboard_section_header.dart';
import '../constants/aluno_360_layout.dart';
import '../data/aluno_repository.dart';
import '../utils/aluno360_ferramentas_logic.dart';
import 'aluno360_help_sheets.dart';
import 'aluno360_operacao_tab.dart';

/// Ferramentas tab: medidas + módulos de ação no first paint.
class Aluno360FerramentasTab extends StatelessWidget {
  const Aluno360FerramentasTab({
    super.key,
    required this.aluno,
    required this.alunoId,
    required this.primary,
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
  final Widget modulesSection;
  final String? bf;
  final String? massaMagra;
  final bool measurementsLoading;
  final bool animateEntrance;
  final VoidCallback? onEntrancePlayed;

  void _openMeasurementField(
    BuildContext context,
    Aluno360MeasurementField field, {
    required bool complete,
  }) {
    final editarRoute = '/alunos/$alunoId/editar';
    final evolucaoRoute = '/alunos/$alunoId/evolucao';
    switch (field) {
      case Aluno360MeasurementField.idade:
      case Aluno360MeasurementField.altura:
        if (!complete) {
          context.push(editarRoute, extra: aluno);
          return;
        }
        context.push(evolucaoRoute, extra: aluno.nome);
      case Aluno360MeasurementField.gordura:
      case Aluno360MeasurementField.massaMagra:
        // Composição corporal registra na Evolução (nova medida).
        context.push(evolucaoRoute, extra: aluno.nome);
    }
  }

  IconData _measurementIcon(Aluno360MeasurementField field) {
    return switch (field) {
      Aluno360MeasurementField.idade => Icons.cake_outlined,
      Aluno360MeasurementField.altura => Icons.height_outlined,
      Aluno360MeasurementField.gordura => Icons.pie_chart_outline_outlined,
      Aluno360MeasurementField.massaMagra => Icons.monitor_weight_outlined,
    };
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
    final rows = Aluno360FerramentasLogic.measurementRows(
      aluno: aluno,
      bf: bf,
      massaMagra: massaMagra,
    );
    final allComplete = Aluno360FerramentasLogic.measurementsAllComplete(
      aluno: aluno,
      bf: bf,
      massaMagra: massaMagra,
    );
    final completeSummary = Aluno360FerramentasLogic.measurementsCompleteSummary(
      aluno: aluno,
      bf: bf,
      massaMagra: massaMagra,
    );

    final measurements = _section(
      0,
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DashboardSectionHeader(
            title: 'Medidas',
            actionLabel: 'Ajuda',
            onAction: () => showAluno360FerramentasHelpSheet(context),
          ),
          Text(
            Aluno360FerramentasLogic.medidasCaption,
            style: Aluno360Layout.metaStyle(context),
          ),
          const SizedBox(height: TokensStrip.s3),
          if (measurementsLoading)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: FxLoading.sectionShimmer(
                context,
                height: 52,
                showHeader: false,
              ),
            )
          else if (allComplete)
            Semantics(
              label:
                  'Medidas em dia. $completeSummary. Toque para registrar ou ver evolução.',
              button: true,
              child: FxSatelliteListTile(
                title: 'Medidas em dia',
                titleCase: false,
                subtitle: Text(completeSummary),
                accent: primary,
                onTap:
                    () => context.push(
                      '/alunos/$alunoId/evolucao',
                      extra: aluno.nome,
                    ),
              ),
            )
          else
            ...rows.map(
              (row) => FxSatelliteListTile(
                title: row.label,
                titleCase: false,
                subtitle: Text(row.subtitle),
                trailing: Text(row.value),
                leading: Icon(_measurementIcon(row.field), color: primary),
                accent: row.highlight ? primary : null,
                onTap:
                    () => _openMeasurementField(
                      context,
                      row.field,
                      complete: row.complete,
                    ),
              ),
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
            const SizedBox(height: TokensStrip.s4),
            modules,
          ],
        ),
      ),
    );
  }
}
