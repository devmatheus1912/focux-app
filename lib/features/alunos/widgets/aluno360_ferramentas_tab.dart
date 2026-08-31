import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/fx_settings_layout.dart';
import '../../../core/widgets/fx_loading.dart';
import '../../../core/widgets/fx_settings_group.dart';
import '../../../core/widgets/fx_settings_tile.dart';
import '../constants/aluno_360_layout.dart';
import '../data/aluno_repository.dart';
import '../utils/aluno360_ferramentas_logic.dart';
import 'aluno360_help_sheets.dart';
import 'aluno360_operacao_tab.dart';

/// Ferramentas tab: medidas inset + módulos de ação.
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
    final evolucaoRoute = '/alunos/$alunoId/evolucao';

    final measurements = _section(
      0,
      FxSettingsGroup(
        header: 'Medidas',
        caption: Aluno360FerramentasLogic.medidasCaption,
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
          else if (allComplete)
            FxSettingsTile(
              icon: Icons.verified_outlined,
              label: 'Medidas em dia',
              subtitle: completeSummary,
              value: '',
              accent: primary,
              highlight: true,
              showDivider: false,
              semanticsLabel:
                  'Medidas em dia. $completeSummary. Toque para ver evolução.',
              onTap: () => context.push(evolucaoRoute, extra: aluno.nome),
            )
          else
            ...rows.asMap().entries.map((entry) {
              final index = entry.key;
              final row = entry.value;
              return FxSettingsTile(
                icon: _measurementIcon(row.field),
                label: row.label,
                subtitle: row.subtitle,
                value: row.value,
                highlight: row.highlight,
                showDivider: index < rows.length - 1,
                onTap:
                    () => _openMeasurementField(
                      context,
                      row.field,
                      complete: row.complete,
                    ),
              );
            }),
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
            const SizedBox(height: FxSettingsLayout.groupGap),
            modules,
          ],
        ),
      ),
    );
  }
}
