import 'package:flutter/material.dart';

import '../constants/aluno_360_layout.dart';
import '../utils/aluno360_ferramentas_logic.dart';
import 'aluno360_operacao_tab.dart';
import 'aluno360_tab_section_title.dart';

/// Ferramentas tab layout: measurements grid + modules grid.
class Aluno360FerramentasTab extends StatelessWidget {
  const Aluno360FerramentasTab({
    super.key,
    required this.primary,
    required this.isDark,
    required this.measurementsSection,
    required this.modulesSection,
    this.animateEntrance = false,
    this.onEntrancePlayed,
  });

  final Color primary;
  final bool isDark;
  final Widget measurementsSection;
  final Widget modulesSection;
  final bool animateEntrance;
  final VoidCallback? onEntrancePlayed;

  Widget _section(int step, Widget child) {
    return Aluno360OperacaoEntrance(
      enabled: animateEntrance,
      delay: Duration(milliseconds: step * 40),
      onPlayed: onEntrancePlayed,
      child: child,
    );
  }

  Widget _sectionHeader(String title) {
    return Aluno360TabSectionTitle(
      title: title,
      primary: primary,
      isDark: isDark,
    );
  }

  @override
  Widget build(BuildContext context) {
    final measurements = _section(
      0,
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader('Medidas'),
          const SizedBox(height: Aluno360FerramentasLogic.sectionHeaderGap),
          measurementsSection,
        ],
      ),
    );
    final modules = _section(
      1,
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader('Módulos'),
          const SizedBox(height: Aluno360FerramentasLogic.sectionHeaderGap),
          modulesSection,
        ],
      ),
    );

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
